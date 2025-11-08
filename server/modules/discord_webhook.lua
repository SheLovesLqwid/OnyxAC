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

OnyxAC.DiscordWebhook = {}

local webhookQueue = {}

function OnyxAC.DiscordWebhook.Initialize()
    if not OnyxAC.Config.discord.enabled then
        print("^3[OnyxAC]^7 Discord webhooks disabled in configuration")
        return
    end
    
    print("^2[OnyxAC]^7 Initializing Discord webhook system...")
    
    Citizen.CreateThread(function()
        while true do
            OnyxAC.DiscordWebhook.ProcessQueue()
            Wait(2000)
        end
    end)
    
    print("^2[OnyxAC]^7 Discord webhook system initialized!")
end

function OnyxAC.DiscordWebhook.SendLog(logEntry)
    if not OnyxAC.Config.discord.enabled then return end
    
    local embed = OnyxAC.DiscordWebhook.CreateEmbed(logEntry)
    if embed then
        table.insert(webhookQueue, embed)
    end
end

function OnyxAC.DiscordWebhook.CreateEmbed(logEntry)
    local color = OnyxAC.Config.discord.embedColors[logEntry.level] or OnyxAC.Config.discord.embedColors.info
    
    local embed = {
        title = string.format("OnyxAC - %s", string.upper(logEntry.level)),
        description = logEntry.message,
        color = color,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", logEntry.timestamp),
        footer = {
            text = string.format("OnyxAC v%s | %s", OnyxAC.Config.general.version, logEntry.serverId)
        },
        fields = {}
    }
    
    if logEntry.category then
        table.insert(embed.fields, {
            name = "Category",
            value = string.upper(logEntry.category),
            inline = true
        })
    end
    
    if logEntry.data then
        if logEntry.data.playerName then
            table.insert(embed.fields, {
                name = "Player",
                value = logEntry.data.playerName,
                inline = true
            })
        end
        
        if logEntry.data.adminName then
            table.insert(embed.fields, {
                name = "Admin",
                value = logEntry.data.adminName,
                inline = true
            })
        end
        
        if logEntry.data.detectionType then
            table.insert(embed.fields, {
                name = "Detection Type",
                value = logEntry.data.detectionType,
                inline = true
            })
        end
        
        if logEntry.data.score or logEntry.data.totalScore then
            local scoreText = ""
            if logEntry.data.scoreAdded and logEntry.data.totalScore then
                scoreText = string.format("+%d = %d", logEntry.data.scoreAdded, logEntry.data.totalScore)
            elseif logEntry.data.totalScore then
                scoreText = tostring(logEntry.data.totalScore)
            elseif logEntry.data.score then
                scoreText = tostring(logEntry.data.score)
            end
            
            if scoreText ~= "" then
                table.insert(embed.fields, {
                    name = "Score",
                    value = scoreText,
                    inline = true
                })
            end
        end
        
        if logEntry.data.reason then
            table.insert(embed.fields, {
                name = "Reason",
                value = logEntry.data.reason,
                inline = false
            })
        end
        
        if logEntry.data.duration then
            local durationText = logEntry.data.duration == 0 and "Permanent" or (logEntry.data.duration .. " minutes")
            table.insert(embed.fields, {
                name = "Duration",
                value = durationText,
                inline = true
            })
        end
        
        if logEntry.data.banId then
            table.insert(embed.fields, {
                name = "Ban ID",
                value = tostring(logEntry.data.banId),
                inline = true
            })
        end
    end
    
    return embed
end

