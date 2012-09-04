local addonName, L = ...;

local PagingUseProfileBackup; -- Store previous configuration so we can revert
local PagingProfilesBackup;   -- to it on Cancel

local PagingEditProfile; -- which profile is being edited

-- Profile management functions and data --

local PagingProfile_Types = {
	CHARACTER = L["Character"],
	CLASS = L["Class"],
	REALM = L["Realm"],
	DEFAULT = L["Default"],
	EXAMPLE = L["Example"],
};

local PagingProfile_AutoProfiles = {
	["CHARACTER"] = "CHARACTER:" .. UnitName("player") .. "-" .. GetRealmName(),
	["CLASS"] = "CLASS:" .. UnitClassBase("player"),
	["REALM"] = "REALM:" .. GetRealmName(),
	["DEFAULT"] = "DEFAULT",
};

local PagingProfile_AutoProfilesPriority = {
	"CHARACTER", "CLASS", "REALM", "DEFAULT"
};

function PagingProfile_Initialize()
	if type(PagingProfiles) ~= "table" then
		PagingProfiles = {};
	end

	-- Create example profile if necessary
	if not PagingProfile_Exists("EXAMPLE") then
		PagingProfile_Create("EXAMPLE");
		PagingProfiles["EXAMPLE"].selector = "[mod: shift] 6; [mod: ctrl] 5;";
	end

	PagingProfile_ApplyEffectiveProfile();
end

function PagingProfile_ApplyEffectiveProfile()
	PagingProfile_Apply(PagingProfile_GetEffectiveProfile());
end

function PagingProfile_Apply(profileName)
	local options = "";
	local overrideModifiers = true;

	if PagingProfile_Exists(profileName) then
		options = PagingProfiles[profileName].selector;
		overrideModifiers = (PagingProfiles[profileName].overrideModifiers ~= false);
	end

	-- By default, we disable Paging for certain "special" occasions where the
	-- default action bar is overridden, such as in vehicles, while possessing
	-- an enemy unit or during pet battles. The user may not think about
	-- accounting for these, and it would be very unfortunate if his selector
	-- broke them at an inconvenient time.
	-- The user can change this behaviour by explicitly adding a selector for
	-- these bars as desired.

	local disableFor = { "overridebar", "extrabar", "possessbar", "petbattle" };
	local disableForSelector = "";

	for i, bar in ipairs(disableFor) do
		if string.find(options, bar) == nil then
			disableForSelector = disableForSelector .. "[" .. bar .. "]";
		end
	end

	if disableForSelector == "" then
		Paging_SetOptions(options, overrideModifiers);
	else
		Paging_SetOptions(disableForSelector .. ";" .. options, overrideModifiers);
	end
end

function PagingProfile_Exists(profileName)
	return (type(PagingProfiles) == "table" and type(PagingProfiles[profileName]) == "table");
end

function PagingProfile_IsActive(profileName)
	return (PagingProfile_Exists(profileName) and PagingProfiles[profileName].selector ~= "");
end

function PagingProfile_Create(profileName)
	if not PagingProfile_Exists(profileName) then
		PagingProfiles[profileName] = { selector = "", overrideModifiers = true };
		return true;
	end

	return false;
end

function PagingProfile_Delete(profileName)
	if PagingProfile_Exists(profileName) then
		PagingProfiles[profileName] = nil;
		return true;
	end

	return false;
end

local function deepcopy(object)
	-- Create a deep copy of an object.
	-- from http://lua-users.org/wiki/CopyTable

	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

function PagingProfile_Copy(sourceProfile, destinationProfile)
	if sourceProfile == destinationProfile then
		return;
	end

	-- Ensure that the target profile exists
	PagingProfile_Create(destinationProfile);

	-- Copy profile
	PagingProfiles[destinationProfile] = deepcopy(PagingProfiles[sourceProfile]);
end

function PagingProfile_GetDisplayText(profileName)
	local profileType, profileSubject = profileName:match("(%u+):?([^-]*)");
	local displayText = NORMAL_FONT_COLOR_CODE .. PagingProfile_Types[profileType];

	if profileSubject ~= "" then
		if PagingProfile_IsActive(profileName) then
			displayText = displayText .. ": " .. FONT_COLOR_CODE_CLOSE .. profileSubject;
		else
			displayText = displayText .. ": " .. GRAY_FONT_COLOR_CODE .. profileSubject;
		end
	end

	if PagingUseProfile == nil and PagingProfile_GetAutomaticProfile() == profileName then
		displayText = displayText .. GREEN_FONT_COLOR_CODE .. " (" .. L["automatic"] .. ")";
	end

	return displayText;
