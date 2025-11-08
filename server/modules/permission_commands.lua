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

OnyxAC.PermissionCommands = {}

function OnyxAC.PermissionCommands.Initialize()
    if not OnyxAC.Config.adminCommands.enabled then
        return
    end
    
    print("^2[OnyxAC]^7 Initializing permission management commands...")
    
    OnyxAC.PermissionCommands.RegisterCommands()
    
    print("^2[OnyxAC]^7 Permission management commands initialized!")
end

function OnyxAC.PermissionCommands.RegisterCommands()
    -- Set player role command
    RegisterCommand('setrole', function(source, args, rawCommand)
        if source == 0 then
            -- Console command
            if #args < 2 then
                print("Usage: setrole <playerID> <role>")
                return
            end
            
            local targetId = tonumber(args[1])
            local role = args[2]
            
            if not targetId or not GetPlayerName(targetId) then
                print("Invalid player ID.")
                return
            end
            
            if not OnyxAC.Config.permissions.roles[role] then
                print("Invalid role. Available roles:")
                for roleName, _ in pairs(OnyxAC.Config.permissions.roles) do
                    print("  - " .. roleName)
                end
                return
            end
            
            local success = OnyxAC.Permissions.SetPlayerRole(targetId, role, nil)
            if success then
                local targetName = GetPlayerName(targetId)
                print(string.format("Set %s's role to %s", targetName, role))
                TriggerClientEvent('onyxac:admin:notify', targetId, string.format("Your role has been set to %s", role), "info")
            else
                print("Failed to set player role")
            end
            return
        end
        
        -- Player command
        if not OnyxAC.Permissions.HasPermission(source, "managestaff") then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You don't have permission to use this command."}
            })
            return
        end
        
        if #args < 2 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 0},
                multiline = true,
                args = {"OnyxAC", "Usage: /setrole <playerID> <role>"}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        local role = args[2]
        
        if not targetId or not GetPlayerName(targetId) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "Invalid player ID."}
            })
            return
        end
        
        if not OnyxAC.Config.permissions.roles[role] then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "Invalid role."}
            })
            return
        end
        
        if not OnyxAC.Permissions.HasHigherRole(source, targetId) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You cannot modify this player's role (insufficient permissions)."}
            })
            return
        end
        
        local success = OnyxAC.Permissions.SetPlayerRole(targetId, role, source)
        if success then
            local targetName = GetPlayerName(targetId)
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"OnyxAC", string.format("Set %s's role to %s", targetName, role)}
            })
            TriggerClientEvent('onyxac:admin:notify', targetId, string.format("Your role has been set to %s", role), "info")
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "Failed to set player role"}
            })
        end
    end, false)
    
    -- Remove player role command
    RegisterCommand('removerole', function(source, args, rawCommand)
        if source == 0 then
            -- Console command
            if #args < 1 then
                print("Usage: removerole <playerID>")
                return
            end
            
            local targetId = tonumber(args[1])
            
            if not targetId or not GetPlayerName(targetId) then
                print("Invalid player ID.")
                return
            end
            
            local success = OnyxAC.Permissions.RemovePlayerRole(targetId, nil)
            if success then
                local targetName = GetPlayerName(targetId)
                print(string.format("Removed %s's staff role", targetName))
                TriggerClientEvent('onyxac:admin:notify', targetId, "Your staff role has been removed", "info")
            else
                print("Failed to remove player role")
            end
            return
        end
        
        -- Player command
        if not OnyxAC.Permissions.HasPermission(source, "managestaff") then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You don't have permission to use this command."}
            })
            return
        end
        
        if #args < 1 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 0},
                multiline = true,
                args = {"OnyxAC", "Usage: /removerole <playerID>"}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        
        if not targetId or not GetPlayerName(targetId) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "Invalid player ID."}
            })
            return
        end
        
        if not OnyxAC.Permissions.HasHigherRole(source, targetId) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You cannot modify this player's role (insufficient permissions)."}
            })
            return
        end
        
        local success = OnyxAC.Permissions.RemovePlayerRole(targetId, source)
        if success then
            local targetName = GetPlayerName(targetId)
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"OnyxAC", string.format("Removed %s's staff role", targetName)}
            })
            TriggerClientEvent('onyxac:admin:notify', targetId, "Your staff role has been removed", "info")
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "Failed to remove player role"}
            })
        end
    end, false)
    
    -- Set individual permission command
    RegisterCommand('setperm', function(source, args, rawCommand)
        if source == 0 then
            -- Console command
            if #args < 3 then
                print("Usage: setperm <playerID> <permission> <true/false>")
                return
            end
            
            local targetId = tonumber(args[1])
            local permission = args[2]
            local granted = args[3]:lower() == "true"
            
            if not targetId or not GetPlayerName(targetId) then
                print("Invalid player ID.")
                return
            end
            
            local success, message = OnyxAC.Permissions.SetIndividualPermission(targetId, permission, granted, nil)
            if success then
                local targetName = GetPlayerName(targetId)
                local action = granted and "granted" or "revoked"
                print(string.format("%s %s permission for %s", action:gsub("^%l", string.upper), permission, targetName))
            else
                print(message or "Failed to set permission")
            end
            return
        end
        
        -- Player command
        if not OnyxAC.Permissions.HasPermission(source, "setpermissions") then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You don't have permission to use this command."}
            })
            return
        end
        
        if #args < 3 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 0},
                multiline = true,
                args = {"OnyxAC", "Usage: /setperm <playerID> <permission> <true/false>"}
            })
            return
        end
        
        local targetId = tonumber(args[1])
        local permission = args[2]
        local granted = args[3]:lower() == "true"
        
        if not targetId or not GetPlayerName(targetId) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "Invalid player ID."}
            })
            return
        end
        
        if not OnyxAC.Permissions.HasHigherRole(source, targetId) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You cannot modify this player's permissions (insufficient permissions)."}
            })
            return
        end
        
        local success, message = OnyxAC.Permissions.SetIndividualPermission(targetId, permission, granted, source)
        if success then
            local targetName = GetPlayerName(targetId)
            local action = granted and "granted" or "revoked"
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"OnyxAC", string.format("%s %s permission for %s", action:gsub("^%l", string.upper), permission, targetName)}
            })
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", message or "Failed to set permission"}
            })
        end
    end, false)
    
    -- Check player permissions command
    RegisterCommand('checkperms', function(source, args, rawCommand)
        if source == 0 then
            -- Console command
            if #args < 1 then
                print("Usage: checkperms <playerID>")
                return
            end
            
            local targetId = tonumber(args[1])
            
            if not targetId or not GetPlayerName(targetId) then
                print("Invalid player ID.")
                return
            end
            
            local permissions = OnyxAC.Permissions.GetPlayerPermissions(targetId)
            local targetName = GetPlayerName(targetId)
            
            print(string.format("=== Permissions for %s ===", targetName))
            print(string.format("License: %s", permissions.license or "None"))
            print(string.format("Role: %s (Level: %d)", permissions.role, permissions.level))
            print(string.format("Admin UI Access: %s", permissions.canAccessAdminUI and "Yes" or "No"))
            print(string.format("AC UI Access: %s", permissions.canAccessACUI and "Yes" or "No"))
            print(string.format("Bypass Detections: %s", permissions.canBypassDetections and "Yes" or "No"))
            
            if permissions.individualPermissions and next(permissions.individualPermissions) then
                print("Individual Permissions:")
                for perm, granted in pairs(permissions.individualPermissions) do
                    print(string.format("  %s: %s", perm, granted and "Granted" or "Denied"))
                end
            end
            return
        end
        
        -- Player command
        if not OnyxAC.Permissions.HasPermission(source, "managestaff") then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You don't have permission to use this command."}
            })
            return
        end
        
        local targetId = source
        if #args >= 1 then
            targetId = tonumber(args[1])
            if not targetId or not GetPlayerName(targetId) then
                TriggerClientEvent('chat:addMessage', source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {"OnyxAC", "Invalid player ID."}
                })
                return
            end
        end
        
        local permissions = OnyxAC.Permissions.GetPlayerPermissions(targetId)
        local targetName = GetPlayerName(targetId)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 255},
            multiline = true,
            args = {"OnyxAC", string.format("=== Permissions for %s ===", targetName)}
        })
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 255},
            multiline = true,
            args = {"OnyxAC", string.format("Role: %s (Level: %d)", permissions.role, permissions.level)}
        })
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 255},
            multiline = true,
            args = {"OnyxAC", string.format("Admin UI: %s | AC UI: %s | Bypass: %s", 
                permissions.canAccessAdminUI and "Yes" or "No",
                permissions.canAccessACUI and "Yes" or "No",
                permissions.canBypassDetections and "Yes" or "No")}
        })
    end, false)
    
    -- List all roles command
    RegisterCommand('listroles', function(source, args, rawCommand)
        if source == 0 then
            -- Console command
            print("=== Available Roles ===")
            local sortedRoles = {}
            for roleName, roleConfig in pairs(OnyxAC.Config.permissions.roles) do
                table.insert(sortedRoles, {name = roleName, level = roleConfig.level, desc = roleConfig.description})
            end
            
            table.sort(sortedRoles, function(a, b) return a.level > b.level end)
            
            for _, role in ipairs(sortedRoles) do
                print(string.format("%s (Level: %d) - %s", role.name, role.level, role.desc or "No description"))
            end
            return
        end
        
        -- Player command
        if not OnyxAC.Permissions.HasPermission(source, "managestaff") then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"OnyxAC", "You don't have permission to use this command."}
            })
            return
        end
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 255},
            multiline = true,
            args = {"OnyxAC", "=== Available Roles ==="}
        })
        
        local sortedRoles = {}
        for roleName, roleConfig in pairs(OnyxAC.Config.permissions.roles) do
            table.insert(sortedRoles, {name = roleName, level = roleConfig.level, desc = roleConfig.description})
        end
        
        table.sort(sortedRoles, function(a, b) return a.level > b.level end)
        
        for _, role in ipairs(sortedRoles) do
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 255},
                multiline = true,
                args = {"OnyxAC", string.format("%s (Level: %d) - %s", role.name, role.level, role.desc or "No description")}
            })
        end
    end, false)
end
