local MarkerDraw = require 'core.markers.markerdraw'
local SpriteDraw = require 'core.markers.spritedraw'
local TextDraw = require 'core.markers.textdraw'

local MarkerCreator = {}
MarkerCreator.Registry = {}
MarkerCreator.ActiveMarkers = {}
MarkerCreator.ActiveMarkersByID = {}
MarkerCreator.LoadedTxds = {}

local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetGameplayCamCoord = GetGameplayCamCoord
local StartShapeTestRay = StartShapeTestRay
local GetShapeTestResult = GetShapeTestResult
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local math_abs = math.abs
local pairs = pairs
local ipairs = ipairs
local vector3 = vector3

local function triangleWave(time, period)
    local t = (time % period) / period
    return 1 - 2 * math_abs(t - 0.5)
end

local function loadTexture(dict)
    if not dict then return end
    if not HasStreamedTextureDictLoaded(dict) then
        RequestStreamedTextureDict(dict, false)
    end
    if not MarkerCreator.LoadedTxds[dict] then
        MarkerCreator.LoadedTxds[dict] = 1
    else
        MarkerCreator.LoadedTxds[dict] += 1
    end
end

local function unloadTexture(dict)
    if not dict then return end
    if MarkerCreator.LoadedTxds[dict] then
        MarkerCreator.LoadedTxds[dict] -= 1
        if MarkerCreator.LoadedTxds[dict] <= 0 then
            MarkerCreator.LoadedTxds[dict] = nil
            SetStreamedTextureDictAsNoLongerNeeded(dict)
        end
    end
end

local function unloadActiveMarker(id)
    local activeMarkers = MarkerCreator.ActiveMarkers
    for i = #activeMarkers, 1, -1 do
        if activeMarkers[i] and activeMarkers[i].id == id then
            for _, item in ipairs(activeMarkers[i].collection) do
                if item.textureDict then
                    unloadTexture(item.textureDict)
                end
            end
            activeMarkers[i] = false
            MarkerCreator.ActiveMarkersByID[id] = nil
            break
        end
    end
end