function OnyxAC.DiscordWebhook.ProcessQueue()
    if #webhookQueue == 0 then return end
    
    local embeds = {}
    for i = 1, math.min(#webhookQueue, 10) do
        table.insert(embeds, table.remove(webhookQueue, 1))
    end
    
    local payload = {
        embeds = embeds
    }
    
    if OnyxAC.Config.discord.enableMentions and OnyxAC.Config.discord.mentionRoleID then
        payload.content = string.format("<@&%s>", OnyxAC.Config.discord.mentionRoleID)
    end
    
    OnyxAC.DiscordWebhook.SendWebhook(payload)
end

function OnyxAC.DiscordWebhook.SendWebhook(payload, retryCount)
    retryCount = retryCount or 0
    
    if retryCount >= OnyxAC.Config.discord.retryAttempts then
        print("^1[OnyxAC]^7 Failed to send Discord webhook after " .. retryCount .. " attempts")
        return
    end
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    PerformHttpRequest(OnyxAC.Config.discord.webhookURL, function(statusCode, response, responseHeaders)
        if statusCode == 200 or statusCode == 204 then
            if OnyxAC.Config.general.enableDebugMode then
                print("^2[OnyxAC]^7 Discord webhook sent successfully")
            end
        elseif statusCode == 429 then
            local retryAfter = 5
            if response then
                local success, data = pcall(json.decode, response)
                if success and data.retry_after then
                    retryAfter = math.ceil(data.retry_after / 1000)
                end
            end
            
            print("^3[OnyxAC]^7 Discord webhook rate limited, retrying in " .. retryAfter .. " seconds")
            
            Citizen.SetTimeout(retryAfter * 1000, function()
                OnyxAC.DiscordWebhook.SendWebhook(payload, retryCount + 1)
            end)
        else
            print("^1[OnyxAC]^7 Discord webhook failed with status: " .. statusCode)
            
            if retryCount < OnyxAC.Config.discord.retryAttempts then
                Citizen.SetTimeout(OnyxAC.Config.discord.retryDelay, function()
                    OnyxAC.DiscordWebhook.SendWebhook(payload, retryCount + 1)
                end)
            end
        end
    end, "POST", json.encode(payload), headers)
end

function OnyxAC.DiscordWebhook.SendDetection(playerId, detectionType, data, score)
    if not OnyxAC.Config.discord.enabled then return end
    
    local playerData = OnyxAC.GetPlayerData(playerId)
    if not playerData then return end
    
    local embed = {
        title = "🚨 Anti-Cheat Detection",
        description = string.format("**%s** detected for player **%s**", detectionType, playerData.name),
        color = OnyxAC.Config.discord.embedColors.detection,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {
            text = string.format("OnyxAC v%s", OnyxAC.Config.general.version)
        },
        fields = {
            {
                name = "Player",
                value = playerData.name,
                inline = true
            },
            {
                name = "Detection Type",
                value = detectionType,
                inline = true
            },
            {
                name = "Current Score",
                value = tostring(score),
                inline = true
            }
        }
    }
    
    if data then
        local dataStr = ""
        for key, value in pairs(data) do
            dataStr = dataStr .. string.format("**%s:** %s\n", key, tostring(value))
        end
        
        if dataStr ~= "" then
            table.insert(embed.fields, {
                name = "Detection Data",
                value = dataStr,
                inline = false
            })
        end
    end
    
    table.insert(webhookQueue, embed)
end

function OnyxAC.DiscordWebhook.SendBan(playerId, adminId, reason, duration, banId)
    if not OnyxAC.Config.discord.enabled then return end
    
    local playerData = OnyxAC.GetPlayerData(playerId)
    local adminData = adminId and OnyxAC.GetPlayerData(adminId) or nil
    
    local embed = {
        title = "🔨 Player Banned",
        description = string.format("**%s** has been banned from the server", playerData and playerData.name or "Unknown Player"),
        color = OnyxAC.Config.discord.embedColors.ban,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {
            text = string.format("OnyxAC v%s", OnyxAC.Config.general.version)
        },
        fields = {
            {
                name = "Player",
                value = playerData and playerData.name or "Unknown",
                inline = true
            },
            {
                name = "Admin",
                value = adminData and adminData.name or "System",
                inline = true
            },
            {
                name = "Duration",
                value = duration == 0 and "Permanent" or (duration .. " minutes"),
                inline = true
            },
            {
                name = "Reason",
                value = reason,
                inline = false
            },
            {
                name = "Ban ID",
                value = tostring(banId),
                inline = true
            }
        }
    }
    
    table.insert(webhookQueue, embed)
end

function OnyxAC.DiscordWebhook.SendUnban(banId, adminId, reason)
    if not OnyxAC.Config.discord.enabled then return end
    
    local adminData = adminId and OnyxAC.GetPlayerData(adminId) or nil
    
    local embed = {
        title = "✅ Ban Removed",
        description = string.format("Ban **%s** has been removed", banId),
        color = OnyxAC.Config.discord.embedColors.unban,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {
            text = string.format("OnyxAC v%s", OnyxAC.Config.general.version)
        },
        fields = {
            {
                name = "Ban ID",
                value = tostring(banId),
                inline = true
            },
            {
                name = "Admin",
                value = adminData and adminData.name or "System",
                inline = true
            },
            {
                name = "Reason",
                value = reason or "No reason provided",
                inline = false
            }
        }
    }
    
    table.insert(webhookQueue, embed)
end
