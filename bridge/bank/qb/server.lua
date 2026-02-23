local Bank = {}

local math_floor = math.floor
local math_abs = math.abs

local function toAmount(value)
    local n = tonumber(value) or 0
    n = math_floor(n)
    return n
end

local function getPlayerSafe(source)
    if not source then return nil end
    if type(source) == 'table' then return source end -- source is a player object
    return srs.bridge.GetPlayer(source)
end

function Bank.AddBank(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local Player = getPlayerSafe(source)
    if not Player then return false end
    return Player.Functions.AddMoney('bank', amount)
end

function Bank.AddCash(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local Player = getPlayerSafe(source)
    if not Player then return false end
    return Player.Functions.AddMoney('cash', amount)
end

function Bank.RemoveBank(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local Player = getPlayerSafe(source)
    if not Player then return false end
    return Player.Functions.RemoveMoney('bank', amount)
end

function Bank.RemoveCash(source, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local Player = getPlayerSafe(source)
    if not Player then return false end
    return Player.Functions.RemoveMoney('cash', amount)
end

function Bank.AddMoneyByType(source, type, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local Player = getPlayerSafe(source)
    if not Player then return false end

    if type == 'bank' then
        return Player.Functions.AddMoney('bank', amount)
    elseif type == 'cash' then
        return Player.Functions.AddMoney('cash', amount)
    end

    return false
end

function Bank.RemoveMoneyByType(source, type, value)
    local amount = math_abs(toAmount(value))
    if amount <= 0 then return false end
    local Player = getPlayerSafe(source)
    if not Player then return false end

    if type == 'bank' then
        return Player.Functions.RemoveMoney('bank', amount)
    elseif type == 'cash' then
        return Player.Functions.RemoveMoney('cash', amount)
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