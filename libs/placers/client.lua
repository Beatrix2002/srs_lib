--[[
    Adapted from community_bridge
    https://github.com/The-Order-Of-The-Hat/community_bridge

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 The Order Of The Hat
]]

local Placer = {}
local activePlacementProp

local function finishPlacing()
    if srs.bridge.Notify and srs.bridge.Notify.HideHelpText then
        srs.bridge.Notify.HideHelpText()
    else
        ClearAllHelpMessages()
    end

    if not activePlacementProp then return end

    DeleteObject(activePlacementProp)
    activePlacementProp = nil
end

function Placer.placeObject(object, distance, snapToGround, allowedMats, offset)
    distance = tonumber(distance or 10.0)
    if activePlacementProp then return end

    if not object then
        print('placeObject: object is required')
        return nil, nil
    end

    local propObject = type(object) == 'string' and joaat(object) or object
    local heading = 0.0
    local checkDist = distance or 10.0
    local ped = PlayerPedId()

    srs.lib.requestModel(propObject)

    activePlacementProp = CreateObject(propObject, 1.0, 1.0, 1.0, false, true, true)
    SetModelAsNoLongerNeeded(propObject)
    SetEntityAlpha(activePlacementProp, 150, false)
    SetEntityCollision(activePlacementProp, false, false)
    SetEntityInvincible(activePlacementProp, true)
    FreezeEntityPosition(activePlacementProp, true)

    if srs.bridge.Notify and srs.bridge.Notify.ShowHelpText then
        srs.bridge.Notify.ShowHelpText('~INPUT_PICKUP~ Place  ~INPUT_FRONTEND_RRIGHT~ Cancel  ~INPUT_CELLPHONE_SCROLL_FORWARD~ Rotate +  ~INPUT_CELLPHONE_SCROLL_BACKWARD~ Rotate -')
    end

    local outLine = false

    while activePlacementProp do
        local hit, _, coords, _, materialHash = srs.lib.raycast.fromCamera(1, 4)

        if hit then
            if offset then
                coords = coords + offset
            end

            SetEntityCoords(activePlacementProp, coords.x, coords.y, coords.z, false, false, false, false)
            local distCheck = #(GetEntityCoords(ped) - coords)
            SetEntityHeading(activePlacementProp, heading)

            if snapToGround then
                PlaceObjectOnGroundProperly(activePlacementProp)
            end

            if outLine then
                outLine = false
                SetEntityDrawOutline(activePlacementProp, false)
            end

            if (allowedMats and not allowedMats[materialHash]) or distCheck >= checkDist then
                if not outLine then
                    outLine = true
                    SetEntityDrawOutline(activePlacementProp, true)
                end
            end

            if IsControlJustReleased(0, 38) then
                if not outLine and (not allowedMats or allowedMats[materialHash]) and distCheck < checkDist then
                    finishPlacing()
                    return coords, heading
                end
            end

            if IsControlJustReleased(0, 73) then
                finishPlacing()
                return nil, nil
            end

            if IsControlJustReleased(0, 14) then
                heading = heading + 5
                if heading > 360 then heading = 0.0 end
            end

            if IsControlJustReleased(0, 15) then
                heading = heading - 5
                if heading < 0 then
                    heading = 360.0
                end
            end
        end

        Wait(0)
    end
end

function Placer.stopPlacing()
    finishPlacing()
end

srs.lib.placers = Placer

return Placer
