/*
    made by TheOGDev Founder/CEO of OGDev Studios LLC
    OnyxAC - Database Migration Script for FiveM License-Based Permissions
    
    This migration script updates existing OnyxAC installations to support
    the new FiveM license-based permission system with hierarchical roles
    and individual permission management.
    
    Run this script AFTER backing up your existing database!
*/

-- Backup existing staff table (optional but recommended)
CREATE TABLE IF NOT EXISTS `onyxac_staff_backup` AS SELECT * FROM `onyxac_staff`;

-- Drop the old staff table structure
DROP TABLE IF EXISTS `onyxac_staff`;

-- Create new staff table with FiveM license support
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

-- Create individual permissions table
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

-- Migrate existing staff data (if backup table exists)
-- Note: This requires manual mapping of old identifiers to FiveM licenses
-- You'll need to update the license values manually for your specific staff members

-- Example migration (uncomment and modify as needed):
/*
INSERT INTO `onyxac_staff` (`fivem_license`, `steam_id`, `name`, `role`, `added_by`, `server_id`, `is_active`)
SELECT 
    CASE 
        WHEN identifier LIKE 'steam:%' THEN CONCAT('license:', SUBSTRING(identifier, 7))  -- Convert steam to license format
        ELSE identifier  -- Keep as is if already license format
    END as fivem_license,
    CASE 
        WHEN identifier LIKE 'steam:%' THEN identifier
        ELSE NULL
    END as steam_id,
    name,
    CASE 
        WHEN role = 'superadmin' THEN 'developer'
        WHEN role = 'admin' THEN 'admin'
        WHEN role = 'moderator' THEN 'moderator'
        WHEN role = 'auditor' THEN 'trial_mgmt'
        WHEN role = 'support' THEN 'trial'
        ELSE 'trial'
    END as role,
    added_by,
    server_id,
    is_active
FROM `onyxac_staff_backup`
WHERE is_active = 1;
*/

-- Insert example staff members (replace with your actual FiveM licenses)
-- These are just examples - replace with your actual staff licenses
INSERT IGNORE INTO `onyxac_staff` (`fivem_license`, `name`, `role`, `server_id`, `notes`) VALUES
('license:example1234567890abcdef', 'Example Developer', 'developer', 'default', 'Example developer account - replace with actual license'),
('license:example0987654321fedcba', 'Example Owner', 'ownership', 'default', 'Example owner account - replace with actual license');

-- Create stored procedures for permission management
DELIMITER //

-- Procedure to get staff member by FiveM license
CREATE PROCEDURE GetStaffByLicense(IN p_license VARCHAR(255))
BEGIN
    SELECT 
        s.*,
        GROUP_CONCAT(CONCAT(sp.permission, ':', sp.granted) SEPARATOR ',') as individual_permissions
    FROM onyxac_staff s
    LEFT JOIN onyxac_staff_permissions sp ON s.id = sp.staff_id
    WHERE s.fivem_license = p_license AND s.is_active = 1
    GROUP BY s.id;
END //

-- Procedure to set individual permission
CREATE PROCEDURE SetIndividualPermission(
    IN p_license VARCHAR(255),
    IN p_permission VARCHAR(100),
    IN p_granted BOOLEAN,
    IN p_granted_by VARCHAR(255)
)
BEGIN
    DECLARE staff_id_var INT;
    
    -- Get staff ID
    SELECT id INTO staff_id_var 
    FROM onyxac_staff 
    WHERE fivem_license = p_license AND is_active = 1 
    LIMIT 1;
    
    IF staff_id_var IS NOT NULL THEN
        -- Insert or update permission
        INSERT INTO onyxac_staff_permissions (staff_id, permission, granted, granted_by)
        VALUES (staff_id_var, p_permission, p_granted, p_granted_by)
        ON DUPLICATE KEY UPDATE
        granted = VALUES(granted),
        granted_by = VALUES(granted_by),
        granted_date = CURRENT_TIMESTAMP;
        
        SELECT 'SUCCESS' as result, 'Permission updated successfully' as message;
    ELSE
        SELECT 'ERROR' as result, 'Staff member not found' as message;
    END IF;
END //

