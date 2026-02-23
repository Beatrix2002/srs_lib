--[[
    Adapted from community_bridge
    https://github.com/The-Order-Of-The-Hat/community_bridge

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 The Order Of The Hat
]]

local Cutscene = {}
Cutscene.done = true

local LOAD_TIMEOUT = 10000
local FADE_DURATION = 1000
local CUTSCENE_WAIT = 1000

local characterTags = {
    { male = 'MP_1' },
    { male = 'MP_2' },
    { male = 'MP_3' },
    { male = 'MP_4' },
    { male = 'MP_Male_Character',   female = 'MP_Female_Character' },
    { male = 'MP_Male_Character_1', female = 'MP_Female_Character_1' },
    { male = 'MP_Male_Character_2', female = 'MP_Female_Character_2' },
    { male = 'MP_Male_Character_3', female = 'MP_Female_Character_3' },
    { male = 'MP_Male_Character_4', female = 'MP_Female_Character_4' },
    { male = 'MP_Plane_Passenger_1' },
    { male = 'MP_Plane_Passenger_2' },
    { male = 'MP_Plane_Passenger_3' },
    { male = 'MP_Plane_Passenger_4' },
    { male = 'MP_Plane_Passenger_5' },
    { male = 'MP_Plane_Passenger_6' },
    { male = 'MP_Plane_Passenger_7' },
    { male = 'MP_Plane_Passenger_8' },
    { male = 'MP_Plane_Passenger_9' },
}

local componentsToSave = {
    { name = 'head',        id = 0,  type = 'drawable' },
    { name = 'beard',       id = 1,  type = 'drawable' },
    { name = 'hair',        id = 2,  type = 'drawable' },
    { name = 'arms',        id = 3,  type = 'drawable' },
    { name = 'pants',       id = 4,  type = 'drawable' },
    { name = 'parachute',   id = 5,  type = 'drawable' },
    { name = 'feet',        id = 6,  type = 'drawable' },
    { name = 'accessories', id = 7,  type = 'drawable' },
    { name = 'undershirt',  id = 8,  type = 'drawable' },
    { name = 'vest',        id = 9,  type = 'drawable' },
    { name = 'decals',      id = 10, type = 'drawable' },
    { name = 'jacket',      id = 11, type = 'drawable' },
    { name = 'hat',         id = 0,  type = 'prop' },
    { name = 'glasses',     id = 1,  type = 'prop' },
    { name = 'ears',        id = 2,  type = 'prop' },
    { name = 'watch',       id = 3,  type = 'prop' },
    { name = 'bracelet',    id = 4,  type = 'prop' },
    { name = 'misc',        id = 5,  type = 'prop' },
    { name = 'left_wrist',  id = 6,  type = 'prop' },
    { name = 'right_wrist', id = 7,  type = 'prop' },
    { name = 'prop8',       id = 8,  type = 'prop' },
    { name = 'prop9',       id = 9,  type = 'prop' },
}

local function shallowCopy(source)
    local t = {}
    for k, v in pairs(source) do
        t[k] = v
    end
    return t
end

local function waitForModelLoad(modelHash)
    local timeout = GetGameTimer() + LOAD_TIMEOUT
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasModelLoaded(modelHash)
end

local function createPedFromModel(modelName, coords)
    local model = type(modelName) == 'number' and modelName or joaat(modelName)

    RequestModel(model)
    if not waitForModelLoad(model) then
        print(('Failed to load model: %s'):format(modelName))
        return nil
    end

    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, 0.0, true, false)
    if not DoesEntityExist(ped) then
        print(('Failed to create ped from model: %s'):format(modelName))
        return nil
    end

    SetModelAsNoLongerNeeded(model)
    return ped
end

local function loadCutscene(cutscene)
    assert(cutscene, 'Cutscene.Load called without a cutscene name.')
    local playbackList = IsPedMale(PlayerPedId()) and 31 or 103
    RequestCutsceneWithPlaybackList(cutscene, playbackList, 8)

    local timeout = GetGameTimer() + LOAD_TIMEOUT
    while not HasCutsceneLoaded() and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasCutsceneLoaded() then
        print(('Cutscene failed to load: %s'):format(cutscene))
        return false
    end

    return true
