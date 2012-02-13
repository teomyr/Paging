local addonName, L = ...;

local PagingUseProfileTemporary;
local PagingProfilesTemporary;
local PagingEditProfile;

-- Profile management functions and data --

local PagingProfile_Types = {
	CHARACTER = L["Character"],
	CLASS = L["Class"],
	REALM = L["Realm"],
	DEFAULT = L["Default"],
	EXAMPLE = L["Example"],
};

local PagingProfile_AutoProfiles = {
	"CHARACTER:" .. UnitName("player") .. "-" .. GetRealmName(),
	"CLASS:" .. UnitClassBase("player"),
	"REALM:" .. GetRealmName(),
	"DEFAULT",
};

function PagingProfile_Initialize()
	if type(PagingProfiles) ~= "table" then
		PagingProfiles = {};
	end

	-- Create example profile if necessary
	if not PagingProfile_Exists(PagingProfiles, "EXAMPLE") then
		PagingProfile_Create(PagingProfiles, "EXAMPLE");
		PagingProfiles["EXAMPLE"].selector = "[mod:shift] 6; [mod:ctrl] 5;";
	end

	PagingProfile_ApplyEffectiveProfile();
end

function PagingProfile_ApplyEffectiveProfile()
	local usedProfile = PagingProfile_GetEffectiveProfile(PagingProfiles, PagingUseProfile);
	local options = "";
	local overrideModifiers = true;

	if PagingProfile_Exists(PagingProfiles, usedProfile) then
		options = PagingProfiles[usedProfile].selector;
		overrideModifiers = (PagingProfiles[usedProfile].overrideModifiers ~= false);
	end

	Paging_SetOptions(options, overrideModifiers);
end

function PagingProfile_ApplyTemporaryProfile()
	Paging_SetOptions(PagingSettingsFrameEditSelectorText:GetText(), (PagingSettingsFrameOverrideModifiers:GetChecked() == 1));
end

function PagingProfile_Exists(profiles, profileName)
	return (type(profiles) == "table" and type(profiles[profileName]) == "table");
end

function PagingProfile_IsActive(profiles, profileName)
	return (PagingProfile_Exists(profiles, profileName) and profiles[profileName].selector ~= "");
end

function PagingProfile_Create(profiles, profileName)
	if not PagingProfile_Exists(profiles, profileName) then
		profiles[profileName] = { selector = "", overrideModifiers = true };
		return true;
	end

	return false;
end

function PagingProfile_Delete(profiles, profileName)
	if PagingProfile_Exists(profiles, profileName) then
		profiles[profileName] = nil;
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

function PagingProfile_Copy(profiles, sourceProfile, destinationProfile)
	if sourceProfile == destinationProfile then
		return;
	end

	-- Ensure that the target profile exists
	PagingProfile_Create(profiles, destinationProfile);

	-- Copy profile
	profiles[destinationProfile] = deepcopy(profiles[sourceProfile]);
end

function PagingProfile_GetDisplayText(profiles, profileName)
	local profileType, profileSubject = profileName:match("(%u+):?([^-]*)");
	local displayText = NORMAL_FONT_COLOR_CODE .. PagingProfile_Types[profileType];

	if profileSubject ~= "" then
		if PagingProfile_IsActive(profiles, profileName) then
			displayText = displayText .. ": " .. FONT_COLOR_CODE_CLOSE .. profileSubject;
		else
			displayText = displayText .. ": " .. GRAY_FONT_COLOR_CODE .. profileSubject;
		end
	end

	if PagingUseProfileTemporary == nil and PagingProfile_GetAutomaticProfile(profiles) == profileName then
		displayText = displayText .. GREEN_FONT_COLOR_CODE .. " (" .. L["automatic"] .. ")";
	end

	return displayText;
end

function PagingProfile_GetEffectiveProfile(profiles, useProfile)
	if useProfile ~= nil then
		return useProfile;
	else
		return PagingProfile_GetAutomaticProfile(profiles);
	end
end

function PagingProfile_GetAutomaticProfile(profiles)
	if profiles ~= nil then
		for profileIndex, profileName in pairs(PagingProfile_AutoProfiles) do
			if PagingProfile_IsActive(profiles, profileName) or profileName == "DEFAULT" then
				return profileName;
			end
		end
	end

	return "DEFAULT";
