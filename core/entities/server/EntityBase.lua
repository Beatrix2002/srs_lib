local Network = srs.lib.Network
local EntityBase = srs.lib.class("EntityBase")
EntityBase.ById = {}
EntityBase.ByOwner = {}
EntityBase.ByPlate = {}
EntityBase.Synced = {}
EntityBase.Network = {}
EntityBase.counter = 0

EntityBase.Create = function(data)
    if EntityBase.ById[data.id] then
        print("Entity with ID already exists:", data.id)
        return false
    end
    local entity = EntityBase:new(data)
    return entity
end


EntityBase.serverSettersMap = {
    ["FreezeEntityPosition"] = function(entity, freeze)
        FreezeEntityPosition(entity.handle, freeze == true)
    end,
    ["SetEntityHeading"] = function(entity, heading)
        SetEntityHeading(entity.handle, heading + 0.0)
    end,
    ["SetEntityRotation"] = function(entity, x, y, z)
        SetEntityRotation(entity.handle, x + 0.0, y + 0.0, z + 0.0, 2, true)
    end,
}

function EntityBase.genID(owner, t)
    EntityBase.counter += 1
    t = t == "network" and "n" or "s"
    return ("srs_%s_%d_%d"):format(t, owner, EntityBase.counter)
end

EntityBase.Plate = {
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    numbers = '0123456789',
}
EntityBase.Plate.charsLen = #EntityBase.Plate.chars
EntityBase.Plate.numbersLen = #EntityBase.Plate.numbers

function EntityBase.Plate.genPlate()
    local plate = ""
    local len = EntityBase.Plate.charsLen
    for i = 1, 3 do
        plate = plate .. EntityBase.Plate.chars:sub(math.random(1, len), math.random(1, len))
    end
    plate = plate .. " "
    len = EntityBase.Plate.numbersLen
    for i = 1, 3 do
        plate = plate .. EntityBase.Plate.numbers:sub(math.random(1, len), math.random(1, len))
    end
    return plate
end

function EntityBase:constructor(data)
    self.owner = data.owner
    self.id = data.id or EntityBase.genID(data.owner, data.mode)
    self.entityType = data.entityType
    self.mode = data.mode -- "synced" or "network"
    self.model = data.model
    self.coords = data.coords

    self._setters = data.setters
    self._serverSetters = data.serverSetters -- only for network entities

    self.netId = nil                         -- only for network entities
    self.handle = nil                        -- only for local entities
    self.bucket = data.bucket or 0

    self.invoked = data.invoked
    self.spawnSide = data.spawnSide

    self._lifeTime = data.lifeTime

    self.spawnDistance = data.spawnDistance

    self.behaviors = data.behaviors
    self.sBehaviors = data.sBehaviors
    self.customStates = data.customStates -- id and netId will be added automatically

    if self.mode == "synced" then
        EntityBase.Synced[self.id] = self
        TriggerClientEvent("srs_lib:entities:registerSyncedEntity", -1, {
            id = self.id,
            owner = self.owner,
            entityType = self.entityType,
            model = self.model,
            coords = self.coords,
            netId = self.netId,
            plate = self.plate,
            setters = self._setters,
            behaviors = self.behaviors,
            spawnDistance = self.spawnDistance
        })
    elseif self.mode == "network" then
        self.netId = data.netId
        self.handle = Network.GetEntityFromNetId(self.netId)
        if not self.handle then
            print("Failed to get entity handle from netId for entity ID:", self.id)
            return nil
        end
        EntityBase.Network[self.id] = self

        local states = self.customStates or {}
        Entity(self.handle).state.srs_entity = {
            id = self.id,
            netId = self.netId,
        }
        for key, value in pairs(states) do
            Entity(self.handle).state[("srs_e:%s"):format(key)] = value
        end

        if self._serverSetters then
            local map = EntityBase.serverSettersMap
            for key, value in pairs(self._serverSetters) do
                map[key](self, table.unpack(value))
            end
        end
        if self._setters then
            local controlOwner = NetworkGetEntityOwner(self.handle)
            if controlOwner and controlOwner > 0 then
                srs.callback("srs_lib:entities:setSetters", controlOwner, function() end, self.netId, self._setters)
            end
        end

        if self.owner == 0 then
            SetEntityOrphanMode(self.handle, 2)
        end

        if self.bucket ~= 0 then
            SetEntityRoutingBucket(self.handle, self.bucket)
        end
    end
    EntityBase.ById[self.id] = self
    if not EntityBase.ByOwner[self.owner] then
        EntityBase.ByOwner[self.owner] = {}
    end
    EntityBase.ByOwner[self.owner][self.id] = self
    if self.entityType == "vehicle" then
        self.plate = data.plate or EntityBase.Plate.genPlate()
        EntityBase.ByPlate[self.plate] = self
    end
    if self.sBehaviors then
        for behaviorName, params in pairs(self.sBehaviors) do
            Behaviors.trigger(behaviorName, self, "onCreate", params)
        end
    end
    return self
end

function EntityBase:destroy()
    if self.entityType == "vehicle" then
        EntityBase.ByPlate[self.plate] = nil
    end
    EntityBase.ById[self.id] = nil
    if EntityBase.ByOwner[self.owner] then
        EntityBase.ByOwner[self.owner][self.id] = nil
        if next(EntityBase.ByOwner[self.owner]) == nil then
            EntityBase.ByOwner[self.owner] = nil
        end
    end
    if self.sBehaviors then
        for behaviorName, params in pairs(self.sBehaviors) do
            Behaviors.trigger(behaviorName, self, "onDestroy", params)
        end
    end
    if self.mode == "synced" then
        EntityBase.Synced[self.id] = nil
        TriggerClientEvent("srs_lib:entities:unregisterSyncedEntity", -1, self.id)
    elseif self.mode == "network" then
        EntityBase.Network[self.id] = nil
    end
    if DoesEntityExist(self.handle) then
        DeleteEntity(self.handle)
    end
end

return EntityBase
