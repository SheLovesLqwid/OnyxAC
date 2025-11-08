# OnyxAC Installation Guide

This guide will walk you through the complete installation and setup process for OnyxAC.

## Prerequisites

Before installing OnyxAC, ensure you have:

- **FiveM Server**: Latest recommended version
- **Database Server**: MySQL 5.7+ or MariaDB 10.2+
- **Node.js**: Version 16.0+ (for ban sync service)
- **mysql-async**: FiveM resource for database connectivity

## Step 1: Download OnyxAC

### Option A: Git Clone (Recommended)
```bash
cd /path/to/your/fivem/resources/
git clone https://github.com/SheLovesLqwid/OnyxAC.git
```

### Option B: Manual Download
1. Download the latest release from GitHub
2. Extract the ZIP file to your resources folder
3. Rename the folder to `OnyxAC` if necessary

## Step 2: Database Setup

### Create Database
```sql
CREATE DATABASE onyxac CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'onyxac'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON onyxac.* TO 'onyxac'@'localhost';
FLUSH PRIVILEGES;
```

### Import Schema
```bash
mysql -u onyxac -p onyxac < sql/schema.sql
```

### Verify Installation
```sql
USE onyxac;
SHOW TABLES;
-- Should show 9 tables starting with 'onyxac_'
```

## Step 3: Configuration

### Basic Configuration
1. Copy the example configuration:
   ```bash
   cp config.json.example config.json
   ```

2. Edit `config.json` with your settings:
   ```json
   {
     "database": {
       "enabled": true,
       "connectionString": "mysql://onyxac:your_password@localhost/onyxac"
     },
     "discord": {
       "enabled": true,
       "webhookURL": "your_discord_webhook_url"
     }
   }
   ```

### Staff Permissions
Add your Steam ID to the staff list:
```json
{
  "permissions": {
    "staffIdentifiers": {
      "steam:YOUR_STEAM_HEX_ID": "superadmin"
    }
  }
}
```

**Finding Your Steam ID:**
1. Visit [steamid.io](https://steamid.io/)
2. Enter your Steam profile URL
3. Copy the "Steam64 (Dec)" value
4. Convert to hex format: `steam:CONVERTED_HEX_VALUE`

## Step 4: FiveM Server Setup

### server.cfg Configuration
Add these lines to your `server.cfg`:
```cfg
# Ensure required resources
ensure mysql-async
ensure OnyxAC

# Optional: OnyxAC convars
set onyxac_debug false
set onyxac_performance_mode true
set onyxac_log_level info
```

### Resource Order
Ensure OnyxAC starts after mysql-async:
```cfg
start mysql-async
start OnyxAC
# ... other resources
```

## Step 5: Central Ban Sync Service (Optional)

The central service enables cross-server ban synchronization.

### Installation
```bash
cd node/central_service/
npm install
```

### Configuration
```bash
cp .env.example .env
nano .env
```

Edit the `.env` file:
```env
PORT=3000
API_KEY=your-secure-api-key-here
HMAC_SECRET=your-hmac-secret-key-here
DB_TYPE=mysql
DB_HOST=localhost
DB_NAME=onyxac_central
DB_USER=onyxac
DB_PASSWORD=your-database-password
```

### Start Service
```bash
# Development
npm run dev

# Production
npm start

# Using PM2 (recommended for production)
npm install -g pm2
pm2 start index.js --name "onyxac-central"
pm2 save
pm2 startup
```

### Configure FiveM Servers
Update each server's `config.json`:
```json
{
  "banManager": {
    "enableBanSync": true,
    "banSyncURL": "http://your-server:3000/api",
    "banSyncAPIKey": "your-secure-api-key-here",
    "banSyncHMACSecret": "your-hmac-secret-key-here"
  }
}
```

## Step 6: Verification

### Check Resource Status
In your FiveM server console:
```
status
# OnyxAC should appear in the resource list
```

### Test Database Connection
```
restart OnyxAC
# Check for successful database connection messages
```

### Test Admin Commands
In-game, try:
```
/onyxadmin
# Should open the admin panel if you have permissions
```

### Verify Logging
Check for log files in:
- `logs/onyxac_YYYY-MM-DD.log` (if file logging enabled)
- Database `onyxac_logs` table
- Discord webhook (if configured)

## Step 7: Advanced Configuration

### Performance Tuning
For high-population servers:
```json
{
  "general": {
    "enablePerformanceMetrics": true,
    "maxPlayersToMonitor": 128
  },
  "detectors": {
    "antiTeleport": {
      "checkInterval": 2000
    }
  }
}
```

### Discord Integration
Set up Discord webhooks for notifications:
1. Create a webhook in your Discord server
2. Copy the webhook URL
3. Add to configuration:
   ```json
   {
     "discord": {
       "enabled": true,
       "webhookURL": "https://discord.com/api/webhooks/...",
       "enableMentions": true,
       "mentionRoleID": "your-staff-role-id"
     }
   }
   ```

### SSL/HTTPS Setup (Production)
For the central service:
```env
SSL_ENABLED=true
SSL_CERT_PATH=/path/to/cert.pem
SSL_KEY_PATH=/path/to/key.pem
```

## Troubleshooting

### Common Issues

**Resource won't start:**
- Check mysql-async is running first
- Verify database connection string
- Check server console for error messages

**Database connection failed:**
- Verify MySQL/MariaDB is running
- Check username/password in config
- Ensure database exists and user has permissions

**Admin commands not working:**
- Verify your Steam ID is in staffIdentifiers
- Check permission levels in config
- Restart the resource after config changes

**UI not opening:**
- Check browser console for JavaScript errors
- Verify NUI files are present in resources/ui/
- Try clearing FiveM cache

### Logs and Debugging

Enable debug mode for detailed logging:
```json
{
  "general": {
    "enableDebugMode": true
  },
  "logging": {
    "logLevel": "debug"
  }
}
```

Check log locations:
- FiveM server console
- `logs/onyxac_*.log` files
- Database `onyxac_logs` table
- Discord webhook messages

### Getting Help

If you encounter issues:
1. Check the [FAQ](faq.md)
2. Search existing [GitHub Issues](https://github.com/SheLovesLqwid/OnyxAC/issues)
3. Join our Discord community
4. Create a new issue with:
   - FiveM server version
   - OnyxAC version
   - Error messages/logs
   - Configuration (remove sensitive data)

## Next Steps

After successful installation:
1. Read the [Configuration Guide](configuration.md)
2. Review [Admin Commands](admin-commands.md)
3. Set up [Detection Rules](detection-configuration.md)
4. Configure [Permissions](permissions.md)
5. Review [Security Best Practices](security.md)
