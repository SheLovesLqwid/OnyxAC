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

OnyxAC.Detectors.connectionRequirements = {}

function OnyxAC.Detectors.connectionRequirements.Initialize()
    print("^2[OnyxAC]^7 Connection Requirements detector initialized")
end

function OnyxAC.Detectors.connectionRequirements.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Connection Requirements detector config updated")
end

function OnyxAC.Detectors.connectionRequirements.ValidatePlayer(playerId, name, identifiers)
    local config = OnyxAC.Config.connectionRequirements
    
    local steamId = nil
    local discordId = nil
    
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "steam:") then
            steamId = identifier
        elseif string.find(identifier, "discord:") then
            discordId = identifier
        end
    end
    
    if config.requireSteam and not steamId then
        return false, "Steam is required to join this server"
    end
    
    if config.requireDiscord and not discordId then
        return false, "Discord is required to join this server"
    end
    
    if config.requireAlphanumericName then
        local nameLength = string.len(name)
        
        if nameLength < config.minNameLength or nameLength > config.maxNameLength then
            return false, string.format("Name must be between %d and %d characters", 
                config.minNameLength, config.maxNameLength)
        end
        
        for _, bannedPattern in ipairs(config.bannedNamePatterns) do
            if string.find(string.lower(name), string.lower(bannedPattern)) then
                return false, "Name contains banned words"
            end
        end
        
        local validChars = config.allowedNameCharacters
        for i = 1, nameLength do
            local char = string.sub(name, i, i)
            if not string.find(validChars, char, 1, true) then
                return false, "Name contains invalid characters"
            end
        end
    end
    
    return true, nil
end
