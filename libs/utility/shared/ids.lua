local Ids = {}

Ids.CreateUniqueId = function(tbl, len, pattern)
    tbl = tbl or {}
    len = len or 8

    local id = ""
    for i = 1, len do
        local char
        if pattern then
            local charIndex = math.random(1, #pattern)
            char = pattern:sub(charIndex, charIndex)
        else
            if math.random(1, 2) == 1 then
                char = string.char(math.random(65, 90))
            else
                char = string.format('%d', math.random(10) - 1)
            end
        end
        id = id .. char
    end

    if tbl[id] then
        return Ids.CreateUniqueId(tbl, len, pattern)
    end

    return id
end

Ids.RandomUpper = function(tbl, len)
    return Ids.CreateUniqueId(tbl, len, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')
end

Ids.RandomLower = function(tbl, len)
    return Ids.CreateUniqueId(tbl, len, 'abcdefghijklmnopqrstuvwxyz')
end

Ids.RandomString = function(tbl, len)
    return Ids.CreateUniqueId(tbl, len, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
end

Ids.RandomNumber = function(tbl, len)
    return Ids.CreateUniqueId(tbl, len, '0123456789')
end

Ids.Random = function(tbl, len)
    return Ids.CreateUniqueId(tbl, len)
end

return Ids
