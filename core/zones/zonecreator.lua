local ZoneCreator = {}
ZoneCreator.Registry = {}

local function createZone(id, data)
    local zoneData = data or {}
    zoneData.id = id

    local zone
    if zoneData.zoneType == 'box' then
        zone = srs.lib.zones.box(zoneData)
    elseif zoneData.zoneType == 'sphere' then
        zone = srs.lib.zones.sphere(zoneData)
    else
        zone = srs.lib.zones.poly(zoneData)
    end

    local entry = {
        id = id,
        zone = zone,
        invoker = GetInvokingResource() or GetCurrentResourceName(),
        meta = zoneData.meta,
    }

    ZoneCreator.Registry[id] = entry
    return entry
end

function ZoneCreator.addZone(data)
    if type(data) ~= 'table' then return nil end

    local id = data.id
    if not id then return nil end

    local existing = ZoneCreator.Registry[id]
    if existing then return existing end

    return createZone(id, data)
end

function ZoneCreator.rmZone(id)
    local entry = ZoneCreator.Registry[id]
    if not entry then
        return false
    end

    if entry.zone and entry.zone.remove then
        entry.zone:remove()
    end

    ZoneCreator.Registry[id] = nil
    return true
end

function ZoneCreator.updateZone(id, newData)
    if not ZoneCreator.rmZone(id) then
        return nil
    end

    local zoneData = newData or {}
    zoneData.id = id

    return createZone(id, zoneData)
end

function ZoneCreator.getZone(id)
    return ZoneCreator.Registry[id]
end

exports('addZone', ZoneCreator.addZone)
exports('rmZone', ZoneCreator.rmZone)
exports('updateZone', ZoneCreator.updateZone)
exports('getZone', ZoneCreator.getZone)

AddEventHandler('onResourceStop', function(resourceName)
    for id, entry in pairs(ZoneCreator.Registry) do
        if entry.invoker == resourceName then
            ZoneCreator.rmZone(id)
        end
    end
end)

return ZoneCreator
