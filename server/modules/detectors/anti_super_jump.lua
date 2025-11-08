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

OnyxAC.Detectors.antiSuperJump = {}

local playerJumpData = {}

function OnyxAC.Detectors.antiSuperJump.Initialize()
    print("^2[OnyxAC]^7 Anti-Super Jump detector initialized")
    
    RegisterNetEvent('onyxac:client:jumpDetection')
    AddEventHandler('onyxac:client:jumpDetection', function(jumpHeight, velocity)
        OnyxAC.Detectors.antiSuperJump.HandleJumpDetection(source, jumpHeight, velocity)
    end)
end

function OnyxAC.Detectors.antiSuperJump.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Anti-Super Jump detector config updated")
end

function OnyxAC.Detectors.antiSuperJump.HandleJumpDetection(playerId, jumpHeight, velocity)
    local config = OnyxAC.Config.detectors.antiSuperJump
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    if jumpHeight > config.maxJumpHeight then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if not playerData then return end
        
        if not playerJumpData[playerId] then
            playerJumpData[playerId] = {
                violations = 0,
                lastViolation = 0
            }
        end
        
        local currentTime = GetGameTimer()
        local jumpData = playerJumpData[playerId]
        
        if currentTime - jumpData.lastViolation > 10000 then
            jumpData.violations = 0
        end
        
        jumpData.violations = jumpData.violations + 1
        jumpData.lastViolation = currentTime
        
        if jumpData.violations >= 2 then
            local detectionData = {
                jumpHeight = jumpHeight,
                maxHeight = config.maxJumpHeight,
                velocity = velocity,
                violations = jumpData.violations
            }
            
            OnyxAC.ScoringEngine.AddInfraction(playerId, "antiSuperJump", config.scoreWeight, detectionData)
            
            if OnyxAC.Config.general.enableDebugMode then
                print(string.format("^3[OnyxAC-DEBUG]^7 Super jump detected for %s: %.2fm (max: %.2fm)", 
                    playerData.name, jumpHeight, config.maxJumpHeight))
            end
            
            jumpData.violations = 0
        end
    end
end

AddEventHandler('playerDropped', function()
    local playerId = source
    playerJumpData[playerId] = nil
end)
