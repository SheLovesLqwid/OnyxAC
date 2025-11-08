# OnyxAC Admin Commands Reference

This document provides a comprehensive reference for all OnyxAC admin commands, their usage, and required permissions.

## Command Categories

- [UI Access Commands](#ui-access-commands)
- [Player Management](#player-management)
- [Moderation Commands](#moderation-commands)
- [Utility Commands](#utility-commands)
- [Anti Cheat Commands](#anti-cheat-commands)
- [System Commands](#system-commands)

## UI Access Commands

### `/onyxadmin`
Opens the OnyxAC Admin Panel interface.

**Usage:** `/onyxadmin`  
**Permission:** `canAccessAdminUI`  
**Keybind:** F6 (default)  
**Description:** Opens the modern web-based admin interface for player management, quick actions, and server administration.

### `/onyxac`
Opens the OnyxAC Anti Cheat Control Panel.

**Usage:** `/onyxac`  
**Permission:** `canAccessACUI`  
**Keybind:** F7 (default)  
**Description:** Opens the anti cheat management interface for monitoring detections, configuring modules, and viewing statistics.

## Player Management

### `/acban`
Bans a player using the OnyxAC ban system.

**Usage:** `/acban <playerID> <durationMinutes> <reason>`  
**Permission:** `acban` command permission  
**Examples:**
```
/acban 1 1440 Cheating with aimbot
/acban 5 0 Permanent ban for repeated violations
/acban 12 60 Temporary ban for trolling
```

**Parameters:**
- `playerID`: Target player's server ID
- `durationMinutes`: Ban duration in minutes (0 = permanent)
- `reason`: Reason for the ban (supports spaces)

**Features:**
- Automatic ban sync across servers (if enabled)
- Discord webhook notification
- Evidence attachment support
- Database logging

### `/acunban`
Removes a ban by ban ID.

**Usage:** `/acunban <banID> [reason]`  
**Permission:** `acunban` command permission  
**Examples:**
```
/acunban 12345 Appeal accepted
/acunban 67890 False positive
```

**Parameters:**
- `banID`: The unique ban identifier
- `reason`: Optional reason for removal

### `/kick`
Kicks a player from the server.

**Usage:** `/kick <playerID> <reason>`  
**Permission:** `kick` command permission  
**Examples:**
```
/kick 3 Please read the rules
/kick 8 Inappropriate behavior
```

**Parameters:**
- `playerID`: Target player's server ID
- `reason`: Reason for the kick

### `/warn`
Sends a warning message to a player.

**Usage:** `/warn <playerID> <reason>`  
**Permission:** `warn` command permission  
**Examples:**
```
/warn 2 Stop spamming chat
/warn 7 Follow traffic rules
```

**Parameters:**
- `playerID`: Target player's server ID
- `reason`: Warning message

**Features:**
- In-game notification to player
- Discord webhook logging
- Database record keeping

## Utility Commands

### `/tp`
Teleports you to another player.

**Usage:** `/tp <playerID>`  
**Permission:** `tp` command permission  
**Cooldown:** 1 second (configurable)  
**Examples:**
```
/tp 5
/tp 12
```

**Parameters:**
- `playerID`: Target player's server ID

### `/bring`
Teleports another player to your location.

**Usage:** `/bring <playerID>`  
**Permission:** `bring` command permission  
**Cooldown:** 1 second (configurable)  
**Examples:**
```
/bring 3
/bring 9
```

**Parameters:**
- `playerID`: Target player's server ID

### `/freeze`
Toggles freeze status for a player.

**Usage:** `/freeze <playerID>`  
**Permission:** `freeze` command permission  
**Examples:**
```
/freeze 4
/freeze 11
```

**Parameters:**
- `playerID`: Target player's server ID

**Effects:**
- Prevents player movement
- Enables invincibility while frozen
- Shows notification to target player

### `/spectate`
Enters spectate mode for a specific player.

**Usage:** `/spectate <playerID>`  
**Permission:** `spectate` command permission  
**Examples:**
```
/spectate 6
/spectate 15
```

**Parameters:**
- `playerID`: Target player's server ID

**Features:**
- Invisible spectating
- Use same command to stop spectating
- Automatic cleanup on target disconnect

### `/heal`
Restores a player's health and armor.

**Usage:** `/heal <playerID>`  
**Permission:** `heal` command permission  
**Cooldown:** 2 seconds (configurable)  
**Examples:**
```
/heal 1
/heal 8
```

**Parameters:**
- `playerID`: Target player's server ID

### `/revive`
Revives a dead player.

**Usage:** `/revive <playerID>`  
**Permission:** `revive` command permission  
**Cooldown:** 3 seconds (configurable)  
**Examples:**
```
/revive 2
/revive 10
```

**Parameters:**
- `playerID`: Target player's server ID

### `/god`
Toggles godmode for yourself or another player.

**Usage:** `/god [playerID]`  
**Permission:** `god` command permission  
**Examples:**
```
/god          # Toggle for yourself
/god 5        # Toggle for player 5
```

**Parameters:**
- `playerID`: Optional target player's server ID

**Note:** Only use for staff members, not regular players.

### `/slap`
Applies knockback and minor damage to a player.

**Usage:** `/slap <playerID>`  
**Permission:** `slap` command permission  
**Cooldown:** 5 seconds (configurable)  
**Examples:**
```
/slap 7
/slap 13
```

**Parameters:**
- `playerID`: Target player's server ID

**Effects:**
- 10 damage
- Knockback effect
- Fun utility command

## Anti Cheat Commands

### `/checkscore`
Displays a player's current anti cheat score.

**Usage:** `/checkscore <playerID>`  
**Permission:** `checkscore` command permission  
**Examples:**
```
/checkscore 4
/checkscore 9
```

**Parameters:**
- `playerID`: Target player's server ID

**Output:** Shows current score and threshold information.

### `/clearinfractions`
Resets a player's anti cheat score to zero.

**Usage:** `/clearinfractions <playerID>`  
**Permission:** `clearinfractions` command permission  
**Examples:**
```
/clearinfractions 6
/clearinfractions 14
```

**Parameters:**
- `playerID`: Target player's server ID

**Note:** Use carefully - this removes all accumulated infractions.

## System Commands

### `/announce`
Sends a server-wide announcement.

**Usage:** `/announce <message>`  
**Permission:** `announce` command permission  
**Examples:**
```
/announce Server restart in 10 minutes
/announce New update deployed - check the changelog
```

**Parameters:**
- `message`: Announcement text (supports spaces)

**Features:**
- Displays to all players
- Special formatting and colors
- Logged to database

### `/onxreloadconfig`
Reloads the OnyxAC configuration file.

**Usage:** `/onxreloadconfig`  
**Permission:** Superadmin only (`*` commands)  
**Examples:**
```
/onxreloadconfig
```

**Features:**
- Hot-reloads configuration
- Updates detector settings
- No server restart required
- Validates configuration before applying

## Permission Levels

Commands are restricted based on role permissions:

### Superadmin (Level 100)
- All commands (`*`)
- Can bypass all detections
- Can reload configuration

### Admin (Level 80)
- Most moderation commands
- Ban/unban capabilities
- Anti cheat management

### Moderator (Level 60)
- Basic moderation commands
- Player management
- Limited anti cheat access

### Auditor (Level 40)
- Read-only access
- Score checking
- Spectate capabilities

### Support (Level 20)
- Utility commands only
- Teleport and heal
- No moderation powers

## Command Cooldowns

Some commands have cooldowns to prevent abuse:

| Command | Default Cooldown |
|---------|------------------|
| `/tp` | 1 second |
| `/bring` | 1 second |
| `/heal` | 2 seconds |
| `/revive` | 3 seconds |
| `/slap` | 5 seconds |

Cooldowns can be configured in `config.json`:
```json
{
  "adminCommands": {
    "cooldowns": {
      "tp": 1000,
      "bring": 1000,
      "heal": 2000,
      "revive": 3000,
      "slap": 5000
    }
  }
}
```

## Usage Tips

### Best Practices
1. **Always provide clear reasons** for moderation actions
2. **Use appropriate ban durations** - not everything needs a permanent ban
3. **Document evidence** when possible
4. **Communicate with players** before taking action when appropriate
5. **Use the web interface** for complex operations

### Keyboard Shortcuts
- **F6**: Quick access to admin panel
- **F7**: Quick access to anti cheat panel
- **ESC**: Close any open OnyxAC interface

### Batch Operations
Use the web interface for:
- Managing multiple players
- Bulk ban operations
- Advanced filtering and search
- Detailed player information

### Integration with Discord
All admin actions can be logged to Discord:
```json
{
  "discord": {
    "enabled": true,
    "webhookURL": "your-webhook-url",
    "enableMentions": true
  }
}
```

## Error Messages

Common error messages and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| "You don't have permission" | Insufficient role level | Check staff configuration |
| "Invalid player ID" | Player not found | Verify player is online |
| "Command on cooldown" | Too frequent usage | Wait for cooldown to expire |
| "Cannot target this player" | Higher role level | Only target lower-level staff |

## Logging

All command usage is logged with:
- Timestamp
- Admin identifier
- Command executed
- Target player (if applicable)
- Parameters used
- Result/outcome

Logs are stored in:
- Database (`onyxac_admin_actions` table)
- Log files (if enabled)
- Discord webhooks (if configured)

## API Integration

Commands can also be executed via the web interface, which uses the same permission system and logging mechanisms. The web interface provides additional features like:
- Player search and filtering
- Batch operations
- Visual confirmation dialogs
- Real-time updates
