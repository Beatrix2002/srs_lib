local Network = {}
local POLL_WAIT = IsDuplicityVersion() and 50 or 0

function Network.GetEntityFromNetId(netId)
    local deadline = GetGameTimer() + 5000
    while GetGameTimer() < deadline do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) then
            return entity
        end
        Wait(POLL_WAIT)
    end
    return nil
end

function Network.GetNetIdFromEntity(handle)
    local deadline = GetGameTimer() + 5000
    while GetGameTimer() < deadline do
        local netId = NetworkGetNetworkIdFromEntity(handle)
        if netId and netId ~= 0 then
            return netId
        end
        Wait(POLL_WAIT)
    end
    return nil
end

if IsDuplicityVersion() then
    Network.WaitForCreate = function(handle, deadlineTime)
        local deadline = GetGameTimer() + (deadlineTime or 5000)
        while not DoesEntityExist(handle) do
            Wait(50)
            if GetGameTimer() > deadline then
                print("EntityUtils: WaitForCreate timed out")
                return false
            end
        end
        return true
    end
else
    function Network.RequestControlOfEntity(handle)
        local deadline = GetGameTimer() + 5000
        while GetGameTimer() < deadline do
            if NetworkHasControlOfEntity(handle) then
                return true
            end
            NetworkRequestControlOfEntity(handle)
            Wait(0)
        end
        return false
    end
end

return Network
