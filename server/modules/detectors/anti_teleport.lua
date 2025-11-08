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

OnyxAC.Detectors.antiTeleport = {}

local lastPositions = {}

function OnyxAC.Detectors.antiTeleport.Initialize()
    print("^2[OnyxAC]^7 Anti-Teleport detector initialized")
    
    Citizen.CreateThread(function()
        while true do
            OnyxAC.Detectors.antiTeleport.CheckPlayers()
            Wait(1000)
        end
    end)
end

function OnyxAC.Detectors.antiTeleport.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Teleport detector config updated")
end

function OnyxAC.Detectors.antiTeleport.CheckPlayers()
    local config = OnyxAC.Config.detectors.antiTeleport
    if not config.enabled then return end
    
    for playerId, playerData in pairs(OnyxAC.Players) do
        if not OnyxAC.IsPlayerExempt(playerId) then
            OnyxAC.Detectors.antiTeleport.CheckPlayer(playerId, config)
        end
    end
end

function OnyxAC.Detectors.antiTeleport.CheckPlayer(playerId, config)
    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 then return end
    
    local currentPos = GetEntityCoords(playerPed)
    local lastPos = lastPositions[playerId]
    
    if lastPos then
        local distance = #(currentPos - lastPos)
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local maxDistance = vehicle ~= 0 and config.maxDistanceVehicle or config.maxDistance
        
        if distance > maxDistance then
            local playerData = OnyxAC.GetPlayerData(playerId)
            if not playerData then return end
            
            if config.exemptInteriors and (GetInteriorFromEntity(playerPed) ~= 0) then
                lastPositions[playerId] = currentPos
                return
            end
            
            if config.exemptCutscenes and IsPedInAnyVehicle(playerPed, false) then
                local vehicleEntity = GetVehiclePedIsIn(playerPed, false)
                if IsEntityInAir(vehicleEntity) then
                    lastPositions[playerId] = currentPos
                    return
                end
            end
            
            local detectionData = {
                distance = math.floor(distance),
                maxDistance = maxDistance,
                fromPosition = {x = lastPos.x, y = lastPos.y, z = lastPos.z},
                toPosition = {x = currentPos.x, y = currentPos.y, z = currentPos.z},
                inVehicle = vehicle ~= 0,
                vehicleModel = vehicle ~= 0 and GetEntityModel(vehicle) or nil
            }
            
            OnyxAC.ScoringEngine.AddInfraction(playerId, "antiTeleport", config.scoreWeight, detectionData)
            
            if OnyxAC.Config.general.enableDebugMode then
                print(string.format("^3[OnyxAC-DEBUG]^7 Teleport detected for %s: %.2fm (max: %.2fm)", 
                    playerData.name, distance, maxDistance))
            end
        end
    end
    
    lastPositions[playerId] = currentPos
end

AddEventHandler('playerDropped', function()
    local playerId = source
    lastPositions[playerId] = nil
end)
