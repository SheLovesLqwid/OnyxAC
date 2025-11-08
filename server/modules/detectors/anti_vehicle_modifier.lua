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

OnyxAC.Detectors.antiVehicleModifier = {}

function OnyxAC.Detectors.antiVehicleModifier.Initialize()
    print("^2[OnyxAC]^7 Anti-Vehicle Modifier detector initialized")
    
    RegisterNetEvent('onyxac:client:vehicleModification')
    AddEventHandler('onyxac:client:vehicleModification', function(vehicleData)
        OnyxAC.Detectors.antiVehicleModifier.HandleVehicleModification(source, vehicleData)
    end)
end

function OnyxAC.Detectors.antiVehicleModifier.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Vehicle Modifier detector config updated")
end

function OnyxAC.Detectors.antiVehicleModifier.HandleVehicleModification(playerId, vehicleData)
    local config = OnyxAC.Config.detectors.antiVehicleModifier
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    local violations = {}
    
    if vehicleData.speedMultiplier > config.maxSpeedMultiplier then
        table.insert(violations, {
            type = "speed",
            value = vehicleData.speedMultiplier,
            max = config.maxSpeedMultiplier
        })
    end
    
    if config.checkEngineMultiplier and vehicleData.engineMultiplier > 3.0 then
        table.insert(violations, {
            type = "engine",
            value = vehicleData.engineMultiplier,
            max = 3.0
        })
    end
    
    if config.checkTorqueMultiplier and vehicleData.torqueMultiplier > 3.0 then
        table.insert(violations, {
            type = "torque",
            value = vehicleData.torqueMultiplier,
            max = 3.0
        })
    end
    
    if #violations > 0 then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local detectionData = {
            vehicleModel = vehicleData.model,
            violations = violations
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiVehicleModifier", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Vehicle modifier detected for %s: %d violations", 
                playerData.name, #violations))
        end
    end
end
