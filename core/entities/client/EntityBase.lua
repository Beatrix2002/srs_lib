---@diagnostic disable: inject-field, undefined-field
local EntityBase = srs.lib.class("EntityBase")
EntityBase.ById = {}
EntityBase.Points = {}
EntityBase.counter = 0

EntityBase.Create = function(data)
    if EntityBase.ById[data.id] then
        print("Entity with ID already exists:", data.id)
        return false
    end
    local entity = EntityBase:new(data)
    return entity
end

function EntityBase.genID(owner, t)
    EntityBase.counter += 1
    t = t == "local" and "l" or "s"
    return ("srs_%s_%d_%d"):format(t, owner, EntityBase.counter)
end

function EntityBase:constructor(data)
    self.id = data.id or EntityBase.genID(data.owner, data.mode)
    self.entityType = data.entityType
    self.owner = data.owner
    self.mode = data.mode
    self.model = data.model
    self.coords = data.coords

    self._setters = data.setters -- only for local entities
    self._serverSetters = data.serverSetters -- only for net Entities

    self.handle = data.handle

    self.spawned = false

    self.behaviors = data.behaviors
    self.sBehaviors = data.sBehaviors

    self._onSpawn = data.onSpawn
    self._onDespawn = data.onDespawn
    self.spawnDistance = data.spawnDistance
    if self.spawnDistance and self.spawnDistance == -1 then
        self:spawn()
    else
        self.pointId = data.pointId or self.id
        self.spawnDistance = data.spawnDistance or 50.0
        if EntityBase.Points[self.pointId] then
            self.point = EntityBase.Points[self.pointId]
            self.point.entities[self.id] = self
        else
            self.point = srs.lib.points.new({ coords = self.coords, distance = self.spawnDistance })
            self.point.entities = {}
            function self.point:onEnter()
                for _, entity in pairs(self.entities) do
                    entity:spawn()
                end
            end

            function self.point:onExit()
                for _, entity in pairs(self.entities) do
                    entity:despawn()
                end
            end

            EntityBase.Points[self.pointId] = self.point
            EntityBase.Points[self.pointId].entities[self.id] = self
        end
    end
    if self.behaviors then
        for behaviorName, params in pairs(self.behaviors) do
            Behaviors.trigger(behaviorName, self, "onCreate", params)
        end
    end

    EntityBase.ById[self.id] = self
end

EntityBase.settersMap = {
    ["SetEntityAlpha"] = function(entity, alpha)
        SetEntityAlpha(entity.handle, alpha or 255, false)
    end,
    ["SetEntityVisible"] = function(entity, visible)
        SetEntityVisible(entity.handle, visible ~= false, false)
    end,
    ["SetEntityCollision"] = function(entity, enabled)
        SetEntityCollision(entity.handle, enabled ~= false, true)
    end,
    ["FreezeEntityPosition"] = function(entity, freeze)
        FreezeEntityPosition(entity.handle, freeze == true)
    end,
    ["SetEntityCoordsNoOffset"] = function(entity, x, y, z)
        SetEntityCoordsNoOffset(entity.handle, x, y, z, false, false, false)
    end,
    ["SetEntityCoords"] = function(entity, x, y, z)
        SetEntityCoords(entity.handle, x, y, z, false, false, false, true)
    end,
    ["SetEntityRotation"] = function(entity, rx, ry, rz)
        SetEntityRotation(entity.handle, rx, ry, rz, 2, true)
    end,
    ["SetEntityHeading"] = function(entity, heading)
        SetEntityHeading(entity.handle, heading or 0.0)
    end,
    ["SetEntityInvincible"] = function(entity, invincible)
        SetEntityInvincible(entity.handle, invincible == true)
    end,
    ["SetEntityHealth"] = function(entity, health)
        if health then
            SetEntityHealth(entity.handle, math.floor(health))
        end
    end,
    ["SetEntityProofs"] = function(entity, bullet, fire, explosion, collision, melee, steam, p7, drown)
        SetEntityProofs(entity.handle, bullet or false, fire or false, explosion or false, collision or false,
            melee or false, steam or false, p7 or false, drown or false)
    end,
    ["SetPedArmour"] = function(entity, armour)
        if entity.entityType == 'ped' then
            SetPedArmour(entity.handle, armour or 0)
        end
    end,
}

function EntityBase:spawn() -- if enter the area
    if self.spawned then return end
    self.spawned = true
    if not srs.lib.requestModel(self.model) then
        print("Failed to load model:", self.model)
        self.spawned = false
        return
    end
    if self.entityType == "ped" then
        self.handle = CreatePed(4, self.model, self.coords.x, self.coords.y, self.coords.z, self.coords.w or 0.0, false,
            false)
    elseif self.entityType == "vehicle" then
        self.handle = CreateVehicle(self.model, self.coords.x, self.coords.y, self.coords.z, self.coords.w or 0.0, false,
            false)
    elseif self.entityType == "object" then
        self.handle = CreateObjectNoOffset(self.model, self.coords.x, self.coords.y, self.coords.z, false, true, false)
        if self.coords.w then
            SetEntityHeading(self.handle, self.coords.w)
        end
    end
    SetModelAsNoLongerNeeded(self.model)
    SetEntityAsMissionEntity(self.handle, true, true)
    if self._setters then
        local setterMap = EntityBase.settersMap
        for setter, params in pairs(self._setters) do
            setterMap[setter](self, table.unpack(params))
        end
    end
    if self._onSpawn then
        self._onSpawn(self)
    end
    if self.behaviors then
        for behaviorName, params in pairs(self.behaviors) do
            Behaviors.trigger(behaviorName, self, "onSpawn", params)
        end
    end
end

function EntityBase:despawn() -- if leave the area
    if not self.spawned then return end
    self.spawned = false
    if self._onDespawn then
        self._onDespawn(self)
    end
    if DoesEntityExist(self.handle) then
        DeleteEntity(self.handle)
    end
    if self.behaviors then
        for behaviorName, params in pairs(self.behaviors) do
            Behaviors.trigger(behaviorName, self, "onDespawn", params)
        end
    end
    self.handle = nil
end

function EntityBase:destroy()
    if self.point and self.point.entities then
        self.point.entities[self.id] = nil
        if not next(self.point.entities) then
            self.point:remove()
            EntityBase.Points[self.pointId] = nil
        end
    end
    if self.behaviors then
        for behaviorName, params in pairs(self.behaviors) do
            Behaviors.trigger(behaviorName, self, "onDestroy", params)
        end
    end
    self:despawn()
    EntityBase.ById[self.id] = nil
end

return EntityBase
