--[[
    Adapted from community_bridge
    https://github.com/The-Order-Of-The-Hat/community_bridge

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 The Order Of The Hat
]]

local Anim = {}
local active = {}
local running = false
local nextId = 0

local function createId()
    repeat
        nextId += 1
    until not active[nextId]

    return nextId
end

local function requestDict(animDict)
    if type(animDict) ~= 'string' then
        return false
    end

    return srs.lib.requestAnimDict(animDict) ~= nil
end

local function updateLoop()
    if running then return end
    running = true

    CreateThread(function()
        while running do
            local ids = {}
            for id in pairs(active) do
                ids[#ids + 1] = id
            end

            if #ids == 0 then
                Wait(750)
            else
                for i = 1, #ids do
                    local id = ids[i]
                    local animData = active[id]

                    if animData then
                        local entity = animData.entity
                        local onComplete = animData.onComplete

                        if not DoesEntityExist(entity) then
                            if onComplete then onComplete(false, 'despawned') end
                            active[id] = nil
                        elseif animData.status == 'pending_task' then
                            TaskPlayAnim(entity, animData.animDict, animData.animName, animData.blendIn, animData.blendOut,
                                animData.duration, animData.flag, animData.playbackRate, false, false, false)
                            animData.startTime = GetGameTimer()
                            animData.animEndTime = animData.duration > 0 and (animData.startTime + animData.duration) or -1
                            animData.status = 'playing'
                        elseif animData.status == 'playing' then
                            local completed = false

                            if animData.duration == -1 then
                                if not IsEntityPlayingAnim(entity, animData.animDict, animData.animName, 3)
                                    and GetEntityAnimCurrentTime(entity, animData.animDict, animData.animName) > 0.8 then
                                    completed = true
                                end
                            elseif animData.animEndTime ~= -1 and GetGameTimer() >= animData.animEndTime then
                                completed = true
                            end

                            if completed then
                                if onComplete then onComplete(true, 'completed') end
                                active[id] = nil
                            end
                        end
                    end
                end
                Wait(100)
            end

            if next(active) == nil then
                running = false
            end
        end
    end)
end

function Anim.play(id, entity, animDict, animName, blendIn, blendOut, duration, flag, playbackRate, onComplete)
    local newId = id or createId()

    if active[newId] then
        if onComplete then onComplete(false, 'id_in_use') end
        return newId
    end

    if not entity or not DoesEntityExist(entity) or not IsEntityAPed(entity) then
        if onComplete then onComplete(false, 'invalid_entity') end
        return nil
    end

    if not requestDict(animDict) then
        if onComplete then onComplete(false, 'dict_load_failed') end
        return nil
    end

    active[newId] = {
        entity = entity,
        animDict = animDict,
        animName = animName,
        blendIn = blendIn or 8.0,
        blendOut = blendOut or -8.0,
        duration = duration or -1,
        flag = flag or 1,
        playbackRate = playbackRate or 0.0,
        onComplete = onComplete,
        status = 'pending_task',
        startTime = 0,
        animEndTime = 0,
    }

    updateLoop()
    return newId
end

function Anim.stop(id)
    if not id or not active[id] then
        return false
    end

    local animData = active[id]

    if animData.entity and DoesEntityExist(animData.entity) and IsEntityAPed(animData.entity) then
        if animData.status == 'playing' or animData.status == 'pending_task' then
            StopAnimTask(animData.entity, animData.animDict, animData.animName, 1.0)
        end
    end

    if animData.onComplete then
        animData.onComplete(false, 'stopped_by_id')
    end

    active[id] = nil
    return true
end

srs.lib.anim = Anim

return Anim
