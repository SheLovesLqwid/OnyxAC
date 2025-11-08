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

OnyxAC.Detectors.antiGodmode = {}

local playerHealthData = {}

function OnyxAC.Detectors.antiGodmode.Initialize()
    print("^2[OnyxAC]^7 Anti-Godmode detector initialized")
    
    Citizen.CreateThread(function()
        while true do
            OnyxAC.Detectors.antiGodmode.CheckPlayers()
            Wait(OnyxAC.Config.detectors.antiGodmode.checkInterval)
        end
    end)
end

function OnyxAC.Detectors.antiGodmode.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Godmode detector config updated")
end

function OnyxAC.Detectors.antiGodmode.CheckPlayers()
    local config = OnyxAC.Config.detectors.antiGodmode
    if not config.enabled then return end
    
    for playerId, playerData in pairs(OnyxAC.Players) do
        if not OnyxAC.IsPlayerExempt(playerId) then
            OnyxAC.Detectors.antiGodmode.CheckPlayer(playerId, config)
        end
    end
end

function OnyxAC.Detectors.antiGodmode.CheckPlayer(playerId, config)
    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 then return end
    
    local currentHealth = GetEntityHealth(playerPed)
    local maxHealth = GetEntityMaxHealth(playerPed)
    
    if not playerHealthData[playerId] then
        playerHealthData[playerId] = {
            lastHealth = currentHealth,
            damageAttempts = 0,
            lastDamageTime = 0
        }
        return
    end
    
    local healthData = playerHealthData[playerId]
    
    if currentHealth < healthData.lastHealth then
        healthData.damageAttempts = 0
        healthData.lastHealth = currentHealth
        return
    end
    
    if currentHealth == maxHealth and healthData.lastHealth == maxHealth then
        local currentTime = GetGameTimer()
        
        if currentTime - healthData.lastDamageTime > 5000 then
            SetEntityHealth(playerPed, maxHealth - 1)
            healthData.lastDamageTime = currentTime
            
            Citizen.SetTimeout(100, function()
                local newHealth = GetEntityHealth(playerPed)
                
                if newHealth >= maxHealth then
                    healthData.damageAttempts = healthData.damageAttempts + 1
                    
                    if healthData.damageAttempts >= 3 then
                        local playerData = OnyxAC.GetPlayerData(playerId)
                        if not playerData then return end
                        
                        local detectionData = {
                            currentHealth = newHealth,
                            maxHealth = maxHealth,
                            damageAttempts = healthData.damageAttempts,
                            testDamage = 1
                        }
                        
                        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiGodmode", config.scoreWeight, detectionData)
                        
                        if OnyxAC.Config.general.enableDebugMode then
                            print(string.format("^3[OnyxAC-DEBUG]^7 Godmode detected for %s (attempts: %d)", 
                                playerData.name, healthData.damageAttempts))
                        end
                        
                        healthData.damageAttempts = 0
                    end
                else
                    healthData.damageAttempts = 0
                end
                
                healthData.lastHealth = newHealth
            end)
        end
    else
        healthData.lastHealth = currentHealth
    end
end

AddEventHandler('playerDropped', function()
    local playerId = source
    playerHealthData[playerId] = nil
end)
