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

OnyxAC.Detectors.entityWhitelistBlacklist = {}

function OnyxAC.Detectors.entityWhitelistBlacklist.Initialize()
    print("^2[OnyxAC]^7 Entity Whitelist/Blacklist detector initialized")
    
    AddEventHandler('entityCreating', function(entity)
        OnyxAC.Detectors.entityWhitelistBlacklist.HandleEntityCreation(source, entity)
    end)
end

function OnyxAC.Detectors.entityWhitelistBlacklist.UpdateConfig(newConfig)
    print("^2[OnyxAC]^7 Entity Whitelist/Blacklist detector config updated")
end

function OnyxAC.Detectors.entityWhitelistBlacklist.HandleEntityCreation(playerId, entity)
    local config = OnyxAC.Config.detectors.entityWhitelistBlacklist
    if not config.enabled then return end
    
    if OnyxAC.IsPlayerExempt(playerId) then return end
    
    local entityModel = GetEntityModel(entity)
    local modelName = GetEntityArchetypeName(entity)
    
    local isAllowed = true
    
    if config.useWhitelist then
        isAllowed = false
        for _, whitelistedEntity in ipairs(OnyxAC.Config.whitelists.entities) do
            if modelName == whitelistedEntity or entityModel == GetHashKey(whitelistedEntity) then
                isAllowed = true
                break
            end
        end
    end
    
    if config.useBlacklist and isAllowed then
        for _, blacklistedEntity in ipairs(OnyxAC.Config.blacklists.entities) do
            if modelName == blacklistedEntity or entityModel == GetHashKey(blacklistedEntity) then
                isAllowed = false
                break
            end
        end
    end
    
    if not isAllowed then
        local playerData = OnyxAC.GetPlayerData(playerId)
        if playerData then
            local detectionData = {
                entityModel = entityModel,
                modelName = modelName,
                entityType = GetEntityType(entity)
            }
            
            OnyxAC.ScoringEngine.AddInfraction(playerId, "entityWhitelistBlacklist", config.scoreWeight, detectionData)
            
            if OnyxAC.Config.general.enableDebugMode then
                print(string.format("^3[OnyxAC-DEBUG]^7 Unauthorized entity spawned by %s: %s", 
                    playerData.name, modelName))
            end
        end
        
        CancelEvent()
    end
end
