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

OnyxAC = {}
OnyxAC.Client = {}
OnyxAC.UI = {}
OnyxAC.Detection = {}

local isAdminMenuOpen = false
local isACMenuOpen = false
local isFrozen = false
local isSpectating = false
local spectateTarget = nil
local godmodeEnabled = false

Citizen.CreateThread(function()
    while true do
        OnyxAC.Detection.RunDetectionChecks()
        Wait(1000)
    end
end)

RegisterNetEvent('onyxac:client:openAdminMenu')
AddEventHandler('onyxac:client:openAdminMenu', function()
    if not isAdminMenuOpen then
        OnyxAC.UI.OpenAdminMenu()
    end
end)

RegisterNetEvent('onyxac:client:openACMenu')
AddEventHandler('onyxac:client:openACMenu', function()
    if not isACMenuOpen then
        OnyxAC.UI.OpenACMenu()
    end
end)

RegisterNetEvent('onyxac:client:showWarning')
AddEventHandler('onyxac:client:showWarning', function(message)
    OnyxAC.UI.ShowNotification(message, "warning")
end)

RegisterNetEvent('onyxac:client:showAnnouncement')
AddEventHandler('onyxac:client:showAnnouncement', function(message)
    OnyxAC.UI.ShowAnnouncement(message)
end)

RegisterNetEvent('onyxac:admin:teleportToPlayer')
AddEventHandler('onyxac:admin:teleportToPlayer', function(targetPlayerId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetPlayerId))
    if targetPed and targetPed ~= 0 then
        local targetCoords = GetEntityCoords(targetPed)
        SetEntityCoords(PlayerPedId(), targetCoords.x, targetCoords.y, targetCoords.z + 1.0, false, false, false, true)
    end
end)

RegisterNetEvent('onyxac:admin:bringPlayer')
AddEventHandler('onyxac:admin:bringPlayer', function(adminPlayerId)
    local adminPed = GetPlayerPed(GetPlayerFromServerId(adminPlayerId))
    if adminPed and adminPed ~= 0 then
        local adminCoords = GetEntityCoords(adminPed)
        SetEntityCoords(PlayerPedId(), adminCoords.x + 2.0, adminCoords.y, adminCoords.z, false, false, false, true)
    end
end)

RegisterNetEvent('onyxac:admin:toggleFreeze')
AddEventHandler('onyxac:admin:toggleFreeze', function()
    isFrozen = not isFrozen
    local playerPed = PlayerPedId()
    
    if isFrozen then
        FreezeEntityPosition(playerPed, true)
        SetEntityInvincible(playerPed, true)
        OnyxAC.UI.ShowNotification("You have been frozen by an admin", "warning")
    else
        FreezeEntityPosition(playerPed, false)
        SetEntityInvincible(playerPed, false)
        OnyxAC.UI.ShowNotification("You have been unfrozen", "success")
    end
end)

RegisterNetEvent('onyxac:admin:spectatePlayer')
AddEventHandler('onyxac:admin:spectatePlayer', function(targetPlayerId)
    if isSpectating and spectateTarget == targetPlayerId then
        OnyxAC.Client.StopSpectating()
    else
        OnyxAC.Client.StartSpectating(targetPlayerId)
    end
end)

RegisterNetEvent('onyxac:admin:revivePlayer')
AddEventHandler('onyxac:admin:revivePlayer', function()
    local playerPed = PlayerPedId()
    
    if IsEntityDead(playerPed) then
        NetworkResurrectLocalPlayer(GetEntityCoords(playerPed), GetEntityHeading(playerPed), true, false)
        SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
        ClearPedBloodDamage(playerPed)
        OnyxAC.UI.ShowNotification("You have been revived by an admin", "success")
    end
end)

RegisterNetEvent('onyxac:admin:healPlayer')
AddEventHandler('onyxac:admin:healPlayer', function()
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    SetPedArmour(playerPed, GetPlayerMaxArmour(PlayerId()))
    ClearPedBloodDamage(playerPed)
    OnyxAC.UI.ShowNotification("You have been healed by an admin", "success")
end)

RegisterNetEvent('onyxac:admin:toggleGodmode')
AddEventHandler('onyxac:admin:toggleGodmode', function()
    godmodeEnabled = not godmodeEnabled
    local playerPed = PlayerPedId()
    
    SetEntityInvincible(playerPed, godmodeEnabled)
    
    if godmodeEnabled then
        OnyxAC.UI.ShowNotification("Godmode enabled", "success")
    else
        OnyxAC.UI.ShowNotification("Godmode disabled", "info")
    end
end)

