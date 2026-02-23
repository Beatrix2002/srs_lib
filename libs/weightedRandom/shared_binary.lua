-- Credit: ox_lib community, modified 
-- Binary Search + Prefix Sum implementation (O(log N)) - Recommended for large lists (50+ items)

local deepclone = srs.lib.table.deepclone
local RandomWeightedBinary = srs.lib.class('RandomWeightedBinary')
local RandomLists = {}
local counter = 0

-- Helper: Binary Search
local function binarySearch(items, target, min, max)
    local low, high = min, max
    while low <= high do
        local mid = math.floor((low + high) / 2)
        local item = items[mid]
        
        if item.cumulative >= target then
            if mid == 1 or items[mid-1].cumulative < target then
                return mid
            end
            high = mid - 1
        else
            low = mid + 1
        end
    end
    return low
end

RandomWeightedBinary.create = function(items, resetOnEmpty, id)
    if type(items) ~= 'table' then
        error('RandomWeightedBinary.create - items must be a table')
    end
    return RandomWeightedBinary:new(items, resetOnEmpty, id)
end

function RandomWeightedBinary:constructor(items, resetOnEmpty, id)
    counter = counter + 1
    self.id = tostring(id or counter)
    
    self.originalTemplate = deepclone(items)
    self.items = {} 
    self.resetOnEmpty = resetOnEmpty == nil and true or resetOnEmpty
    self.totalWeight = 0
    self.itemCount = 0
    self.lastSelected = nil
    
    self:_rebuild()
    RandomLists[self.id] = self
    return self
end

function RandomWeightedBinary:_rebuild()
    local list = {}
    local total = 0
    local count = 0
    
    for k, v in pairs(self.originalTemplate) do
        local w = tonumber(v.weight)
        if w and w > 0 then
            total = total + w
            count = count + 1
            list[count] = {
                cumulative = total,
                weight = w,
                key = k,
                data = v
            }
        end
    end
    
    self.items = list
    self.totalWeight = total
    self.itemCount = count
end

function RandomWeightedBinary:getItem(remove, count)
    local num = count or 1
    local selectedItems = {}

    if self.itemCount == 0 then
        if self.resetOnEmpty then
            self:_rebuild()
            if self.itemCount == 0 then
                return num > 1 and {} or nil
            end
        else
            return num > 1 and {} or nil
        end
    end

    for i = 1, num do
        if self.itemCount == 0 then
            if self.resetOnEmpty then
                self:_rebuild()
                if self.itemCount == 0 then break end
            else
                break
            end
        end
        
        local rand = math.random() * self.totalWeight
        local index = binarySearch(self.items, rand, 1, self.itemCount)
        local selected = self.items[index]
        
        if selected then
            local result = { key = selected.key, item = selected.data }
            selectedItems[#selectedItems + 1] = result
            self.lastSelected = result
            
            if remove then
                local removedWeight = selected.weight
                
                for j = index + 1, self.itemCount do
                    self.items[j].cumulative = self.items[j].cumulative - removedWeight
                end
                
                table.remove(self.items, index)
                self.totalWeight = self.totalWeight - removedWeight
                self.itemCount = self.itemCount - 1
            end
        end
    end

    return num > 1 and selectedItems or selectedItems[1]
end

function RandomWeightedBinary:reset()
    self:_rebuild()
end

function RandomWeightedBinary:addItem(key, item)
    if type(item) ~= 'table' or type(item.weight) ~= 'number' or item.weight <= 0 then
        error('RandomWeightedBinary:addItem - item must be a table with positive weight')
    end
    
    self.originalTemplate[key] = item
    
    self.totalWeight = self.totalWeight + item.weight
    self.itemCount = self.itemCount + 1
    
    self.items[self.itemCount] = {
        cumulative = self.totalWeight,
        weight = item.weight,
        key = key,
        data = item
    }
end

function RandomWeightedBinary:removeItem(key)
    for i = 1, self.itemCount do
        if self.items[i].key == key then
            local removedWeight = self.items[i].weight
            
            for j = i + 1, self.itemCount do
                self.items[j].cumulative = self.items[j].cumulative - removedWeight
            end
            
            self.totalWeight = self.totalWeight - removedWeight
            table.remove(self.items, i)
            self.itemCount = self.itemCount - 1
            self.originalTemplate[key] = nil
            return true
        end
    end
    return false
end

function RandomWeightedBinary:destroy()
    self.items = nil
    self.originalTemplate = nil
    self.totalWeight = nil
    self.itemCount = nil
    self.lastSelected = nil
    RandomLists[self.id] = nil
end

function RandomWeightedBinary.getById(id)
    return RandomLists[tostring(id)]
end

function RandomWeightedBinary.clearById(id)
    local list = RandomLists[tostring(id)]
    if list then list:destroy() end
end

function RandomWeightedBinary.clearAll()
    for id, list in pairs(RandomLists) do
        list:destroy()
    end
end


local Binary = {
    create = RandomWeightedBinary.create,
    getById = RandomWeightedBinary.getById,
    clearById = RandomWeightedBinary.clearById,
    clearAll = RandomWeightedBinary.clearAll
}

exports('WeightedRandomBinary', function()
    return Binary
end)

return Binary

