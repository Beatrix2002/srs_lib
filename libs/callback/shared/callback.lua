local Callback = {}

if IsDuplicityVersion() then
    function Callback.Register(name, handler)
        return srs.callback.register(name, handler)
    end

    function Callback.Trigger(name, target, ...)
        local args = { ... }
        local cb = type(args[1]) == 'function' and table.remove(args, 1) or nil

        if type(target) == 'table' then
            for i = 1, #target do
                local playerId = tonumber(target[i])
                if playerId then
                    if cb then
                        srs.callback(name, playerId, cb, table.unpack(args))
                    else
                        srs.callback.await(name, playerId, table.unpack(args))
                    end
                end
            end
            return
        end

        local playerId = tonumber(target) or -1

        if cb then
            return srs.callback(name, playerId, cb, table.unpack(args))
        end

        return srs.callback.await(name, playerId, table.unpack(args))
    end
else
    local reboundCallbacks = {}

    function Callback.Register(name, handler)
        return srs.callback.register(name, handler)
    end

    function Callback.RegisterRebound(name, handler)
        reboundCallbacks[name] = handler
    end

    function Callback.Trigger(name, ...)
        local args = { ... }
        local cb = type(args[1]) == 'function' and table.remove(args, 1) or nil

        if cb then
            return srs.callback(name, false, function(...)
                local rebound = reboundCallbacks[name]
                if rebound then rebound(...) end
                cb(...)
            end, table.unpack(args))
        end

        local response = { srs.callback.await(name, false, table.unpack(args)) }
        local rebound = reboundCallbacks[name]

        if rebound then
            rebound(table.unpack(response))
        end

        return table.unpack(response)
    end
end

return Callback
