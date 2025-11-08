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

OnyxAC.Logger = {}

local recentDetections = {}
local totalDetections = 0
local logQueue = {}

function OnyxAC.Logger.Initialize()
    print("^2[OnyxAC]^7 Initializing logger...")
    
    Citizen.CreateThread(function()
        while true do
            OnyxAC.Logger.ProcessLogQueue()
            Wait(1000)
        end
    end)
    
    print("^2[OnyxAC]^7 Logger initialized!")
end

function OnyxAC.Logger.Log(level, message, data, category)
    if not OnyxAC.Config.logging.logCategories[category or "general"] then
        return
    end
    
    local logEntry = {
        level = level,
        message = message,
        data = data,
        category = category or "general",
        timestamp = os.time(),
        serverId = GetConvar("sv_hostname", "Unknown Server")
    }
    
    if data and data.playerId then
        local playerData = OnyxAC.GetPlayerData(data.playerId)
        if playerData then
            logEntry.playerIdentifier = OnyxAC.Config.logging.hashSensitiveData and 
                                       OnyxAC.Logger.HashIdentifier(playerData.steamId or playerData.license) or 
                                       (playerData.steamId or playerData.license)
        end
    end
    
    table.insert(logQueue, logEntry)
    
    if level == "detection" then
        totalDetections = totalDetections + 1
        table.insert(recentDetections, 1, logEntry)
        
        if #recentDetections > 100 then
            table.remove(recentDetections)
        end
    end
    
    if OnyxAC.Config.general.enableDebugMode or level == "error" then
        local color = OnyxAC.Logger.GetLogColor(level)
        print(string.format("^%d[OnyxAC-%s]^7 %s", color, string.upper(level), message))
        
        if data and OnyxAC.Config.general.enableDebugMode then
            print("^3[OnyxAC-DEBUG]^7 Data: " .. json.encode(data))
        end
    end
end

function OnyxAC.Logger.GetLogColor(level)
    local colors = {
        info = 2,
        warning = 3,
        error = 1,
        detection = 5,
        ban = 1,
        kick = 3,
        success = 2
    }
    return colors[level] or 7
end

