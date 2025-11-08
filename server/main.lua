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

OnyxAC = {}
OnyxAC.Players = {}
OnyxAC.Config = {}
OnyxAC.Detectors = {}
OnyxAC.BanCache = {}
OnyxAC.ScoreCache = {}

local function InitializeOnyxAC()
    print("^2[OnyxAC]^7 Initializing OnyxAC Anti-Cheat System...")
    
    if not OnyxAC.ConfigManager then
        print("^1[OnyxAC]^7 Error: ConfigManager not loaded!")
        return
    end
    
    OnyxAC.Config = OnyxAC.ConfigManager.LoadConfig()
    
    if not OnyxAC.Config then
        print("^1[OnyxAC]^7 Error: Failed to load configuration!")
        return
    end
    
    if OnyxAC.Config.database.enabled then
        OnyxAC.Database.Initialize()
    end
    
    OnyxAC.Logger.Initialize()
    OnyxAC.DiscordWebhook.Initialize()
    OnyxAC.BanManager.Initialize()
    OnyxAC.ScoringEngine.Initialize()
    OnyxAC.Permissions.Initialize()
    OnyxAC.AdminCommands.Initialize()
    OnyxAC.PermissionCommands.Initialize()
    
    for detectorName, detectorConfig in pairs(OnyxAC.Config.detectors) do
        if detectorConfig.enabled then
            local detectorModule = OnyxAC.Detectors[detectorName]
            if detectorModule and detectorModule.Initialize then
                detectorModule.Initialize()
                print("^2[OnyxAC]^7 Detector initialized: " .. detectorName)
            end
        end
    end
    
    print("^2[OnyxAC]^7 Successfully initialized!")
    
    OnyxAC.Logger.Log("info", "OnyxAC initialized successfully", {
        version = OnyxAC.Config.general.version,
        detectors_enabled = OnyxAC.GetEnabledDetectorsCount()
    })
end

function OnyxAC.GetEnabledDetectorsCount()
    local count = 0
    for _, config in pairs(OnyxAC.Config.detectors) do
        if config.enabled then
            count = count + 1
        end
    end
    return count
end

function OnyxAC.GetPlayerData(playerId)
    return OnyxAC.Players[playerId]
end

function OnyxAC.SetPlayerData(playerId, data)
    if not OnyxAC.Players[playerId] then
        OnyxAC.Players[playerId] = {}
    end
    
    for key, value in pairs(data) do
        OnyxAC.Players[playerId][key] = value
    end
end

function OnyxAC.RemovePlayerData(playerId)
    OnyxAC.Players[playerId] = nil
    OnyxAC.ScoreCache[playerId] = nil
end

function OnyxAC.IsPlayerExempt(playerId)
    local playerData = OnyxAC.GetPlayerData(playerId)
    if not playerData then return false end
    
    local role = OnyxAC.Permissions.GetPlayerRole(playerId)
    local roleConfig = OnyxAC.Config.permissions.roles[role]
    
    return roleConfig and roleConfig.canBypassDetections
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local playerId = source
    local identifiers = GetPlayerIdentifiers(playerId)
    
    deferrals.defer()
    
    Wait(0)
    deferrals.update("OnyxAC: Checking player credentials...")
    
    local steamId = nil
    local discordId = nil
    local license = nil
    
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "steam:") then
            steamId = identifier
        elseif string.find(identifier, "discord:") then
            discordId = identifier
        elseif string.find(identifier, "license:") then
            license = identifier
        end
    end
    
    if OnyxAC.Config.connectionRequirements.requireSteam and not steamId then
        deferrals.done("OnyxAC: Steam is required to join this server.")
        return
    end
    
    if OnyxAC.Config.connectionRequirements.requireDiscord and not discordId then
        deferrals.done("OnyxAC: Discord is required to join this server.")
        return
    end
    
    if OnyxAC.Config.connectionRequirements.requireAlphanumericName then
        local nameValid = true
        local nameLength = string.len(name)
        
        if nameLength < OnyxAC.Config.connectionRequirements.minNameLength or 
           nameLength > OnyxAC.Config.connectionRequirements.maxNameLength then
            nameValid = false
        end
        
        if nameValid then
            for bannedPattern in pairs(OnyxAC.Config.connectionRequirements.bannedNamePatterns) do
                if string.find(string.lower(name), string.lower(bannedPattern)) then
                    nameValid = false
                    break
                end
            end
        end
        
        if not nameValid then
            deferrals.done("OnyxAC: Invalid player name. Please use an alphanumeric name between " .. 
                          OnyxAC.Config.connectionRequirements.minNameLength .. " and " .. 
                          OnyxAC.Config.connectionRequirements.maxNameLength .. " characters.")
            return
        end
    end
    
    deferrals.update("OnyxAC: Checking ban status...")
    
    local banData = OnyxAC.BanManager.CheckPlayerBan(license or steamId)
    if banData then
        local banMessage = string.format("You are banned from this server.\nReason: %s\nExpires: %s\nBan ID: %s", 
                                        banData.reason, 
                                        banData.expires == 0 and "Never" or os.date("%Y-%m-%d %H:%M:%S", banData.expires),
                                        banData.id)
        deferrals.done(banMessage)
        return
    end
    
    deferrals.update("OnyxAC: Finalizing connection...")
    
    OnyxAC.SetPlayerData(playerId, {
        name = name,
        identifiers = identifiers,
        steamId = steamId,
        discordId = discordId,
        license = license,
        joinTime = os.time(),
        lastPosition = vector3(0, 0, 0),
        score = 0
    })
    
    deferrals.done()
    
    OnyxAC.Logger.Log("info", "Player connected", {
        playerId = playerId,
        name = name,
        steamId = steamId,
        discordId = discordId
    })
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local playerData = OnyxAC.GetPlayerData(playerId)
    
    if playerData then
        OnyxAC.Logger.Log("info", "Player disconnected", {
            playerId = playerId,
            name = playerData.name,
            reason = reason,
            sessionTime = os.time() - playerData.joinTime
        })
        
        OnyxAC.RemovePlayerData(playerId)
    end