end

function PagingProfile_GetEffectiveProfile()
	if PagingUseProfile ~= nil then
		return PagingUseProfile;
	else
		return PagingProfile_GetAutomaticProfile();
	end
end

function PagingProfile_GetAutomaticProfile()
	if PagingProfiles ~= nil then
		for _, autoProfileClass in pairs(PagingProfile_AutoProfilesPriority) do
			local profileName = PagingProfile_AutoProfiles[autoProfileClass];

			if PagingProfile_IsActive(profileName) or profileName == "DEFAULT" then
				return profileName;
			end
		end
	end

	return "DEFAULT";
end

function PagingProfile_Edit(profileName)
	UIDropDownMenu_SetSelectedValue(PagingSettingsFrameProfileSelection, profileName);
	PagingSettingsFrameProfileSelection_UpdateText();

	PagingEditProfile = profileName;

	PagingProfile_Create(profileName);
	local profileObject = PagingProfiles[profileName];

	PagingSettingsFrameEditSelectorText:SetText(profileObject.selector);
	PagingSettingsFrameOverrideModifiers:SetChecked(profileObject.overrideModifiers ~= false);

	PagingProfile_Apply(profileName);
end

-- Settings frame --

local retainBackup = false;

function PagingSettingsFrame_Refresh(self)
	-- Called when the settings frame is brought up or after applying defaults.
	
	PagingSettingsFrameAutoChooseProfile:SetChecked(PagingUseProfile == nil);
	PagingProfile_Edit(PagingProfile_GetEffectiveProfile());

	if not retainBackup then
		-- This will be skipped after the user has pressed the "Defaults" button
		-- to reset the addon's settings, in order to give him a chance to
		-- undo that decision by pressing "Cancel".

		PagingUseProfileBackup = PagingUseProfile;
		PagingProfilesBackup = deepcopy(PagingProfiles);
	end

	retainBackup = false;
end

function PagingSettingsFrame_Okay(self)
	PagingProfile_ApplyEffectiveProfile();
end

function PagingSettingsFrame_Cancel(self)
	PagingUseProfile = PagingUseProfileBackup;
	PagingProfiles = deepcopy(PagingProfilesBackup);

	PagingProfile_ApplyEffectiveProfile();
end

function PagingSettingsFrame_Default(self)
	-- Clear this character's settings
	
	-- Before clearing, make a backup so that the user can undo this using
	-- the "Cancel" button.
	PagingUseProfileBackup = PagingUseProfile;
	PagingProfilesBackup = deepcopy(PagingProfiles);
	retainBackup = true;

	PagingUseProfile = nil;
	PagingProfile_Delete(PagingProfile_AutoProfiles["CHARACTER"]);

	-- Blizzard's UI sends a refresh event right afterwards
end

function PagingSettingsFrame_OnLoad(self)
	PagingSettingsFrameVersion:SetText(L["Version %s"]:format(GetAddOnMetadata(addonName, "Version")));

	self.name = L["Paging"];
	self.refresh = PagingSettingsFrame_Refresh;
	self.okay = PagingSettingsFrame_Okay;
	self.cancel = PagingSettingsFrame_Cancel;
	self.default = PagingSettingsFrame_Default;

	InterfaceOptions_AddCategory(self);

	self:RegisterEvent("VARIABLES_LOADED");
end

function PagingSettingsFrame_OnEvent(self, event)
	if event == "VARIABLES_LOADED" then
		PagingProfile_Initialize();
	end
end

-- Profile selection --

function PagingSettingsFrameProfileSelection_UpdateText()
	local profileName = UIDropDownMenu_GetSelectedValue(PagingSettingsFrameProfileSelection);
	PagingSettingsFrameProfileSelectionText:SetText(PagingProfile_GetDisplayText(profileName));
end

