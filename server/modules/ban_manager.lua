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

OnyxAC.BanManager = {}

local banCache = {}
local activeBansCount = 0

function OnyxAC.BanManager.Initialize()
    print("^2[OnyxAC]^7 Initializing ban manager...")
    
    if OnyxAC.Config.banManager.enableBanSync then
        Citizen.CreateThread(function()
            while true do
                OnyxAC.BanManager.SyncBans()
                Wait(OnyxAC.Config.banManager.syncInterval)
            end
        end)
    end
    
    OnyxAC.BanManager.LoadBanCache()
    print("^2[OnyxAC]^7 Ban manager initialized!")
end

function OnyxAC.BanManager.LoadBanCache()
    if not OnyxAC.Config.database.enabled then return end
    
    local query = [[
        SELECT id, player_identifier, reason, expire_date, ban_date
        FROM onyxac_bans 
        WHERE is_active = TRUE AND (expire_date IS NULL OR expire_date > NOW())
    ]]
    
    OnyxAC.Database.FetchQuery(query, {}, function(result)
        banCache = {}
        activeBansCount = 0
        
        for _, ban in ipairs(result) do
            banCache[ban.player_identifier] = {
                id = ban.id,
                reason = ban.reason,
                expires = ban.expire_date and os.time(ban.expire_date) or 0,
                banDate = os.time(ban.ban_date)
            }
            activeBansCount = activeBansCount + 1
        end
        
        print("^2[OnyxAC]^7 Loaded " .. activeBansCount .. " active bans into cache")
    end)
end

function OnyxAC.BanManager.CheckPlayerBan(playerIdentifier)
    if not playerIdentifier then return nil end
    
    local cachedBan = banCache[playerIdentifier]
    if cachedBan then
        if cachedBan.expires == 0 or cachedBan.expires > os.time() then
            return cachedBan
        else
            banCache[playerIdentifier] = nil
            activeBansCount = activeBansCount - 1
        end
    end
    
    return nil
end

function OnyxAC.BanManager.BanPlayer(playerId, adminId, reason, duration, evidence)
    local playerData = OnyxAC.GetPlayerData(playerId)
    if not playerData then return false end
    
    local adminData = adminId and OnyxAC.GetPlayerData(adminId) or nil
    local playerIdentifier = playerData.steamId or playerData.license
    
    if not playerIdentifier then return false end
    
    duration = duration or OnyxAC.Config.banManager.defaultBanDuration
    if duration > OnyxAC.Config.banManager.maxBanDuration then
        duration = OnyxAC.Config.banManager.maxBanDuration
    end
    
    local expireDate = duration == 0 and nil or os.date("%Y-%m-%d %H:%M:%S", os.time() + (duration * 60))
    
    local banData = {
        playerIdentifier = playerIdentifier,
        playerName = playerData.name,
        adminIdentifier = adminData and (adminData.steamId or adminData.license) or nil,
        adminName = adminData and adminData.name or "System",
        reason = reason,
        expireDate = expireDate,
        evidence = evidence,
        serverId = GetConvar("sv_hostname", "Unknown Server")
    }
    
    if OnyxAC.Config.database.enabled then
        OnyxAC.Database.InsertBan(banData, function(banId)
            if banId then
                banCache[playerIdentifier] = {
                    id = banId,
                    reason = reason,
                    expires = duration == 0 and 0 or (os.time() + (duration * 60)),
                    banDate = os.time()
                }
                activeBansCount = activeBansCount + 1
                
                OnyxAC.Logger.LogBan(playerId, adminId, reason, duration, banId)
                
                if OnyxAC.Config.banManager.enableBanSync then
                    OnyxAC.BanManager.SyncBanToNetwork(banData)
                end
                
                DropPlayer(playerId, string.format("You have been banned from this server.\nReason: %s\nDuration: %s\nBan ID: %s", 
                    reason, 
                    duration == 0 and "Permanent" or (duration .. " minutes"),
                    banId))
            end
        end)
    else
        local banId = "local_" .. os.time()
        banCache[playerIdentifier] = {
            id = banId,
            reason = reason,
            expires = duration == 0 and 0 or (os.time() + (duration * 60)),
            banDate = os.time()
        }
        activeBansCount = activeBansCount + 1
        
        OnyxAC.Logger.LogBan(playerId, adminId, reason, duration, banId)
        
        DropPlayer(playerId, string.format("You have been banned from this server.\nReason: %s\nDuration: %s\nBan ID: %s", 
            reason, 
            duration == 0 and "Permanent" or (duration .. " minutes"),
            banId))
    end
    
    return true
