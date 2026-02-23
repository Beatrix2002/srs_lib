Behaviors = {
    registry = {}
}

function Behaviors.register(name, fn)
    if not name or not fn then return end
    Behaviors.registry[name] = fn
end

function Behaviors.unregister(name)
    Behaviors.registry[name] = nil
end

function Behaviors.trigger(name, entity, event, params, ...)
    local handler = Behaviors.registry[name]
    if not handler then return end
    return handler(entity, event, params, ...)
end

exports('registerEntityBehavior', Behaviors.register)
exports('unregisterEntityBehavior', Behaviors.unregister)
exports('triggerEntityBehavior', Behaviors.trigger)

return Behaviors