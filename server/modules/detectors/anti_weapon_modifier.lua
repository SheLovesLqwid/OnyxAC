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

OnyxAC.Detectors.antiWeaponModifier = {}

function OnyxAC.Detectors.antiWeaponModifier.Initialize()
    print("^2[OnyxAC]^7 Anti-Weapon Modifier detector initialized")
    
    RegisterNetEvent('onyxac:client:weaponModification')
    AddEventHandler('onyxac:client:weaponModification', function(weaponHash, damageMultiplier, rangeMultiplier, ammoCount)
        OnyxAC.Detectors.antiWeaponModifier.HandleWeaponModification(source, weaponHash, damageMultiplier, rangeMultiplier, ammoCount)
    end)
end

function OnyxAC.Detectors.antiWeaponModifier.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Weapon Modifier detector config updated")
end

function OnyxAC.Detectors.antiWeaponModifier.HandleWeaponModification(playerId, weaponHash, damageMultiplier, rangeMultiplier, ammoCount)
    local config = OnyxAC.Config.detectors.antiWeaponModifier
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    local violations = {}
    
    if config.checkDamageModifier and damageMultiplier > config.maxDamageMultiplier then
        table.insert(violations, {
            type = "damage",
            value = damageMultiplier,
            max = config.maxDamageMultiplier
        })
    end
    
    if config.checkRangeModifier and rangeMultiplier > 2.0 then
        table.insert(violations, {
            type = "range",
            value = rangeMultiplier,
            max = 2.0
        })
    end
    
    if config.checkAmmoModifier and ammoCount > 9999 then
        table.insert(violations, {
            type = "ammo",
            value = ammoCount,
            max = 9999
        })
    end
    
    if #violations > 0 then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        local detectionData = {
            weaponHash = weaponHash,
            violations = violations
        }
        
        OnyxAC.ScoringEngine.AddInfraction(playerId, "antiWeaponModifier", config.scoreWeight, detectionData)
        
        if OnyxAC.Config.general.enableDebugMode then
            print(string.format("^3[OnyxAC-DEBUG]^7 Weapon modifier detected for %s: %d violations", 
                playerData.name, #violations))
        end
    end
end
