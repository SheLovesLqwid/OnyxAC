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

OnyxAC.Detectors.antiSpectate = {}

function OnyxAC.Detectors.antiSpectate.Initialize()
    print("^2[OnyxAC]^7 Anti-Spectate detector initialized")
    
    RegisterNetEvent('onyxac:client:spectateDetection')
    AddEventHandler('onyxac:client:spectateDetection', function(isSpectating, targetPlayer)
        OnyxAC.Detectors.antiSpectate.HandleSpectateDetection(source, isSpectating, targetPlayer)
    end)
end

function OnyxAC.Detectors.antiSpectate.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Spectate detector config updated")
end

function OnyxAC.Detectors.antiSpectate.HandleSpectateDetection(playerId, isSpectating, targetPlayer)
    local config = OnyxAC.Config.detectors.antiSpectate
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    if config.allowStaffSpectate and OnyxAC.Permissions.HasCommand(playerId, "spectate") then
        return
    end
    
    if isSpectating then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local detectionData = {
            isSpectating = isSpectating,
            targetPlayer = targetPlayer
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiSpectate", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Unauthorized spectate detected for %s", 
                playerData.name))
        end
    end
end