end)

RegisterNetEvent('onyxac:client:detection')
AddEventHandler('onyxac:client:detection', function(detectionType, data)
    local playerId = source
    
    if OnyxAC.IsPlayerExempt(playerId) then
        return
    end
    
    local playerData = OnyxAC.GetPlayerData(playerId)
    if not playerData then return end
    
    local detectorConfig = OnyxAC.Config.detectors[detectionType]
    if not detectorConfig or not detectorConfig.enabled then
        return
    end
    
    OnyxAC.ScoringEngine.AddInfraction(playerId, detectionType, detectorConfig.scoreWeight, data)
    
    OnyxAC.Logger.Log("detection", "Client detection triggered", {
        playerId = playerId,
        playerName = playerData.name,
        detectionType = detectionType,
        data = data,
        score = OnyxAC.ScoringEngine.GetPlayerScore(playerId)
    })
end)

RegisterNetEvent('onyxac:admin:requestPlayerList')
AddEventHandler('onyxac:admin:requestPlayerList', function()
    local playerId = source
    
    if not OnyxAC.Permissions.HasPermission(playerId, "canAccessAdminUI") then
        return
    end
    
    local playerList = {}
    
    for id, data in pairs(OnyxAC.Players) do
        table.insert(playerList, {
            id = id,
            name = data.name,
            ping = GetPlayerPing(id),
            score = OnyxAC.ScoringEngine.GetPlayerScore(id),
            identifiers = data.identifiers
        })
    end
    
    TriggerClientEvent('onyxac:admin:receivePlayerList', playerId, playerList)
end)

RegisterNetEvent('onyxac:admin:requestACData')
AddEventHandler('onyxac:admin:requestACData', function()
    local playerId = source
    
    if not OnyxAC.Permissions.HasPermission(playerId, "canAccessACUI") then
        return
    end
    
    local acData = {
        detectors = {},
        recentDetections = OnyxAC.Logger.GetRecentDetections(50),
        serverStats = {
            playersOnline = #GetPlayers(),
            detectorsEnabled = OnyxAC.GetEnabledDetectorsCount(),
            totalDetections = OnyxAC.Logger.GetTotalDetections(),
            activeBans = OnyxAC.BanManager.GetActiveBansCount()
        }
    }
    
    for detectorName, config in pairs(OnyxAC.Config.detectors) do
        acData.detectors[detectorName] = {
            enabled = config.enabled,
            scoreWeight = config.scoreWeight
        }
    end
    
    TriggerClientEvent('onyxac:admin:receiveACData', playerId, acData)
end)

Citizen.CreateThread(function()
    Wait(1000)
    InitializeOnyxAC()
end)

Citizen.CreateThread(function()
    while true do
        if OnyxAC.Config and OnyxAC.Config.scoringEngine.autoDecayEnabled then
            OnyxAC.ScoringEngine.DecayAllScores()
        end
        
        Wait(OnyxAC.Config and OnyxAC.Config.scoringEngine.decayInterval or 300000)
    end
end)
