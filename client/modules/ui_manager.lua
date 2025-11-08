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

function OnyxAC.UI.OpenAdminMenu()
    if isAdminMenuOpen then return end
    
    isAdminMenuOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "openAdminMenu"
    })
end

function OnyxAC.UI.OpenACMenu()
    if isACMenuOpen then return end
    
    isACMenuOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "openACMenu"
    })
end

function OnyxAC.UI.ShowNotification(message, type)
    type = type or "info"
    
    SendNUIMessage({
        type = "showNotification",
        message = message,
        notificationType = type
    })
    
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

function OnyxAC.UI.ShowAnnouncement(message)
    SendNUIMessage({
        type = "showAnnouncement",
        message = message
    })
    
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName("~r~[SERVER ANNOUNCEMENT]~w~ " .. message)
    EndTextCommandPrint(8000, true)
end

function OnyxAC.UI.ShowWarningDialog(title, message, callback)
    SendNUIMessage({
        type = "showDialog",
        title = title,
        message = message,
        dialogType = "warning"
    })
    
    if callback then
        callback()
    end
end

function OnyxAC.UI.ShowConfirmDialog(title, message, callback)
    SendNUIMessage({
        type = "showDialog",
        title = title,
        message = message,
        dialogType = "confirm"
    })
    
    if callback then
        callback()
    end
end

function OnyxAC.UI.UpdatePlayerList(players)
    SendNUIMessage({
        type = "updatePlayerList",
        players = players
    })
end

function OnyxAC.UI.UpdateACData(data)
    SendNUIMessage({
        type = "updateACData",
        data = data
    })
end
