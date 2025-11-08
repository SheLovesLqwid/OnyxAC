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

OnyxAC.Permissions = {}

local staffCache = {}
local individualPermissions = {}

function OnyxAC.Permissions.Initialize()
    print("^2[OnyxAC]^7 Initializing FiveM license-based permissions system...")
    
    -- Load staff from config (fallback)
    if OnyxAC.Config.permissions.staffLicenses then
        for license, role in pairs(OnyxAC.Config.permissions.staffLicenses) do
            staffCache[license] = {
                role = role,
                individualPermissions = {}
            }
        end
    end
    
    -- Load staff from database if enabled
    if OnyxAC.Config.database.enabled then
        OnyxAC.Permissions.LoadStaffFromDatabase()
    end
    
    print("^2[OnyxAC]^7 FiveM license-based permissions system initialized!")
end

function OnyxAC.Permissions.LoadStaffFromDatabase()
    if not OnyxAC.Database then return end
    
    local query = [[
        SELECT s.fivem_license, s.role, s.individual_permissions, 
               GROUP_CONCAT(CONCAT(sp.permission, ':', sp.granted) SEPARATOR ',') as permissions
        FROM onyxac_staff s
        LEFT JOIN onyxac_staff_permissions sp ON s.id = sp.staff_id
        WHERE s.is_active = 1
        GROUP BY s.id
    ]]
    
    OnyxAC.Database.Query(query, {}, function(results)
        if results then
            for _, staff in ipairs(results) do
                staffCache[staff.fivem_license] = {
                    role = staff.role,
                    individualPermissions = {}
                }
                
                -- Parse individual permissions
                if staff.permissions then
                    for permissionData in string.gmatch(staff.permissions, "([^,]+)") do
                        local permission, granted = string.match(permissionData, "([^:]+):([^:]+)")
                        if permission and granted then
                            staffCache[staff.fivem_license].individualPermissions[permission] = granted == "1"
                        end
                    end
                end
            end
            print(string.format("^2[OnyxAC]^7 Loaded %d staff members from database", #results))
        end
    end)
end

function OnyxAC.Permissions.GetPlayerLicense(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, "^license:") then
            return identifier
        end
    end
    return nil
end

function OnyxAC.Permissions.GetPlayerRole(playerId)
    local license = OnyxAC.Permissions.GetPlayerLicense(playerId)
    if not license then
        return OnyxAC.Config.permissions.defaultRole or "player"
    end
    
    local staffData = staffCache[license]
    if staffData then
        return staffData.role
    end
    
    return OnyxAC.Config.permissions.defaultRole or "player"
end

function OnyxAC.Permissions.GetRoleLevel(role)
    local roleConfig = OnyxAC.Config.permissions.roles[role]
    return roleConfig and roleConfig.level or 0
end

function OnyxAC.Permissions.HasPermission(playerId, permission)
    local license = OnyxAC.Permissions.GetPlayerLicense(playerId)
    if not license then return false end
    
    local staffData = staffCache[license]
    if not staffData then return false end
    
    -- Check individual permissions first (overrides role permissions)
    if OnyxAC.Config.permissions.allowIndividualPermissions and staffData.individualPermissions[permission] ~= nil then
        return staffData.individualPermissions[permission]
    end
    
    -- Check role permissions
    local roleConfig = OnyxAC.Config.permissions.roles[staffData.role]
    if not roleConfig then return false end
    
    -- Check if role has this specific permission
    if roleConfig.permissions and roleConfig.permissions[permission] ~= nil then
        return roleConfig.permissions[permission]
    end
    
    -- Check legacy permission format
    if roleConfig[permission] ~= nil then
        return roleConfig[permission]
    end
    
    return false
end

function OnyxAC.Permissions.HasCommand(playerId, command)
    local license = OnyxAC.Permissions.GetPlayerLicense(playerId)
    if not license then return false end
    
    local staffData = staffCache[license]
    if not staffData then return false end
    
    local roleConfig = OnyxAC.Config.permissions.roles[staffData.role]
    if not roleConfig or not roleConfig.commands then return false end
    
    for _, allowedCommand in ipairs(roleConfig.commands) do
        if allowedCommand == "*" or allowedCommand == command then
            return true
        end
    end
    
    return false
end

function OnyxAC.Permissions.HasHigherRole(playerId, targetPlayerId)
    local playerRole = OnyxAC.Permissions.GetPlayerRole(playerId)
    local targetRole = OnyxAC.Permissions.GetPlayerRole(targetPlayerId)
    
    local playerLevel = OnyxAC.Permissions.GetRoleLevel(playerRole)
    local targetLevel = OnyxAC.Permissions.GetRoleLevel(targetRole)
    
    return playerLevel > targetLevel
end

function OnyxAC.Permissions.SetPlayerRole(playerId, role, adminId)
    local license = OnyxAC.Permissions.GetPlayerLicense(playerId)
    if not license then return false end
    
    if not OnyxAC.Config.permissions.roles[role] then return false end
    
    local playerName = GetPlayerName(playerId)
    local adminLicense = adminId and OnyxAC.Permissions.GetPlayerLicense(adminId) or nil
    
    -- Update cache
    if not staffCache[license] then
        staffCache[license] = { individualPermissions = {} }
    end
    staffCache[license].role = role
    
    -- Update database if enabled
    if OnyxAC.Config.database.enabled and OnyxAC.Database then
        local query = [[
            INSERT INTO onyxac_staff (fivem_license, name, role, added_by, server_id)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            role = VALUES(role), name = VALUES(name), added_by = VALUES(added_by)
        ]]
        
        OnyxAC.Database.Query(query, {
            license,
            playerName,
            role,
            adminLicense,
            GetConvar("sv_hostname", "Unknown Server")
        })
    end
    
    return true
end

function OnyxAC.Permissions.RemovePlayerRole(playerId, adminId)
    local license = OnyxAC.Permissions.GetPlayerLicense(playerId)
    if not license then return false end
    
    -- Remove from cache
    staffCache[license] = nil
    
    -- Update database if enabled
    if OnyxAC.Config.database.enabled and OnyxAC.Database then
        local query = "UPDATE onyxac_staff SET is_active = 0 WHERE fivem_license = ?"
        OnyxAC.Database.Query(query, { license })
    end
    
    return true
end

function OnyxAC.Permissions.SetIndividualPermission(playerId, permission, granted, adminId)
    if not OnyxAC.Config.permissions.allowIndividualPermissions then
        return false, "Individual permissions are disabled"
    end
    
    local license = OnyxAC.Permissions.GetPlayerLicense(playerId)
    if not license then return false, "Player license not found" end
    
    local staffData = staffCache[license]
    if not staffData then return false, "Player is not staff" end
    
    -- Update cache
    staffData.individualPermissions[permission] = granted
    
    -- Update database if enabled
    if OnyxAC.Config.database.enabled and OnyxAC.Database then
        -- First get staff ID
        local getStaffQuery = "SELECT id FROM onyxac_staff WHERE fivem_license = ? AND is_active = 1"
        OnyxAC.Database.Query(getStaffQuery, { license }, function(results)
            if results and #results > 0 then
                local staffId = results[1].id
                local adminLicense = adminId and OnyxAC.Permissions.GetPlayerLicense(adminId) or nil
                
                local query = [[
                    INSERT INTO onyxac_staff_permissions (staff_id, permission, granted, granted_by)
                    VALUES (?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE
                    granted = VALUES(granted), granted_by = VALUES(granted_by), granted_date = CURRENT_TIMESTAMP
                ]]
                
                OnyxAC.Database.Query(query, {
                    staffId,
                    permission,
                    granted and 1 or 0,
                    adminLicense
                })
            end
        end)
    end
    
    return true, "Permission updated successfully"
end

function OnyxAC.Permissions.GetAllRoles()
    local roles = {}
    for roleName, roleConfig in pairs(OnyxAC.Config.permissions.roles) do
        roles[roleName] = {
            level = roleConfig.level,
            commands = roleConfig.commands,
            permissions = roleConfig.permissions,
            canAccessAdminUI = roleConfig.canAccessAdminUI,
            canAccessACUI = roleConfig.canAccessACUI,
            canBypassDetections = roleConfig.canBypassDetections,
            description = roleConfig.description
        }
    end
    return roles
end

function OnyxAC.Permissions.GetPlayerPermissions(playerId)
    local license = OnyxAC.Permissions.GetPlayerLicense(playerId)
    local role = OnyxAC.Permissions.GetPlayerRole(playerId)
    local roleConfig = OnyxAC.Config.permissions.roles[role]
    
    local permissions = {
        license = license,
        role = role,
        level = roleConfig and roleConfig.level or 0,
        commands = roleConfig and roleConfig.commands or {},
        permissions = roleConfig and roleConfig.permissions or {},
        canAccessAdminUI = roleConfig and roleConfig.canAccessAdminUI or false,
        canAccessACUI = roleConfig and roleConfig.canAccessACUI or false,
        canBypassDetections = roleConfig and roleConfig.canBypassDetections or false,
        individualPermissions = {}
    }
    
    -- Add individual permissions if enabled
    if license and staffCache[license] and OnyxAC.Config.permissions.allowIndividualPermissions then
        permissions.individualPermissions = staffCache[license].individualPermissions or {}
    end
    
    return permissions
end

function OnyxAC.Permissions.GetStaffList()
    local staffList = {}
    for license, staffData in pairs(staffCache) do
        table.insert(staffList, {
            license = license,
            role = staffData.role,
            individualPermissions = staffData.individualPermissions
        })
    end
    return staffList
end

-- Network Events
RegisterNetEvent('onyxac:admin:requestPermissions')
AddEventHandler('onyxac:admin:requestPermissions', function()
    local playerId = source
    local permissions = OnyxAC.Permissions.GetPlayerPermissions(playerId)
    
    TriggerClientEvent('onyxac:admin:receivePermissions', playerId, permissions)
end)

RegisterNetEvent('onyxac:admin:requestStaffList')
AddEventHandler('onyxac:admin:requestStaffList', function()
    local playerId = source
    
    if not OnyxAC.Permissions.HasPermission(playerId, "managestaff") then
        return
    end
    
    local staffList = OnyxAC.Permissions.GetStaffList()
    TriggerClientEvent('onyxac:admin:receiveStaffList', playerId, staffList)
end)

RegisterNetEvent('onyxac:admin:setPlayerRole')
AddEventHandler('onyxac:admin:setPlayerRole', function(targetId, role)
    local playerId = source
    
    if not OnyxAC.Permissions.HasPermission(playerId, "managestaff") then
        TriggerClientEvent('onyxac:admin:notify', playerId, "You don't have permission to manage staff", "error")
        return
    end
    
    if not OnyxAC.Permissions.HasHigherRole(playerId, targetId) then
        TriggerClientEvent('onyxac:admin:notify', playerId, "You cannot modify this player's role", "error")
        return
    end
    
    local success = OnyxAC.Permissions.SetPlayerRole(targetId, role, playerId)
    if success then
        local targetName = GetPlayerName(targetId)
        TriggerClientEvent('onyxac:admin:notify', playerId, string.format("Set %s's role to %s", targetName, role), "success")
        TriggerClientEvent('onyxac:admin:notify', targetId, string.format("Your role has been set to %s", role), "info")
    else
        TriggerClientEvent('onyxac:admin:notify', playerId, "Failed to set player role", "error")
    end
end)

RegisterNetEvent('onyxac:admin:setIndividualPermission')
AddEventHandler('onyxac:admin:setIndividualPermission', function(targetId, permission, granted)
    local playerId = source
    
    if not OnyxAC.Permissions.HasPermission(playerId, "setpermissions") then
        TriggerClientEvent('onyxac:admin:notify', playerId, "You don't have permission to set individual permissions", "error")
        return
    end
    
    if not OnyxAC.Permissions.HasHigherRole(playerId, targetId) then
        TriggerClientEvent('onyxac:admin:notify', playerId, "You cannot modify this player's permissions", "error")
        return
    end
    
    local success, message = OnyxAC.Permissions.SetIndividualPermission(targetId, permission, granted, playerId)
    if success then
        local targetName = GetPlayerName(targetId)
        local action = granted and "granted" or "revoked"
        TriggerClientEvent('onyxac:admin:notify', playerId, 
            string.format("%s %s permission for %s", action:gsub("^%l", string.upper), permission, targetName), "success")
    else
        TriggerClientEvent('onyxac:admin:notify', playerId, message or "Failed to set permission", "error")
    end
end)