CreateThread(function()
    local activeMarkers = MarkerCreator.ActiveMarkers
    local now, entry, collection, item, extraZ

    while true do
        activeMarkers = MarkerCreator.ActiveMarkers
        local activeCount = #activeMarkers

        if activeCount > 0 then
            now = GetGameTimer()
            for i = activeCount, 1, -1 do
                entry = activeMarkers[i]
                if entry and entry ~= false then
                    collection = entry.collection
                    for j = 1, #collection do
                        item = collection[j]
                        if item then
                            extraZ = 0.0
                            if item.bobUpAndDown then
                                extraZ = triangleWave(now / item.bobPeriod, 2) * item.bobHeight
                            end
                            item:draw(extraZ)
                        end
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    local activeMarkers = MarkerCreator.ActiveMarkers
    local now, playerPed, playerCoords, camCoords, entry, raycastItems, item, targetZ, handle, hit

    while true do
        activeMarkers = MarkerCreator.ActiveMarkers
        local activeCount = #activeMarkers
        local compactedMarkers = {}
        if activeCount > 0 then
            now = GetGameTimer()
            playerPed = PlayerPedId()
            camCoords = GetGameplayCamCoord()

            for i = activeCount, 1, -1 do
                entry = activeMarkers[i]

                if entry and entry ~= false and (now - entry.lastRaycast > entry.raycastInterval) then
                    raycastItems = entry.raycastItems
                    if raycastItems and #raycastItems > 0 then
                        for j = 1, #raycastItems do
                            item = raycastItems[j]
                            targetZ = item.coords.z + (item.zOffset or 0.0)

                            handle = StartShapeTestRay(
                                camCoords.x, camCoords.y, camCoords.z,
                                item.coords.x, item.coords.y, targetZ,
                                17, playerPed, 0
                            )
                            _, hit = GetShapeTestResult(handle)
                            item.raycastVisible = (hit == 0)
                        end
                    end
                    entry.lastRaycast = now
                end
                if entry and entry ~= false then
                    compactedMarkers[#compactedMarkers + 1] = activeMarkers[i]
                end
            end
            --playerPed = PlayerPedId()
            playerCoords = GetEntityCoords(playerPed)
            MarkerCreator.ActiveMarkers = compactedMarkers
            activeMarkers = compactedMarkers

            table_sort(compactedMarkers, function(a, b)
                return #(a.coords - playerCoords) > #(b.coords - playerCoords)
            end)
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

function MarkerCreator.addMarker(data)
    local id = data.id
    if not id then return end

    if MarkerCreator.Registry[id] then return MarkerCreator.Registry[id] end

    local coords = data.coords
    if not coords then return end

    local collection = {}
    local raycastItems = {}

    local function getCoords(offset)
        if not offset then return coords end
        return vector3(coords.x + offset.x, coords.y + offset.y, coords.z + offset.z)
    end

    if data.markers then
        for _, mData in ipairs(data.markers) do
            local mCoords = getCoords(mData.offset)
            table_insert(collection, MarkerDraw.new(mCoords, mData))
        end
    end
    if data.sprites then
        for _, sData in ipairs(data.sprites) do
            local sCoords = getCoords(sData.offset)
            local item = SpriteDraw.new(sCoords, sData)
            table_insert(collection, item)
            if item.useRaycast then
                table_insert(raycastItems, item)
            end
        end
    end

    if data.texts then
        for _, tData in ipairs(data.texts) do
            local tCoords = getCoords(tData.offset)
            local item = TextDraw.new(tData.text, tCoords, tData)
            table_insert(collection, item)
            if item.useRaycast then
                table_insert(raycastItems, item)
            end
        end
    end

    local entry = {
        id = id,
        coords = coords,
        collection = collection,
        raycastItems = raycastItems,
        raycastInterval = data.raycastInterval or 500,
        lastRaycast = 0,
        invoker = GetInvokingResource() or GetCurrentResourceName(),
        meta = data.meta,
        insideInteract = false,
        onEnter = data.onEnter,
        onExit = data.onExit
    }

    local interactDist = data.interactDistance or 1.5

    local point = srs.lib.points.new({
        coords = coords,
        distance = data.distance or 10.0,
        onEnter = function(self)
            for _, item in ipairs(entry.collection) do
                if item.textureDict then
                    loadTexture(item.textureDict)
                end
            end
            MarkerCreator.ActiveMarkersByID[id] = entry
            table_insert(MarkerCreator.ActiveMarkers, entry)
        end,
        onExit = function(self)
            local activeEntry = MarkerCreator.ActiveMarkersByID[id]
            if activeEntry then
                unloadActiveMarker(id)
            end
            if entry.insideInteract then
                entry.insideInteract = false
                if entry.onExit then entry.onExit(entry) end
            end
        end,
        nearby = function(self)
            if self.currentDistance < interactDist then
                if not entry.insideInteract then
                    entry.insideInteract = true
                    if entry.onEnter then entry.onEnter(entry) end
                end
            else
                if entry.insideInteract then
                    entry.insideInteract = false
                    if entry.onExit then entry.onExit(entry) end
                end
            end
        end
    })

    entry.point = point
    MarkerCreator.Registry[id] = entry

    return entry
end

function MarkerCreator.rmMarker(id)
    local entry = MarkerCreator.Registry[id]
    if entry then
        local activeEntry = MarkerCreator.ActiveMarkersByID[id]
        if activeEntry then
            unloadActiveMarker(id)
        end

        if entry.insideInteract then
            entry.insideInteract = false
            if entry.onExit then entry.onExit(entry) end
        end

        entry.point:remove()
        MarkerCreator.Registry[id] = nil
        return true
    end
    return false
end

exports('addMarker', MarkerCreator.addMarker)
exports('rmMarker', MarkerCreator.rmMarker)
exports('updateMarker', function(id, newData)
    if MarkerCreator.rmMarker(id) then
        newData.id = id
        return MarkerCreator.addMarker(newData)
    end
    return nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    for id, entry in pairs(MarkerCreator.Registry) do
        if entry.invoker == resourceName then
            MarkerCreator.rmMarker(id)
        end
    end
end)

return MarkerCreator
