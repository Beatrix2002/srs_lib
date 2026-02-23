--[[
    Adapted from community_bridge
    https://github.com/The-Order-Of-The-Hat/community_bridge

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 The Order Of The Hat
]]

local Shells = srs.lib.shells or {}
Shells.All = Shells.All or {}
Shells.Events = Shells.Events or {
    OnSpawn = {},
    OnRemove = {},
}

local insideShell = false
local returnPoint

local spawnedObjects = {}

local function triggerEvent(eventName, ...)
    local list = Shells.Events[eventName]
    if not list then return end

    for i = 1, #list do
        list[i](...)
    end
end

function Shells.EventAdd(eventName, callback)
    if not Shells.Events[eventName] then
        print(('Shells.EventAdd: Invalid event name %s'):format(eventName))
        return
    end

    Shells.Events[eventName][#Shells.Events[eventName] + 1] = callback
end

local function spawnObject(id, data)
    if not data.model then return end

    local model = type(data.model) == 'number' and data.model or joaat(data.model)
    srs.lib.requestModel(model)

    local obj = CreateObject(model, data.coords.x, data.coords.y, data.coords.z, false, false, false)
    if data.rotation then
        SetEntityRotation(obj, data.rotation.x or 0.0, data.rotation.y or 0.0, data.rotation.z or 0.0, 2, false)
    end

    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(model)

    spawnedObjects[id] = obj
end

local function removeObject(id)
    local obj = spawnedObjects[id]
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    spawnedObjects[id] = nil
end

local function addTargetZone(shellId, pointData)
    if not srs.bridge.Target or not srs.bridge.Target.AddBoxZone then return end

    local targetOptions = Shells.Target.get(pointData.type, shellId, pointData.id)
    if not targetOptions then return end

    local size = vector3(pointData.distance / 2, pointData.distance / 2, pointData.distance / 2)
    srs.bridge.Target.AddBoxZone(pointData.id, pointData.coords, size, pointData.rotation and pointData.rotation.z or 0.0, targetOptions, true)
end

local function removeTargetZone(pointId)
    if srs.bridge.Target and srs.bridge.Target.RemoveZone then
        srs.bridge.Target.RemoveZone(pointId)
    end
end

function Shells.addInteriorObject(shell, objectData)
    objectData.OnSpawn = function(pointData)
        triggerEvent('OnSpawn', objectData, pointData.spawned)
        addTargetZone(shell.id, objectData)
        spawnObject(objectData.id, objectData)
    end

    objectData.OnRemove = function(pointData)
        triggerEvent('OnRemove', objectData, pointData.spawned)
        removeTargetZone(objectData.id)
        removeObject(objectData.id)
    end

    return srs.lib.points.new({
        coords = objectData.coords,
        distance = objectData.distance or 2.0,
        onEnter = objectData.OnSpawn,
        onExit = objectData.OnRemove,
    })
end

function Shells.setupInterior(shell)
    if not shell or not shell.interior then return end
    for _, v in pairs(shell.interior) do
        local pointData = Shells.addInteriorObject(shell, v)
        shell.interiorSpawned[pointData.id] = pointData
    end
end

function Shells.setupExterior(shell)
    if not shell or not shell.exterior then return end
    for _, v in pairs(shell.exterior) do
        local pointData = Shells.addInteriorObject(shell, v)
        shell.exteriorSpawned[pointData.id] = pointData
    end
end

function Shells.clearInterior(shell)
    if not shell or not shell.interiorSpawned then return end
    for _, v in pairs(shell.interiorSpawned) do
        if v.remove then v:remove() end
        removeTargetZone(v.id)
        removeObject(v.id)
    end
    shell.interiorSpawned = {}
end

function Shells.clearExterior(shell)
    if not shell or not shell.exteriorSpawned then return end
    for _, v in pairs(shell.exteriorSpawned) do
        if v.remove then v:remove() end
        removeTargetZone(v.id)
        removeObject(v.id)
    end
    shell.exteriorSpawned = {}
end

function Shells.new(data)
    assert(data.id, "Shells.new: 'id' is required")
    assert(data.model, "Shells.new: 'model' is required")
    assert(data.coords, "Shells.new: 'coords' is required")

    local exteriorSpawned = {}

    for _, v in pairs(data.exterior or {}) do
        v.OnSpawn = function(pointData)
            triggerEvent('OnSpawn', v, pointData.spawned)
            addTargetZone(data.id, v)
            spawnObject(v.id, v)
        end

        v.OnRemove = function(pointData)
            triggerEvent('OnRemove', v, pointData.spawned)
            removeTargetZone(v.id)
            removeObject(v.id)
        end

        local pointData = srs.lib.points.new({
            coords = v.coords,
            distance = v.distance or 2.0,
            onEnter = v.OnSpawn,
            onExit = v.OnRemove,
        })

        exteriorSpawned[pointData.id] = pointData
    end

    data.interiorSpawned = {}
    data.exteriorSpawned = exteriorSpawned
    Shells.All[data.id] = data
    return data
end

function Shells.enter(id, entranceId)
    local shell = Shells.All[id]
    if not shell then
        print(('Shells.enter: Shell with ID %s not found'):format(id))
        return
    end

    local entrance = shell.interior and shell.interior[entranceId]
    if not entrance then
        print(('Shells.enter: Entrance %s not found in shell %s'):format(entranceId, id))
        return
    end

    local ped = PlayerPedId()
    returnPoint = GetEntityCoords(ped)

    DoScreenFadeOut(1000)
    Wait(1000)

    SetEntityCoords(ped, entrance.coords.x, entrance.coords.y, entrance.coords.z, false, false, false, true)
    FreezeEntityPosition(ped, true)

    local oldShell = insideShell and Shells.All[insideShell]
    if oldShell and oldShell.id ~= id then
        Shells.clearExterior(oldShell)
        Shells.clearInterior(oldShell)
    end

    Shells.clearExterior(shell)
    Shells.setupInterior(shell)

    Wait(1000)
    FreezeEntityPosition(ped, false)
    DoScreenFadeIn(1000)

    insideShell = shell.id
end

function Shells.exit(id, exitId)
    local shell = Shells.All[id]
    if not shell then
        print(('Shells.exit: Shell with ID %s not found'):format(id))
        return
    end

    local oldPoint = shell.exterior and shell.exterior[exitId]
    if not oldPoint then
        print(('Shells.exit: Exit %s not found in shell %s'):format(exitId, id))
        return
    end

    DoScreenFadeOut(1000)
    Wait(1000)

    local ped = PlayerPedId()
    SetEntityCoords(ped, oldPoint.coords.x, oldPoint.coords.y, oldPoint.coords.z, false, false, false, true)
    FreezeEntityPosition(ped, true)

    Shells.clearInterior(shell)
    Shells.setupExterior(shell)
    shell.interiorSpawned = {}

    FreezeEntityPosition(ped, false)
    DoScreenFadeIn(1000)

    insideShell = false
end

function Shells.inside()
    return insideShell
end

RegisterNetEvent('srs_lib:shells:create', function(shell)
    Shells.new(shell)
end)

RegisterNetEvent('srs_lib:shells:createBulk', function(shells)
    for _, shell in pairs(shells) do
        Shells.new(shell)
    end
end)

RegisterNetEvent('srs_lib:shells:enter', function(shellId, entranceId, _)
    Shells.enter(shellId, entranceId)
end)

RegisterNetEvent('srs_lib:shells:exit', function(shellId, exitId)
    Shells.exit(shellId, exitId)
end)

RegisterNetEvent('srs_lib:shells:addObjects', function(shellId, interiorObjects, exteriorObjects)
    local shell = Shells.All[shellId]
    if not shell then
        print(('Shells.addObjects: Shell with ID %s not found'):format(shellId))
        return
    end

    local currentShell = Shells.inside()

    if interiorObjects then
        for _, obj in pairs(interiorObjects) do
            if not shell.interior[obj.id] then
                shell.interior[obj.id] = obj
                if currentShell and currentShell == shellId then
                    local pointData = Shells.addInteriorObject(shell, obj)
                    shell.interiorSpawned[pointData.id] = pointData
                end
            end
        end
    end

    if exteriorObjects then
        for _, obj in pairs(exteriorObjects) do
            if not shell.exterior[obj.id] then
                shell.exterior[obj.id] = obj
                if not currentShell then
                    local pointData = Shells.addInteriorObject(shell, obj)
                    shell.exteriorSpawned[pointData.id] = pointData
                end
            end
        end
    end
end)

RegisterNetEvent('srs_lib:shells:removeObjects', function(shellId, objectIds)
    local shell = Shells.All[shellId]
    if not shell then
        print(('Shells.removeObjects: Shell with ID %s not found'):format(shellId))
        return
    end

    if type(objectIds) ~= 'table' then
        objectIds = { objectIds }
    end

    for i = 1, #objectIds do
        local objId = objectIds[i]
        shell.interior[objId] = nil
        shell.exterior[objId] = nil
        removeTargetZone(objId)
        removeObject(objId)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        DoScreenFadeIn(1000)
        if returnPoint then
            SetEntityCoords(PlayerPedId(), returnPoint.x, returnPoint.y, returnPoint.z, false, false, false, true)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(spawnedObjects) do
        removeObject(id)
    end
end)

srs.lib.shells = Shells

return Shells