function OnyxAC.Logger.ProcessLogQueue()
    if #logQueue == 0 then return end
    
    local logsToProcess = {}
    for i = 1, math.min(#logQueue, 10) do
        table.insert(logsToProcess, table.remove(logQueue, 1))
    end
    
    for _, logEntry in ipairs(logsToProcess) do
        if OnyxAC.Config.logging.enableFileLogging then
            OnyxAC.Logger.WriteToFile(logEntry)
        end
        
        if OnyxAC.Config.logging.enableDatabaseLogging and OnyxAC.Database then
            OnyxAC.Database.InsertLog(logEntry)
        end
        
        if OnyxAC.Config.logging.enableDiscordLogging and OnyxAC.DiscordWebhook then
            OnyxAC.DiscordWebhook.SendLog(logEntry)
        end
    end
end

function OnyxAC.Logger.WriteToFile(logEntry)
    local logDir = "logs/"
    local logFile = logDir .. "onyxac_" .. os.date("%Y-%m-%d") .. ".log"
    
    local logLine = string.format("[%s] [%s] [%s] %s",
        os.date("%Y-%m-%d %H:%M:%S", logEntry.timestamp),
        string.upper(logEntry.level),
        string.upper(logEntry.category),
        logEntry.message
    )
    
    if logEntry.data then
        logLine = logLine .. " | Data: " .. json.encode(logEntry.data)
    end
    
    logLine = logLine .. "\n"
    
    SaveResourceFile(GetCurrentResourceName(), logFile, LoadResourceFile(GetCurrentResourceName(), logFile) or "" .. logLine, -1)
end

function OnyxAC.Logger.HashIdentifier(identifier)
    if not identifier then return nil end
    
    local hash = 0
    for i = 1, #identifier do
        hash = ((hash << 5) - hash) + string.byte(identifier, i)
        hash = hash & 0xFFFFFFFF
    end
    
    return string.format("hash_%08x", hash)
end

function OnyxAC.Logger.GetRecentDetections(limit)
    limit = limit or 50
    local result = {}
    
    for i = 1, math.min(#recentDetections, limit) do
        table.insert(result, recentDetections[i])
    end
    
    return result
end

function OnyxAC.Logger.GetTotalDetections()
    return totalDetections
end

function OnyxAC.Logger.LogDetection(playerId, detectionType, data, scoreAdded, totalScore)
    local playerData = OnyxAC.GetPlayerData(playerId)
    if not playerData then return end
    
    local logData = {
        playerId = playerId,
        playerName = playerData.name,
        detectionType = detectionType,
        detectionData = data,
        scoreAdded = scoreAdded,
        totalScore = totalScore,
        playerIdentifier = playerData.steamId or playerData.license
    }
    
    OnyxAC.Logger.Log("detection", string.format("Detection triggered: %s for player %s (Score: +%d = %d)", 
        detectionType, playerData.name, scoreAdded, totalScore), logData, "detections")
    
    if OnyxAC.Config.database.enabled then
        OnyxAC.Database.InsertDetection({
            playerId = playerId,
            playerIdentifier = playerData.steamId or playerData.license,
            playerName = playerData.name,
            detectionType = detectionType,
            detectionData = data,
            scoreAdded = scoreAdded,
            totalScore = totalScore,
            serverId = GetConvar("sv_hostname", "Unknown Server")
        })
    end
end

function OnyxAC.Logger.LogBan(playerId, adminId, reason, duration, banId)
    local playerData = OnyxAC.GetPlayerData(playerId)
    local adminData = adminId and OnyxAC.GetPlayerData(adminId) or nil
    
    local logData = {
        playerId = playerId,
        playerName = playerData and playerData.name or "Unknown",
        adminId = adminId,
        adminName = adminData and adminData.name or "System",
        reason = reason,
        duration = duration,
        banId = banId
    }
    
    OnyxAC.Logger.Log("ban", string.format("Player banned: %s by %s for %s (Duration: %s minutes)", 
        logData.playerName, logData.adminName, reason, duration == 0 and "Permanent" or tostring(duration)), 
        logData, "bans")
end

function OnyxAC.Logger.LogUnban(banId, adminId, reason)
    local adminData = adminId and OnyxAC.GetPlayerData(adminId) or nil
    
    local logData = {
        banId = banId,
        adminId = adminId,
        adminName = adminData and adminData.name or "System",
        reason = reason or "No reason provided"
    }
    
    OnyxAC.Logger.Log("success", string.format("Ban removed: ID %s by %s (%s)", 
        banId, logData.adminName, reason), logData, "bans")
end

function OnyxAC.Logger.LogKick(playerId, adminId, reason)
    local playerData = OnyxAC.GetPlayerData(playerId)
    local adminData = adminId and OnyxAC.GetPlayerData(adminId) or nil
    
    local logData = {
        playerId = playerId,
        playerName = playerData and playerData.name or "Unknown",
        adminId = adminId,
        adminName = adminData and adminData.name or "System",
        reason = reason
    }
    
    OnyxAC.Logger.Log("kick", string.format("Player kicked: %s by %s for %s", 
        logData.playerName, logData.adminName, reason), logData, "kicks")
end

function OnyxAC.Logger.LogWarning(playerId, adminId, reason)
    local playerData = OnyxAC.GetPlayerData(playerId)
    local adminData = adminId and OnyxAC.GetPlayerData(adminId) or nil
    
    local logData = {
        playerId = playerId,
        playerName = playerData and playerData.name or "Unknown",
        adminId = adminId,
        adminName = adminData and adminData.name or "System",
        reason = reason
    }
    
    OnyxAC.Logger.Log("warning", string.format("Player warned: %s by %s for %s", 
        logData.playerName, logData.adminName, reason), logData, "warnings")
end

function OnyxAC.Logger.LogAdminAction(adminId, action, targetId, data)
    local adminData = OnyxAC.GetPlayerData(adminId)
    local targetData = targetId and OnyxAC.GetPlayerData(targetId) or nil
    
    local logData = {
        adminId = adminId,
        adminName = adminData and adminData.name or "Unknown",
        action = action,
        targetId = targetId,
        targetName = targetData and targetData.name or "N/A",
        data = data
    }
    
    OnyxAC.Logger.Log("info", string.format("Admin action: %s performed %s on %s", 
        logData.adminName, action, logData.targetName), logData, "adminActions")
end
