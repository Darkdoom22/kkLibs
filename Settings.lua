require("Tables")

local Settings = {
    ["AddonPath"] = Utils.filesystem.GetAddonPath()
}

local MetaTable = {
    __index = Settings,
    __class = "Settings",
}

function Settings:TryCreateAddonSettingsDirectory(addonName)
    tracy.ZoneBeginN("Settings:TryCreateSettingsDirectory");
    local addonSettingsPath = string.format("%s\\%s\\settings", self["AddonPath"], addonName)
    if(not Utils.filesystem.exists(addonSettingsPath))then
        Utils.filesystem.create_directory(addonSettingsPath)
    end
    tracy.ZoneEnd()
end

function Settings:DoesAddonSettingsFileExist(addonName, settingsFileName)
    tracy.ZoneBeginN("Settings:DoesAddonSettingsFileExist")
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, settingsFileName)
    local exists = Utils.filesystem.exists(addonSettingsPath)
    tracy.ZoneEnd()

    return exists
end

function Settings:CreateAddonSettingsFile(addonName, fileName, settingsTable)
    tracy.ZoneBeginN("Settings:CreateAddonSettingsFile")
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, fileName)
    local settings = self:OpenOutFile(addonSettingsPath)
    if(settings)then
        settings:write(settingsTable:Serialize())
        settings:close()
    end
    tracy.ZoneEnd()
end

function Settings:GetAddonSettingsTable(addonName, settingsFileName)
    tracy.ZoneBeginN("Settings:GetAddonSettingsTable")
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, settingsFileName)
    if(Utils.filesystem.exists(addonSettingsPath))then
        return T(dofile(addonSettingsPath))
    end
    tracy.ZoneEnd()
   
    return {}
end

function Settings:OpenAddonSettingsOutFile(addonName, settingsFileName)
    tracy.ZoneBeginN("Settings:OpenAddonSettingsOutFile")
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, settingsFileName)
    local outFile = self:OpenOutFile(addonSettingsPath)
    tracy.ZoneEnd()

    return outFile
end

function Settings:OpenOutFile(path)
    tracy.ZoneBeginN("Settings:OpenOutFile")
    local ofstream = Utils.filesystem.ofstream.new(path)
    tracy.ZoneEnd()

    return ofstream
end

--TODO: take the table and serialize it here instead of in the caller
function Settings:SaveAddonSettingsFile(addonName, settingsFile, string)
    tracy.ZoneBeginN("Settings:SaveAddonSettingsFile")
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, settingsFile)
    local settings = self:OpenOutFile(addonSettingsPath)
    if(settings)then
        settings:write(string)
        settings:close()
    end
    tracy.ZoneEnd()
end

function Settings:CompareAndSaveAddonSettingsFile(addonName, settingsFileName, oldSettingsTable, newSettingsTable)
    tracy.ZoneBeginN("Settings:CompareAndSaveAddonSettingsFile")
    if(not oldSettingsTable:SequenceEqual(newSettingsTable))then
        self:SaveAddonSettingsFile(addonName, settingsFileName, newSettingsTable:Serialize())
    end
    tracy.ZoneEnd()
end

return setmetatable({}, MetaTable)