function PagingSettingsFrameProfileSelection_DropDownOnClick(info)
	PagingProfile_Edit(info.value);
	PagingUseProfile = info.value;
	
	if PagingUseProfile ~= PagingProfile_GetAutomaticProfile() then
		PagingSettingsFrameAutoChooseProfile:SetChecked(false);
	end
end

StaticPopupDialogs["PAGING_CONFIRM_OVERWRITE"] = {
	text = L["This will overwrite the old selector you have configured for profile %s.\nAre you sure?"],
	button1 = OKAY,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	timeout = 0,
};

function PagingSettingsFrameProfileSelection_CopyFromOnClick(info)
	local sourceProfile = info.value;

	CloseDropDownMenus(1);

	function commitCopy()
		PagingProfile_Copy(sourceProfile, PagingEditProfile);

		-- Update UI
		PagingProfile_Edit(PagingEditProfile);
	end

	-- Prompt before simply overwriting the currently edited selector
	if PagingProfile_IsActive(PagingEditProfile) then
		StaticPopupDialogs["PAGING_CONFIRM_OVERWRITE"].OnAccept = commitCopy;
		
		local profileType, profileSubject = PagingEditProfile:match("(%u+):?([^-]*)");
		local displayText = PagingProfile_Types[profileType];

		if profileSubject ~= "" then
			displayText = displayText .. ": " .. profileSubject;
		end

		StaticPopup_Show("PAGING_CONFIRM_OVERWRITE", NORMAL_FONT_COLOR_CODE .. displayText .. FONT_COLOR_CODE_CLOSE);
	else
		commitCopy();
	end
end

function PagingSettingsFrameProfileSelection_DropDownCallback(self, level)
	local info = UIDropDownMenu_CreateInfo();

	if level == 1 then
		-- Entries for main level of profile selection:
		info.func = PagingSettingsFrameProfileSelection_DropDownOnClick;

		-- Generate list of available profiles
		for _, autoProfileClass in pairs(PagingProfile_AutoProfilesPriority) do
			local profileName = PagingProfile_AutoProfiles[autoProfileClass];

			info.text = PagingProfile_GetDisplayText(profileName);
			info.value = profileName;
			info.checked = nil;
			UIDropDownMenu_AddButton(info, level);
		end

		-- Entry leading to "Copy from" sub menu
		info.hasArrow = true;
		info.notCheckable = true;
		info.func = nil;
		info.text = L["Copy from…"];
		info.value = nil;
		UIDropDownMenu_AddButton(info, level);
	elseif level == 2 then
		-- Entries for "Copy from" sub menu
		info.notCheckable = true;
		info.func = PagingSettingsFrameProfileSelection_CopyFromOnClick;

		for profileName, profile in pairs(PagingProfiles) do
			-- Generate list of all existing profiles, but skip empty ones and
			-- the one currently being edited.
			if profileName ~= PagingEditProfile and profile.selector ~= "" then
				local profileType, profileSubject = profileName:match("(%u+):?(.*)");
				local displayText = NORMAL_FONT_COLOR_CODE .. PagingProfile_Types[profileType];

				if profileSubject ~= "" then
					displayText = displayText .. ": " .. FONT_COLOR_CODE_CLOSE .. profileSubject;
				end

				info.text = displayText;
				info.value = profileName;

				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
end

function PagingSettingsFrameAutoChooseProfile_OnClick(self)
	if self:GetChecked() then
		PagingUseProfile = nil;
		PagingProfile_Edit(PagingProfile_GetAutomaticProfile());
	else
		PagingUseProfile = UIDropDownMenu_GetSelectedValue(PagingSettingsFrameProfileSelection);
	end

	PagingSettingsFrameProfileSelection_UpdateText();
end

-- Override Modifiers --

function PagingSettingsFrameOverrideModifiers_OnClick(self)
	PagingProfiles[PagingEditProfile].overrideModifiers = (self:GetChecked() == 1);
	PagingProfile_ApplyEffectiveProfile();
end

-- Selector --

function PagingSettingsFrameEditSelectorText_OnTextChanged(self)
	PagingProfiles[PagingEditProfile].selector = self:GetText();

	PagingSettingsFrameProfileSelection_UpdateText();
end

function PagingSettingsFrameEditSelectorText_OnEditFocusLost(self)
	PagingProfile_ApplyEffectiveProfile();
end
