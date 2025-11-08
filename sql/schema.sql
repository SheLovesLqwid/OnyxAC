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

-- OnyxAC Database Schema
-- Compatible with MySQL 5.7+ and MariaDB 10.2+

-- Create database (optional - you may want to create this manually)
-- CREATE DATABASE IF NOT EXISTS onyxac CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE onyxac;

-- Bans table - stores all ban records
CREATE TABLE IF NOT EXISTS `onyxac_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(255) NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `admin_identifier` VARCHAR(255) NULL,
    `admin_name` VARCHAR(255) NULL,
    `reason` TEXT NOT NULL,
    `ban_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expire_date` TIMESTAMP NULL,
    `is_active` BOOLEAN DEFAULT TRUE,
    `evidence` TEXT NULL,
    `server_id` VARCHAR(100) NULL,
    `unban_date` TIMESTAMP NULL,
    `unban_reason` TEXT NULL,
    `unban_admin` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_active` (`is_active`),
    INDEX `idx_expire` (`expire_date`),
    INDEX `idx_ban_date` (`ban_date`),
    INDEX `idx_server_id` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Detections table - stores anti-cheat detection events
CREATE TABLE IF NOT EXISTS `onyxac_detections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` INT NOT NULL,
    `player_identifier` VARCHAR(255) NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `detection_type` VARCHAR(100) NOT NULL,
    `detection_data` JSON NULL,
    `score_added` INT DEFAULT 0,
    `total_score` INT DEFAULT 0,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `server_id` VARCHAR(100) NULL,
    `session_id` VARCHAR(100) NULL,
    `ip_hash` VARCHAR(64) NULL,
    
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_detection_type` (`detection_type`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_server_id` (`server_id`),
    INDEX `idx_score` (`total_score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Logs table - stores system logs and events
CREATE TABLE IF NOT EXISTS `onyxac_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `log_level` ENUM('debug', 'info', 'warning', 'error', 'critical') NOT NULL DEFAULT 'info',
    `category` VARCHAR(50) NOT NULL,
    `message` TEXT NOT NULL,
    `data` JSON NULL,
    `player_id` INT NULL,
    `player_identifier` VARCHAR(255) NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `server_id` VARCHAR(100) NULL,
    `ip_hash` VARCHAR(64) NULL,
    
    INDEX `idx_level` (`log_level`),
    INDEX `idx_category` (`category`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_server_id` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player scores table - tracks current anti-cheat scores
CREATE TABLE IF NOT EXISTS `onyxac_player_scores` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(255) NOT NULL UNIQUE,
    `player_name` VARCHAR(255) NOT NULL,
    `current_score` INT DEFAULT 0,
    `total_infractions` INT DEFAULT 0,
    `last_infraction` TIMESTAMP NULL,
    `first_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `server_id` VARCHAR(100) NULL,
    
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_score` (`current_score`),
    INDEX `idx_last_infraction` (`last_infraction`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Whitelist table - stores whitelisted entities, particles, explosions
CREATE TABLE IF NOT EXISTS `onyxac_whitelist` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` ENUM('entity', 'particle', 'explosion', 'weapon', 'vehicle') NOT NULL,
    `value` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `added_by` VARCHAR(255) NULL,
    `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `server_id` VARCHAR(100) NULL,
    
    UNIQUE KEY `unique_whitelist` (`type`, `value`, `server_id`),
    INDEX `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Blacklist table - stores blacklisted entities, particles, explosions
CREATE TABLE IF NOT EXISTS `onyxac_blacklist` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` ENUM('entity', 'particle', 'explosion', 'weapon', 'vehicle') NOT NULL,
    `value` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `added_by` VARCHAR(255) NULL,
    `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `server_id` VARCHAR(100) NULL,
    
    UNIQUE KEY `unique_blacklist` (`type`, `value`, `server_id`),
    INDEX `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin actions table - tracks admin command usage
CREATE TABLE IF NOT EXISTS `onyxac_admin_actions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier` VARCHAR(255) NOT NULL,
    `admin_name` VARCHAR(255) NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `target_identifier` VARCHAR(255) NULL,
    `target_name` VARCHAR(255) NULL,
    `parameters` JSON NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `server_id` VARCHAR(100) NULL,
    `ip_hash` VARCHAR(64) NULL,
    
    INDEX `idx_admin_identifier` (`admin_identifier`),
    INDEX `idx_action` (`action`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_target_identifier` (`target_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sessions table - tracks player sessions
CREATE TABLE IF NOT EXISTS `onyxac_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `session_id` VARCHAR(100) NOT NULL UNIQUE,
    `player_identifier` VARCHAR(255) NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `connect_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `disconnect_time` TIMESTAMP NULL,
    `duration` INT NULL, -- in seconds
    `server_id` VARCHAR(100) NULL,
    `ip_hash` VARCHAR(64) NULL,
    `disconnect_reason` VARCHAR(255) NULL,
    
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_connect_time` (`connect_time`),
    INDEX `idx_session_id` (`session_id`),
    INDEX `idx_server_id` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Configuration table - stores server-specific configurations
CREATE TABLE IF NOT EXISTS `onyxac_config` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_id` VARCHAR(100) NOT NULL,
    `config_key` VARCHAR(100) NOT NULL,
    `config_value` JSON NOT NULL,
    `updated_by` VARCHAR(255) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `unique_config` (`server_id`, `config_key`),
    INDEX `idx_server_id` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff permissions table - stores staff role assignments with FiveM license support
CREATE TABLE IF NOT EXISTS `onyxac_staff` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `fivem_license` VARCHAR(255) NOT NULL,
    `steam_id` VARCHAR(255) NULL,
    `discord_id` VARCHAR(255) NULL,
    `name` VARCHAR(255) NOT NULL,
    `role` ENUM('trial', 'mod', 'moderator', 'sr_mod', 'head_mod', 'jr_admin', 'admin', 'head_admin', 'sr_head_admin', 'trial_mgmt', 'jr_mgmt', 'mgmt', 'sr_mgmt', 'head_of_mgmt', 'ownership', 'developer') NOT NULL,
    `individual_permissions` JSON NULL,
    `added_by` VARCHAR(255) NULL,
    `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_active` TIMESTAMP NULL,
    `server_id` VARCHAR(100) NULL,
    `is_active` BOOLEAN DEFAULT TRUE,
    `notes` TEXT NULL,
    
    UNIQUE KEY `unique_staff_license` (`fivem_license`, `server_id`),
    INDEX `idx_fivem_license` (`fivem_license`),
    INDEX `idx_steam_id` (`steam_id`),
    INDEX `idx_role` (`role`),
    INDEX `idx_server_id` (`server_id`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Individual permissions table - stores granular permissions per staff member
CREATE TABLE IF NOT EXISTS `onyxac_staff_permissions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `staff_id` INT NOT NULL,
    `permission` VARCHAR(100) NOT NULL,
    `granted` BOOLEAN DEFAULT TRUE,
    `granted_by` VARCHAR(255) NULL,
    `granted_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `reason` TEXT NULL,
    
    FOREIGN KEY (`staff_id`) REFERENCES `onyxac_staff`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `unique_staff_permission` (`staff_id`, `permission`),
    INDEX `idx_staff_id` (`staff_id`),
    INDEX `idx_permission` (`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default blacklist entries
INSERT IGNORE INTO `onyxac_blacklist` (`type`, `value`, `description`) VALUES
('weapon', 'WEAPON_RAILGUN', 'Railgun - typically modded weapon'),
('weapon', 'WEAPON_MINIGUN', 'Minigun - restricted weapon'),
('explosion', '29', 'Orbital Cannon explosion type'),
('explosion', '30', 'Modded explosion type'),
('explosion', '31', 'Modded explosion type'),
('explosion', '32', 'Modded explosion type'),
('entity', 'VEHICLE_HYDRA', 'Military jet - restricted'),
('entity', 'VEHICLE_LAZER', 'Military jet - restricted'),
('particle', 'scr_xs_dr', 'Suspicious particle effect'),
('particle', 'scr_xs_props', 'Suspicious particle effect');

-- Insert default configuration
INSERT IGNORE INTO `onyxac_config` (`server_id`, `config_key`, `config_value`) VALUES
('default', 'detection_thresholds', '{"warning": 50, "kick": 100, "tempBan": 150, "permanentBan": 200}'),
('default', 'auto_actions', '{"enabled": true, "autoKick": true, "autoBan": true}'),
('default', 'logging_settings', '{"enableFileLogging": true, "enableDatabaseLogging": true, "logLevel": "info"}');

-- Create views for easier querying
CREATE OR REPLACE VIEW `onyxac_active_bans` AS
SELECT 
    b.*,
    CASE 
        WHEN b.expire_date IS NULL THEN 'Permanent'
        WHEN b.expire_date > NOW() THEN 'Active'
        ELSE 'Expired'
    END as ban_status
FROM `onyxac_bans` b
WHERE b.is_active = TRUE 
AND (b.expire_date IS NULL OR b.expire_date > NOW());

CREATE OR REPLACE VIEW `onyxac_detection_summary` AS
SELECT 
    player_identifier,
    player_name,
    detection_type,
    COUNT(*) as detection_count,
    SUM(score_added) as total_score_added,
    MAX(timestamp) as last_detection,
    server_id
FROM `onyxac_detections`
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY player_identifier, detection_type, server_id
ORDER BY total_score_added DESC;

-- Create stored procedures for common operations
DELIMITER //

CREATE PROCEDURE GetPlayerBanStatus(IN p_identifier VARCHAR(255))
BEGIN
    SELECT 
        id,
        reason,
        ban_date,
        expire_date,
        admin_name,
        CASE 
            WHEN expire_date IS NULL THEN 'Permanent'
            WHEN expire_date > NOW() THEN 'Active'
            ELSE 'Expired'
        END as status
    FROM onyxac_bans 
    WHERE player_identifier = p_identifier 
    AND is_active = TRUE 
    AND (expire_date IS NULL OR expire_date > NOW())
    ORDER BY ban_date DESC 
    LIMIT 1;
END //

CREATE PROCEDURE CleanupOldLogs(IN days_to_keep INT)
BEGIN
    DELETE FROM onyxac_logs 
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
    
    DELETE FROM onyxac_detections 
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL days_to_keep DAY);
    
    SELECT ROW_COUNT() as deleted_rows;
END //

DELIMITER ;

-- Create indexes for performance optimization
CREATE INDEX idx_bans_composite ON onyxac_bans (player_identifier, is_active, expire_date);
CREATE INDEX idx_detections_composite ON onyxac_detections (player_identifier, timestamp, detection_type);
CREATE INDEX idx_logs_composite ON onyxac_logs (timestamp, log_level, category);

-- Show table information
SELECT 
    TABLE_NAME as 'Table',
    TABLE_ROWS as 'Estimated Rows',
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as 'Size (MB)'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME LIKE 'onyxac_%'
ORDER BY TABLE_NAME;
