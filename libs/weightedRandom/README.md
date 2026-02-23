# WeightedRandom Library

High-performance weighted random selection system with automatic algorithm selection.

---

## Features

- **Automatic Algorithm Selection**: Automatically chooses between Linear O(N) or Binary O(log N) based on item count
- **Two Implementations**:
  - **Linear**: Best for lists with < 50 items
  - **Binary**: Optimized for large lists (50+ items) using binary search with prefix sums
- **Reset on Empty**: Automatically replenish items from original template when exhausted
- **Session Persistence**: Original list preserved for reliable reset behavior
- **Memory Safe**: Proper cleanup and resource management

---

## Basic Usage

### Quick Start (Auto-Select)

```lua
local lootTable = srs.WeightedRandom.create({
    sword = { weight = 10, damage = 50 },
    shield = { weight = 15, defense = 30 },
    potion = { weight = 25, healing = 100 },
    gold = { weight = 50, amount = 500 }
}, true) -- resetOnEmpty = true

-- Get single item (doesn't remove from pool)
local item = lootTable:getItem()
print(item.key, item.item.damage)

-- Get and remove item
local reward = lootTable:getItem(true)

-- Get multiple items at once
local drops = lootTable:getItem(true, 3)
for i, drop in ipairs(drops) do
    print(drop.key)
end
```

---

## API Reference

### Creating Lists

#### `srs.WeightedRandom.create(items, resetOnEmpty, id)`

Automatically selects Linear or Binary implementation based on item count (threshold: 50).

**Parameters:**
- `items` (table): Key-value map or array with `weight` property
- `resetOnEmpty` (boolean, optional): Auto-refill when empty (default: `true`)
- `id` (string, optional): Custom identifier for retrieval

**Returns:** WeightedRandom instance

**Example:**
```lua
local box = srs.WeightedRandom.create({
    rare = { weight = 5, value = 1000 },
    common = { weight = 95, value = 10 }
})
```

---

#### `srs.WeightedRandom.Linear.create(items, resetOnEmpty, id)`

Force Linear implementation (O(N) selection).

**Best for:** < 50 items

---

#### `srs.WeightedRandom.Binary.create(items, resetOnEmpty, id)`

Force Binary Search implementation (O(log N) selection).

**Best for:** 50+ items

---

### Getting Items

#### `:getItem(remove, count)`

Select weighted random item(s).

**Parameters:**
- `remove` (boolean, optional): Remove from pool after selection (default: `false`)
- `count` (number, optional): Number of items to select (default: `1`)

**Returns:**
- Single item: `{ key = "sword", item = { weight = 10, damage = 50 } }`
- Multiple items: Array of results

**Example:**
```lua
-- Draw without removal (repeatable)
local inspect = box:getItem()

-- Draw and consume
local consumed = box:getItem(true)

-- Draw 5 items at once
local batch = box:getItem(true, 5)
```

---

### Managing Items

#### `:addItem(key, item)`

Add new item to pool (updates original template).

**Parameters:**
- `key` (string): Unique identifier
- `item` (table): Must have `weight` property (> 0)

**Example:**
```lua
lootTable:addItem("legendary", { weight = 1, power = 9999 })
```

---

#### `:removeItem(key)`

Remove item from pool and template.

**Returns:** `true` if found, `false` otherwise

**Example:**
```lua
lootTable:removeItem("common")
```

---

#### `:reset()`

Restore all items from original template.

**Example:**
```lua
lootTable:reset() -- Replenish all consumed items
```

---

### State Queries

#### `:IsEmpty()`

Check if pool is exhausted.

---

#### `.lastSelected`

Last selected item result (cached).

---

### Static Methods

#### `srs.WeightedRandom.getById(id)`

Retrieve instance by ID (searches both Linear and Binary pools).

**Example:**
```lua
local list = srs.WeightedRandom.getById("daily_rewards")
```

---

#### `srs.WeightedRandom.clearById(id)`

Destroy instance and free memory.

---

#### `srs.WeightedRandom.clearAll()`

Destroy all active instances (both Linear and Binary).

---

## Advanced Examples

### Quest Reward System

```lua
local rewards = srs.WeightedRandom.create({
    xp = { weight = 50, amount = 100 },
    money = { weight = 30, amount = 500 },
    item = { weight = 15, itemId = "rare_key" },
    bonus = { weight = 5, multiplier = 2 }
}, true, "quest_123")

local reward = rewards:getItem(true)
if reward.key == "xp" then
    player.addXP(reward.item.amount)
elseif reward.key == "money" then
    player.addMoney(reward.item.amount)
end
```

---

### Gacha System with Pity

```lua
local gacha = srs.WeightedRandom.create({
    ssr = { weight = 1, rarity = 5 },
    sr = { weight = 9, rarity = 4 },
    r = { weight = 90, rarity = 3 }
}, false, "gacha")

local pulls = gacha:getItem(false, 10) -- 10-pull without removal

local foundSSR = false
for _, pull in ipairs(pulls) do
    if pull.key == "ssr" then
        foundSSR = true
        break
    end
end

if not foundSSR then
    -- Pity system: increase SSR weight
    gacha:removeItem("ssr")
    gacha:addItem("ssr", { weight = 5, rarity = 5 })
end
```

---

### Dynamic Event Spawner

```lua
local events = srs.WeightedRandom.Binary.create({
    robbery = { weight = 20, difficulty = 3 },
    race = { weight = 40, difficulty = 1 },
    delivery = { weight = 50, difficulty = 2 },
    heist = { weight = 5, difficulty = 5 }
}, true)

CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        local event = events:getItem()
        TriggerEvent('server:startEvent', event.key, event.item)
    end
end)
```

---

## Performance Guidelines

| Item Count | Recommended | Selection Speed |
|------------|-------------|-----------------|
| 1-20       | Linear      | ~0.001ms        |
| 20-50      | Linear      | ~0.003ms        |
| 50-200     | Binary      | ~0.002ms        |
| 200+       | Binary      | ~0.003ms        |

**Auto-select threshold:** 50 items

---

## Best Practices

### ✅ Do

- Use `resetOnEmpty = true` for repeatable loot tables
- Use `remove = true` for one-time consumable rewards
- Store instances with IDs for easy retrieval
- Call `:destroy()` or `clearById()` when done

### ❌ Don't

- Don't modify `originalTemplate` directly
- Don't use `weight = 0` (will be ignored)
- Don't forget to validate item structure before `addItem()`

---

## Troubleshooting

**Items not resetting:**
- Check `resetOnEmpty` is `true`
- Verify original template has valid weights

**Selection seems biased:**
- Weights are relative, not percentages
- Use larger weight differences for noticeable changes

**Memory issues:**
- Call `clearAll()` on resource stop
- Remove unused instances with `clearById()`

---

## Export Usage

```lua
-- From other resources
local WR = exports['srs_lib']:WeightedRandom()
local myList = WR.create({ ... })
```

---

## Technical Details

**Linear Algorithm:**
- O(N) selection time
- O(1) add/remove
- Best for frequent modifications

**Binary Algorithm:**
- O(log N) selection time
- O(N) add/remove (cumulative weight update)
- Best for read-heavy workloads

**Reset Behavior:**
- Original template cloned with `lib.table.deepclone`
- `_rebuild()` reconstructs pool from template
- Remove operations don't affect template (use `removeItem()` for permanent changes)
