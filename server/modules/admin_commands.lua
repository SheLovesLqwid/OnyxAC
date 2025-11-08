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

OnyxAC.AdminCommands = {}

local commandCooldowns = {}

function OnyxAC.AdminCommands.Initialize()
    if not OnyxAC.Config.adminCommands.enabled then
        print("^3[OnyxAC]^7 Admin commands disabled in configuration")
        return
    end
    
    print("^2[OnyxAC]^7 Initializing admin commands...")
    
    OnyxAC.AdminCommands.RegisterCommands()
    
    print("^2[OnyxAC]^7 Admin commands initialized!")
end

function OnyxAC.AdminCommands.RegisterCommands()
    RegisterCommand('onyxadmin', function(source, args, rawCommand)
        if source == 0 then return end
        
        if OnyxAC.Permissions.HasPermission(source, "canAccessAdminUI") then
            TriggerClientEvent('onyxac:client:openAdminMenu', source)
        else
            OnyxAC.AdminCommands.SendMessage(source, "^1You don't have permission to use this command.")
        end
    end, false)
    
    RegisterCommand('onyxac', function(source, args, rawCommand)
        if source == 0 then return end
        
        if OnyxAC.Permissions.HasPermission(source, "canAccessACUI") then
            TriggerClientEvent('onyxac:client:openACMenu', source)
        else
            OnyxAC.AdminCommands.SendMessage(source, "^1You don't have permission to use this command.")
        end
    end, false)
    
    RegisterCommand('acban', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "acban") then return end
        
        if #args < 3 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /acban <playerID> <durationMinutes> <reason>")
            return
        end
        
        local targetId = tonumber(args[1])
        local duration = tonumber(args[2])
        local reason = table.concat(args, " ", 3)
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        if not duration or duration < 0 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid duration. Use 0 for permanent ban.")
            return
        end
        
        if not OnyxAC.Permissions.HasHigherRole(source, targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1You cannot ban this player (insufficient permissions).")
            return
        end
        
        local success = OnyxAC.BanManager.BanPlayer(targetId, source, reason, duration)
        
        if success then
            OnyxAC.AdminCommands.SendMessage(source, string.format("^2Player %s banned for %s minutes. Reason: %s", 
                GetPlayerName(targetId), duration == 0 and "permanent" or tostring(duration), reason))
            
            OnyxAC.Logger.LogAdminAction(source, "ban", targetId, {
                reason = reason,
                duration = duration
            })
        else
            OnyxAC.AdminCommands.SendMessage(source, "^1Failed to ban player.")
        end
    end, false)
    
    RegisterCommand('acunban', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "acunban") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /acunban <banID>")
            return
        end
        
        local banId = args[1]
        local reason = table.concat(args, " ", 2)
        
        if reason == "" then
            reason = "Unbanned by admin"
        end
        
        local success = OnyxAC.BanManager.UnbanPlayer(banId, source, reason)
        
        if success then
            OnyxAC.AdminCommands.SendMessage(source, string.format("^2Ban %s removed. Reason: %s", banId, reason))
            
            OnyxAC.Logger.LogAdminAction(source, "unban", nil, {
                banId = banId,
                reason = reason
            })
        else
            OnyxAC.AdminCommands.SendMessage(source, "^1Failed to remove ban or ban not found.")
        end
    end, false)
    
    RegisterCommand('kick', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "kick") then return end
        
        if #args < 2 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /kick <playerID> <reason>")
            return
        end
        
        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2)
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        if not OnyxAC.Permissions.HasHigherRole(source, targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1You cannot kick this player (insufficient permissions).")
            return
        end
        
        local targetName = GetPlayerName(targetId)
        DropPlayer(targetId, "Kicked by admin: " .. reason)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Player %s kicked. Reason: %s", targetName, reason))
        
        OnyxAC.Logger.LogKick(targetId, source, reason)
        OnyxAC.Logger.LogAdminAction(source, "kick", targetId, {reason = reason})
    end, false)
    
    RegisterCommand('warn', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "warn") then return end
        
        if #args < 2 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /warn <playerID> <reason>")
            return
        end
        
        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2)
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        local targetName = GetPlayerName(targetId)
        
        TriggerClientEvent('onyxac:client:showWarning', targetId, 
            string.format("Warning from admin: %s", reason))
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^3Player %s warned. Reason: %s", targetName, reason))
        
        OnyxAC.Logger.LogWarning(targetId, source, reason)
        OnyxAC.Logger.LogAdminAction(source, "warn", targetId, {reason = reason})
    end, false)
    
    RegisterCommand('tp', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "tp") then return end
        if not OnyxAC.AdminCommands.CheckCooldown(source, "tp") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /tp <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        TriggerClientEvent('onyxac:admin:teleportToPlayer', source, targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Teleporting to %s", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "teleport", targetId, {})
    end, false)
    
    RegisterCommand('bring', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "bring") then return end
        if not OnyxAC.AdminCommands.CheckCooldown(source, "bring") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /bring <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        TriggerClientEvent('onyxac:admin:bringPlayer', targetId, source)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Bringing %s to you", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "bring", targetId, {})
    end, false)
    
    RegisterCommand('freeze', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "freeze") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /freeze <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        TriggerClientEvent('onyxac:admin:toggleFreeze', targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Toggled freeze for %s", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "freeze", targetId, {})
    end, false)
    
    RegisterCommand('spectate', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "spectate") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /spectate <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        TriggerClientEvent('onyxac:admin:spectatePlayer', source, targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Spectating %s", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "spectate", targetId, {})
    end, false)
    
    RegisterCommand('revive', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "revive") then return end
        if not OnyxAC.AdminCommands.CheckCooldown(source, "revive") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /revive <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        TriggerClientEvent('onyxac:admin:revivePlayer', targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Revived %s", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "revive", targetId, {})
    end, false)
    
    RegisterCommand('heal', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "heal") then return end
        if not OnyxAC.AdminCommands.CheckCooldown(source, "heal") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /heal <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        TriggerClientEvent('onyxac:admin:healPlayer', targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Healed %s", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "heal", targetId, {})
    end, false)
    
    RegisterCommand('god', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "god") then return end
        
        if #args < 1 then
            TriggerClientEvent('onyxac:admin:toggleGodmode', source)
            OnyxAC.AdminCommands.SendMessage(source, "^2Toggled godmode for yourself")
        else
            local targetId = tonumber(args[1])
            
            if not targetId or not GetPlayerName(targetId) then
                OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
                return
            end
            
            if not OnyxAC.Permissions.HasHigherRole(source, targetId) then
                OnyxAC.AdminCommands.SendMessage(source, "^1You cannot toggle godmode for this player.")
                return
            end
            
            TriggerClientEvent('onyxac:admin:toggleGodmode', targetId)
            OnyxAC.AdminCommands.SendMessage(source, string.format("^2Toggled godmode for %s", GetPlayerName(targetId)))
        end
        
        OnyxAC.Logger.LogAdminAction(source, "godmode", args[1] and tonumber(args[1]) or source, {})
    end, false)
    
    RegisterCommand('slap', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "slap") then return end
        if not OnyxAC.AdminCommands.CheckCooldown(source, "slap") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /slap <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        TriggerClientEvent('onyxac:admin:slapPlayer', targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Slapped %s", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "slap", targetId, {})
    end, false)
    
    RegisterCommand('announce', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "announce") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /announce <message>")
            return
        end
        
        local message = table.concat(args, " ")
        
        TriggerClientEvent('onyxac:client:showAnnouncement', -1, message)
        
        OnyxAC.AdminCommands.SendMessage(source, "^2Announcement sent to all players")
        
        OnyxAC.Logger.LogAdminAction(source, "announce", nil, {message = message})
    end, false)
    
    RegisterCommand('checkscore', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "checkscore") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /checkscore <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        local score = OnyxAC.ScoringEngine.GetPlayerScore(targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^3%s's current anti-cheat score: ^2%d", 
            GetPlayerName(targetId), score))
        
        OnyxAC.Logger.LogAdminAction(source, "checkscore", targetId, {score = score})
    end, false)
    
    RegisterCommand('clearinfractions', function(source, args, rawCommand)
        if not OnyxAC.AdminCommands.CheckPermission(source, "clearinfractions") then return end
        
        if #args < 1 then
            OnyxAC.AdminCommands.SendMessage(source, "^1Usage: /clearinfractions <playerID>")
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            OnyxAC.AdminCommands.SendMessage(source, "^1Invalid player ID.")
            return
        end
        
        OnyxAC.ScoringEngine.ClearPlayerScore(targetId)
        
        OnyxAC.AdminCommands.SendMessage(source, string.format("^2Cleared infractions for %s", GetPlayerName(targetId)))
        
        OnyxAC.Logger.LogAdminAction(source, "clearinfractions", targetId, {})
    end, false)
    
    RegisterCommand('onxreloadconfig', function(source, args, rawCommand)
        if source ~= 0 and not OnyxAC.Permissions.HasCommand(source, "*") then
            OnyxAC.AdminCommands.SendMessage(source, "^1You don't have permission to use this command.")
            return
        end
        
        local success = OnyxAC.ConfigManager.ReloadConfig()
        
        if success then
            local message = "^2OnyxAC configuration reloaded successfully!"
            if source == 0 then
                print(message)
            else
                OnyxAC.AdminCommands.SendMessage(source, message)
                OnyxAC.Logger.LogAdminAction(source, "reloadconfig", nil, {})
            end
        else
            local message = "^1Failed to reload OnyxAC configuration!"
            if source == 0 then
                print(message)
            else
                OnyxAC.AdminCommands.SendMessage(source, message)
            end
        end
    end, true)
