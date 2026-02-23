local EntityBase = require "core.entities.server.EntityBase"
local Network = srs.lib.Network

local creators = {
    ["vehicle"] = function(model, coords, type)
        return CreateVehicleServerSetter(model, type or "automobile", coords.x, coords.y, coords.z, coords.w or 0.0)
    end,
    ["ped"] = function(model, coords)
        return CreatePed(4, model, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    end,
    ["object"] = function(model, coords)
        return CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true, false)
    end,
}

local allowedModes = { network = true, synced = true, ["local"] = true }
local allowedTypes = { vehicle = true, ped = true, object = true }

srs.callback.register("srs_lib:entities:register", function(playerId, data)
    data.src = playerId
    -- basic input validation
    if type(data) ~= "table" then
        print("Invalid entity data from player", playerId)
        return false
    end

    if not data.mode or not allowedModes[data.mode] then
        print("Invalid entity mode from player", playerId, data.mode)
        return false
    end
    if not data.entityType or not allowedTypes[data.entityType] then
        print("Invalid entityType from player", playerId, data.entityType)
        return false
    end
    if not data.coords then
        print("Missing or invalid coords from player", playerId)
        return false
    end
    if not data.owner then data.owner = playerId end
    if data.mode == "network" then
        if data.spawnSide == "server" then
            local model = data.model
            local handle = creators[data.entityType](model, data.coords, data.vehicleType)
            if not Network.WaitForCreate(handle) then
                DeleteEntity(handle)
                print("Failed to create entity on server:", data.entityType, model)
                return false
            end
            local netId = Network.GetNetIdFromEntity(handle)
            if not netId then
                print("Failed to get netId for entity")
                DeleteEntity(handle)
                return false
            end
            data.handle = handle
            data.netId = netId
            data.bucket = data.bucket or GetPlayerRoutingBucket(playerId)
            local entity = EntityBase.Create(data)
            if not entity then return false end
            return netId
        else
            local entity = EntityBase.Create(data)
            if not entity then
                    print("Failed to create network entity with ID:", data.id)
                    return false
            end
            return true
        end
    elseif data.mode == "synced" then
        local entity = EntityBase.Create(data)
        if not entity then
            print("Failed to create synced entity with ID:", data.id)
            return
        end
        return true
    end
end)

local EntityHandlers = {}

EntityHandlers.CreateSyncedEntity = function(data)
    local entity = EntityBase.Create(data)
    if not entity then
        print("Failed to create synced entity with ID:", data.id)
        return
    end
end

EntityHandlers.CreateNetworkEntity = function(data)
    local model = data.model
    local handle = creators[data.entityType](model, data.coords, data.vehicleType)
    if not Network.WaitForCreate(handle) then
        print("Failed to create entity on server:", data.entityType, model)
        return
    end
    local netId = Network.GetNetIdFromEntity(handle)
    if not netId then
        print("Failed to get netId for entity")
        DeleteEntity(handle)
        return
    end
    data.handle = handle
    data.netId = netId
    local entity = EntityBase.Create(data)
    return entity
end

EntityHandlers.DestroyEntityById = function(id)
    local entity = EntityBase.ById[id]
    if not entity then
        print("No entity found with ID:", id)
        return false
    end
    entity:destroy()
    return true
end

srs.callback.register("srs_lib:entities:destroy", function(playerId, id)
    EntityHandlers.DestroyEntityById(id)
end)

srs.callback.register("srs_lib:entities:getSyncedEntities", function(playerId)
    local rawEntities = {}
    for id, entity in pairs(EntityBase.Synced) do
        rawEntities[id] = {
            id = entity.id,
            owner = entity.owner,
            entityType = entity.entityType,
            model = entity.model,
            coords = entity.coords,
            netId = entity.netId,
            plate = entity.plate,
            setters = entity._setters,
            behaviors = entity.behaviors,
            spawnDistance = entity.spawnDistance
        }
    end
    return rawEntities
end)

exports("CreateSyncedEntity", EntityHandlers.CreateSyncedEntity)
exports("CreateNetworkEntity", EntityHandlers.CreateNetworkEntity)
exports("DestroyEntityById", EntityHandlers.DestroyEntityById)
