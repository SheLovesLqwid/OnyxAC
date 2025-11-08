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

OnyxAC.Admin = {}

RegisterNetEvent('onyxac:admin:kickPlayer')
AddEventHandler('onyxac:admin:kickPlayer', function(targetId, reason)
    -- Server handles the actual kick
end)

RegisterNetEvent('onyxac:admin:banPlayer')
AddEventHandler('onyxac:admin:banPlayer', function(targetId, duration, reason)
    -- Server handles the actual ban
end)

RegisterNetEvent('onyxac:admin:warnPlayer')
AddEventHandler('onyxac:admin:warnPlayer', function(targetId, reason)
    -- Server handles the actual warning
end)

RegisterNetEvent('onyxac:admin:teleportToPlayer')
AddEventHandler('onyxac:admin:teleportToPlayer', function(targetId)
    -- Server handles the teleport
end)

RegisterNetEvent('onyxac:admin:bringPlayer')
AddEventHandler('onyxac:admin:bringPlayer', function(targetId)
    -- Server handles bringing the player
end)

RegisterNetEvent('onyxac:admin:freezePlayer')
AddEventHandler('onyxac:admin:freezePlayer', function(targetId)
    -- Server handles the freeze
end)

RegisterNetEvent('onyxac:admin:spectatePlayer')
AddEventHandler('onyxac:admin:spectatePlayer', function(targetId)
    -- Server handles spectate mode
end)

RegisterNetEvent('onyxac:admin:healPlayer')
AddEventHandler('onyxac:admin:healPlayer', function(targetId)
    -- Server handles healing
end)

RegisterNetEvent('onyxac:admin:revivePlayer')
AddEventHandler('onyxac:admin:revivePlayer', function(targetId)
    -- Server handles reviving
end)

function OnyxAC.Admin.SendAction(action, targetId, data)
    TriggerServerEvent('onyxac:admin:' .. action, targetId, data)
end

function OnyxAC.Admin.RequestPlayerList()
    TriggerServerEvent('onyxac:admin:requestPlayerList')
end

function OnyxAC.Admin.RequestACData()
    TriggerServerEvent('onyxac:admin:requestACData')
end
