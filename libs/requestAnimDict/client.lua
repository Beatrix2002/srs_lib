--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright (c) 2025 Linden <https://github.com/thelindat>
]]

function srs.lib.requestAnimDict(animDict, timeout)
    if HasAnimDictLoaded(animDict) then return animDict end

    if type(animDict) ~= 'string' then
        error(("expected animDict to have type 'string' (received %s)"):format(type(animDict)))
    end

    if not DoesAnimDictExist(animDict) then
        error(("attempted to load invalid animDict '%s'"):format(animDict))
    end

    return srs.lib.streamingRequest(RequestAnimDict, HasAnimDictLoaded, 'animDict', animDict, timeout)
end

return srs.lib.requestAnimDict
