local function RoundFloat(value)
    return tonumber(string.format('%.2f', value))
end

local ActiveTimers = {}
local TimerCounter = 0

local Timer = {}
Timer.__index = Timer


function Timer.new(durationMs, onEnd, id)
    durationMs = tonumber(durationMs)
    if id then
        id = tostring(id)
        if ActiveTimers[id] then
            error('Timer with ID "' .. id .. '" already exists.')
        end
    end
    if not durationMs or durationMs <= 0 then
        error('Invalid duration for Timer: ' .. tostring(durationMs))
    end

    TimerCounter += 1
    local id = tostring(id or TimerCounter)
    local self = setmetatable({}, Timer)
    self.id = tostring(id or TimerCounter)
    self.finished = false
    self.onEnd = onEnd
    local now = GetGameTimer()
    self.endTime = now + durationMs
    self.startTime = now
    self.invoker = GetInvokingResource() or GetCurrentResourceName()

    ActiveTimers[self.id] = self

    SetTimeout(durationMs, function()
        if not ActiveTimers[self.id] or self.finished then return end
        self.finished = true
        if self.onEnd then
            local success, err = pcall(self.onEnd)
            if not success then
                print(('[Timer] Callback error (ID: %s): %s'):format(self.id, err))
            end
        end
        ActiveTimers[self.id] = nil
    end)

    return self
end

function Timer:ForceEnd(triggerCallback)
    local state = ActiveTimers[self.id]
    if not state or state.finished then return false end
    
    state.finished = true
    
    if triggerCallback and state.onEnd then
        local success, err = pcall(state.onEnd)
        if not success then
            print(('[Timer] Callback error (ID: %s): %s'):format(self.id, err))
        end
    end
    
    ActiveTimers[self.id] = nil
    return true
end

-- getters

function Timer:IsFinished()
    local state = ActiveTimers[self.id]
    return not state or state.finished
end

function Timer:IsActive()
    local state = ActiveTimers[self.id]
    return state and not state.finished
end

function Timer:GetTimeLeft(format)
    local state = ActiveTimers[self.id]
    if not state or self.finished then return 0 end
    
    local ms = math.max(0, state.endTime - GetGameTimer())
    format = format or 'ms'
    
    if format == 'ms' then
        return RoundFloat(ms)
    elseif format == 's' then
        return RoundFloat(ms / 1000)
    elseif format == 'm' then
        return RoundFloat(ms / 60000)
    elseif format == 'h' then
        return RoundFloat(ms / 3600000)
    end
    
    return RoundFloat(ms)
end

function Timer:GetEndTime()
    local state = ActiveTimers[self.id]
    return state and state.endTime or nil
end

-- static getters
function Timer.GetActiveTimers()
    return ActiveTimers
end

function Timer.GetActiveTimerCount()
    local count = 0
    for _ in pairs(ActiveTimers) do count += 1 end
    return count
end

function Timer.GetTimerById(id)
    return ActiveTimers[tostring(id)]
end

function Timer.ClearTimers(triggerCallbacks, resourceName)
    if not resourceName and not triggerCallbacks then
        ActiveTimers = {}
        return
    end

    for timerId, state in pairs(ActiveTimers) do
        if not resourceName or state.invoker == resourceName then
            state.finished = true
            
            if triggerCallbacks and state.onEnd then
                local success, err = pcall(state.onEnd)
                if not success then
                    print(('[Timer] Callback error during clear (ID: %s): %s'):format(timerId, err))
                end
            end
            
            ActiveTimers[timerId] = nil
        end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    Timer.ClearTimers(false, resourceName)
end)

local SRS_Timer = {
    Create = Timer.new,
    GetActiveTimers = Timer.GetActiveTimers,
    GetActiveTimerCount = Timer.GetActiveTimerCount,
    GetTimerById = Timer.GetTimerById,
    ClearTimers = Timer.ClearTimers,
}

exports('Timer', function()
    return SRS_Timer
end)

return SRS_Timer





