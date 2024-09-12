require("Tables")

local Settings = {
    ["AddonPath"] = Utils.filesystem.GetAddonPath()
}

local MetaTable = {
    __index = Settings,
    __class = "Settings",
}

function Settings:TryCreateAddonSettingsDirectory(addonName)
    local addonSettingsPath = string.format("%s\\%s\\settings", self["AddonPath"], addonName)
    if(not Utils.filesystem.exists(addonSettingsPath))then
        Utils.filesystem.create_directory(addonSettingsPath)
    end
end

function Settings:GetAddonSettingsTable(addonName, settingsFileName)
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, settingsFileName)
    if(Utils.filesystem.exists(addonSettingsPath))then
        return T(dofile(addonSettingsPath))
    end
    return {}
end

function Settings:OpenAddonSettingsOutFile(addonName, settingsFileName)
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, settingsFileName)
    return self:OpenOutFile(addonSettingsPath)
end

function Settings:OpenOutFile(path)
    return Utils.filesystem.ofstream.new(path)
end

function Settings:SaveAddonSettingsFile(addonName, settingsFile, string)
    local addonSettingsPath = string.format("%s\\%s\\settings\\%s.lua", self["AddonPath"], addonName, settingsFile)
    local settings = self:OpenOutFile(addonSettingsPath)
    if(settings)then
        settings:write(string)
        settings:close()
    end
end

return setmetatable({}, MetaTable)