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

local lastPosition = vector3(0, 0, 0)
local lastJumpTime = 0
local lastHealthCheck = 0

function OnyxAC.Detection.RunDetectionChecks()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return end
    
    OnyxAC.Detection.CheckSuperJump(playerPed)
    OnyxAC.Detection.CheckNoclip(playerPed)
    OnyxAC.Detection.CheckFreecam(playerPed)
    OnyxAC.Detection.CheckSpectate(playerPed)
    OnyxAC.Detection.CheckWeaponModifications(playerPed)
    OnyxAC.Detection.CheckVehicleModifications(playerPed)
    OnyxAC.Detection.CheckFilePatterns()
end

function OnyxAC.Detection.CheckSuperJump(playerPed)
    if IsPedJumping(playerPed) then
        local currentTime = GetGameTimer()
        if currentTime - lastJumpTime > 1000 then
            local velocity = GetEntityVelocity(playerPed)
            local jumpHeight = velocity.z
            
            if jumpHeight > 3.0 then
                TriggerServerEvent('onyxac:client:jumpDetection', jumpHeight, velocity)
            end
            
            lastJumpTime = currentTime
        end
    end
end

function OnyxAC.Detection.CheckNoclip(playerPed)
    local currentPos = GetEntityCoords(playerPed)
    local velocity = GetEntityVelocity(playerPed)
    local speed = #velocity
    
    if speed > 30.0 then
        local isInAir = not IsPedOnGround(playerPed)
        local collisionDisabled = not GetEntityCollisionDisabled(playerPed)
        
        if isInAir and not collisionDisabled then
            TriggerServerEvent('onyxac:client:noclipDetection', speed, isInAir, collisionDisabled)
        end
    end
    
    lastPosition = currentPos
end

function OnyxAC.Detection.CheckFreecam(playerPed)
    local cam = GetRenderingCam()
    if cam ~= -1 then
        local camCoords = GetCamCoord(cam)
        local pedCoords = GetEntityCoords(playerPed)
        local distance = #(camCoords - pedCoords)
        
        if distance > 50.0 then
            TriggerServerEvent('onyxac:client:freecamDetection', true, camCoords, pedCoords)
        end
    end
end

function OnyxAC.Detection.CheckSpectate(playerPed)
    if NetworkIsInSpectatorMode() then
        local spectateTarget = NetworkGetSpectatorTarget()
        if spectateTarget and spectateTarget ~= playerPed then
            TriggerServerEvent('onyxac:client:spectateDetection', true, GetPlayerServerId(NetworkGetPlayerIndexFromPed(spectateTarget)))
        end
    end
end

function OnyxAC.Detection.CheckWeaponModifications(playerPed)
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if currentWeapon and currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
        local damageModifier = GetWeaponDamageModifier(currentWeapon)
        local rangeModifier = GetWeaponRangeModifier(currentWeapon)
        local ammoCount = GetAmmoInPedWeapon(playerPed, currentWeapon)
        
        if damageModifier > 1.5 or rangeModifier > 1.5 or ammoCount > 9999 then
            TriggerServerEvent('onyxac:client:weaponModification', currentWeapon, damageModifier, rangeModifier, ammoCount)
        end
    end
end

function OnyxAC.Detection.CheckVehicleModifications(playerPed)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle and vehicle ~= 0 then
        local maxSpeed = GetVehicleMaxSpeed(vehicle)
        local engineHealth = GetVehicleEngineHealth(vehicle)
        local engineMultiplier = GetVehicleCheatPowerIncrease(vehicle)
        
        local vehicleData = {
            model = GetEntityModel(vehicle),
            speedMultiplier = maxSpeed / GetVehicleModelMaxSpeed(GetEntityModel(vehicle)),
            engineMultiplier = engineMultiplier,
            torqueMultiplier = GetVehicleCheatTorqueMultiplier(vehicle)
        }
        
        if vehicleData.speedMultiplier > 2.0 or vehicleData.engineMultiplier > 2.0 or vehicleData.torqueMultiplier > 2.0 then
            TriggerServerEvent('onyxac:client:vehicleModification', vehicleData)
        end
    end
end

function OnyxAC.Detection.CheckFilePatterns()
    local suspiciousPatterns = {}
    
    local commonCheatPatterns = {
        "x64", "ai_", "cheat", "mod_menu", "trainer", "hack", "inject"
    }
    
    for _, pattern in ipairs(commonCheatPatterns) do
        if OnyxAC.Detection.CheckForPattern(pattern) then
            table.insert(suspiciousPatterns, pattern)
        end
    end
    
    if #suspiciousPatterns > 0 then
        TriggerServerEvent('onyxac:client:filePatternDetection', suspiciousPatterns)
    end
end

function OnyxAC.Detection.CheckForPattern(pattern)
    return false
end
