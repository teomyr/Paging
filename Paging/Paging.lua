local PagingOptions;
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
		PagingIndicatorFrame:Show();
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
	
	MainMenuBarPageNumber:SetText(currentPage);
end;

function Paging_Initialize()
	if InCombatLockdown() then
		PagingFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		return
	end

	Paging_InitializeRestrictedEnvironment();

	PagingFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
	PagingInitialized = true;

	print("Paging 1.0.2 (Dual-Override branch) initialized. Experimental release - please test thoroughly!");
end

function Paging_InitializeRestrictedEnvironment()
	PagingFrame:SetFrameRef("BonusActionBarFrame", BonusActionBarFrame);

	PagingFrame:Execute(([[
		NUM_ACTIONBAR_BUTTONS = %d;
		buttons = newtable();
		BonusActionBarFrame = self:GetFrameRef("BonusActionBarFrame");
	]]):format(NUM_ACTIONBAR_BUTTONS));

	for id = 1, NUM_ACTIONBAR_BUTTONS do
		local button_name = "ActionButton" .. id;
		local bonusbutton_name = "BonusActionButton" .. id;

		PagingFrame:SetFrameRef(button_name, getglobal(button_name));
		PagingFrame:SetFrameRef(bonusbutton_name, getglobal(bonusbutton_name));

		PagingFrame:Execute(([[
			buttons[%d] = self:GetFrameRef("%s");
			buttons[%d + NUM_ACTIONBAR_BUTTONS] = self:GetFrameRef("%s");
		]]):format(id, button_name, id, bonusbutton_name));
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

	for button_index = 1, NUM_ACTIONBAR_BUTTONS do
		local command = "ACTIONBUTTON" .. button_index;
		local primary_binding = GetBindingKey(command);

		if primary_binding ~= nil then
			for modifier in string.gmatch(PagingOptions, "%[[^%]]*mod%s*:%s*(%w+)[^%]]*%]") do
				local modified_binding = modifier .. "-" .. primary_binding;

				if GetBindingAction(modified_binding) ~= "" then
					SetOverrideBinding(PagingFrame, false, modified_binding, "nil");
				end
			end
		end
	end

	PagingFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
	PagingBindingsUpdated = true;
end

function Paging_SetOptions(options)
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

	RegisterStateDriver(PagingFrame, "paging", options);
	
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
			Paging_SetOptions(PagingOptionsQueued);
		end
	elseif event == "UPDATE_BINDINGS" then
		PagingBindingsUpdated = false;
		Paging_UpdateBindings();
	elseif event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
		self:UpdatePageDisplay();
	end
end);