end

function OnyxAC.AdminCommands.CheckPermission(playerId, command)
    if not OnyxAC.Permissions.HasCommand(playerId, command) then
        OnyxAC.AdminCommands.SendMessage(playerId, "^1You don't have permission to use this command.")
        return false
    end
    return true
end

function OnyxAC.AdminCommands.CheckCooldown(playerId, command)
    local cooldownTime = OnyxAC.Config.adminCommands.cooldowns[command]
    if not cooldownTime then return true end
    
    local playerKey = playerId .. "_" .. command
    local lastUsed = commandCooldowns[playerKey] or 0
    local currentTime = GetGameTimer()
    
    if currentTime - lastUsed < cooldownTime then
        local remainingTime = math.ceil((cooldownTime - (currentTime - lastUsed)) / 1000)
        OnyxAC.AdminCommands.SendMessage(playerId, string.format("^1Command on cooldown. Wait %d seconds.", remainingTime))
        return false
    end
    
    commandCooldowns[playerKey] = currentTime
    return true
end

function OnyxAC.AdminCommands.SendMessage(playerId, message)
    if OnyxAC.Config.adminCommands.enableChatFeedback then
        TriggerClientEvent('chatMessage', playerId, "^5[OnyxAC]", {255, 255, 255}, message)
    end
end
