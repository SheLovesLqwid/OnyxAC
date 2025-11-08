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

OnyxAC.ScoringEngine = {}

function OnyxAC.ScoringEngine.Initialize()
    print("^2[OnyxAC]^7 Initializing scoring engine...")
    print("^2[OnyxAC]^7 Scoring engine initialized!")
end

function OnyxAC.ScoringEngine.GetPlayerScore(playerId)
    if not OnyxAC.ScoreCache[playerId] then
        OnyxAC.ScoreCache[playerId] = 0
    end
    return OnyxAC.ScoreCache[playerId]
end

function OnyxAC.ScoringEngine.SetPlayerScore(playerId, score)
    OnyxAC.ScoreCache[playerId] = math.max(0, score)
    
    local playerData = OnyxAC.GetPlayerData(playerId)
    if playerData and OnyxAC.Config.database.enabled then
        local playerIdentifier = playerData.steamId or playerData.license
        if playerIdentifier then
            OnyxAC.Database.UpdatePlayerScore(playerIdentifier, playerData.name, OnyxAC.ScoreCache[playerId])
        end
    end
end

function OnyxAC.ScoringEngine.AddInfraction(playerId, detectionType, scoreWeight, data)
    local currentScore = OnyxAC.ScoringEngine.GetPlayerScore(playerId)
    local newScore = currentScore + scoreWeight
    
    OnyxAC.ScoringEngine.SetPlayerScore(playerId, newScore)
    
    OnyxAC.Logger.LogDetection(playerId, detectionType, data, scoreWeight, newScore)
    
    if OnyxAC.Config.scoringEngine.autoBanEnabled then
        OnyxAC.ScoringEngine.CheckAutoAction(playerId, newScore)
    end
    
    return newScore
end

function OnyxAC.ScoringEngine.CheckAutoAction(playerId, score)
    local thresholds = OnyxAC.Config.scoringEngine.thresholds
    local playerData = OnyxAC.GetPlayerData(playerId)
    
    if not playerData then return end
    
    if score >= thresholds.permanentBan then
        OnyxAC.BanManager.AutoBanPlayer(playerId, "Automatic permanent ban - Anti-cheat score exceeded threshold", {
            score = score,
            threshold = thresholds.permanentBan
        })
        
    elseif score >= thresholds.tempBan then
        OnyxAC.BanManager.BanPlayer(playerId, nil, "Automatic temporary ban - Anti-cheat score exceeded threshold", 
            OnyxAC.Config.banManager.defaultBanDuration, {
            score = score,
            threshold = thresholds.tempBan
        })
        
    elseif score >= thresholds.kick then
        DropPlayer(playerId, string.format("Kicked by OnyxAC - Anti-cheat score too high (%d/%d)", 
            score, thresholds.kick))
        
        OnyxAC.Logger.LogKick(playerId, nil, string.format("Auto-kick - Score: %d/%d", score, thresholds.kick))
        
    elseif score >= thresholds.warning then
        TriggerClientEvent('onyxac:client:showWarning', playerId, 
            string.format("Warning: Your anti-cheat score is high (%d/%d). Continued violations may result in a ban.", 
            score, thresholds.warning))
        
        OnyxAC.Logger.LogWarning(playerId, nil, string.format("Auto-warning - Score: %d/%d", score, thresholds.warning))
    end
end

function OnyxAC.ScoringEngine.DecayPlayerScore(playerId)
    if not OnyxAC.Config.scoringEngine.autoDecayEnabled then return end
    
    local currentScore = OnyxAC.ScoringEngine.GetPlayerScore(playerId)
    if currentScore > 0 then
        local newScore = math.max(0, currentScore - OnyxAC.Config.scoringEngine.decayRate)
        OnyxAC.ScoringEngine.SetPlayerScore(playerId, newScore)
        
        if OnyxAC.Config.general.enableDebugMode and newScore ~= currentScore then
            print(string.format("^3[OnyxAC-DEBUG]^7 Score decay for player %d: %d -> %d", playerId, currentScore, newScore))
        end
    end
end

