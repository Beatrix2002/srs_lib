local THRESHOLD = 50
local Linear = require('libs.weightedRandom.shared_linear')
local Binary = require('libs.weightedRandom.shared_binary')

local WeightedRandom = {}

function WeightedRandom.create(items, resetOnEmpty, id)
    if type(items) ~= 'table' then
        error('WeightedRandom.create - items must be a table')
    end
    
    local itemCount = 0
    for _ in pairs(items) do
        itemCount = itemCount + 1
    end
    
    if itemCount > THRESHOLD then
        return Binary.create(items, resetOnEmpty, id)
    end

    return Linear.create(items, resetOnEmpty, id)
end

function WeightedRandom.getById(id)
    return Linear.getById(id) or Binary.getById(id)
end

function WeightedRandom.clearById(id)
    Linear.clearById(id)
    Binary.clearById(id)
end

function WeightedRandom.clearAll()
    Linear.clearAll()
    Binary.clearAll()
end

return WeightedRandom