-- Procedure to get all active staff with their permissions
CREATE PROCEDURE GetAllActiveStaff()
BEGIN
    SELECT 
        s.id,
        s.fivem_license,
        s.steam_id,
        s.discord_id,
        s.name,
        s.role,
        s.added_date,
        s.last_active,
        s.notes,
        GROUP_CONCAT(
            CASE WHEN sp.granted = 1 
            THEN CONCAT(sp.permission, ':granted') 
            ELSE CONCAT(sp.permission, ':denied') 
            END SEPARATOR ','
        ) as individual_permissions
    FROM onyxac_staff s
    LEFT JOIN onyxac_staff_permissions sp ON s.id = sp.staff_id
    WHERE s.is_active = 1
    GROUP BY s.id
    ORDER BY 
        CASE s.role
            WHEN 'developer' THEN 1000
            WHEN 'ownership' THEN 900
            WHEN 'head_of_mgmt' THEN 800
            WHEN 'sr_mgmt' THEN 750
            WHEN 'mgmt' THEN 700
            WHEN 'jr_mgmt' THEN 650
            WHEN 'trial_mgmt' THEN 600
            WHEN 'sr_head_admin' THEN 550
            WHEN 'head_admin' THEN 500
            WHEN 'admin' THEN 450
            WHEN 'jr_admin' THEN 400
            WHEN 'head_mod' THEN 350
            WHEN 'sr_mod' THEN 300
            WHEN 'moderator' THEN 250
            WHEN 'mod' THEN 200
            WHEN 'trial' THEN 100
            ELSE 0
        END DESC;
END //

DELIMITER ;

-- Create views for easier querying
CREATE OR REPLACE VIEW `onyxac_staff_with_permissions` AS
SELECT 
    s.id,
    s.fivem_license,
    s.steam_id,
    s.discord_id,
    s.name,
    s.role,
    CASE s.role
        WHEN 'developer' THEN 1000
        WHEN 'ownership' THEN 900
        WHEN 'head_of_mgmt' THEN 800
        WHEN 'sr_mgmt' THEN 750
        WHEN 'mgmt' THEN 700
        WHEN 'jr_mgmt' THEN 650
        WHEN 'trial_mgmt' THEN 600
        WHEN 'sr_head_admin' THEN 550
        WHEN 'head_admin' THEN 500
        WHEN 'admin' THEN 450
        WHEN 'jr_admin' THEN 400
        WHEN 'head_mod' THEN 350
        WHEN 'sr_mod' THEN 300
        WHEN 'moderator' THEN 250
        WHEN 'mod' THEN 200
        WHEN 'trial' THEN 100
        ELSE 0
    END as role_level,
    s.added_date,
    s.last_active,
    s.is_active,
    s.notes,
    GROUP_CONCAT(
        CONCAT(sp.permission, ':', sp.granted) SEPARATOR ','
    ) as individual_permissions
FROM onyxac_staff s
LEFT JOIN onyxac_staff_permissions sp ON s.id = sp.staff_id
WHERE s.is_active = 1
GROUP BY s.id;

-- Update configuration table with new permission settings
INSERT IGNORE INTO `onyxac_config` (`server_id`, `config_key`, `config_value`) VALUES
('default', 'fivem_permissions', '{"enabled": true, "allowIndividualPermissions": true, "useFiveMLicenses": true}'),
('default', 'permission_hierarchy', '{"developer": 1000, "ownership": 900, "head_of_mgmt": 800, "sr_mgmt": 750, "mgmt": 700, "jr_mgmt": 650, "trial_mgmt": 600, "sr_head_admin": 550, "head_admin": 500, "admin": 450, "jr_admin": 400, "head_mod": 350, "sr_mod": 300, "moderator": 250, "mod": 200, "trial": 100}');

-- Show migration results
SELECT 
    'Migration completed successfully!' as status,
    COUNT(*) as staff_members_migrated
FROM onyxac_staff 
WHERE is_active = 1;

-- Show available permissions that can be individually assigned
SELECT 'Available individual permissions:' as info;
SELECT 
    'kick, ban, unban, tp, bring, freeze, spectate, revive, heal, announce, checkscore, clearinfractions, setpermissions, managestaff, serverconfig, database, logs' as permissions;

-- Instructions for manual setup
SELECT 'IMPORTANT: Update the FiveM licenses in the onyxac_staff table with your actual staff member licenses!' as instruction;
SELECT 'Use the following command to update a staff member license:' as instruction;
SELECT 'UPDATE onyxac_staff SET fivem_license = "license:YOUR_ACTUAL_LICENSE_HERE" WHERE name = "Staff Member Name";' as example;
