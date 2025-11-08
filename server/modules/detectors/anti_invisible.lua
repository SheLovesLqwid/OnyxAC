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

OnyxAC.Detectors.antiInvisible = {}

function OnyxAC.Detectors.antiInvisible.Initialize()
    print("^2[OnyxAC]^7 Anti-Invisible detector initialized")
    
    Citizen.CreateThread(function()
        while true do
            OnyxAC.Detectors.antiInvisible.CheckPlayers()
            Wait(OnyxAC.Config.detectors.antiInvisible.checkInterval)
        end
    end)
end

function OnyxAC.Detectors.antiInvisible.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Invisible detector config updated")
end

function OnyxAC.Detectors.antiInvisible.CheckPlayers()
    local config = OnyxAC.Config.detectors.antiInvisible
    if not config.enabled then return end
    
    for playerId, playerData in pairs(OnyxAC.Players) do
        if not OnyxAC.IsPlayerExempt(playerId) then
            OnyxAC.Detectors.antiInvisible.CheckPlayer(playerId, config)
        end
    end
end

function OnyxAC.Detectors.antiInvisible.CheckPlayer(playerId, config)
    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 then return end
    
    local alpha = GetEntityAlpha(playerPed)
    
    if alpha < 100 then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local detectionData = {
            alpha = alpha,
            normalAlpha = 255
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiInvisible", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Invisible player detected: %s (alpha: %d)", 
                playerData.name, alpha))
        end
        
        SetEntityAlpha(playerPed, 255, false)
    end
end
