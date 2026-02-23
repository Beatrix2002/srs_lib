print("ssd")

local EntityBase = require "core.entities.client.EntityBase"
local Network = srs.lib.Network

local function registerSyncedEntity(data)
    local entity = EntityBase.Create(data)
    return entity
end

local function unregisterSyncedEntity(id)
    local entity = EntityBase.ById[id]
    if entity then
        entity:destroy()
    end
end

RegisterNetEvent("srs_lib:entities:unregisterSyncedEntity", function(id)
    unregisterSyncedEntity(id)
end)

RegisterNetEvent("srs_lib:entities:registerSyncedEntity", function(data)
    registerSyncedEntity(data)
end)

local function registerLocalEntity(data)
    local entity = EntityBase.Create(data)
    return entity
end

local creators = {
    ["vehicle"] = function(model, coords)
        return CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    end,
    ["ped"] = function(model, coords)
        return CreatePed(4, model, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    end,
    ["object"] = function(model, coords)
        return CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true, false)
    end,
}

local function createEntityOnClient(data)
    local model = data.model
    if not srs.lib.requestModel(model) then
        print("Failed to request model on client:", model)
        return false
    end
    local entity = creators[data.entityType](model, data.coords)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(entity, true, true)
    local netId = Network.GetNetIdFromEntity(entity)
    if not netId then
        print("Failed to get netId for entity")
        DeleteEntity(entity)
        return false
    end
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    local result = srs.callback.await("srs_lib:entities:register", false, {
        id = data.id,
        owner = data.owner,
        mode = data.mode,
        entityType = data.entityType,
        model = model,
        coords = data.coords,
        netId = netId,
        spawnSide = "client",
        serverSetters = data.serverSetters,
    })
    if not result then
        print("Failed to register entity on client")
        Network.RequestControlOfEntity(entity)
        DeleteEntity(entity)
        return
    end
    return entity, netId
end

local EntityHandlers = {}

EntityHandlers.CreateSyncedEntity = function(data)
    return srs.callback.await("srs_lib:entities:register", false, data)
end

EntityHandlers.CreateLocalEntity = registerLocalEntity

EntityHandlers.CreateNetworkEntity = function(data)
    if data.spawnSide == "client" then
        return createEntityOnClient(data)
    elseif data.spawnSide == "server" then
        local netId = srs.callback.await("srs_lib:entities:register", false, data)
        if not netId then
            print("Failed to register network entity on client")
            return
        end
        local handle = Network.GetEntityFromNetId(netId)
        if not handle then
            print("Failed to get entity from netId on client")
            return
        end
        return handle, netId
    end
end

srs.callback.register("srs_lib:entities:setSetters", function(netId,settersData)

    local entity = Network.GetEntityFromNetId(netId)
    if not entity then
        print("Failed to get entity from netId for setting setters")
        return
    end
    local setterMap = EntityBase.settersMap
    for action, params in pairs(settersData) do
        setterMap[action](entity, table.unpack(params))
    end
end)



EntityHandlers.DestroyEntityById = function(id)
    local entity = EntityBase.ById[id]
    if not entity then
        return false
    end
    if entity.mode == "local" then
        entity:destroy()
        return true
    elseif entity.mode == "synced" or entity.mode == "network" then
        return srs.callback.await("srs_lib:entities:destroy", false, id)
    end
end

Citizen.CreateThread(function()
    Wait(2000)
    local syncedEntities = srs.callback.await("srs_lib:entities:getSyncedEntities", false)
    for _, data in pairs(syncedEntities or {}) do
        registerSyncedEntity(data)
    end
end)

exports("CreateSyncedEntity", EntityHandlers.CreateSyncedEntity)
exports("CreateLocalEntity", EntityHandlers.CreateLocalEntity)
exports("CreateNetworkEntity", EntityHandlers.CreateNetworkEntity)