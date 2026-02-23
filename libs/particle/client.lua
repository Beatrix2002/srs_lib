--[[
    Adapted from community_bridge
    https://github.com/The-Order-Of-The-Hat/community_bridge

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 The Order Of The Hat
]]

local Particle = {}
local active = {}
local assets = {}

local function useAsset(dict)
    if type(dict) ~= 'string' then return false end

    local data = assets[dict]
    if data then
        data.count = data.count + 1
        return true
    end

    if not srs.lib.requestNamedPtfxAsset(dict) then
        return false
    end

    assets[dict] = { count = 1 }
    return true
end

local function releaseAsset(dict)
    local data = assets[dict]
    if not data then return end

    data.count = data.count - 1
    if data.count <= 0 then
        RemoveNamedPtfxAsset(dict)
        assets[dict] = nil
    end
end

local function track(handle, dict, looped)
    if not handle or handle == 0 then return nil end
    local id = tostring(handle)
    active[id] = {
        handle = handle,
        dict = dict,
        looped = looped,
    }
    return id
end

function Particle.Stop(handleOrId)
    if not handleOrId then return end
    local id = tostring(handleOrId)
    local data = active[id]
    local handle = data and data.handle or handleOrId

    if data and data.looped and DoesParticleFxLoopedExist(handle) then
        StopParticleFxLooped(handle, false)
    end

    RemoveParticleFx(handle, false)

    if data then
        releaseAsset(data.dict)
        active[id] = nil
    end
end

function Particle.Play(dict, ptfx, pos, rot, scale, color, looped, removeAfter)
    if not useAsset(dict) then return nil end

    UseParticleFxAssetNextCall(dict)

    local handle
    scale = scale or 1.0
    rot = rot or vec3(0.0, 0.0, 0.0)

    if looped then
        handle = StartParticleFxLoopedAtCoord(ptfx, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, scale, false, false, false, false)
        if handle == 0 then
            releaseAsset(dict)
            return nil
        end

        if color then
            SetParticleFxLoopedColour(handle, color.x, color.y, color.z)
        end

        local id = track(handle, dict, true)
        if removeAfter and removeAfter > 0 then
            SetTimeout(removeAfter, function()
                Particle.Stop(id)
            end)
        end

        return id
    end

    if color then
        SetParticleFxNonLoopedColour(color.x, color.y, color.z)
    end

    handle = StartParticleFxNonLoopedAtCoord(ptfx, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, scale, false, false, false, false)
    releaseAsset(dict)
    return handle
end

function Particle.CreateOnEntity(dict, ptfx, entity, offset, rot, scale, color, looped, loopLength)
    if not useAsset(dict) then return nil end

    UseParticleFxAssetNextCall(dict)
    scale = scale or 1.0
    offset = offset or vec3(0.0, 0.0, 0.0)
    rot = rot or vec3(0.0, 0.0, 0.0)

    local handle
    if looped then
        handle = StartNetworkedParticleFxLoopedOnEntity(ptfx, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale, false, false, false)
        if color then
            SetParticleFxLoopedColour(handle, color.x, color.y, color.z)
        end

        local id = track(handle, dict, true)
        if loopLength and loopLength > 0 then
            SetTimeout(loopLength, function()
                Particle.Stop(id)
            end)
        end
        return id
    end

    if color then
        SetParticleFxNonLoopedColour(color.x, color.y, color.z)
    end

    handle = StartNetworkedParticleFxNonLoopedOnEntity(ptfx, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale, false, false, false)
    releaseAsset(dict)
    return handle
end

function Particle.CreateOnEntityBone(dict, ptfx, entity, bone, offset, rot, scale, color, looped, loopLength)
    if not useAsset(dict) then return nil end

    UseParticleFxAssetNextCall(dict)
    scale = scale or 1.0
    offset = offset or vec3(0.0, 0.0, 0.0)
    rot = rot or vec3(0.0, 0.0, 0.0)

    local handle
    if looped then
        handle = StartNetworkedParticleFxLoopedOnEntityBone(ptfx, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, bone, scale, false, false, false)
        if color then
            SetParticleFxLoopedColour(handle, color.x, color.y, color.z)
        end

        local id = track(handle, dict, true)
        if loopLength and loopLength > 0 then
            SetTimeout(loopLength, function()
                Particle.Stop(id)
            end)
        end
        return id
    end

    if color then
        SetParticleFxNonLoopedColour(color.x, color.y, color.z)
    end

    handle = StartNetworkedParticleFxNonLoopedOnEntityBone(ptfx, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, bone, scale, false, false, false)
    releaseAsset(dict)
    return handle
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(active) do
        Particle.Stop(id)
    end
end)

srs.lib.Particle = Particle

return Particle
