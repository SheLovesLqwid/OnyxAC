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

fx_version 'cerulean'
game 'gta5'

name 'OnyxAC'
description 'Professional Anti Cheat and Admin Toolkit for FiveM'
author 'TheOGDev - OGDev Studios LLC'
version '1.0.0'
url 'https://github.com/SheLovesLqwid'

server_scripts {
    'server/main.lua',
    'server/modules/config_manager.lua',
    'server/modules/database.lua',
    'server/modules/permissions.lua',
    'server/modules/logger.lua',
    'server/modules/ban_manager.lua',
    'server/modules/scoring_engine.lua',
    'server/modules/discord_webhook.lua',
    'server/modules/admin_commands.lua',
    'server/modules/permission_commands.lua',
    'server/modules/detectors/anti_teleport.lua',
    'server/modules/detectors/anti_noclip.lua',
    'server/modules/detectors/anti_invisible.lua',
    'server/modules/detectors/anti_godmode.lua',
    'server/modules/detectors/anti_weapon_modifier.lua',
    'server/modules/detectors/anti_super_jump.lua',
    'server/modules/detectors/anti_freecam.lua',
    'server/modules/detectors/anti_spectate.lua',
    'server/modules/detectors/anti_vehicle_modifier.lua',
    'server/modules/detectors/anti_duplicate_connection.lua',
    'server/modules/detectors/anti_explosion.lua',
    'server/modules/detectors/entity_whitelist_blacklist.lua',
    'server/modules/detectors/file_pattern_detection.lua',
    'server/modules/detectors/connection_requirements.lua'
}

client_scripts {
    'client/main.lua',
    'client/modules/ui_manager.lua',
    'client/modules/detection_client.lua',
    'client/modules/admin_client.lua'
}

ui_page 'resources/ui/index.html'

files {
    'resources/ui/index.html',
    'resources/ui/admin/admin.html',
    'resources/ui/admin/admin.css',
    'resources/ui/admin/admin.js',
    'resources/ui/anticheat/anticheat.html',
    'resources/ui/anticheat/anticheat.css',
    'resources/ui/anticheat/anticheat.js',
    'resources/ui/shared/shared.css',
    'resources/ui/shared/shared.js',
    'config.json'
}

dependencies {
    'mysql-async'
}

lua54 'yes'
