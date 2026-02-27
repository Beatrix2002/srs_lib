-- Credit: ox_lib community, modified
-- Linear Scan implementation (O(N)) - Best for small lists (< 50 items)

local deepclone = srs.lib.table.deepclone
local RandomWeightedLinear = srs.lib.class('RandomWeightedLinear')
local RandomLists = {}
local counter = 0

RandomWeightedLinear.create = function(items, resetOnEmpty, id)
    if type(items) ~= 'table' then
        error('RandomWeightedLinear.create - items must be a table')
    end
    return RandomWeightedLinear:new(items, resetOnEmpty, id)
end

function RandomWeightedLinear:constructor(items, resetOnEmpty, id)
    counter = counter + 1
    self.id = tostring(id or counter)
    
    -- Store original for resets
    self.originalTemplate = deepclone(items)
    self.items = {} 
    self.resetOnEmpty = resetOnEmpty == nil and true or resetOnEmpty
    self.totalWeight = 0
    self.itemCount = 0
    self.lastSelected = nil
    
    -- Build internal structure
    self:_rebuild()
    
    RandomLists[self.id] = self
    return self
end

function RandomWeightedLinear:_rebuild()
    local list = {}
    local total = 0
    local count = 0
    
    for k, v in pairs(self.originalTemplate) do
        local w = tonumber(v.weight)
        if w and w > 0 then
            total = total + w
            count = count + 1
            list[count] = {
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

function RandomWeightedLinear:getItem(remove, count)
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
        local currentWeight = 0
        local selectedIndex = nil
        
        for j = 1, self.itemCount do
            local item = self.items[j]
            currentWeight = currentWeight + item.weight
            if rand <= currentWeight then
                selectedIndex = j
                local result = { key = item.key, item = item.data }
                selectedItems[#selectedItems + 1] = result
                self.lastSelected = result
                break
            end
        end
        
        if remove and selectedIndex then
            local item = self.items[selectedIndex]
            self.totalWeight = self.totalWeight - item.weight
            table.remove(self.items, selectedIndex)
            self.itemCount = self.itemCount - 1
        end
    end

    return num > 1 and selectedItems or selectedItems[1]
end

function RandomWeightedLinear:reset()
    self:_rebuild()
end

function RandomWeightedLinear:addItem(key, item)
    if type(item) ~= 'table' or type(item.weight) ~= 'number' or item.weight <= 0 then
        error('RandomWeightedLinear:addItem - item must be a table with positive weight')
    end
    
    self.originalTemplate[key] = item
    self.totalWeight = self.totalWeight + item.weight
    self.itemCount = self.itemCount + 1
    
    self.items[self.itemCount] = {
        weight = item.weight,
        key = key,
        data = item
    }
end

function RandomWeightedLinear:removeItem(key)
    for i = 1, self.itemCount do
        if self.items[i].key == key then
            local w = self.items[i].weight
            self.totalWeight = self.totalWeight - w
            table.remove(self.items, i)
            self.itemCount = self.itemCount - 1
            self.originalTemplate[key] = nil
            return true
        end
    end
    return false
end

function RandomWeightedLinear:destroy()
    self.items = nil
    self.originalTemplate = nil
    self.totalWeight = nil
    self.itemCount = nil
    self.lastSelected = nil
    RandomLists[self.id] = nil
end

function RandomWeightedLinear.getById(id)
    return RandomLists[tostring(id)]
end

function RandomWeightedLinear.clearById(id)
    local list = RandomLists[tostring(id)]
    if list then list:destroy() end
end

function RandomWeightedLinear.clearAll()
    for id, list in pairs(RandomLists) do
        list:destroy()
    end
end

local Linear = {
    create = RandomWeightedLinear.create,
    getById = RandomWeightedLinear.getById,
    clearById = RandomWeightedLinear.clearById,
    clearAll = RandomWeightedLinear.clearAll
}

return Linear