function OnyxAC.ScoringEngine.DecayAllScores()
    if not OnyxAC.Config.scoringEngine.autoDecayEnabled then return end
    
    local playersDecayed = 0
    
    for playerId, _ in pairs(OnyxAC.Players) do
        local currentScore = OnyxAC.ScoringEngine.GetPlayerScore(playerId)
        if currentScore > 0 then
            OnyxAC.ScoringEngine.DecayPlayerScore(playerId)
            playersDecayed = playersDecayed + 1
        end
    end
    
    if playersDecayed > 0 and OnyxAC.Config.general.enableDebugMode then
        print(string.format("^3[OnyxAC-DEBUG]^7 Score decay applied to %d players", playersDecayed))
    end
end

function OnyxAC.ScoringEngine.ClearPlayerScore(playerId)
    OnyxAC.ScoringEngine.SetPlayerScore(playerId, 0)
    
    local playerData = OnyxAC.GetPlayerData(playerId)
    if playerData then
        OnyxAC.Logger.Log("info", string.format("Score cleared for player %s", playerData.name), {
            playerId = playerId,
            playerName = playerData.name
        }, "adminActions")
    end
end

function OnyxAC.ScoringEngine.GetScoreBreakdown(playerId)
    local playerData = OnyxAC.GetPlayerData(playerId)
    if not playerData or not OnyxAC.Config.database.enabled then
        return {
            currentScore = OnyxAC.ScoringEngine.GetPlayerScore(playerId),
            totalInfractions = 0,
            recentDetections = {}
        }
    end
    
    local query = [[
        SELECT detection_type, COUNT(*) as count, SUM(score_added) as total_score, MAX(timestamp) as last_detection
        FROM onyxac_detections 
        WHERE player_identifier = ? 
        GROUP BY detection_type 
        ORDER BY total_score DESC
    ]]
    
    local playerIdentifier = playerData.steamId or playerData.license
    
    OnyxAC.Database.FetchQuery(query, {playerIdentifier}, function(result)
        local breakdown = {
            currentScore = OnyxAC.ScoringEngine.GetPlayerScore(playerId),
            totalInfractions = 0,
            detectionTypes = {},
            recentDetections = OnyxAC.Logger.GetRecentDetections(10)
        }
        
        for _, detection in ipairs(result) do
            breakdown.totalInfractions = breakdown.totalInfractions + detection.count
            table.insert(breakdown.detectionTypes, {
                type = detection.detection_type,
                count = detection.count,
                totalScore = detection.total_score,
                lastDetection = detection.last_detection
            })
        end
        
        TriggerClientEvent('onyxac:admin:receiveScoreBreakdown', playerId, breakdown)
    end)
end

function OnyxAC.ScoringEngine.GetServerScoreStats()
    local stats = {
        totalPlayers = 0,
        playersWithScore = 0,
        averageScore = 0,
        highestScore = 0,
        scoreDistribution = {
            low = 0,      -- 0-25
            medium = 0,   -- 26-75
            high = 0,     -- 76-150
            critical = 0  -- 151+
        }
    }
    
    local totalScore = 0
    
    for playerId, _ in pairs(OnyxAC.Players) do
        stats.totalPlayers = stats.totalPlayers + 1
        local score = OnyxAC.ScoringEngine.GetPlayerScore(playerId)
        
        if score > 0 then
            stats.playersWithScore = stats.playersWithScore + 1
            totalScore = totalScore + score
            
            if score > stats.highestScore then
                stats.highestScore = score
            end
            
            if score <= 25 then
                stats.scoreDistribution.low = stats.scoreDistribution.low + 1
            elseif score <= 75 then
                stats.scoreDistribution.medium = stats.scoreDistribution.medium + 1
            elseif score <= 150 then
                stats.scoreDistribution.high = stats.scoreDistribution.high + 1
            else
                stats.scoreDistribution.critical = stats.scoreDistribution.critical + 1
            end
        else
            stats.scoreDistribution.low = stats.scoreDistribution.low + 1
        end
    end
    
    if stats.playersWithScore > 0 then
        stats.averageScore = math.floor(totalScore / stats.playersWithScore)
    end
    
    return stats
end

RegisterNetEvent('onyxac:admin:requestScoreBreakdown')
AddEventHandler('onyxac:admin:requestScoreBreakdown', function(targetPlayerId)
    local playerId = source
    
    if not OnyxAC.Permissions.HasPermission(playerId, "canAccessAdminUI") then
        return
    end
    
    OnyxAC.ScoringEngine.GetScoreBreakdown(targetPlayerId)
end)
