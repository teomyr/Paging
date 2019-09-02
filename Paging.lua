local PagingOptions, PagingOverrideModifiers;
local PagingInitialized = false;
local PagingBindingsUpdated = false;

local PagingFrame = CreateFrame("FRAME", nil, nil, "SecureHandlerStateTemplate");

PagingFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
PagingFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED");
PagingFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR");
PagingFrame:RegisterEvent("UPDATE_BINDINGS");

PagingFrame.UpdatePageDisplay = function(self)
	local referenceButton = ActionButton1;
	local currentPage = referenceButton:GetAttribute("actionpage");
	local isCurrentlyPaged = (currentPage ~= nil);

	if isCurrentlyPaged then
		-- The action bar page is currently modified by us, thus we disable the
		-- default up/down paging mechanism to indicate this.
		ActionBarUpButton:Disable();
		ActionBarDownButton:Disable();

		if MainMenuBarArtFrame.PageNumber:IsVisible() and MainMenuBarArtFrameBackground:IsVisible() then
			PagingIndicatorFrame:Show();
		end
	else
		-- No paging is currently done, the default action bar is visible.
		-- Enable the default controls.
		ActionBarUpButton:Enable();
		ActionBarDownButton:Enable();
		PagingIndicatorFrame:Hide();

		local isShowingBonusBar = (GetActionBarPage() == 1 and GetBonusBarOffset() > 0);

		if isShowingBonusBar then
			-- A "bonus action bar" such as Shadowform or Stealth is currently shown.
			currentPage = NUM_ACTIONBAR_PAGES + GetBonusBarOffset();
		else
			currentPage = GetActionBarPage();
		end
	end

	MainMenuBarArtFrame.PageNumber:SetText(currentPage);
end;

function Paging_Initialize()
	if InCombatLockdown() then
		PagingFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		return
	end

	Paging_InitializeRestrictedEnvironment();

	PagingFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
	PagingInitialized = true;
end

function Paging_InitializeRestrictedEnvironment()
	PagingFrame:Execute(([[
		NUM_ACTIONBAR_BUTTONS = %d;
		buttons = newtable();
	]]):format(NUM_ACTIONBAR_BUTTONS));

	for id = 1, NUM_ACTIONBAR_BUTTONS do
		local button_name = "ActionButton" .. id;

		PagingFrame:SetFrameRef(button_name, getglobal(button_name));

		PagingFrame:Execute(([[
			buttons[%d] = self:GetFrameRef("%s");
		]]):format(id, button_name));
	end

	PagingFrame:SetAttribute("_onstate-paging", ([[
		local newpage = tonumber(self:GetAttribute("state-paging"));

		for index, button in pairs(buttons) do
			button:SetAttribute("actionpage", newpage);
		end

		control:CallMethod("UpdatePageDisplay");
	]]):format(NUM_ACTIONBAR_BUTTONS));
end

function Paging_UpdateBindings()
	-- Some combinations like SHIFT-1, SHIFT-2 etc. might be already bound to
	-- other functions. We check which combinations are required by the current
	-- paging options and then override those key combinations.

	if PagingOptions == nil then
		return
	end

	if InCombatLockdown() then
		PagingFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		return
	end

	ClearOverrideBindings(PagingFrame);

	if PagingOverrideModifiers then
		-- find selectors (anything in square brackets)
		for selector in string.gmatch(PagingOptions, "%b[]") do
			-- find modifier specifiers ("mod:" or "modifier:")

			for modifier_string in string.gmatch(selector, "mod%s*:%s*([^%],]+)") do
				-- find individual modifiers (e.g. "ctrl" or "alt-shift")
				for modifier in string.gmatch(modifier_string, "[%a-]+") do
					Paging_OverrideSingleModifier(modifier);
				end
			end

			for modifier_string in string.gmatch(selector, "modifier%s*:%s*([^%[,]+)") do
				for modifier in string.gmatch(modifier_string, "[%a-]+") do
					Paging_OverrideSingleModifier(modifier);
				end
			end
		end
	end

	PagingFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
	PagingBindingsUpdated = true;
end

local function modifierCombinations(modIter)
	-- Given an iterator that yields one modifier each, list all possible
	-- combinations that are part of it, e.g. for "alt-shift-lctrl", this
	-- yields "alt", "alt-shift", "alt-shift-ctrl", "alt-shift-lctrl" etc.
	-- not necessarily in this order

	local mod = modIter();

	if mod ~= nil then
		local index = 0;
		local sub_iterator = modifierCombinations(modIter);
		local sub_term;
		local side_spec, side_neutral_mod = string.match(mod, "^([rl])(%a+)$");

		return function()
			index = index + 1;

			if index == 1 then
				return mod;
			end

			if index == 2 then
				if side_spec ~= nil then
					return side_neutral_mod;
				else
					index = index + 1;
				end
			end

			if sub_iterator ~= nil then
				if index % 3 == 2 then
					if side_spec ~= nil then
						if sub_term ~= nil then
							return side_neutral_mod .. "-" .. sub_term;
						end
					else
						index = index + 1;
					end
				end

				if index % 3 == 0 then
					sub_term = sub_iterator();

					if sub_term ~= nil then
						return sub_term;
					end
				elseif index % 3 == 1 then
					if sub_term ~= nil then
						return mod .. "-" .. sub_term;
					end
				end
			end
		end
	end
end

function Paging_OverrideSingleModifier(modifier)
	for combination in modifierCombinations(string.gmatch(modifier, "%a+")) do
		for button_index = 1, NUM_ACTIONBAR_BUTTONS do
			local command = "ACTIONBUTTON" .. button_index;
			local primary_binding = GetBindingKey(command);

			if primary_binding ~= nil then
				local modified_binding = combination .. "-" .. primary_binding;

				if GetBindingAction(modified_binding) ~= "" then
					SetOverrideBinding(PagingFrame, false, modified_binding, "nil");
				end
			end
		end

	end
end

function Paging_SetOptions(options, overrideModifiers)
	PagingOverrideModifiers = overrideModifiers;

	if not PagingInitialized or InCombatLockdown() then
		PagingOptionsQueued = options;

		if InCombatLockdown() then
			PagingFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		end

		return;
	end

	PagingOptions = options;
	PagingOptionsQueued = nil;

	PagingFrame:SetAttribute("state-paging", SecureCmdOptionParse(options));

	RegisterAttributeDriver(PagingFrame, "state-paging", options);

	PagingBindingsUpdated = false;
	Paging_UpdateBindings();
end

PagingFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
		if not PagingInitialized then
			Paging_Initialize();
		end

		if not PagingBindingsUpdated then
			Paging_UpdateBindings();
		end

		if PagingOptionsQueued then
			Paging_SetOptions(PagingOptionsQueued, PagingOverrideModifiers);
		end
	elseif event == "UPDATE_BINDINGS" then
		PagingBindingsUpdated = false;
		Paging_UpdateBindings();
	elseif event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
		self:UpdatePageDisplay();
	end
end);
