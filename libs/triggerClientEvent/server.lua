--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local lib = srs.lib

function lib.triggerClientEvent(eventName, targetIds, ...)
    local payload = msgpack.pack_args(...)
    local payloadLen = #payload

    if lib.array.isArray(targetIds) then
        for i = 1, #targetIds do
            TriggerClientEventInternal(eventName, targetIds[i] --[[@as string]], payload, payloadLen)
        end

        return
    end

    TriggerClientEventInternal(eventName, targetIds --[[@as string]], payload, payloadLen)
end

return lib.triggerClientEvent
