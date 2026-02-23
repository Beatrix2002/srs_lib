--[[
    Adapted from community_bridge
    https://github.com/The-Order-Of-The-Hat/community_bridge

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 The Order Of The Hat
]]

local Shells = srs.lib.shells or {}

Shells.Targets = Shells.Targets or {
    entrance = {
        enter = {
            label = 'Enter',
            icon = 'fa-solid fa-door-open',
            onSelect = function(_, shellId, objectId)
                TriggerServerEvent('srs_lib:shells:enter', shellId, objectId)
            end
        },
    },
    exit = {
        leave = {
            label = 'Exit',
            icon = 'fa-solid fa-door-closed',
            onSelect = function(_, shellId, objectId)
                TriggerServerEvent('srs_lib:shells:exit', shellId, objectId)
            end
        }
    }
}

Shells.Target = Shells.Target or {}

function Shells.Target.set(shellType, options)
    assert(shellType, "Shells.Target.set: 'shellType' is required")
    options = options or {}

    for key, value in pairs(options) do
        if Shells.Targets[shellType] and Shells.Targets[shellType][key] then
            value.onSelect = Shells.Targets[shellType][key].onSelect
        end
        Shells.Targets[shellType] = Shells.Targets[shellType] or {}
        Shells.Targets[shellType][key] = value
    end
    return true
end

function Shells.Target.get(shellType, shellId, objectId)
    local options = {}

    for _, value in pairs(Shells.Targets[shellType] or {}) do
        local onSelect = value.onSelect
        value.onSelect = function(entity)
            onSelect(entity, shellId, objectId)
        end
        options[#options + 1] = value
    end

    return options
end

srs.lib.shells = Shells

return Shells