RegisterNetEvent('onyxac:admin:slapPlayer')
AddEventHandler('onyxac:admin:slapPlayer', function()
    local playerPed = PlayerPedId()
    local currentHealth = GetEntityHealth(playerPed)
    
    SetEntityHealth(playerPed, math.max(1, currentHealth - 10))
    
    local forwardVector = GetEntityForwardVector(playerPed)
    SetEntityVelocity(playerPed, forwardVector.x * 10, forwardVector.y * 10, 5.0)
    
    OnyxAC.UI.ShowNotification("You have been slapped by an admin!", "warning")
end)

function OnyxAC.Client.StartSpectating(targetPlayerId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetPlayerId))
    if not targetPed or targetPed == 0 then return end
    
    isSpectating = true
    spectateTarget = targetPlayerId
    
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, false)
    SetEntityCollision(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)
    
    NetworkSetInSpectatorMode(true, targetPed)
    
    OnyxAC.UI.ShowNotification("Spectating player " .. GetPlayerName(GetPlayerFromServerId(targetPlayerId)), "info")
end

function OnyxAC.Client.StopSpectating()
    if not isSpectating then return end
    
    isSpectating = false
    spectateTarget = nil
    
    local playerPed = PlayerPedId()
    NetworkSetInSpectatorMode(false, playerPed)
    
    SetEntityVisible(playerPed, true, false)
    SetEntityCollision(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)
    
    OnyxAC.UI.ShowNotification("Stopped spectating", "info")
end

RegisterKeyMapping('onyxadmin', 'Open OnyxAC Admin Menu', 'keyboard', 'F6')
RegisterKeyMapping('onyxac', 'Open OnyxAC Control Menu', 'keyboard', 'F7')

RegisterCommand('onyxadmin', function()
    TriggerServerEvent('onyxac:admin:requestPermissions')
end, false)

RegisterCommand('onyxac', function()
    TriggerServerEvent('onyxac:admin:requestPermissions')
end, false)

RegisterNetEvent('onyxac:admin:receivePermissions')
AddEventHandler('onyxac:admin:receivePermissions', function(permissions)
    if permissions.canAccessAdminUI then
        TriggerServerEvent('onyxac:admin:requestPlayerList')
        OnyxAC.UI.OpenAdminMenu()
    elseif permissions.canAccessACUI then
        TriggerServerEvent('onyxac:admin:requestACData')
        OnyxAC.UI.OpenACMenu()
    else
        OnyxAC.UI.ShowNotification("You don't have permission to access admin menus", "error")
    end
end)

RegisterNetEvent('onyxac:admin:receivePlayerList')
AddEventHandler('onyxac:admin:receivePlayerList', function(playerList)
    SendNUIMessage({
        type = "updatePlayerList",
        players = playerList
    })
end)

RegisterNetEvent('onyxac:admin:receiveACData')
AddEventHandler('onyxac:admin:receiveACData', function(acData)
    SendNUIMessage({
        type = "updateACData",
        data = acData
    })
end)

RegisterNUICallback('closeAdminMenu', function(data, cb)
    isAdminMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeACMenu', function(data, cb)
    isACMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('adminAction', function(data, cb)
    local action = data.action
    local targetId = data.targetId
    local reason = data.reason or ""
    local duration = data.duration or 0
    
    if action == "kick" then
        TriggerServerEvent('onyxac:admin:kickPlayer', targetId, reason)
    elseif action == "ban" then
        TriggerServerEvent('onyxac:admin:banPlayer', targetId, duration, reason)
    elseif action == "warn" then
        TriggerServerEvent('onyxac:admin:warnPlayer', targetId, reason)
    elseif action == "tp" then
        TriggerServerEvent('onyxac:admin:teleportToPlayer', targetId)
    elseif action == "bring" then
        TriggerServerEvent('onyxac:admin:bringPlayer', targetId)
    elseif action == "freeze" then
        TriggerServerEvent('onyxac:admin:freezePlayer', targetId)
    elseif action == "spectate" then
        TriggerServerEvent('onyxac:admin:spectatePlayer', targetId)
    elseif action == "heal" then
        TriggerServerEvent('onyxac:admin:healPlayer', targetId)
    elseif action == "revive" then
        TriggerServerEvent('onyxac:admin:revivePlayer', targetId)
    end
    
    cb('ok')
end)

RegisterNUICallback('refreshPlayerList', function(data, cb)
    TriggerServerEvent('onyxac:admin:requestPlayerList')
    cb('ok')
end)

RegisterNUICallback('refreshACData', function(data, cb)
    TriggerServerEvent('onyxac:admin:requestACData')
    cb('ok')
end)

Citizen.CreateThread(function()
    while true do
        if isSpectating and spectateTarget then
            local targetPed = GetPlayerPed(GetPlayerFromServerId(spectateTarget))
            if not targetPed or targetPed == 0 then
                OnyxAC.Client.StopSpectating()
            end
        end
        
        Wait(1000)
    end
end)
