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

OnyxAC.Detectors.antiNoclip = {}

function OnyxAC.Detectors.antiNoclip.Initialize()
    print("^2[OnyxAC]^7 Anti-Noclip detector initialized")
    
    RegisterNetEvent('onyxac:client:noclipDetection')
    AddEventHandler('onyxac:client:noclipDetection', function(velocity, isInAir, collisionDisabled)
        OnyxAC.Detectors.antiNoclip.HandleNoclipDetection(source, velocity, isInAir, collisionDisabled)
    end)
end

function OnyxAC.Detectors.antiNoclip.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Noclip detector config updated")
end

function OnyxAC.Detectors.antiNoclip.HandleNoclipDetection(playerId, velocity, isInAir, collisionDisabled)
    local config = OnyxAC.Config.detectors.antiNoclip
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    if velocity > config.maxVelocityThreshold and isInAir and collisionDisabled then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local detectionData = {
            velocity = velocity,
            maxVelocity = config.maxVelocityThreshold,
            isInAir = isInAir,
            collisionDisabled = collisionDisabled
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiNoclip", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Noclip detected for %s: velocity %.2f", 
                playerData.name, velocity))
        end
    end
end
