--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright (c) 2025 Linden <https://github.com/thelindat>
]]

function srs.lib.requestWeaponAsset(weaponType, timeout, weaponResourceFlags, extraWeaponComponentFlags)
    if HasWeaponAssetLoaded(weaponType) then return weaponType end

    local weaponTypeType = type(weaponType)

    if weaponTypeType ~= 'string' and weaponTypeType ~= 'number' then
        error(("expected weaponType to have type 'string' or 'number' (received %s)"):format(weaponTypeType))
    end

    if weaponResourceFlags and type(weaponResourceFlags) ~= 'number' then
        error(("expected weaponResourceFlags to have type 'number' (received %s)"):format(type(weaponResourceFlags)))
    end

    if extraWeaponComponentFlags and type(extraWeaponComponentFlags) ~= 'number' then
        error(("expected extraWeaponComponentFlags to have type 'number' (received %s)"):format(type(extraWeaponComponentFlags)))
    end

    return srs.lib.streamingRequest(RequestWeaponAsset, HasWeaponAssetLoaded, 'weaponHash', weaponType, timeout, weaponResourceFlags or 31, extraWeaponComponentFlags or 0)
end

return srs.lib.requestWeaponAsset
