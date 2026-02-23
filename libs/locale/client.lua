--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local lib = srs.lib
local cache = srs.cache
local currentLocale = GetConvar('ox:locale', 'en')

local function loadLocaleFile(key)
    local file = LoadResourceFile(cache.resource, ('locales/%s.json'):format(key))
        or LoadResourceFile(cache.resource, 'locales/en.json')

    return file and json.decode(file) or {}
end

function lib.getLocaleKey() return currentLocale end

---@param key string
function lib.setLocale(key)
    currentLocale = key
    TriggerEvent('srs_lib:setLocale', key)
    SendNUIMessage({
        action = 'setLocale',
        data = loadLocaleFile(key)
    })
end

RegisterNUICallback('init', function(_, cb)
    cb(1)

    SendNUIMessage({
        action = 'setLocale',
        data = loadLocaleFile(currentLocale)
    })
end)

    lib.locale(currentLocale)
