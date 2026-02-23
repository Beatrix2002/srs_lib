--[[
    Adapted from community_bridge
    https://github.com/The-Order-Of-The-Hat/community_bridge

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 The Order Of The Hat
]]

local Shells = srs.lib.shells or {}
Shells.All = Shells.All or {}
Shells.ActivePlayers = Shells.ActivePlayers or {}
Shells.BucketsInUse = Shells.BucketsInUse or {}

local function nextBucket()
    local bucket

    repeat
        bucket = math.random(1000, 9999)
    until not Shells.BucketsInUse[bucket]

    Shells.BucketsInUse[bucket] = true
    return bucket
end

local function normalizeInteractables(list, baseCoords)
    local result = {}

    for id, value in pairs(list or {}) do
        local data = value
        data.id = data.id or id

        if baseCoords and data.offset then
            data.coords = baseCoords + data.offset
        end

        result[data.id] = data
    end

    return result
end

function Shells.new(data)
    local id = data.id
    local model = data.model
    local coords = data.coords

    assert(id, "Shells.new: 'id' is required")
    assert(model, "Shells.new: 'model' is required")
    assert(coords, "Shells.new: 'coords' is required")

    local shellData = {
        id = id,
        type = data.type or 'none',
        model = model,
        coords = coords,
        size = data.size or vector3(10.0, 10.0, 10.0),
        rotation = data.rotation or vector3(0.0, 0.0, 0.0),
        interior = normalizeInteractables(data.interior, coords),
        exterior = normalizeInteractables(data.exterior, nil),
        bucket = data.bucket,
        meta = data.meta or {},
    }

    Shells.All[id] = shellData
    return shellData
end

function Shells.create(data)
    local shell = Shells.new(data)
    TriggerClientEvent('srs_lib:shells:create', -1, shell)
    return shell
end

function Shells.createBulk(shells)
    assert(type(shells) == 'table', "Shells.createBulk: 'shells' must be a table")
    local toClient = {}

    for _, shellData in pairs(shells) do
        local shell = Shells.new(shellData)
        toClient[shell.id] = shell
    end

    TriggerClientEvent('srs_lib:shells:createBulk', -1, toClient)
end

function Shells.enter(src, shellId, entranceId)
    src = tonumber(src)
    assert(src, "Shells.enter: 'src' is required")

    local shell = Shells.All[shellId]
    assert(shell, ('Shell not found: %s'):format(shellId))

    if not shell.bucket then
        shell.bucket = nextBucket()
    end

    SetPlayerRoutingBucket(src, shell.bucket)

    local exitId = shell.exterior[entranceId] and shell.exterior[entranceId].meta and shell.exterior[entranceId].meta.link
    TriggerClientEvent('srs_lib:shells:enter', src, shellId, exitId, Shells.ActivePlayers[tostring(src)])

    Shells.ActivePlayers[tostring(src)] = shellId
    return true
end

function Shells.exit(src, shellId, exitId)
    src = tonumber(src)
    assert(src, "Shells.exit: 'src' is required")

    local shell = Shells.All[shellId]
    assert(shell, ('Shell not found: %s'):format(shellId))

    SetPlayerRoutingBucket(src, 0)

    local entranceId = shell.interior[exitId] and shell.interior[exitId].meta and shell.interior[exitId].meta.link
    TriggerClientEvent('srs_lib:shells:exit', src, shellId, entranceId)

    Shells.ActivePlayers[tostring(src)] = nil
    return true
end

function Shells.get(shellId)
    assert(shellId, "Shells.get: 'shellId' is required")
    return Shells.All[shellId]
end

function Shells.inside(src)
    src = tonumber(src)
    assert(src, "Shells.inside: 'src' is required")

    local shellId = Shells.ActivePlayers[tostring(src)]
    if not shellId then return false end

    return Shells.All[shellId] or false
end

function Shells.addObjects(shellId, objects)
    assert(shellId, "Shells.addObjects: 'shellId' is required")
    assert(type(objects) == 'table', "Shells.addObjects: 'objects' must be a table")

    local shell = Shells.All[shellId]
    assert(shell, ('Shell not found: %s'):format(shellId))

    for _, objData in pairs(objects.interior or {}) do
        objData.id = objData.id or tostring(math.random(100000, 999999))
        shell.interior[objData.id] = objData
    end

    for _, objData in pairs(objects.exterior or {}) do
        objData.id = objData.id or tostring(math.random(100000, 999999))
        shell.exterior[objData.id] = objData
    end

    TriggerClientEvent('srs_lib:shells:addObjects', -1, shellId, shell.interior, shell.exterior)
    return shell
end

function Shells.removeObjects(shellId, objectIds)
    assert(shellId, "Shells.removeObjects: 'shellId' is required")

    if type(objectIds) ~= 'table' then
        objectIds = { objectIds }
    end

    local shell = Shells.All[shellId]
    assert(shell, ('Shell not found: %s'):format(shellId))

    for i = 1, #objectIds do
        local objId = objectIds[i]
        shell.interior[objId] = nil
        shell.exterior[objId] = nil
    end

    TriggerClientEvent('srs_lib:shells:removeObjects', -1, shellId, objectIds)
    return shell
end

RegisterNetEvent('srs_lib:shells:enter', function(shellId, entranceId)
    Shells.enter(source, shellId, entranceId)
end)

RegisterNetEvent('srs_lib:shells:exit', function(shellId, exitId)
    Shells.exit(source, shellId, exitId)
end)

AddEventHandler('onPlayerJoining', function()
    TriggerClientEvent('srs_lib:shells:createBulk', source, Shells.All)
end)

srs.lib.shells = Shells

return Shells
