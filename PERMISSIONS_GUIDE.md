# OnyxAC FiveM License Based Permission System

## Overview

OnyxAC now features a comprehensive FiveM license based permission system with hierarchical roles and individual permission management. This system allows you to manage staff permissions using FiveM licenses, ensuring secure and reliable permission assignment.

## Hierarchy Structure

The permission system includes the following roles in order of authority (highest to lowest):

### Management Tier
- **Developer** (Level 1000) - Full system access, all permissions
- **Ownership** (Level 900) - Server ownership level, nearly all permissions
- **Head of Management** (Level 800) - Top management role
- **Senior Management** (Level 750) - Senior management staff
- **Management** (Level 700) - Management staff
- **Junior Management** (Level 650) - Junior management staff
- **Trial Management** (Level 600) - Trial management staff

### Administration Tier
- **Senior Head Admin** (Level 550) - Senior administrative staff
- **Head Admin** (Level 500) - Head administrative staff
- **Admin** (Level 450) - Administrative staff
- **Junior Admin** (Level 400) - Junior administrative staff

### Moderation Tier
- **Head Moderator** (Level 350) - Head moderation staff
- **Senior Moderator** (Level 300) - Senior moderation staff
- **Moderator** (Level 250) - Standard moderation staff
- **Mod** (Level 200) - Basic moderation staff
- **Trial** (Level 100) - Trial staff members

## Available Permissions

### Core Permissions
- `kick` - Ability to kick players
- `ban` - Ability to ban players
- `unban` - Ability to unban players
- `tp` - Ability to teleport
- `bring` - Ability to bring players
- `freeze` - Ability to freeze players
- `spectate` - Ability to spectate players
- `revive` - Ability to revive players
- `heal` - Ability to heal players
- `announce` - Ability to make server announcements
- `checkscore` - Ability to check player anti cheat scores
- `clearinfractions` - Ability to clear player infractions

### Administrative Permissions
- `setpermissions` - Ability to set individual permissions
- `managestaff` - Ability to manage staff roles
- `serverconfig` - Ability to modify server configuration
- `database` - Ability to access database functions
- `logs` - Ability to access system logs

### UI Access Permissions
- `canAccessAdminUI` - Access to admin interface
- `canAccessACUI` - Access to anti cheat interface
- `canBypassDetections` - Bypass anti cheat detections

## Setup Instructions

### 1. Database Setup

Run the migration script to update your database:

```sql
-- Run the migration script
SOURCE sql/migration_fivem_permissions.sql;
```

### 2. Configure Staff Members

#### Method 1: Configuration File (config.json)
Add staff members to the `staffLicenses` section:

```json
{
  "permissions": {
    "staffLicenses": {
      "license:1234567890abcdef": "developer",
      "license:0987654321fedcba": "admin",
      "license:abcdef1234567890": "moderator"
    }
  }
}
```

#### Method 2: Database (Recommended)
Insert staff members directly into the database:

```sql
INSERT INTO onyxac_staff (fivem_license, name, role, server_id) VALUES
('license:1234567890abcdef', 'John Developer', 'developer', 'default'),
('license:0987654321fedcba', 'Jane Admin', 'admin', 'default');
```

### 3. Get FiveM Licenses

To get a player's FiveM license, use this command in-game:

```lua
-- In server console or as a developer
/lua print(GetPlayerIdentifiers(playerID)[1])
```

## Commands

### Staff Management Commands

#### `/setrole <playerID> <role>`
Sets a player's staff role.
- **Permission Required:** `managestaff`
- **Example:** `/setrole 1 admin`

#### `/removerole <playerID>`
Removes a player's staff role.
- **Permission Required:** `managestaff`
- **Example:** `/removerole 1`

#### `/setperm <playerID> <permission> <true/false>`
Sets an individual permission for a staff member.
- **Permission Required:** `setpermissions`
- **Example:** `/setperm 1 ban true`

#### `/checkperms [playerID]`
Checks permissions for yourself or another player.
- **Permission Required:** `managestaff`
- **Example:** `/checkperms 1`

#### `/listroles`
Lists all available roles and their levels.
- **Permission Required:** `managestaff`
- **Example:** `/listroles`

### Console Commands

All commands can be used from the server console without permission checks:

```
setrole 1 developer
removerole 1
setperm 1 ban false
checkperms 1
listroles
```

## Individual Permissions

The system supports individual permission overrides that take precedence over role based permissions. This allows you to:

- Grant specific permissions to lower level staff
- Revoke specific permissions from higher level staff
- Create custom permission sets for special cases

### Example Use Cases

1. **Grant ban permission to a moderator:**
   ```
   /setperm 1 ban true
   ```

2. **Revoke teleport permission from an admin:**
   ```
   /setperm 1 tp false
   ```

3. **Grant management permissions to a trusted admin:**
   ```
   /setperm 1 managestaff true
   ```

## Database Schema

### onyxac_staff Table
Stores staff member information and roles.

### onyxac_staff_permissions Table
Stores individual permission overrides for staff members.

## Configuration Options

### config.json Settings

```json
{
  "permissions": {
    "useFiveMLicenses": true,
    "allowIndividualPermissions": true,
    "defaultRole": "player"
  }
}
```

- `useFiveMLicenses` - Enable FiveM license based permissions
- `allowIndividualPermissions` - Allow individual permission overrides
- `defaultRole` - Default role for non-staff players

## Security Features

1. **FiveM License Validation** - Uses secure FiveM licenses for identification
2. **Hierarchical Permissions** - Higher level staff cannot be modified by lower level staff
3. **Database Integration** - Persistent storage with audit trails
4. **Individual Overrides** - Granular permission control
5. **Console Access** - Server owners can manage permissions via console

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Ensure the player has the required permission level
   - Check if individual permissions override role permissions

2. **License Not Found**
   - Verify the FiveM license is correct
   - Ensure the player is connected and has a valid license

3. **Database Errors**
   - Check database connection settings
   - Ensure migration script was run successfully

### Debug Commands

```lua
-- Check player's license
print(OnyxAC.Permissions.GetPlayerLicense(playerID))

-- Check player's role
print(OnyxAC.Permissions.GetPlayerRole(playerID))

-- Check specific permission
print(OnyxAC.Permissions.HasPermission(playerID, "ban"))
```

## Migration from Old System

If you're upgrading from an older permission system:

1. **Backup your database** before running the migration
2. **Run the migration script** to update the schema
3. **Update staff licenses** in the new table structure
4. **Test permissions** thoroughly before going live

## Support

For support with the permission system:

1. Check this documentation first
2. Review the migration script for database issues
3. Test commands in a development environment
4. Contact support with specific error messages and logs

---

**Note:** Always backup your database before making changes to the permission system. Test thoroughly in a development environment before deploying to production.
