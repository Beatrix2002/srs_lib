local Bank = {}

local math_floor = math.floor
local math_abs = math.abs
local qbx = exports.qbx_core

local function toAmount(value)
    local n = tonumber(value) or 0
    n = math_floor(n)
    return n
end

local function getPlayerSafe(source)
    if not source then return nil end
    if type(source) == 'table' then return source end -- source is a player object
    return qbx:GetPlayer(source)
end

local function getIdentifier(source)
    if not source then return nil end
    
    -- If source is a number, return it directly
    if type(source) == 'number' then
        return source
    end
    
    -- If source is a Player object, extract identifier
    if type(source) == 'table' then
        -- Prefer source (for online players)
        if source.PlayerData and source.PlayerData.source then
            return source.PlayerData.source
        end
        -- Fallback to citizenid
        if source.PlayerData and source.PlayerData.citizenid then
            return source.PlayerData.citizenid
        end
    end
    
    return nil
end

function Bank.AddBank(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    return qbx:AddMoney(identifier, 'bank', amount)
end

function Bank.AddCash(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    return qbx:AddMoney(identifier, 'cash', amount)
end

function Bank.RemoveBank(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    return qbx:RemoveMoney(identifier, 'bank', amount)
end

function Bank.RemoveCash(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end
    return qbx:RemoveMoney(identifier, 'cash', amount)
end

function Bank.AddMoneyByType(source, type, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end

    if type == 'bank' then
        return qbx:AddMoney(identifier, 'bank', amount)
    elseif type == 'cash' then
        return qbx:AddMoney(identifier, 'cash', amount)
    end

    return false
end

function Bank.RemoveMoneyByType(source, type, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local identifier = getIdentifier(source)
    if not identifier then return false end

    if type == 'bank' then
        return qbx:RemoveMoney(identifier, 'bank', amount)
    elseif type == 'cash' then
        return qbx:RemoveMoney(identifier, 'cash', amount)
    end

    return false
end

function Bank.GetBank(source)
    local Player = getPlayerSafe(source)
    if not Player then return 0 end
    return Player.PlayerData.money['bank'] or 0
end

function Bank.GetCash(source)
    local Player = getPlayerSafe(source)
    if not Player then return 0 end
    return Player.PlayerData.money['cash'] or 0
end

function Bank.GetMoney(source, type)
    local Player = getPlayerSafe(source)
    if not Player then return 0 end

    if type == 'bank' then
        return Player.PlayerData.money['bank'] or 0
    elseif type == 'cash' then
        return Player.PlayerData.money['cash'] or 0
    end

    return 0
end

return Bank
