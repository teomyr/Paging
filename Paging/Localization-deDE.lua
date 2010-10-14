local _, L = ...;
if GetLocale() == "deDE" then

L["Profile:"] = "Profil:";
L["automatic"] = "automatisch";
L["Example"] = "Beispiel";

L["Automatically choose matching profile"] = "Passendes Profil automatisch wählen";

L["Selects the most appropriate profile automatically at each login."] = "Verwendet bei jedem Login automatisch das passendste Profil.";
L["Profiles at the top of the list have priority over those at the bottom."] = "Einträge am Anfang der Liste werden gegenüber den nachfolgenden Einträgen bevorzugt.";
L["The relevant profile is tagged with \"automatic\" in the list."] = "Das entsprechende Profil ist dabei mit \"automatisch\" gekennzeichnet.";

L["Use macro modifier syntax to specify the page numbers, separated by semicolons."] = "Benutzt die üblichen Makro-Bedingungen, um Seitenzahlen anzugeben. Trennt die Einträge mit Strichpunkten.";
L["If a condition is missing a page number, it will use the default page instead."] = "Fehlt die Seitennummer, so verwendet Paging die Standardleiste.";
L["Make sure the selector ends with a semicolon (%s)."] = "Der Selektor sollte mit einem Strichpunkt (%s) enden.";

L["Selector:"] = "Selektor:";

end
