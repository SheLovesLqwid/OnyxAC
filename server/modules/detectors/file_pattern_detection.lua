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

OnyxAC.Detectors.filePatternDetection = {}

function OnyxAC.Detectors.filePatternDetection.Initialize()
    print("^2[OnyxAC]^7 File Pattern Detection initialized")
    
    RegisterNetEvent('onyxac:client:filePatternDetection')
    AddEventHandler('onyxac:client:filePatternDetection', function(detectedPatterns)
        OnyxAC.Detectors.filePatternDetection.HandlePatternDetection(source, detectedPatterns)
    end)
end

function OnyxAC.Detectors.filePatternDetection.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 File Pattern Detection config updated")
end

function OnyxAC.Detectors.filePatternDetection.HandlePatternDetection(playerId, detectedPatterns)
    local config = OnyxAC.Config.detectors.filePatternDetection
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    if #detectedPatterns > 0 then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local detectionData = {
            patterns = detectedPatterns,
            patternCount = #detectedPatterns
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "filePatternDetection", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Suspicious file patterns detected for %s: %s", 
                playerData.name, table.concat(detectedPatterns, ", ")))
        end
        
        OnyxAC.BanManager.BanPlayer(playerId, nil, "Suspicious file patterns detected: " .. table.concat(detectedPatterns, ", "), 0)
    end
end
