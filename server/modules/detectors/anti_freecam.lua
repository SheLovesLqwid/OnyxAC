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

OnyxAC.Detectors.antiFreecam = {}

function OnyxAC.Detectors.antiFreecam.Initialize()
    print("^2[OnyxAC]^7 Anti-Freecam detector initialized")
    
    RegisterNetEvent('onyxac:client:freecamDetection')
    AddEventHandler('onyxac:client:freecamDetection', function(isFreecam, camCoords, pedCoords)
        OnyxAC.Detectors.antiFreecam.HandleFreecamDetection(source, isFreecam, camCoords, pedCoords)
    end)
end

function OnyxAC.Detectors.antiFreecam.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Freecam detector config updated")
end

function OnyxAC.Detectors.antiFreecam.HandleFreecamDetection(playerId, isFreecam, camCoords, pedCoords)
    local config = OnyxAC.Config.detectors.antiFreecam
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    if isFreecam then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local distance = #(vector3(camCoords.x, camCoords.y, camCoords.z) - vector3(pedCoords.x, pedCoords.y, pedCoords.z))
        
        local detectionData = {
            isFreecam = isFreecam,
            distance = distance,
            camCoords = camCoords,
            pedCoords = pedCoords
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiFreecam", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Freecam detected for %s: distance %.2fm", 
                playerData.name, distance))
        end
    end
end
