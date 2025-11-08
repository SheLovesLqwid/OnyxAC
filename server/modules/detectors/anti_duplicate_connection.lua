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

OnyxAC.Detectors.antiDuplicateConnection = {}

local connectionTracker = {}

function OnyxAC.Detectors.antiDuplicateConnection.Initialize()
    print("^2[OnyxAC]^7 Anti-Duplicate Connection detector initialized")
end

function OnyxAC.Detectors.antiDuplicateConnection.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Duplicate Connection detector config updated")
end

function OnyxAC.Detectors.antiDuplicateConnection.CheckConnection(playerId, identifiers)
    local config = OnyxAC.Config.detectors.antiDuplicateConnection
    if not config.enabled then return true end
    
    local license = nil
    local ip = nil
    
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "license:") then
            license = identifier
        elseif string.find(identifier, "ip:") then
            ip = identifier
        end
    end
    
    if license then
        local licenseCount = 0
        for _, playerData in pairs(OnyxAC.Players) do
            if playerData.license == license then
                licenseCount = licenseCount + 1
            end
        end
        
        if licenseCount >= config.maxConnectionsPerLicense then
            OnyxAC.Detectors.antiDuplicateConnection.HandleViolation(playerId, "license", licenseCount, config)
            return false
        end
    end
    
    if ip then
        local ipCount = 0
        for _, playerData in pairs(OnyxAC.Players) do
            for _, ident in ipairs(playerData.identifiers) do
                if ident == ip then
                    ipCount = ipCount + 1
                    break
                end
            end
        end
        
        if ipCount >= config.maxConnectionsPerIP then
            OnyxAC.Detectors.antiDuplicateConnection.HandleViolation(playerId, "ip", ipCount, config)
            return false
        end
    end
    
    return true
end

function OnyxAC.Detectors.antiDuplicateConnection.HandleViolation(playerId, violationType, count, config)
    local playerData = OnyxAC.GetPlayerData(playerId)
    if not playerData then return end
    
    local detectionData = {
        violationType = violationType,
        connectionCount = count,
        maxAllowed = violationType == "license" and config.maxConnectionsPerLicense or config.maxConnectionsPerIP
    }
    
    if config.action == "kick" then
        DropPlayer(playerId, "Multiple connections detected from same " .. violationType)
    elseif config.action == "ban" then
        OnyxAC.BanManager.BanPlayer(playerId, nil, "Duplicate connection - " .. violationType, 
            OnyxAC.Config.banManager.defaultBanDuration)
    end
    
    OnyxAC.ScoringEngine.AddInfraction(playerId, "antiDuplicateConnection", config.scoreWeight, detectionData)
    
    if OnyxAC.Config.general.enableDebugMode then
        print(string.format("^3[OnyxAC-DEBUG]^7 Duplicate connection detected: %s (%s: %d)", 
            playerData.name, violationType, count))
    end
end
