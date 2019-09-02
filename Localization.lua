local _, L = ...;
setmetatable(L, {__index = function(L, key) return key; end;});
setglobal("PagingL", L); -- global alias for access from XML

-- For some strings, we have good candidates in GlobalStrings that we can use
-- as defaults.
L["Character"] = _G["CHARACTER"];
L["Class"] = _G["CLASS"];
L["Realm"] = _G["FRIENDS_LIST_REALM"]:match("[^%s%p]+");
L["Default"] = _G["DEFAULT"];

--[[

L["Paging"] = ""; -- used in the interface option panel's category list
L["Version %s"] = "";

L["Profile:"] = "";
L["automatic"] = "";
L["Example"] = "";
L["Copy from…"] = "";
L["This will overwrite the old selector you have configured for profile %s.\nAre you sure?"] = "";

L["Automatically choose matching profile"] = "";

L["Selects the most appropriate profile automatically at each login."] = "";
L["Profiles at the top of the list have priority over those at the bottom."] = "";
L["The relevant profile is tagged with \"automatic\" in the list."] = "";

L["Use macro modifier syntax to specify the page numbers, separated by semicolons."] = "";
L["If a condition is missing a page number, it will use the default page instead."] = "";
L["Make sure the selector ends with a semicolon (%s)."] = "";

]]