end

function OnyxAC.BanManager.UnbanPlayer(banId, adminId, reason)
    if OnyxAC.Config.database.enabled then
        OnyxAC.Database.RemoveBan(banId, function(success)
            if success then
                for identifier, ban in pairs(banCache) do
                    if ban.id == banId then
                        banCache[identifier] = nil
                        activeBansCount = activeBansCount - 1
                        break
                    end
                end
                
                OnyxAC.Logger.LogUnban(banId, adminId, reason)
                
                if OnyxAC.Config.banManager.enableBanSync then
                    OnyxAC.BanManager.SyncUnbanToNetwork(banId)
                end
            end
        end)
    else
        for identifier, ban in pairs(banCache) do
            if ban.id == banId then
                banCache[identifier] = nil
                activeBansCount = activeBansCount - 1
                OnyxAC.Logger.LogUnban(banId, adminId, reason)
                return true
            end
        end
    end
    
    return false
end

function OnyxAC.BanManager.GetActiveBansCount()
    return activeBansCount
end

function OnyxAC.BanManager.AutoBanPlayer(playerId, reason, evidence)
    return OnyxAC.BanManager.BanPlayer(playerId, nil, reason or "Automatic ban - Anti-cheat detection", 0, evidence)
end

function OnyxAC.BanManager.SyncBans()
    if not OnyxAC.Config.banManager.enableBanSync then return end
    
    local syncURL = OnyxAC.Config.banManager.banSyncURL .. "/bulk-sync"
    local apiKey = OnyxAC.Config.banManager.banSyncAPIKey
    
    if not syncURL or not apiKey then return end
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["X-API-Key"] = apiKey
    }
    
    local payload = {
        serverId = GetConvar("sv_hostname", "Unknown Server"),
        timestamp = os.time()
    }
    
    PerformHttpRequest(syncURL, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data.bans then
                OnyxAC.BanManager.ProcessSyncedBans(data.bans)
            end
        end
    end, "POST", json.encode(payload), headers)
end

function OnyxAC.BanManager.ProcessSyncedBans(syncedBans)
    for _, ban in ipairs(syncedBans) do
        if not banCache[ban.playerIdentifier] then
            banCache[ban.playerIdentifier] = {
                id = ban.id,
                reason = ban.reason,
                expires = ban.expires,
                banDate = ban.banDate,
                synced = true
            }
            activeBansCount = activeBansCount + 1
        end
    end
end

function OnyxAC.BanManager.SyncBanToNetwork(banData)
    if not OnyxAC.Config.banManager.enableBanSync then return end
    
    local syncURL = OnyxAC.Config.banManager.banSyncURL .. "/ban"
    local apiKey = OnyxAC.Config.banManager.banSyncAPIKey
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["X-API-Key"] = apiKey
    }
    
    PerformHttpRequest(syncURL, function(statusCode, response, headers)
        if statusCode ~= 200 then
            print("^1[OnyxAC]^7 Failed to sync ban to network: " .. statusCode)
        end
    end, "POST", json.encode(banData), headers)
end

function OnyxAC.BanManager.SyncUnbanToNetwork(banId)
    if not OnyxAC.Config.banManager.enableBanSync then return end
    
    local syncURL = OnyxAC.Config.banManager.banSyncURL .. "/unban"
    local apiKey = OnyxAC.Config.banManager.banSyncAPIKey
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["X-API-Key"] = apiKey
    }
    
    local payload = {
        banId = banId,
        serverId = GetConvar("sv_hostname", "Unknown Server")
    }
    
    PerformHttpRequest(syncURL, function(statusCode, response, headers)
        if statusCode ~= 200 then
            print("^1[OnyxAC]^7 Failed to sync unban to network: " .. statusCode)
        end
    end, "POST", json.encode(payload), headers)
end
