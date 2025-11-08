/*
    made by TheOGDev Founder/CEO of OGDev Studios LLC
    OnyxAC - core script / module / resource
    Description: OnyxAC is an open-source FiveM anti-cheat and admin toolset. Feel free to use,
    rebrand, modify, and redistribute this project. Attribution is appreciated but not required.
    If you redistribute or modify, please include credit to TheOGDev and link to:
    https://github.com/SheLovesLqwid
    WARNING: Attempting to claim this project as your own is discouraged. This file header must
    remain at the top of every file in this repository.
*/

OnyxAC.ConfigManager = {}

function OnyxAC.ConfigManager.LoadConfig()
    local configFile = LoadResourceFile(GetCurrentResourceName(), 'config.json')
    
    if not configFile then
        print("^1[OnyxAC]^7 Error: config.json not found!")
        return nil
    end
    
    local success, config = pcall(json.decode, configFile)
    
    if not success then
        print("^1[OnyxAC]^7 Error: Invalid JSON in config.json!")
        return nil
    end
    
    if not OnyxAC.ConfigManager.ValidateConfig(config) then
        print("^1[OnyxAC]^7 Error: Configuration validation failed!")
        return nil
    end
    
    print("^2[OnyxAC]^7 Configuration loaded successfully!")
    return config
end

function OnyxAC.ConfigManager.ValidateConfig(config)
    local requiredSections = {
        "general",
        "database",
        "connectionRequirements",
        "detectors",
        "scoringEngine",
        "banManager",
        "permissions",
        "logging",
        "discord",
        "ui",
        "adminCommands"
    }
    
    for _, section in ipairs(requiredSections) do
        if not config[section] then
            print("^1[OnyxAC]^7 Error: Missing configuration section: " .. section)
            return false
        end
    end
    
    if not config.permissions.roles then
        print("^1[OnyxAC]^7 Error: No permission roles defined!")
        return false
    end
    
    if not config.detectors then
        print("^1[OnyxAC]^7 Error: No detectors configured!")
        return false
    end
    
    return true
end

function OnyxAC.ConfigManager.ReloadConfig()
    local newConfig = OnyxAC.ConfigManager.LoadConfig()
    
    if newConfig then
        OnyxAC.Config = newConfig
        
        for detectorName, detectorConfig in pairs(OnyxAC.Config.detectors) do
            if OnyxAC.Detectors[detectorName] and OnyxAC.Detectors[detectorName].UpdateConfig then
                OnyxAC.Detectors[detectorName].UpdateConfig(detectorConfig)
            end
        end
        
        return true
    end
    
    return false
end

function OnyxAC.ConfigManager.GetDetectorConfig(detectorName)
    if OnyxAC.Config and OnyxAC.Config.detectors and OnyxAC.Config.detectors[detectorName] then
        return OnyxAC.Config.detectors[detectorName]
    end
    return nil
end

function OnyxAC.ConfigManager.UpdateDetectorConfig(detectorName, newConfig)
    if OnyxAC.Config and OnyxAC.Config.detectors then
        OnyxAC.Config.detectors[detectorName] = newConfig
        
        if OnyxAC.Detectors[detectorName] and OnyxAC.Detectors[detectorName].UpdateConfig then
            OnyxAC.Detectors[detectorName].UpdateConfig(newConfig)
        end
        
        return true
    end
    return false
end