end

function PagingProfile_Edit(profiles, profileName)
	UIDropDownMenu_SetSelectedValue(PagingSettingsFrameProfileSelection, profileName);
	PagingSettingsFrameProfileSelection_UpdateText();

	PagingEditProfile = profileName;

	PagingProfile_Create(PagingProfilesTemporary, profileName);
	local profileObject = PagingProfilesTemporary[profileName];

	PagingSettingsFrameEditSelectorText:SetText(profileObject.selector);
	PagingSettingsFrameOverrideModifiers:SetChecked(profileObject == nil or profileObject.overrideModifiers ~= false);

	PagingProfile_ApplyTemporaryProfile();
end

-- Settings frame --

function PagingSettingsFrame_Refresh(self)
	PagingUseProfileTemporary = PagingUseProfile;

	if type(PagingProfiles) == "table" then
		PagingProfilesTemporary = deepcopy(PagingProfiles);
	else
		PagingProfilesTemporary = {};
	end

	if PagingUseProfileTemporary ~= nil then
		PagingSettingsFrameAutoChooseProfile:SetChecked(false);
		PagingProfile_Edit(PagingProfilesTemporary, PagingUseProfileTemporary);
	else
		PagingSettingsFrameAutoChooseProfile:SetChecked(true);
		PagingProfile_Edit(PagingProfilesTemporary, PagingProfile_GetAutomaticProfile(PagingProfilesTemporary));
	end
end

function PagingSettingsFrame_Okay(self)
	PagingUseProfile = PagingUseProfileTemporary;
	PagingProfiles = deepcopy(PagingProfilesTemporary);

	PagingProfile_ApplyEffectiveProfile();
end

function PagingSettingsFrame_Cancel(self)
	PagingProfile_ApplyEffectiveProfile();
end

function PagingSettingsFrame_OnLoad(self)
	PagingSettingsFrameVersion:SetText(L["Version %s"]:format(GetAddOnMetadata(addonName, "Version")));

	self.name = L["Paging"];
	self.refresh = PagingSettingsFrame_Refresh;
	self.okay = PagingSettingsFrame_Okay;
	self.cancel = PagingSettingsFrame_Cancel;

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
	PagingSettingsFrameProfileSelectionText:SetText(PagingProfile_GetDisplayText(PagingProfilesTemporary, profileName));
end

function PagingSettingsFrameProfileSelection_DropDownOnClick(info)
	PagingProfile_Edit(PagingProfilesTemporary, info.value);
	PagingUseProfileTemporary = info.value;
	
	if PagingUseProfileTemporary ~= PagingProfile_GetAutomaticProfile(PagingProfilesTemporary) then
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
		PagingProfile_Copy(PagingProfilesTemporary, sourceProfile, PagingEditProfile);

		-- Update UI
		PagingProfile_Edit(PagingProfilesTemporary, PagingEditProfile);
	end

	-- Prompt before simply overwriting the currently edited selector
	if PagingProfile_IsActive(PagingProfilesTemporary, PagingEditProfile) then
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
		for profileType, profileName in pairs(PagingProfile_AutoProfiles) do
			info.text = PagingProfile_GetDisplayText(PagingProfilesTemporary, profileName);
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
		PagingUseProfileTemporary = nil;
		PagingProfile_Edit(PagingProfilesTemporary, PagingProfile_GetAutomaticProfile(PagingProfilesTemporary));
	else
		PagingUseProfileTemporary = UIDropDownMenu_GetSelectedValue(PagingSettingsFrameProfileSelection);
	end

	PagingSettingsFrameProfileSelection_UpdateText();
end

-- Override Modifiers --

function PagingSettingsFrameOverrideModifiers_OnClick(self)
	PagingProfilesTemporary[PagingEditProfile].overrideModifiers = (self:GetChecked() == 1);
	PagingProfile_ApplyTemporaryProfile();
end

-- Selector --

function PagingSettingsFrameEditSelectorText_OnTextChanged(self)
	PagingProfilesTemporary[PagingEditProfile].selector = self:GetText();

	PagingSettingsFrameProfileSelection_UpdateText();
end

function PagingSettingsFrameEditSelectorText_OnEditFocusLost(self)
	PagingProfile_ApplyTemporaryProfile();
end
