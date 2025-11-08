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

OnyxAC.Database = {}

local isInitialized = false

function OnyxAC.Database.Initialize()
    if not OnyxAC.Config.database.enabled then
        print("^3[OnyxAC]^7 Database disabled in configuration")
        return
    end
    
    print("^2[OnyxAC]^7 Initializing database connection...")
    
    if OnyxAC.Config.database.enableAutoMigration then
        OnyxAC.Database.CreateTables()
    end
    
    isInitialized = true
    print("^2[OnyxAC]^7 Database initialized successfully!")
end

function OnyxAC.Database.CreateTables()
    local queries = {
        [[
        CREATE TABLE IF NOT EXISTS `onyxac_bans` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `player_identifier` VARCHAR(255) NOT NULL,
            `player_name` VARCHAR(255) NOT NULL,
            `admin_identifier` VARCHAR(255),
            `admin_name` VARCHAR(255),
            `reason` TEXT NOT NULL,
            `ban_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `expire_date` TIMESTAMP NULL,
            `is_active` BOOLEAN DEFAULT TRUE,
            `evidence` TEXT,
            `server_id` VARCHAR(100),
            INDEX `idx_player_identifier` (`player_identifier`),
            INDEX `idx_active` (`is_active`),
            INDEX `idx_expire` (`expire_date`)
        )
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `onyxac_detections` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `player_id` INT NOT NULL,
            `player_identifier` VARCHAR(255) NOT NULL,
            `player_name` VARCHAR(255) NOT NULL,
            `detection_type` VARCHAR(100) NOT NULL,
            `detection_data` TEXT,
            `score_added` INT DEFAULT 0,
            `total_score` INT DEFAULT 0,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `server_id` VARCHAR(100),
            INDEX `idx_player_identifier` (`player_identifier`),
            INDEX `idx_detection_type` (`detection_type`),
            INDEX `idx_timestamp` (`timestamp`)
        )
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `onyxac_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `log_level` VARCHAR(20) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `message` TEXT NOT NULL,
            `data` TEXT,
            `player_id` INT,
            `player_identifier` VARCHAR(255),
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `server_id` VARCHAR(100),
            INDEX `idx_level` (`log_level`),
            INDEX `idx_category` (`category`),
            INDEX `idx_timestamp` (`timestamp`)
        )
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `onyxac_player_scores` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `player_identifier` VARCHAR(255) NOT NULL UNIQUE,
            `player_name` VARCHAR(255) NOT NULL,
            `current_score` INT DEFAULT 0,
            `total_infractions` INT DEFAULT 0,
            `last_infraction` TIMESTAMP NULL,
            `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_player_identifier` (`player_identifier`),
            INDEX `idx_score` (`current_score`)
        )
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `onyxac_whitelist` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `type` ENUM('entity', 'particle', 'explosion') NOT NULL,
            `value` VARCHAR(255) NOT NULL,
            `added_by` VARCHAR(255),
            `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_whitelist` (`type`, `value`)
        )
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `onyxac_blacklist` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `type` ENUM('entity', 'particle', 'explosion') NOT NULL,
            `value` VARCHAR(255) NOT NULL,
            `added_by` VARCHAR(255),
            `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_blacklist` (`type`, `value`)
        )
        ]]
    }
    
    for _, query in ipairs(queries) do
        MySQL.Async.execute(query, {}, function(result)
            if result then
                print("^2[OnyxAC]^7 Database table created/verified")
            else
                print("^1[OnyxAC]^7 Error creating database table")
            end
        end)
    end
end

function OnyxAC.Database.ExecuteQuery(query, parameters, callback)
    if not isInitialized then
        if callback then callback(false) end
        return
    end
    
    MySQL.Async.execute(query, parameters or {}, function(result)
        if callback then
            callback(result ~= nil)
        end
    end)
end

function OnyxAC.Database.FetchQuery(query, parameters, callback)
    if not isInitialized then
        if callback then callback({}) end
        return
    end
    
    MySQL.Async.fetchAll(query, parameters or {}, function(result)
        if callback then
            callback(result or {})
        end
    end)
end

