--[[
    Based on ox_lib callbacks
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local registeredCallbacks = {}

AddEventHandler('onResourceStop', function(resourceName)
    if srs.cache.resource == resourceName then return end

    for callbackName, resource in pairs(registeredCallbacks) do
        if resource == resourceName then
            registeredCallbacks[callbackName] = nil
        end
    end
end)

---@param callbackName string
---@param isValid boolean
function srs.setValidCallback(callbackName, isValid)
    local resourceName = GetInvokingResource() or srs.cache.resource
    local callbackResource = registeredCallbacks[callbackName]

    if callbackResource then
        if not isValid then
            callbackResource[callbackName] = nil
            return
        end

        if callbackResource == resourceName then return end

        local errMessage = ("^1resource '%s' attempted to overwrite callback '%s' owned by resource '%s'^0")
            :format(resourceName, callbackName, callbackResource)

        return print(('^1SCRIPT ERROR: %s^0\n%s'):format(errMessage,
            Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
    end

    srs.lib.print.verbose(("set valid callback '%s' for resource '%s'"):format(callbackName, resourceName))

    registeredCallbacks[callbackName] = resourceName
end

function srs.isCallbackValid(callbackName)
    return registeredCallbacks[callbackName] == GetInvokingResource() or srs.cache.resource
end

local cbEvent = '__srs_cb_%s'

RegisterNetEvent('srs_lib:validateCallback', function(callbackName, invokingResource, key)
    if registeredCallbacks[callbackName] then return end

    local event = cbEvent:format(invokingResource)

    if srs.cache.game == 'fxserver' then
        return TriggerClientEvent(event, source, key, 'cb_invalid')
    end

    TriggerServerEvent(event, key, 'cb_invalid')
end)
