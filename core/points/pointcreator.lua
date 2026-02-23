--[[
        PointCreator - srs_lib core/points/pointcreator.lua

        Provides a registry and API for creating, updating, removing, and retrieving point objects using srs.lib.points.

        API:
            - PointCreator.addPoint(data): Adds a new point with the given data table (must include .id). Returns the registry entry.
            - PointCreator.rmPoint(id): Removes a point by id. Returns true if removed.
            - PointCreator.updatePoint(id, newData): Updates a point by id with new data. Returns the new registry entry.
            - PointCreator.getPoint(id): Retrieves the registry entry for a point by id.

        Exports:
            - addPoint
            - rmPoint
            - updatePoint
            - getPoint

        Points are automatically cleaned up on resource stop for the invoker.
]]
local PointCreator = {}
PointCreator.Registry = {}

local function createPoint(id, data)
    local pointData = data or {}
    pointData.id = id

    local point = srs.lib.points.new(pointData)

    local entry = {
        id = id,
        point = point,
        invoker = GetInvokingResource() or GetCurrentResourceName(),
        meta = pointData.meta,
    }

    PointCreator.Registry[id] = entry
    return entry
end

function PointCreator.addPoint(data)
    if type(data) ~= 'table' then return nil end

    local id = data.id
    if not id then return nil end

    local existing = PointCreator.Registry[id]
    if existing then return existing end

    return createPoint(id, data)
end

function PointCreator.rmPoint(id)
    local entry = PointCreator.Registry[id]
    if not entry then
        return false
    end

    if entry.point and entry.point.remove then
        entry.point:remove()
    end

    PointCreator.Registry[id] = nil
    return true
end

function PointCreator.updatePoint(id, newData)
    if not PointCreator.rmPoint(id) then
        return nil
    end

    local pointData = newData or {}
    pointData.id = id

    return createPoint(id, pointData)
end

function PointCreator.getPoint(id)
    return PointCreator.Registry[id]
end

exports('addPoint', PointCreator.addPoint)
exports('rmPoint', PointCreator.rmPoint)
exports('updatePoint', PointCreator.updatePoint)
exports('getPoint', PointCreator.getPoint)

AddEventHandler('onResourceStop', function(resourceName)
    for id, entry in pairs(PointCreator.Registry) do
        if entry.invoker == resourceName then
            PointCreator.rmPoint(id)
        end
    end
end)

return PointCreator