end

local function getCutsceneTags(cutscene)
    if not loadCutscene(cutscene) then return end

    StartCutscene(0)
    Wait(CUTSCENE_WAIT)

    local tags = {}
    for _, tag in pairs(characterTags) do
        if DoesCutsceneEntityExist(tag.male, 0) or DoesCutsceneEntityExist(tag.female, 0) then
            tags[#tags + 1] = tag
        end
    end

    StopCutsceneImmediately()
    Wait(CUTSCENE_WAIT * 2)
    return tags
end

local function savePedOutfit(ped)
    local outfitData = {}

    for _, component in ipairs(componentsToSave) do
        if component.type == 'drawable' then
            outfitData[component.name] = {
                id = component.id,
                type = component.type,
                drawable = GetPedDrawableVariation(ped, component.id),
                texture = GetPedTextureVariation(ped, component.id),
                palette = GetPedPaletteVariation(ped, component.id),
            }
        elseif component.type == 'prop' then
            outfitData[component.name] = {
                id = component.id,
                type = component.type,
                propIndex = GetPedPropIndex(ped, component.id),
                propTexture = GetPedPropTextureIndex(ped, component.id),
            }
        end
    end

    return outfitData
end

local function applyPedOutfit(ped, outfitData)
    if not outfitData or type(outfitData) ~= 'table' then
        print('ApplyPedOutfit: Invalid outfitData provided.')
        return
    end

    for _, data in pairs(outfitData) do
        if data.type == 'drawable' then
            SetPedComponentVariation(ped, data.id, data.drawable or 0, data.texture or 0, data.palette or 0)
        elseif data.type == 'prop' then
            if data.propIndex == -1 or data.propIndex == nil then
                ClearPedProp(ped, data.id)
            else
                SetPedPropIndex(ped, data.id, data.propIndex, data.propTexture or 0, true)
            end
        end
    end
end

function Cutscene.getTags(cutscene)
    return getCutsceneTags(cutscene)
end

function Cutscene.load(cutscene)
    return loadCutscene(cutscene)
end

function Cutscene.savePedOutfit(ped)
    return savePedOutfit(ped)
end

function Cutscene.applyPedOutfit(ped, outfitData)
    return applyPedOutfit(ped, outfitData)
end

function Cutscene.create(cutscene, coords, srcs)
    local lastCoords = coords or GetEntityCoords(PlayerPedId())
    DoScreenFadeOut(0)

    local tagsFromCutscene = getCutsceneTags(cutscene)
    if not loadCutscene(cutscene) then
        print(('Cutscene.Create: Failed to load cutscene %s'):format(cutscene))
        DoScreenFadeIn(0)
        return false
    end

    srcs = srcs or {}
    local clothes = {}
    local localped = PlayerPedId()

    local playersToProcess = { { ped = localped, identifier = 'localplayer', coords = lastCoords } }

    for i = 1, #srcs do
        local srcRaw = srcs[i]
        if type(srcRaw) == 'number' then
            if srcRaw and not DoesEntityExist(srcRaw) then
                local playerPed = GetPlayerPed(GetPlayerFromServerId(srcRaw))
                if DoesEntityExist(playerPed) then
                    local ped = ClonePed(playerPed, false, false, true)
                    playersToProcess[#playersToProcess + 1] = { ped = ped, identifier = 'player' }
                end
            else
                playersToProcess[#playersToProcess + 1] = { ped = srcRaw, identifier = 'user' }
            end
        elseif type(srcRaw) == 'string' then
            local ped = createPedFromModel(srcRaw, GetEntityCoords(localped))
            if ped then
                playersToProcess[#playersToProcess + 1] = { ped = ped, identifier = 'script' }
            end
        end
    end

    local availableTags = shallowCopy(tagsFromCutscene or {})
    local usedTags = {}
    local cleanupTags = {}

    for i = 1, #playersToProcess do
        local playerData = playersToProcess[i]
        local currentPed = playerData.ped
        if not currentPed or not DoesEntityExist(currentPed) then goto continue end

        local tagTable = table.remove(availableTags, 1)
        if not tagTable then
            print(('Cutscene.Create: No available tags for player %s'):format(playerData.identifier))
            break
        end

        local isPedMale = IsPedMale(currentPed)
        local tag = isPedMale and tagTable.male or tagTable.female
        local unusedTag = not isPedMale and tagTable.male or tagTable.female

        SetCutsceneEntityStreamingFlags(tag, 0, 1)
        RegisterEntityForCutscene(currentPed, tag, 0, GetEntityModel(currentPed), 64)
        SetCutscenePedComponentVariationFromPed(tag, currentPed, 0)

        clothes[tag] = {
            clothing = savePedOutfit(currentPed),
            ped = currentPed,
        }

        usedTags[#usedTags + 1] = tag
        if unusedTag then cleanupTags[#cleanupTags + 1] = unusedTag end

        ::continue::
    end

    for i = 1, #cleanupTags do
        local tag = cleanupTags[i]
        local ped = RegisterEntityForCutscene(0, tag, 3, 0, 64)
        if ped then
            SetEntityVisible(ped, false, false)
        end
    end

    for i = 1, #availableTags do
        local tag = availableTags[i]
        for _, tagType in pairs({ tag.male, tag.female }) do
            if tagType then
                local ped = RegisterEntityForCutscene(0, tagType, 3, 0, 64)
                if ped then
                    SetEntityVisible(ped, false, false)
                end
            end
        end
    end

    return {
        cutscene = cutscene,
        coords = coords,
        tags = usedTags,
        srcs = srcs,
        peds = playersToProcess,
        clothes = clothes,
    }
end

function Cutscene.start(cutsceneData)
    if not cutsceneData then
        print('Cutscene.Start: Cutscene data is nil.')
        return
    end

    DoScreenFadeIn(FADE_DURATION)
    Cutscene.done = false

    local clothes = cutsceneData.clothes
    local coords = cutsceneData.coords

    if coords then
        if type(coords) == 'boolean' then
            coords = GetEntityCoords(PlayerPedId())
        end
        StartCutsceneAtCoords(coords.x, coords.y, coords.z, 0)
    else
        StartCutscene(0)
    end

    Wait(100)

    for k, data in pairs(clothes) do
        local ped = data.ped
        if DoesEntityExist(ped) then
            SetCutscenePedComponentVariationFromPed(k, ped, 0)
            applyPedOutfit(ped, data.clothing)
        end
    end

    CreateThread(function()
        local lastCoords
        while not Cutscene.done do
            local coord = GetWorldCoordFromScreenCoord(0.5, 0.5)
            if not lastCoords or #(lastCoords - coord) > 100 then
                NewLoadSceneStartSphere(coord.x, coord.y, coord.z, 2000, 0)
                lastCoords = coord
            end
            Wait(500)
        end
    end)

    CreateThread(function()
        while not Cutscene.done do
            DisableAllControlActions(0)
            DisableFrontendThisFrame()
            Wait(3)
        end
    end)

    while not HasCutsceneFinished() and not Cutscene.done do
        Wait(0)
        if IsDisabledControlJustPressed(0, 200) then
            DoScreenFadeOut(FADE_DURATION)
            Wait(FADE_DURATION)
            StopCutsceneImmediately()
            Wait(500)
            Cutscene.done = true
            break
        end
    end

    DoScreenFadeIn(FADE_DURATION)
    for i = 1, #cutsceneData.peds do
        local playerData = cutsceneData.peds[i]
        local ped = playerData.ped
        if not ped or not DoesEntityExist(ped) then goto continue end

        if playerData.identifier == 'script' then
            DeleteEntity(ped)
        elseif playerData.identifier == 'localplayer' then
            SetEntityCoords(ped, playerData.coords.x, playerData.coords.y, playerData.coords.z, false, false, false, false)
        end
        ::continue::
    end

    Cutscene.done = true
end

srs.lib.cutscenes = Cutscene

return Cutscene
