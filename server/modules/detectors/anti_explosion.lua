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

OnyxAC.Detectors.antiExplosion = {}

function OnyxAC.Detectors.antiExplosion.Initialize()
    print("^2[OnyxAC]^7 Anti-Explosion detector initialized")
    
    AddEventHandler('explosionEvent', function(sender, ev)
        OnyxAC.Detectors.antiExplosion.HandleExplosion(sender, ev)
    end)
end

function OnyxAC.Detectors.antiExplosion.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Explosion detector config updated")
end

function OnyxAC.Detectors.antiExplosion.HandleExplosion(playerId, explosionData)
    local config = OnyxAC.Config.detectors.antiExplosion
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    local explosionType = explosionData.explosionType
    local isBlacklisted = false
    
    if config.useBlacklist then
        for _, blacklistedType in ipairs(OnyxAC.Config.blacklists.explosions) do
            if explosionType == blacklistedType then
                isBlacklisted = true
                break
            end
        end
    end
    
    if isBlacklisted then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local detectionData = {
            explosionType = explosionType,
            position = {
                x = explosionData.posX,
                y = explosionData.posY,
                z = explosionData.posZ
            },
            damage = explosionData.damageScale
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiExplosion", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Blacklisted explosion detected from %s: type %d", 
                playerData.name, explosionType))
        end
        
        CancelEvent()
    end
end
