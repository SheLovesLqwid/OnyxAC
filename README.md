# OnyxAC - Professional FiveM Anti Cheat & Admin Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue.svg)](https://fivem.net/)
[![Node.js](https://img.shields.io/badge/Node.js-16%2B-green.svg)](https://nodejs.org/)

**Made by TheOGDev - Founder/CEO of OGDev Studios LLC**

OnyxAC is a comprehensive, open source anti cheat and admin management system for FiveM servers. It combines advanced detection algorithms with a powerful admin toolkit, featuring modern web based interfaces, cross server ban synchronization, and extensive customization options.

## 🚀 Features

### Anti Cheat System
- **Advanced Detection Modules**: 13+ detection systems including teleport, noclip, godmode, weapon modifications, and more
- **Behavioral Scoring Engine**: Weighted infractions with auto decay and configurable thresholds
- **Real Time Monitoring**: Client side and server side detection with minimal performance impact
- **File Pattern Detection**: Scans for known cheat signatures and suspicious files
- **Entity/Explosion Control**: Whitelist/blacklist system for entities, particles, and explosions

### Admin Management
- **Modern Web Interface**: Responsive admin panel with dark theme and animations
- **Comprehensive Commands**: 15+ admin commands for player management
- **Permission System**: Role based access control with 16 permission levels
- **Real Time Player Management**: Live player list with instant actions
- **Session Tracking**: Monitor player connections and activity

### Cross Server Features
- **Ban Synchronization**: Central ban database with HMAC secured API
- **Multi Server Support**: Manage multiple servers from one dashboard
- **Evidence Storage**: Attach evidence and detailed reasons to bans
- **Audit Logging**: Complete audit trail of all admin actions

### Logging & Analytics
- **Multi Channel Logging**: File, database, and Discord webhook integration
- **Performance Metrics**: Built in performance monitoring and statistics
- **Detection Analytics**: Detailed reports on detection patterns and trends
- **Privacy Controls**: Configurable data hashing and retention policies

## 📋 Requirements

- **FiveM Server**: Latest recommended version
- **Database**: MySQL 5.7+ or MariaDB 10.2+
- **Node.js**: 16.0+ (for ban sync service)
- **Dependencies**: mysql-async resource

## 🛠️ Installation

### 1. Download and Setup
```bash
# Clone or download OnyxAC to your resources folder
cd resources/
git clone https://github.com/SheLovesLqwid/OnyxAC.git
# or download and extract the ZIP file
```

### 2. Database Setup
```sql
-- Import the database schema
mysql -u your_username -p your_database < sql/schema.sql
```

### 3. Configuration
```bash
# Copy and edit the configuration file
cp config.json.example config.json
# Edit config.json with your settings
```

### 4. FiveM Server Configuration
Add to your `server.cfg`:
```cfg
ensure mysql-async
ensure OnyxAC

# Optional: Set convars
set onyxac_debug false
set onyxac_performance_mode true
```

### 5. Central Ban Sync Service (Optional)
```bash
cd node/central_service/
npm install
cp .env.example .env
# Edit .env with your configuration
npm start
```

## ⚙️ Configuration

### Basic Configuration
Edit `config.json` to customize OnyxAC for your server:

```json
{
  "general": {
    "enableDebugMode": false,
    "enablePerformanceMetrics": true
  },
  "database": {
    "enabled": true,
    "connectionString": "mysql://user:password@localhost/onyxac"
  },
  "detectors": {
    "antiTeleport": {
      "enabled": true,
      "maxDistance": 500.0,
      "scoreWeight": 15
    }
  }
}
```

### Permission System
Configure staff permissions in the `permissions` section:

```json
{
  "permissions": {
    "roles": {
      "superadmin": {
        "level": 100,
        "commands": ["*"],
        "canAccessAdminUI": true,
        "canBypassDetections": true
      }
    },
    "staffIdentifiers": {
      "steam:110000100000000": "superadmin"
    }
  }
}
```

### Detection Modules
Each detector can be individually configured:

- **antiTeleport**: Detects suspicious teleportation
- **antiNoclip**: Prevents noclip/freecam abuse  
- **antiGodmode**: Detects invincibility cheats
- **antiWeaponModifier**: Catches weapon modifications
- **antiSuperJump**: Prevents super jump exploits
- **antiVehicleModifier**: Detects vehicle modifications
- **entityWhitelistBlacklist**: Controls spawnable entities
- **filePatternDetection**: Scans for cheat files

## 🎮 Usage

### Admin Commands
Access admin functions via chat commands or the web interface:

#### Player Management
- `/onyxadmin` - Open admin panel (F6)
- `/acban <playerID> <duration> <reason>` - Ban player
- `/acunban <banID>` - Remove ban
- `/kick <playerID> <reason>` - Kick player
- `/warn <playerID> <reason>` - Warn player

#### Utility Commands
- `/tp <playerID>` - Teleport to player
- `/bring <playerID>` - Bring player to you
- `/freeze <playerID>` - Freeze/unfreeze player
- `/spectate <playerID>` - Spectate player
- `/heal <playerID>` - Heal player
- `/revive <playerID>` - Revive player

#### Anti-Cheat Management
- `/onyxac` - Open anti-cheat panel (F7)
- `/checkscore <playerID>` - Check player's AC score
- `/clearinfractions <playerID>` - Reset player's score
- `/onxreloadconfig` - Reload configuration

### Web Interface
The modern web interface provides:
- **Player Management**: Real-time player list with instant actions
- **Anti-Cheat Control**: Live detection monitoring and configuration
- **Ban Management**: Search, filter, and manage bans
- **Statistics Dashboard**: Server performance and detection analytics

### Keybinds
- **F6**: Open Admin Menu (requires permission)
- **F7**: Open Anti-Cheat Menu (requires permission)

## 🔧 API Documentation

### Ban Sync Service Endpoints

#### POST /api/ban
Create a new ban record
```json
{
  "playerIdentifier": "steam:110000100000000",
  "playerName": "PlayerName",
  "reason": "Cheating",
  "expireDate": "2024-12-31T23:59:59Z",
  "serverId": "MyServer"
}
```

#### POST /api/unban
Remove a ban
```json
{
  "banId": "ban-uuid",
  "serverId": "MyServer",
  "reason": "Appeal accepted"
}
```

#### POST /api/check
Check if player is banned
```json
{
  "playerIdentifier": "steam:110000100000000"
}
```

## 🧪 Testing

Run the test suite:
```bash
# Server-side tests
cd tests/
lua detection_tests.lua

# Central service tests
cd node/central_service/
npm test
```

## 📊 Performance

OnyxAC is designed for optimal performance:
- **Low Resource Usage**: < 0.01ms average execution time
- **Efficient Detection**: Smart caching and rate limiting
- **Scalable Architecture**: Supports 100+ concurrent players
- **Database Optimization**: Indexed queries and connection pooling

## 🔒 Security Features

- **HMAC Authentication**: Secure API communication
- **Rate Limiting**: Protection against abuse
- **Data Encryption**: Sensitive data hashing
- **Audit Logging**: Complete action tracking
- **Permission Validation**: Multi-layer access control

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/SheLovesLqwid/OnyxAC/issues)
- **Discord**: Join our community server
- **Documentation**: Check our [Wiki](https://github.com/SheLovesLqwid/OnyxAC/wiki)

## 🙏 Acknowledgments

- **TheOGDev** - Creator and lead developer
- **OGDev Studios LLC** - Development team
- **FiveM Community** - Testing and feedback
- **Contributors** - All community contributors

## 📈 Roadmap

- [ ] Machine learning detection algorithms
- [ ] Mobile admin app
- [ ] Advanced analytics dashboard
- [ ] Plugin system for custom detectors
- [ ] Multi-language support

---

**Made with ❤️ by TheOGDev - OGDev Studios LLC**

*OnyxAC is open-source software. Feel free to use, modify, and redistribute. Attribution is appreciated but not required.*