function OnyxAC.Database.InsertBan(banData, callback)
    local query = [[
        INSERT INTO onyxac_bans 
        (player_identifier, player_name, admin_identifier, admin_name, reason, expire_date, evidence, server_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    local parameters = {
        banData.playerIdentifier,
        banData.playerName,
        banData.adminIdentifier,
        banData.adminName,
        banData.reason,
        banData.expireDate,
        banData.evidence,
        banData.serverId
    }
    
    MySQL.Async.insert(query, parameters, function(insertId)
        if callback then
            callback(insertId)
        end
    end)
end

function OnyxAC.Database.GetActiveBan(playerIdentifier, callback)
    local query = [[
        SELECT * FROM onyxac_bans 
        WHERE player_identifier = ? AND is_active = TRUE 
        AND (expire_date IS NULL OR expire_date > NOW())
        ORDER BY ban_date DESC LIMIT 1
    ]]
    
    MySQL.Async.fetchAll(query, {playerIdentifier}, function(result)
        if callback then
            callback(result and result[1] or nil)
        end
    end)
end

function OnyxAC.Database.RemoveBan(banId, callback)
    local query = "UPDATE onyxac_bans SET is_active = FALSE WHERE id = ?"
    
    MySQL.Async.execute(query, {banId}, function(result)
        if callback then
            callback(result ~= nil)
        end
    end)
end

function OnyxAC.Database.InsertDetection(detectionData, callback)
    local query = [[
        INSERT INTO onyxac_detections 
        (player_id, player_identifier, player_name, detection_type, detection_data, score_added, total_score, server_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    local parameters = {
        detectionData.playerId,
        detectionData.playerIdentifier,
        detectionData.playerName,
        detectionData.detectionType,
        json.encode(detectionData.detectionData),
        detectionData.scoreAdded,
        detectionData.totalScore,
        detectionData.serverId
    }
    
    OnyxAC.Database.ExecuteQuery(query, parameters, callback)
end

function OnyxAC.Database.InsertLog(logData, callback)
    local query = [[
        INSERT INTO onyxac_logs 
        (log_level, category, message, data, player_id, player_identifier, server_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]]
    
    local parameters = {
        logData.level,
        logData.category,
        logData.message,
        logData.data and json.encode(logData.data) or nil,
        logData.playerId,
        logData.playerIdentifier,
        logData.serverId
    }
    
    OnyxAC.Database.ExecuteQuery(query, parameters, callback)
end

function OnyxAC.Database.UpdatePlayerScore(playerIdentifier, playerName, score, callback)
    local query = [[
        INSERT INTO onyxac_player_scores (player_identifier, player_name, current_score, total_infractions, last_infraction)
        VALUES (?, ?, ?, 1, NOW())
        ON DUPLICATE KEY UPDATE
        current_score = ?, total_infractions = total_infractions + 1, last_infraction = NOW(), player_name = ?
    ]]
    
    local parameters = {playerIdentifier, playerName, score, score, playerName}
    
    OnyxAC.Database.ExecuteQuery(query, parameters, callback)
end

function OnyxAC.Database.GetPlayerScore(playerIdentifier, callback)
    local query = "SELECT current_score FROM onyxac_player_scores WHERE player_identifier = ?"
    
    MySQL.Async.fetchAll(query, {playerIdentifier}, function(result)
        if callback then
            callback(result and result[1] and result[1].current_score or 0)
        end
    end)
end

function OnyxAC.Database.ClearPlayerScore(playerIdentifier, callback)
    local query = "UPDATE onyxac_player_scores SET current_score = 0 WHERE player_identifier = ?"
    
    OnyxAC.Database.ExecuteQuery(query, {playerIdentifier}, callback)
end

function OnyxAC.Database.AddToWhitelist(type, value, addedBy, callback)
    local query = "INSERT IGNORE INTO onyxac_whitelist (type, value, added_by) VALUES (?, ?, ?)"
    
    OnyxAC.Database.ExecuteQuery(query, {type, value, addedBy}, callback)
end

function OnyxAC.Database.RemoveFromWhitelist(type, value, callback)
    local query = "DELETE FROM onyxac_whitelist WHERE type = ? AND value = ?"
    
    OnyxAC.Database.ExecuteQuery(query, {type, value}, callback)
end

function OnyxAC.Database.AddToBlacklist(type, value, addedBy, callback)
    local query = "INSERT IGNORE INTO onyxac_blacklist (type, value, added_by) VALUES (?, ?, ?)"
    
    OnyxAC.Database.ExecuteQuery(query, {type, value, addedBy}, callback)
end

function OnyxAC.Database.RemoveFromBlacklist(type, value, callback)
    local query = "DELETE FROM onyxac_blacklist WHERE type = ? AND value = ?"
    
    OnyxAC.Database.ExecuteQuery(query, {type, value}, callback)
end

function OnyxAC.Database.GetWhitelist(type, callback)
    local query = "SELECT value FROM onyxac_whitelist WHERE type = ?"
    
    OnyxAC.Database.FetchQuery(query, {type}, function(result)
        local values = {}
        for _, row in ipairs(result) do
            table.insert(values, row.value)
        end
        if callback then callback(values) end
    end)
end

function OnyxAC.Database.GetBlacklist(type, callback)
    local query = "SELECT value FROM onyxac_blacklist WHERE type = ?"
    
    OnyxAC.Database.FetchQuery(query, {type}, function(result)
        local values = {}
        for _, row in ipairs(result) do
            table.insert(values, row.value)
        end
        if callback then callback(values) end
    end)
end
