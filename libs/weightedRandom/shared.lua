local THRESHOLD = 50

local WeightedRandom = {}

function WeightedRandom.create(items, resetOnEmpty, id)
    if type(items) ~= 'table' then
        error('WeightedRandom.create - items must be a table')
    end
    
    local itemCount = 0
    for _ in pairs(items) do
        itemCount = itemCount + 1
    end
    
    if itemCount >= THRESHOLD then
        return srs.WeightedRandom.Binary.create(items, resetOnEmpty, id)
    else
        return srs.WeightedRandom.Linear.create(items, resetOnEmpty, id)
    end
end

function WeightedRandom.getById(id)
    return srs.WeightedRandom.Linear.getById(id) or srs.WeightedRandom.Binary.getById(id)
end

function WeightedRandom.clearById(id)
    srs.WeightedRandom.Linear.clearById(id)
    srs.WeightedRandom.Binary.clearById(id)
end

function WeightedRandom.clearAll()
    srs.WeightedRandom.Linear.clearAll()
    srs.WeightedRandom.Binary.clearAll()
end

srs.WeightedRandom.create = WeightedRandom.create
srs.WeightedRandom.getById = WeightedRandom.getById
srs.WeightedRandom.clearById = WeightedRandom.clearById
srs.WeightedRandom.clearAll = WeightedRandom.clearAll

exports('WeightedRandom', function()
    return srs.WeightedRandom
end)
