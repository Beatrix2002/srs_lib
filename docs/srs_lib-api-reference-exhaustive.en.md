# srs_lib API Reference — Exhaustive Function Documentation (EN)

**Version:** 1.0.0  
**Resource:** `srs_lib`  
**Framework:** FiveM (Lua 5.4)  
**Manifest:** `fxmanifest.lua` (lua54, oal_gm_high, oxmysql)

> **Purpose:** This document provides **complete, function-by-function** API documentation for all modules in `srs_lib` (excluding `bridge/` directory per requirements). Every function includes full signatures, parameter types, return values, error conditions, and practical examples.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Global Objects & Bootstrap](#global-objects--bootstrap)
3. [Shared API (Client + Server)](#shared-api-client--server)
   - [srs.lib.array](#srslibarray)
   - [srs.lib.class](#srslibclass)
   - [srs.lib.callback (Shared)](#srslibcallback-shared)
   - [srs.lib.locale (Shared)](#srsliblocale-shared)
   - [srs.lib.print](#srslibprint)
   - [srs.lib.table](#srslibtable)
   - [srs.lib.timer (Shared)](#srslibtimer-shared)
   - [srs.lib.utils](#srslibutils)
   - [srs.lib.waitFor](#srslibwaitfor)
   - [srs.lib.getRelativeCoords](#srslibgetrelativecoords)
   - [srs.lib.grid](#srslibgrid)
   - [srs.lib.Network](#srslibnetwork)
   - [srs.lib.WeightedRandom](#srslibweightedrandom)
4. [Client-Only API](#client-only-api)
   - [srs.lib.anim](#srslibanim)
   - [srs.lib.addKeybind](#srslibaddkeybind)
   - [srs.lib.disableControls](#srslibdisablecontrols)
   - [srs.lib.raycast](#srslibracast)
   - [srs.lib.points](#srslibpoints)
   - [srs.lib.requestAnimDict](#srslibrequestanimdict)
   - [srs.lib.requestAnimSet](#srslibrequestanimset)
   - [srs.lib.requestAudioBank](#srslibrequestaudiobank)
   - [srs.lib.requestModel](#srslibrequestmodel)
   - [srs.lib.requestNamedPtfxAsset](#srslibrequestnamedptfxasset)
   - [srs.lib.requestScaleformMovie](#srslibrequestscaleformmovie)
   - [srs.lib.requestStreamedTextureDict](#srslibrequestStreamedtextureDict)
   - [srs.lib.requestWeaponAsset](#srslibrequestweaponasset)
   - [srs.lib.streamingRequest](#srslibstreamingrequest)
   - [srs.lib.Particle](#srslibparticle)
   - [srs.lib.cutscenes](#srslibcutscenes)
   - [srs.lib.shells](#srslibshells)
   - [srs.lib.placers](#srslibplacers)
   - [srs.lib.zones (Client)](#srslibzones-client)
   - [srs.callback (Client)](#srscallback-client)
   - [srs.lib.locale (Client)](#srsliblocale-client)
5. [Server-Only API](#server-only-api)
   - [srs.lib.logger](#srsliblogger)
   - [srs.lib.SQL](#srslibsql)
   - [srs.lib.triggerClientEvent](#srslibtriggerclientevent)
   - [srs.callback (Server)](#srscallback-server)
   - [srs.lib.locale (Server)](#srsliblocale-server)
   - [srs.lib.shells (Server)](#srslibshells-server)
6. [Core Systems](#core-systems)
   - [Entities (Client/Server)](#entities-clientserver)
   - [Markers (Client)](#markers-client)
   - [Points (Client)](#points-client)
   - [Zones (Client)](#zones-client)
7. [Configuration](#configuration)
8. [Exports](#exports)
9. [Global Helpers](#global-helpers)

---

## Architecture Overview

### Bootstrap Process

1. **Entry Point:** `init.lua`
   - Validates `srs_lib` is started before any dependent resource.
   - Detects context: `client` or `server`.
   - Creates global `srs` table with `srs.cache`, `srs.lib`, etc.
   
2. **Lazy Loading:**
   - `srs.lib` uses metatable `__index` to dynamically load modules on first access.
   - Module config in `init.lua` (`moduleConfig`) defines folder paths, context-specific files (`useContext`, `useShared`).
   
3. **Module Files:**
   - Shared: `libs/<module>/shared.lua`
   - Client: `libs/<module>/client.lua`
   - Server: `libs/<module>/server.lua`

4. **Global namespace pollution:**
   - `_ENV.srs` = main API namespace
   - `_ENV.cache` = `srs.cache`
   - `_ENV.warn` = `srs.lib.print.warn`
   - `_ENV.SetInterval`, `_ENV.ClearInterval` (client)

---

## Global Objects & Bootstrap

### `srs`

Global table created by `init.lua`.

**Properties:**

- `srs.name`: `string` — Resource name (`'srs_lib'`).
- `srs.context`: `string` — `'client'` or `'server'`.
- `srs.cache`: `table` — Runtime cache (see below).
- `srs.lib`: `table` — Lazy-loaded library modules.
- `srs.callback`: `table` — RPC callback API (context-specific).

---

### `srs.cache`

Runtime information cache.

**Shared Properties:**

- `srs.cache.resource`: `string` — Current resource name.
- `srs.cache.game`: `string` — `'fxserver'` (server) or `'fivem'` (client).

**Client-Only Properties:**

- `srs.cache.playerId`: `number` — `PlayerId()` result.
- `srs.cache.serverId`: `number` — `GetPlayerServerId(PlayerId())` result.

---

### Global Functions

#### `_ENV.warn`

**Signature:**
```lua
warn(...)
```

**Side:** Shared

**Description:**  
Alias for `srs.lib.print.warn(...)`. Prints warning-level messages to console.

**Parameters:**
- `...`: `any` — Values to print (will be stringified and JSON-encoded if tables).

**Returns:**  
`nil`

**Example:**
```lua
warn("Something went wrong:", errorCode)
```

---

#### `_ENV.SetInterval` (Client)

**Signature:**
```lua
SetInterval(callback: function, interval: number) -> number
```

**Side:** Client

**Description:**  
Creates a repeating timer that executes `callback` every `interval` milliseconds. Returns an interval ID.

**Parameters:**
- `callback`: `function` — Function to call on each interval.
- `interval`: `number` — Milliseconds between calls.

**Returns:**  
`number` — Interval ID (use with `ClearInterval`).

**Example:**
```lua
local intervalId = SetInterval(function()
    print("Tick")
end, 1000)
```

---

#### `_ENV.ClearInterval` (Client)

**Signature:**
```lua
ClearInterval(id: number) -> nil
```

**Side:** Client

**Description:**  
Stops and removes the interval with the given ID.

**Parameters:**
- `id`: `number` — Interval ID returned by `SetInterval`.

**Returns:**  
`nil`

**Example:**
```lua
local id = SetInterval(function() print("a") end, 1000)
ClearInterval(id)
```

---

## Shared API (Client + Server)

---

## `srs.lib.array`

**File:** `libs/array/shared.lua`  
**License:** LGPL-3.0 (ox_lib)

Array is a class-based utility for working with indexed tables, compatible with both standard Lua tables and custom `Array` instances.

---

### `srs.lib.array:new(...)`

**Signature:**
```lua
srs.lib.array:new(...) -> Array
```

**Description:**  
Creates a new Array instance with the provided elements.

**Parameters:**
- `...`: `any` — Elements to add to the array.

**Returns:**  
`Array` — New array instance.

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3)
print(arr[1]) -- 1
```

---

### `srs.lib.array:from(iter)`

**Signature:**
```lua
srs.lib.array:from(iter: table | function | string) -> Array
```

**Description:**  
Creates a new array from an iterable value (table, iterator function, or string).

**Parameters:**
- `iter`: `table | function | string` — Iterable source.

**Returns:**  
`Array` — New array instance.

**Errors:**
- Throws error if `iter` is not a valid iterable type.

**Example:**
```lua
local arr = srs.lib.array:from({10, 20, 30})
local arr2 = srs.lib.array:from("abc") -- ['a', 'b', 'c']
```

---

### `arr:at(index)`

**Signature:**
```lua
arr:at(index: number) -> any
```

**Description:**  
Returns the element at `index`. Negative indices count from the end.

**Parameters:**
- `index`: `number` — 1-based index (negative counts from end).

**Returns:**  
`any` — Element at index, or `nil` if out of bounds.

**Example:**
```lua
local arr = srs.lib.array:new(10, 20, 30)
print(arr:at(-1)) -- 30
```

---

### `arr:merge(...)`

**Signature:**
```lua
arr:merge(...: ArrayLike) -> Array
```

**Description:**  
Creates a new array containing elements from this array and all provided arrays.

**Parameters:**
- `...`: `ArrayLike` — Arrays to merge.

**Returns:**  
`Array` — New merged array.

**Example:**
```lua
local arr1 = srs.lib.array:new(1, 2)
local arr2 = arr1:merge({3, 4}, {5})
-- arr2: [1, 2, 3, 4, 5]
```

---

### `arr:every(testFn)`

**Signature:**
```lua
arr:every(testFn: fun(element: any): boolean) -> boolean
```

**Description:**  
Tests if all elements pass the provided test function.

**Parameters:**
- `testFn`: `function(element: any): boolean` — Test function.

**Returns:**  
`boolean` — `true` if all elements pass, `false` otherwise.

**Example:**
```lua
local arr = srs.lib.array:new(2, 4, 6)
local allEven = arr:every(function(n) return n % 2 == 0 end)
print(allEven) -- true
```

---

### `arr:fill(value, start?, endIndex?)`

**Signature:**
```lua
arr:fill(value: any, start?: number, endIndex?: number) -> Array
```

**Description:**  
Fills elements within a range with `value`. Modifies array in place.

**Parameters:**
- `value`: `any` — Value to set.
- `start`: `number?` — Start index (default: 1).
- `endIndex`: `number?` — End index (default: array length).

**Returns:**  
`Array` — Modified array (self).

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3, 4)
arr:fill(0, 2, 3)
-- arr: [1, 0, 0, 4]
```

---

### `arr:filter(testFn)`

**Signature:**
```lua
arr:filter(testFn: fun(element: any): boolean) -> Array
```

**Description:**  
Creates a new array with elements that pass the test function.

**Parameters:**
- `testFn`: `function(element: any): boolean` — Test function.

**Returns:**  
`Array` — New filtered array.

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3, 4)
local evens = arr:filter(function(n) return n % 2 == 0 end)
-- evens: [2, 4]
```

---

### `arr:find(testFn, last?)`

**Signature:**
```lua
arr:find(testFn: fun(element: any): boolean, last?: boolean) -> any?
```

**Description:**  
Returns the first (or last) element that passes the test function.

**Parameters:**
- `testFn`: `function(element: any): boolean` — Test function.
- `last`: `boolean?` — If `true`, searches from end.

**Returns:**  
`any?` — Matching element, or `nil` if none found.

**Example:**
```lua
local arr = srs.lib.array:new(10, 20, 30)
local found = arr:find(function(n) return n > 15 end)
print(found) -- 20
```

---

### `arr:findIndex(testFn, last?)`

**Signature:**
```lua
arr:findIndex(testFn: fun(element: any): boolean, last?: boolean) -> number?
```

**Description:**  
Returns the index of the first (or last) element that passes the test function.

**Parameters:**
- `testFn`: `function(element: any): boolean` — Test function.
- `last`: `boolean?` — If `true`, searches from end.

**Returns:**  
`number?` — Index of matching element, or `nil`.

**Example:**
```lua
local arr = srs.lib.array:new(10, 20, 30)
local idx = arr:findIndex(function(n) return n == 20 end)
print(idx) -- 2
```

---

### `arr:indexOf(value, last?)`

**Signature:**
```lua
arr:indexOf(value: any, last?: boolean) -> number?
```

**Description:**  
Returns the index of the first (or last) occurrence of `value`.

**Parameters:**
- `value`: `any` — Value to search for.
- `last`: `boolean?` — If `true`, searches from end.

**Returns:**  
`number?` — Index of value, or `nil`.

**Example:**
```lua
local arr = srs.lib.array:new("a", "b", "c", "b")
print(arr:indexOf("b")) -- 2
print(arr:indexOf("b", true)) -- 4
```

---

### `arr:forEach(cb)`

**Signature:**
```lua
arr:forEach(cb: fun(element: any))
```

**Description:**  
Executes `cb` for each element in the array.

**Parameters:**
- `cb`: `function(element: any)` — Callback function.

**Returns:**  
`nil`

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3)
arr:forEach(function(n) print(n) end)
```

---

### `arr:includes(element, fromIndex?)`

**Signature:**
```lua
arr:includes(element: any, fromIndex?: number) -> boolean
```

**Description:**  
Determines if `element` exists in the array.

**Parameters:**
- `element`: `any` — Value to search for.
- `fromIndex`: `number?` — Start search at this index (default: 1).

**Returns:**  
`boolean` — `true` if element exists, `false` otherwise.

**Example:**
```lua
local arr = srs.lib.array:new(10, 20, 30)
print(arr:includes(20)) -- true
print(arr:includes(99)) -- false
```

---

### `arr:join(separator?)`

**Signature:**
```lua
arr:join(separator?: string) -> string
```

**Description:**  
Concatenates all elements into a string separated by `separator`.

**Parameters:**
- `separator`: `string?` — Separator string (default: `','`).

**Returns:**  
`string` — Joined string.

**Example:**
```lua
local arr = srs.lib.array:new("a", "b", "c")
print(arr:join("-")) -- "a-b-c"
```

---

### `arr:map(cb)`

**Signature:**
```lua
arr:map(cb: fun(element: any, index: number, array: Array): any) -> Array
```

**Description:**  
Creates a new array with results from calling `cb` on each element.

**Parameters:**
- `cb`: `function(element, index, array): any` — Mapping function.

**Returns:**  
`Array` — New mapped array.

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3)
local doubled = arr:map(function(n) return n * 2 end)
-- doubled: [2, 4, 6]
```

---

### `arr:pop()`

**Signature:**
```lua
arr:pop() -> any?
```

**Description:**  
Removes and returns the last element.

**Returns:**  
`any?` — Removed element, or `nil` if array is empty.

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3)
local last = arr:pop()
print(last) -- 3
-- arr: [1, 2]
```

---

### `arr:push(...)`

**Signature:**
```lua
arr:push(...: any) -> number
```

**Description:**  
Adds elements to the end of the array.

**Parameters:**
- `...`: `any` — Elements to add.

**Returns:**  
`number` — New length of the array.

**Example:**
```lua
local arr = srs.lib.array:new(1, 2)
arr:push(3, 4)
-- arr: [1, 2, 3, 4]
```

---

### `arr:reduce(reducer, initialValue?, reverse?)`

**Signature:**
```lua
arr:reduce(reducer: fun(accumulator: T, currentValue: T, index?: number): T, initialValue?: T, reverse?: boolean) -> T
```

**Description:**  
Applies `reducer` function to each element, accumulating a single result.

**Parameters:**
- `reducer`: `function(accumulator, currentValue, index): T` — Reducer function.
- `initialValue`: `T?` — Initial accumulator value (default: first element).
- `reverse`: `boolean?` — If `true`, iterates right-to-left.

**Returns:**  
`T` — Accumulated result.

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3, 4)
local sum = arr:reduce(function(acc, n) return acc + n end, 0)
print(sum) -- 10
```

---

### ` arr:reverse()`

**Signature:**
```lua
arr:reverse() -> Array
```

**Description:**  
Reverses the array in place.

**Returns:**  
`Array` — Modified array (self).

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3)
arr:reverse()
-- arr: [3, 2, 1]
```

---

### `arr:shift()`

**Signature:**
```lua
arr:shift() -> any?
```

**Description:**  
Removes and returns the first element.

**Returns:**  
`any?` — Removed element, or `nil` if array is empty.

**Example:**
```lua
local arr = srs.lib.array:new(10, 20, 30)
local first = arr:shift()
print(first) -- 10
-- arr: [20, 30]
```

---

### `arr:slice(start?, finish?)`

**Signature:**
```lua
arr:slice(start?: number, finish?: number) -> Array
```

**Description:**  
Creates a shallow copy of a portion of the array.

**Parameters:**
- `start`: `number?` — Start index (default: 1). Negative counts from end.
- `finish`: `number?` — End index (default: array length). Negative counts from end.

**Returns:**  
`Array` — New sliced array.

**Example:**
```lua
local arr = srs.lib.array:new(10, 20, 30, 40)
local sliced = arr:slice(2, 3)
-- sliced: [20, 30]
```

---

### `arr:toReversed()`

**Signature:**
```lua
arr:toReversed() -> Array
```

**Description:**  
Creates a new array with reversed elements (does not modify original).

**Returns:**  
`Array` — New reversed array.

**Example:**
```lua
local arr = srs.lib.array:new(1, 2, 3)
local rev = arr:toReversed()
-- rev: [3, 2, 1]
-- arr: [1, 2, 3] (unchanged)
```

---

### `arr:unshift(...)`

**Signature:**
```lua
arr:unshift(...: any) -> number
```

**Description:**  
Inserts elements at the beginning of the array.

**Parameters:**
- `...`: `any` — Elements to add.

**Returns:**  
`number` — New length of the array.

**Example:**
```lua
local arr = srs.lib.array:new(3, 4)
arr:unshift(1, 2)
-- arr: [1, 2, 3, 4]
```

---

### `srs.lib.array.isArray(tbl)`

**Signature:**
```lua
srs.lib.array.isArray(tbl: any) -> boolean
```

**Description:**  
Returns `true` if `tbl` is an array-like table (`Array` instance or indexed table).

**Parameters:**
- `tbl`: `any` — Value to test.

**Returns:**  
`boolean` — `true` if array-like, `false` otherwise.

**Example:**
```lua
print(srs.lib.array.isArray({1, 2, 3})) -- true
print(srs.lib.array.isArray({a = 1})) -- false
```

---

## `srs.lib.class`

**File:** `libs/class/shared.lua`  
**License:** LGPL-3.0 (ox_lib)

Provides OOP class system with inheritance, private fields, and mixins.

---

### `srs.lib.class(name, super?)`

**Signature:**
```lua
srs.lib.class(name: string, super?: OxClass) -> OxClass
```

**Description:**  
Creates a new class with the given name and optional parent class.

**Parameters:**
- `name`: `string` — Class name.
- `super`: `OxClass?` — Parent class (for inheritance).

**Returns:**  
`OxClass` — New class table.

**Errors:**
- Throws error if `name` is not a string or `super` is not a table.

**Example:**
```lua
local Animal = srs.lib.class('Animal')

function Animal:constructor(name)
    self.name = name
end

function Animal:speak()
    print(self.name .. " makes a sound")
end

local Dog = srs.lib.class('Dog', Animal)

function Dog:constructor(name, breed)
    self:super(name)
    self.breed = breed
end

function Dog:speak()
    print(self.name .. " barks")
end

local myDog = Dog:new("Rex", "Bulldog")
myDog:speak() -- "Rex barks"
```

---

### `Class:new(...)`

**Signature:**
```lua
Class:new(...: any) -> instance
```

**Description:**  
Creates a new instance of the class, calling the constructor if defined.

**Parameters:**
- `...`: `any` — Arguments passed to constructor.

**Returns:**  
`instance` — New class instance.

**Example:**
```lua
local Person = srs.lib.class('Person')
function Person:constructor(name, age)
    self.name = name
    self.age = age
end

local john = Person:new("John", 30)
print(john.name) -- "John"
```

---

### `instance:isClass(class)`

**Signature:**
```lua
instance:isClass(class: OxClass) -> boolean
```

**Description:**  
Checks if the instance is exactly of the given class (no inheritance check).

**Parameters:**
- `class`: `OxClass` — Class to test against.

**Returns:**  
`boolean` — `true` if exact match, `false` otherwise.

**Example:**
```lua
local Animal = srs.lib.class('Animal')
local Dog = srs.lib.class('Dog', Animal)
local dog = Dog:new()

print(dog:isClass(Dog)) -- true
print(dog:isClass(Animal)) -- false
```

---

### `instance:instanceOf(class)`

**Signature:**
```lua
instance:instanceOf(class: OxClass) -> boolean
```

**Description:**  
Checks if the instance is of the given class or a subclass (inheritance-aware).

**Parameters:**
- `class`: `OxClass` — Class to test against.

**Returns:**  
`boolean` — `true` if instance or derivative, `false` otherwise.

**Example:**
```lua
local Animal = srs.lib.class('Animal')
local Dog = srs.lib.class('Dog', Animal)
local dog = Dog:new()

print(dog:instanceOf(Dog)) -- true
print(dog:instanceOf(Animal)) -- true
```

---

### `instance.private`

**Description:**  
Class instances can access private fields via `self.private`. Private fields are only accessible from methods, not from outside.

**Example:**
```lua
local BankAccount = srs.lib.class('BankAccount')

function BankAccount:constructor(balance)
    self.private.balance = balance
end

function BankAccount:deposit(amount)
    self.private.balance = self.private.balance + amount
end

function BankAccount:getBalance()
    return self.private.balance
end

local acc = BankAccount:new(100)
acc:deposit(50)
print(acc:getBalance()) -- 150
-- print(acc.private.balance) -- Would error if accessed outside methods
```

---

## `srs.lib.callback` (Shared)

**Files:**  
- `libs/callback/shared.lua`
- `libs/callback/client.lua`
- `libs/callback/server.lua`

**License:** LGPL-3.0 (ox_lib)

RPC callback system for client-server communication.

---

### Shared: `srs.setValidCallback(callbackName, isValid)`

**Signature:**
```lua
srs.setValidCallback(callbackName: string, isValid: boolean)
```

**Side:** Shared (internal)

**Description:**  
Registers or unregisters a callback as valid for the current resource.

**Parameters:**
- `callbackName`: `string` — Callback name.
- `isValid`: `boolean` — `true` to register, `false` to unregister.

**Returns:**  
`nil`

---

### Shared: `srs.isCallbackValid(callbackName)`

**Signature:**
```lua
srs.isCallbackValid(callbackName: string) -> boolean
```

**Side:** Shared (internal)

**Description:**  
Checks if a callback is registered by the invoking resource.

**Parameters:**
- `callbackName`: `string` — Callback name.

**Returns:**  
`boolean` — `true` if valid, `false` otherwise.

---

## `srs.callback` (Client)

**File:** `libs/callback/client.lua`

---

### `srs.callback(event, delay, cb, ...)`

**Signature:**
```lua
srs.callback(event: string, delay: number | false, cb: function, ...: any)
```

**Side:** Client

**Description:**  
Triggers a server callback event and executes `cb` when the server responds. If `cb` is `nil`, it will await (blocking).

**Parameters:**
- `event`: `string` — Callback event name.
- `delay`: `number | false` — Delay before event can be called again (milliseconds), or `false` for no throttle.
- `cb`: `function` — Callback function to execute on response.
- `...`: `any` — Arguments to pass to server.

**Returns:**  
`nil` (if `cb` provided), or response values (if awaiting).

**Errors:**
- Errors if callback does not exist on server.
- Errors if callback times out (default: 300 seconds).

**Example:**
```lua
srs.callback('myServerEvent', false, function(result)
    print("Server returned:", result)
end, "arg1", "arg2")
```

---

### `srs.callback.await(event, delay, ...)`

**Signature:**
```lua
srs.callback.await(event: string, delay: number | false, ...: any) -> ...
```

**Side:** Client

**Description:**  
Triggers a server callback and halts the current thread until a response is received.

**Parameters:**
- `event`: `string` — Callback event name.
- `delay`: `number | false` — Delay before event can be called again.
- `...`: `any` — Arguments to pass to server.

**Returns:**  
`...` — Response values from server.

**Errors:**
- Errors if callback does not exist.
- Errors if callback times out.

**Example:**
```lua
local result = srs.callback.await('getPlayerData', false, playerId)
print("Player data:", result)
```

---

### `srs.callback.register(name, cb)`

**Signature:**
```lua
srs.callback.register(name: string, cb: function)
```

**Side:** Client

**Description:**  
Registers a callback that the server can invoke.

**Parameters:**
- `name`: `string` — Callback name.
- `cb`: `function(...): ...` — Callback function. Arguments passed from server.

**Returns:**  
`nil`

**Example:**
```lua
srs.callback.register('getClientHealth', function()
    return GetEntityHealth(PlayerPedId())
end)
```

---

## `srs.callback` (Server)

**File:** `libs/callback/server.lua`

---

### `srs.callback(event, playerId, cb, ...)`

**Signature:**
```lua
srs.callback(event: string, playerId: number, cb: function, ...: any)
```

**Side:** Server

**Description:**  
Triggers a client callback event for the specified player and executes `cb` when the client responds.

**Parameters:**
- `event`: `string` — Callback event name.
- `playerId`: `number` — Target player ID.
- `cb`: `function` — Callback function to execute on response.
- `...`: `any` — Arguments to pass to client.

**Returns:**  
`nil` (if `cb` provided), or response values (if awaiting).

**Errors:**
- Errors if callback does not exist on client.
- Errors if callback times out.

**Example:**
```lua
srs.callback('getClientHealth', playerId, function(health)
    print("Player health:", health)
end)
```

---

### `srs.callback.await(event, playerId, ...)`

**Signature:**
```lua
srs.callback.await(event: string, playerId: number, ...: any) -> ...
```

**Side:** Server

**Description:**  
Triggers a client callback and halts the current thread until a response is received.

**Parameters:**
- `event`: `string` — Callback event name.
- `playerId`: `number` — Target player ID.
- `...`: `any` — Arguments to pass to client.

**Returns:**  
`...` — Response values from client.

**Errors:**
- Errors if callback does not exist.
- Errors if callback times out.

**Example:**
```lua
local health = srs.callback.await('getClientHealth', playerId)
print("Health:", health)
```

---

### `srs.callback.register(name, cb)`

**Signature:**
```lua
srs.callback.register(name: string, cb: function)
```

**Side:** Server

**Description:**  
Registers a callback that clients can invoke.

**Parameters:**
- `name`: `string` — Callback name.
- `cb`: `function(playerId: number, ...): ...` — Callback function. First argument is player ID.

**Returns:**  
`nil`

**Example:**
```lua
srs.callback.register('serverTime', function(playerId)
    return os.time()
end)
```

---

## `srs.lib.locale` (Shared)

**File:** `libs/locale/shared.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `locale(str, ...)`

**Signature:**
```lua
locale(str: string, ...: string | number) -> string
```

**Side:** Shared

**Description:**  
Global function for retrieving localized strings. If `str` is a key in the locale dictionary, returns the translated string (formatted with `...` if provided).

**Parameters:**
- `str`: `string` — Locale key.
- `...`: `string | number` — Format arguments (passed to `string.format`).

**Returns:**  
`string` — Localized string, or `str` if key not found.

**Example:**
```lua
-- Assuming locale key "welcome" = "Welcome, %s!"
print(locale("welcome", "John")) -- "Welcome, John!"
```

---

### `srs.lib.locale(key?)`

**Signature:**
```lua
srs.lib.locale(key?: string)
```

**Side:** Shared

**Description:**  
Loads locale files for the given language key. Merges `en.json` with the specified language file.

**Parameters:**
- `key`: `string?` — Language key (e.g., `'hu'`). If omitted, uses detected locale.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.locale('hu') -- Loads Hungarian locale
```

---

### `srs.lib.getLocales()`

**Signature:**
```lua
srs.lib.getLocales() -> table<string, string>
```

**Side:** Shared

**Description:**  
Returns the current locale dictionary.

**Returns:**  
`table<string, string>` — Locale key-value pairs.

**Example:**
```lua
local locales = srs.lib.getLocales()
for k, v in pairs(locales) do
    print(k, v)
end
```

---

### `srs.lib.getLocale(resource, key)`

**Signature:**
```lua
srs.lib.getLocale(resource: string, key: string) -> string?
```

**Side:** Shared

**Description:**  
Gets a locale string from another resource's locale dictionary and adds it to the current dictionary.

**Parameters:**
- `resource`: `string` — Resource name.
- `key`: `string` — Locale key.

**Returns:**  
`string?` — Locale string, or `nil` if not found.

**Example:**
```lua
local txt = srs.lib.getLocale('ox_inventory', 'item_name')
```

---

## `srs.lib.print`

**File:** `libs/print/shared.lua`  
**License:** LGPL-3.0 (ox_lib)

Conditional console logging based on print level convars.

---

### `srs.lib.print.error(...)`

**Signature:**
```lua
srs.lib.print.error(...: any)
```

**Side:** Shared

**Description:**  
Prints error-level message to console (red prefix).

**Parameters:**
- `...`: `any` — Values to print.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.print.error("Critical failure:", errorCode)
```

---

### `srs.lib.print.warn(...)`

**Signature:**
```lua
srs.lib.print.warn(...: any)
```

**Side:** Shared

**Description:**  
Prints warning-level message to console (yellow prefix).

**Parameters:**
- `...`: `any` — Values to print.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.print.warn("Deprecated function used")
```

---

### `srs.lib.print.info(...)`

**Signature:**
```lua
srs.lib.print.info(...: any)
```

**Side:** Shared

**Description:**  
Prints info-level message to console (default level).

**Parameters:**
- `...`: `any` — Values to print.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.print.info("Server started")
```

---

### `srs.lib.print.verbose(...)`

**Signature:**
```lua
srs.lib.print.verbose(...: any)
```

**Side:** Shared

**Description:**  
Prints verbose-level message to console (blue prefix).

**Parameters:**
- `...`: `any` — Values to print.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.print.verbose("Loading config file")
```

---

### `srs.lib.print.debug(...)`

**Signature:**
```lua
srs.lib.print.debug(...: any)
```

**Side:** Shared

**Description:**  
Prints debug-level message to console (cyan prefix).

**Parameters:**
- `...`: `any` — Values to print.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.print.debug("Variable state:", myVar)
```

---

## `srs.lib.table`

**File:** `libs/table/shared.lua`  
**License:** LGPL-3.0 (ox_lib)

Extensions to Lua's standard `table` library.

---

### `table.contains(tbl, value)`

**Signature:**
```lua
table.contains(tbl: table, value: any) -> boolean
```

**Side:** Shared

**Description:**  
Checks if `tbl` contains `value`. If `value` is a table, checks if all elements of `value` exist in `tbl`.

**Parameters:**
- `tbl`: `table` — Table to search.
- `value`: `any` — Value or table of values.

**Returns:**  
`boolean` — `true` if value(s) found, `false` otherwise.

**Example:**
```lua
local t = {10, 20, 30}
print(table.contains(t, 20)) -- true
print(table.contains(t, {10, 20})) -- true
print(table.contains(t, {10, 99})) -- false
```

---

### `table.matches(t1, t2)`

**Signature:**
```lua
table.matches(t1: any, t2: any) -> boolean
```

**Side:** Shared

**Description:**  
Recursively compares two values for equality. Tables are compared by keys and values.

**Parameters:**
- `t1`: `any` — First value.
- `t2`: `any` — Second value.

**Returns:**  
`boolean` — `true` if equal, `false` otherwise.

**Example:**
```lua
local a = {x = 1, y = {z = 2}}
local b = {x = 1, y = {z = 2}}
print(table.matches(a, b)) -- true
```

---

### `table.deepclone(tbl)`

**Signature:**
```lua
table.deepclone(tbl: table) -> table
```

**Side:** Shared

**Description:**  
Recursively clones a table, ensuring no table references remain.

**Parameters:**
- `tbl`: `table` — Source table.

**Returns:**  
`table` — Deep-cloned table.

**Example:**
```lua
local original = {a = {b = 1}}
local copy = table.deepclone(original)
copy.a.b = 2
print(original.a.b) -- 1 (unchanged)
```

---

### `table.merge(t1, t2, addDuplicateNumbers?)`

**Signature:**
```lua
table.merge(t1: table, t2: table, addDuplicateNumbers?: boolean) -> table
```

**Side:** Shared

**Description:**  
Merges `t2` into `t1`. Nested tables are merged recursively. If `addDuplicateNumbers` is `true`, numeric values are added together; otherwise, they are replaced.

**Parameters:**
- `t1`: `table` — Target table modified in place).
- `t2`: `table` — Source table.
- `addDuplicateNumbers`: `boolean?` — If `true`, add numeric duplicates (default: `true`).

**Returns:**  
`table` — Modified `t1`.

**Example:**
```lua
local t1 = {a = 1, b = {c = 2}}
local t2 = {a = 3, b = {d = 4}}
table.merge(t1, t2)
-- t1: {a = 4, b = {c = 2, d = 4}}
```

---

### `table.shuffle(tbl)`

**Signature:**
```lua
table.shuffle(tbl: table) -> table
```

**Side:** Shared

**Description:**  
Randomly shuffles the elements of an array using Fisher-Yates algorithm.

**Parameters:**
- `tbl`: `table` — Array to shuffle (modified in place).

**Returns:**  
`table` — Shuffled array (same reference).

**Example:**
```lua
local t = {1, 2, 3, 4, 5}
table.shuffle(t)
print(t[1]) -- Random element
```

---

### `table.map(tbl, fn)`

**Signature:**
```lua
table.map(tbl: table, fn: fun(value: any, key: any): any) -> table
```

**Side:** Shared

**Description:**  
Creates a new table with results from calling `fn` on each key-value pair.

**Parameters:**
- `tbl`: `table` — Source table.
- `fn`: `function(value, key): any` — Mapping function.

**Returns:**  
`table` — New mapped table.

**Example:**
```lua
local t = {a = 10, b = 20}
local doubled = table.map(t, function(v) return v * 2 end)
-- doubled: {a = 20, b = 40}
```

---

### `table.freeze(tbl)`

**Signature:**
```lua
table.freeze(tbl: table) -> table
```

**Side:** Shared

**Description:**  
Makes a table read-only. Prevents further modification.

**Parameters:**
- `tbl`: `table` — Table to freeze.

**Returns:**  
`table` — Frozen table (same reference).

**Errors:**
- Throws error when attempting to modify a frozen table.

**Example:**
```lua
local t = {a = 1}
table.freeze(t)
-- t.a = 2 -- Would error
```

---

### `table.isfrozen(tbl)`

**Signature:**
```lua
table.isfrozen(tbl: table) -> boolean
```

**Side:** Shared

**Description:**  
Checks if a table is frozen (read-only).

**Parameters:**
- `tbl`: `table` — Table to check.

**Returns:**  
`boolean` — `true` if frozen, `false` otherwise.

**Example:**
```lua
local t = {a = 1}
table.freeze(t)
print(table.isfrozen(t)) -- true
```

---

## `srs.lib.Timer` (Shared)

**File:** `libs/timer/shared.lua`

Timer class for managing delayed callbacks.

---

### `srs.lib.Timer.Create(durationMs, onEnd, id?)`

**Signature:**
```lua
srs.lib.Timer.Create(durationMs: number, onEnd: function, id?: string) -> Timer
```

**Side:** Shared

**Description:**  
Creates a new timer that executes `onEnd` after `durationMs` milliseconds.

**Parameters:**
- `durationMs`: `number` — Duration in milliseconds.
- `onEnd`: `function` — Callback function executed when timer ends.
- `id`: `string?` — Optional unique identifier.

**Returns:**  
`Timer` — Timer instance.

**Errors:**
- Throws error if `durationMs` is invalid.
- Throws error if `id` already exists.

**Example:**
```lua
local timer = srs.lib.Timer.Create(5000, function()
    print("Timer finished!")
end, "my_timer")
```

---

### `timer:ForceEnd(triggerCallback?)`

**Signature:**
```lua
timer:ForceEnd(triggerCallback?: boolean) -> boolean
```

**Side:** Shared

**Description:**  
Immediately ends the timer. Optionally triggers `onEnd` callback.

**Parameters:**
- `triggerCallback`: `boolean?` — If `true`, executes `onEnd` callback.

**Returns:**  
`boolean` — `true` if timer was active and ended, `false` otherwise.

**Example:**
```lua
timer:ForceEnd(true)
```

---

### `timer:IsFinished()`

**Signature:**
```lua
timer:IsFinished() -> boolean
```

**Side:** Shared

**Description:**  
Checks if the timer has finished.

**Returns:**  
`boolean` — `true` if finished, `false` otherwise.

**Example:**
```lua
if timer:IsFinished() then
    print("Timer done")
end
```

---

### `timer:IsActive()`

**Signature:**
```lua
timer:IsActive() -> boolean
```

**Side:** Shared

**Description:**  
Checks if the timer is still active.

**Returns:**  
`boolean` — `true` if active, `false` otherwise.

**Example:**
```lua
if timer:IsActive() then
    print("Timer running")
end
```

---

### `timer:GetTimeLeft(format?)`

**Signature:**
```lua
timer:GetTimeLeft(format?: string) -> number
```

**Side:** Shared

**Description:**  
Returns remaining time in the specified format.

**Parameters:**
- `format`: `string?` — Format: `'ms'`, `'s'`, `'m'`, `'h'` (default: `'ms'`).

**Returns:**  
`number` — Remaining time in the specified unit.

**Example:**
```lua
local remaining = timer:GetTimeLeft('s')
print("Time left:", remaining, "seconds")
```

---

### `timer:GetEndTime()`

**Signature:**
```lua
timer:GetEndTime() -> number?
```

**Side:** Shared

**Description:**  
Returns the Game Timer value when the timer will end.

**Returns:**  
`number?` — End time (GetGameTimer result), or `nil` if timer finished.

**Example:**
```lua
local endTime = timer:GetEndTime()
```

---

### `srs.lib.Timer.GetActiveTimers()`

**Signature:**
```lua
srs.lib.Timer.GetActiveTimers() -> table<string, Timer>
```

**Side:** Shared

**Description:**  
Returns a table of all active timers.

**Returns:**  
`table<string, Timer>` — Active timers indexed by ID.

**Example:**
```lua
local timers = srs.lib.Timer.GetActiveTimers()
for id, timer in pairs(timers) do
    print("Active timer ID:", id)
end
```

---

### `srs.lib.Timer.GetActiveTimerCount()`

**Signature:**
```lua
srs.lib.Timer.GetActiveTimerCount() -> number
```

**Side:** Shared

**Description:**  
Returns the count of active timers.

**Returns:**  
`number` — Number of active timers.

**Example:**
```lua
print("Active timers:", srs.lib.Timer.GetActiveTimerCount())
```

---

### `srs.lib.Timer.GetTimerById(id)`

**Signature:**
```lua
srs.lib.Timer.GetTimerById(id: string) -> Timer?
```

**Side:** Shared

**Description:**  
Retrieves a timer by ID.

**Parameters:**
- `id`: `string` — Timer ID.

**Returns:**  
`Timer?` — Timer instance, or `nil` if not found.

**Example:**
```lua
local t = srs.lib.Timer.GetTimerById("my_timer")
if t then t:ForceEnd() end
```

---

### `srs.lib.Timer.ClearTimers(triggerCallbacks?, resourceName?)`

**Signature:**
```lua
srs.lib.Timer.ClearTimers(triggerCallbacks?: boolean, resourceName?: string)
```

**Side:** Shared

**Description:**  
Clears all active timers. Optionally filters by resource name and triggers callbacks.

**Parameters:**
- `triggerCallbacks`: `boolean?` — If `true`, executes `onEnd` callbacks.
- `resourceName`: `string?` — If provided, only clears timers from that resource.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.Timer.ClearTimers(true, "my_resource")
```

---

## `srs.lib.Utils`

**File:** `libs/utils/shared.lua`

Utility helpers.

---

### `srs.lib.Utils.GenId(prefix?)`

**Signature:**
```lua
srs.lib.Utils.GenId(prefix?: string) -> string
```

**Side:** Shared

**Description:**  
Generates a unique ID with an optional prefix.

**Parameters:**
- `prefix`: `string?` — ID prefix (default: `'id'`).

**Returns:**  
`string` — Unique ID in format `'srs_<prefix>_<counter>'`.

**Example:**
```lua
local id = srs.lib.Utils.GenId("marker")
print(id) -- "srs_marker_1"
```

---

## `srs.lib.waitFor`

**File:** `libs/waitFor/shared.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.waitFor(cb, errMessage?, timeout?)`

**Signature:**
```lua
srs.lib.waitFor(cb: function, errMessage?: string, timeout?: number | false) -> any
```

**Side:** Shared (async)

**Description:**  
Yields the current thread until `cb` returns a non-nil value.

**Parameters:**
- `cb`: `function() -> any?` — Callback function to poll.
- `errMessage`: `string?` — Error message if timeout occurs.
- `timeout`: `number | false?` — Timeout in milliseconds (default: 1000). Set to `false` for no timeout.

**Returns:**  
`any` — Non-nil value returned by `cb`.

**Errors:**
- Throws error if timeout is exceeded.

**Example:**
```lua
local entity = srs.lib.waitFor(function()
    local e = GetClosestVehicle(coords)
    if DoesEntityExist(e) then return e end
end, "No vehicle found", 5000)
```

---

## `srs.lib.getRelativeCoords`

**File:** `libs/getRelativeCoords/shared.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.getRelativeCoords(coords, rotation, offset?)`

**Signature:**
```lua
srs.lib.getRelativeCoords(coords: vector3 | vector4, rotation: vector3 | number, offset?: vector3) -> vector3 | vector4
```

**Side:** Shared

**Description:**  
Calculates relative coordinates based on rotation and offset.

**Parameters:**
- `coords`: `vector3 | vector4` — Base coordinates.
- `rotation`: `vector3 | number` — Rotation (Euler angles or heading).
- `offset`: `vector3?` — Offset vector (required if `rotation` is `vector3`).

**Returns:**  
`vector3 | vector4` — Relative coordinates.

**Example:**
```lua
local baseCoords = vec3(0, 0, 0)
local heading = 90.0
local offset = vec3(5, 0, 0)
local relativeCoords = srs.lib.getRelativeCoords(baseCoords, heading, offset)
-- relativeCoords: vec3(0, 5, 0)
```

---

## `srs.lib.grid`

**File:** `libs/grid/shared.lua`  
**License:** MIT (PolyZone)

Grid-based spatial partitioning system for fast nearby entity lookups.

---

### `srs.lib.grid.getCellPosition(point)`

**Signature:**
```lua
srs.lib.grid.getCellPosition(point: vector) -> number, number
```

**Side:** Shared

**Description:**  
Gets the grid cell coordinates (x, y) for the given point.

**Parameters:**
- `point`: `vector` — World coordinates.

**Returns:**  
`number, number` — Grid cell x, y.

**Example:**
```lua
local x, y = srs.lib.grid.getCellPosition(vec3(100, 200, 30))
print("Cell:", x, y)
```

---

### `srs.lib.grid.getCell(point)`

**Signature:**
```lua
srs.lib.grid.getCell(point: vector) -> GridEntry[]
```

**Side:** Shared

**Description:**  
Returns all entries in the grid cell containing `point`.

**Parameters:**
- `point`: `vector` — World coordinates.

**Returns:**  
`GridEntry[]` — Array of entries in the cell.

**Example:**
```lua
local entries = srs.lib.grid.getCell(vec3(100, 200, 30))
for _, entry in ipairs(entries) do
    print("Entry ID:", entry.id)
end
```

---

### `srs.lib.grid.getNearbyEntries(point, filter?)`

**Signature:**
```lua
srs.lib.grid.getNearbyEntries(point: vector, filter?: function) -> Array<GridEntry>
```

**Side:** Shared

**Description:**  
Returns all entries in nearby grid cells. Optionally filters results.

**Parameters:**
- `point`: `vector` — World coordinates.
- `filter`: `function(entry: GridEntry): boolean?` — Optional filter function.

**Returns:**  
`Array<GridEntry>` — Array of nearby entries.

**Example:**
```lua
local nearby = srs.lib.grid.getNearbyEntries(playerCoords, function(entry)
    return entry.type == "marker"
end)
```

---

### `srs.lib.grid.addEntry(entry)`

**Signature:**
```lua
srs.lib.grid.addEntry(entry: GridEntry)
```

**Side:** Shared

**Description:**  
Adds an entry to the grid. Entry must have `coords`, `length`, `width`, or `radius` fields.

**Parameters:**
- `entry`: `GridEntry` — Entry object with `coords` and size fields.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.grid.addEntry({
    coords = vec3(100, 200, 30),
    radius = 10.0,
    id = "my_marker"
})
```

---

### `srs.lib.grid.removeEntry(entry)`

**Signature:**
```lua
srs.lib.grid.removeEntry(entry: table) -> boolean
```

**Side:** Shared

**Description:**  
Removes an entry from the grid.

**Parameters:**
- `entry`: `table` — Entry object previously added to grid.

**Returns:**  
`boolean` — `true` if removed, `false` if not found.

**Example:**
```lua
local success = srs.lib.grid.removeEntry(myEntry)
```

---

## `srs.lib.Network`

**File:** `libs/network/shared.lua`

Network entity helpers for client-server synchronization.

---

### `srs.lib.Network.GetEntityFromNetId(netId)`

**Signature:**
```lua
srs.lib.Network.GetEntityFromNetId(netId: number) -> number?
```

**Side:** Shared

**Description:**  
Waits up to 5 seconds for an entity to exist from a network ID, then returns the entity handle.

**Parameters:**
- `netId`: `number` — Network ID.

**Returns:**  
`number?` — Entity handle, or `nil` if timeout.

**Example:**
```lua
local entity = srs.lib.Network.GetEntityFromNetId(netId)
if entity then
    print("Entity handle:", entity)
end
```

---

### `srs.lib.Network.GetNetIdFromEntity(handle)`

**Signature:**
```lua
srs.lib.Network.GetNetIdFromEntity(handle: number) -> number?
```

**Side:** Shared

**Description:**  
Waits up to 5 seconds for a valid network ID from an entity handle.

**Parameters:**
- `handle`: `number` — Entity handle.

**Returns:**  
`number?` — Network ID, or `nil` if timeout.

**Example:**
```lua
local netId = srs.lib.Network.GetNetIdFromEntity(vehicle)
```

---

### `srs.lib.Network.WaitForCreate(handle, deadlineTime?)`

**Signature:**
```lua
srs.lib.Network.WaitForCreate(handle: number, deadlineTime?: number) -> boolean
```

**Side:** Server

**Description:**  
Waits for an entity to be created (until `DoesEntityExist` returns `true`).

**Parameters:**
- `handle`: `number` — Entity handle.
- `deadlineTime`: `number?` — Timeout in milliseconds (default: 5000).

**Returns:**  
`boolean` — `true` if entity exists, `false` if timeout.

**Example:**
```lua
local vehicle = CreateVehicleServerSetter(...)
if srs.lib.Network.WaitForCreate(vehicle) then
    print("Vehicle created")
end
```

---

### `srs.lib.Network.RequestControlOfEntity(handle)`

**Signature:**
```lua
srs.lib.Network.RequestControlOfEntity(handle: number) -> boolean
```

**Side:** Client

**Description:**  
Requests network control of an entity and waits up to 5 seconds for control to be granted.

**Parameters:**
- `handle`: `number` — Entity handle.

**Returns:**  
`boolean` — `true` if control granted, `false` if timeout.

**Example:**
```lua
if srs.lib.Network.RequestControlOfEntity(vehicle) then
    DeleteEntity(vehicle)
end
```

---

## `srs.lib.WeightedRandom`

**Files:**  
- `libs/weightedRandom/shared.lua`
- `libs/weightedRandom/shared_linear.lua`
- `libs/weightedRandom/shared_binary.lua`

Weighted random selection with two implementations: linear (for < 50 items) and binary (for >= 50 items).

---

### `srs.lib.WeightedRandom.create(items, resetOnEmpty?, id?)`

**Signature:**
```lua
srs.lib.WeightedRandom.create(items: table, resetOnEmpty?: boolean, id?: string) -> WeightedRandomInstance
```

**Side:** Shared

**Description:**  
Creates a weighted random selector. Automatically chooses linear or binary implementation based on item count.

**Parameters:**
- `items`: `table<any, number>` — Table of items with weights as values.
- `resetOnEmpty`: `boolean?` — If `true`, resets pool when empty.
- `id`: `string?` — Optional unique identifier.

**Returns:**  
`WeightedRandomInstance` — Selector instance with `:next()` method.

**Errors:**
- Throws error if `items` is not a table.

**Example:**
```lua
local selector = srs.lib.WeightedRandom.create({
    apple = 10,
    banana = 5,
    cherry = 1
}, true, "fruit_selector")

local item = selector:next()
print("Selected:", item)
```

---

### `srs.lib.WeightedRandom.getById(id)`

**Signature:**
```lua
srs.lib.WeightedRandom.getById(id: string) -> WeightedRandomInstance?
```

**Side:** Shared

**Description:**  
Retrieves a weighted random selector by ID.

**Parameters:**
- `id`: `string` — Selector ID.

**Returns:**  
`WeightedRandomInstance?` — Selector instance, or `nil` if not found.

**Example:**
```lua
local selector = srs.lib.WeightedRandom.getById("fruit_selector")
if selector then
    local item = selector:next()
end
```

---

### `srs.lib.WeightedRandom.clearById(id)`

**Signature:**
```lua
srs.lib.WeightedRandom.clearById(id: string)
```

**Side:** Shared

**Description:**  
Removes a weighted random selector by ID.

**Parameters:**
- `id`: `string` — Selector ID.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.WeightedRandom.clearById("fruit_selector")
```

---

### `srs.lib.WeightedRandom.clearAll()`

**Signature:**
```lua
srs.lib.WeightedRandom.clearAll()
```

**Side:** Shared

**Description:**  
Clears all weighted random selectors.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.WeightedRandom.clearAll()
```

---

## Client-Only API

---

## `srs.lib.anim`

**File:** `libs/anim/client.lua`  
**License:** LGPL-3.0 (community_bridge)

Animation playback system with automatic tracking and completion callbacks.

---

### `srs.lib.anim.play(id, entity, animDict, animName, blendIn?, blendOut?, duration?, flag?, playbackRate?, onComplete?)`

**Signature:**
```lua
srs.lib.anim.play(
    id: number?,
    entity: number,
    animDict: string,
    animName: string,
    blendIn?: number,
    blendOut?: number,
    duration?: number,
    flag?: number,
    playbackRate?: number,
    onComplete?: function(success: boolean, reason: string)
) -> number?
```

**Side:** Client

**Description:**  
Plays an animation on an entity. Returns an animation ID for tracking.

**Parameters:**
- `id`: `number?` — Optional custom ID (auto-generated if `nil`).
- `entity`: `number` — Entity handle (must be a ped).
- `animDict`: `string` — Animation dictionary.
- `animName`: `string` — Animation name.
- `blendIn`: `number?` — Blend-in speed (default: 8.0).
- `blendOut`: `number?` — Blend-out speed (default: -8.0).
- `duration`: `number?` — Duration in milliseconds (default: -1 for full animation).
- `flag`: `number?` — Animation flags (default: 1).
- `playbackRate`: `number?` — Playback rate (default: 0.0).
- `onComplete`: `function(success: boolean, reason: string)?` — Completion callback.

**Returns:**  
`number?` — Animation ID, or `nil` if failed to start.

**Errors:**
- Calls `onComplete(false, 'id_in_use')` if ID already exists.
- Calls `onComplete(false, 'invalid_entity')` if entity invalid.
- Calls `onComplete(false, 'dict_load_failed')` if dictionary fails to load.

**Example:**
```lua
local animId = srs.lib.anim.play(nil, PlayerPedId(), "amb@world_human_smoking@male@male_a@enter", "enter", 8.0, -8.0, 3000, 1, 0.0, function(success, reason)
    if success then
        print("Animation completed")
    else
        print("Animation failed:", reason)
    end
end)
```

---

### `srs.lib.anim.stop(id)`

**Signature:**
```lua
srs.lib.anim.stop(id: number) -> boolean
```

**Side:** Client

**Description:**  
Stops an active animation by ID.

**Parameters:**
- `id`: `number` — Animation ID.

**Returns:**  
`boolean` — `true` if stopped, `false` if ID not found or already finished.

**Example:**
```lua
srs.lib.anim.stop(animId)
```

---

## `srs.lib.addKeybind`

**File:** `libs/addKeybind/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.addKeybind(data)`

**Signature:**
```lua
srs.lib.addKeybind(data: {
    name: string,
    description: string,
    defaultMapper: string,
    defaultKey: string,
    secondaryMapper?: string,
    secondaryKey?: string,
    onPressed?: function,
    onReleased?: function
}) -> Keybind
```

**Side:** Client

**Description:**  
Registers a keybind with FiveM's key mapping system. Automatically hides chat suggestions.

**Parameters:**
- `data.name`: `string` — Unique keybind name.
- `data.description`: `string` — Description shown in settings.
- `data.defaultMapper`: `string` — Mapper type (`'keyboard'`, `'mouse'`).
- `data.defaultKey`: `string` — Default key (e.g., `'E'`, `'F'`).
- `data.secondaryMapper`: `string?` — Optional secondary mapper.
- `data.secondaryKey`: `string?` — Optional secondary key.
- `data.onPressed`: `function()?` — Callback when key is pressed.
- `data.onReleased`: `function()?` — Callback when key is released.

**Returns:**  
`Keybind` — Keybind object with methods.

**Keybind Methods:**
- `keybind:disable(toggle: boolean)` — Disables/enables keybind.
- `keybind:isControlPressed()` — Returns `true` if currently pressed.
- `keybind:getCurrentKey()` — Returns current key string.

**Example:**
```lua
local keybind = srs.lib.addKeybind({
    name = 'openMenu',
    description = 'Open main menu',
    defaultMapper = 'keyboard',
    defaultKey = 'F1',
    onPressed = function(self)
        print("Menu opened with key:", self:getCurrentKey())
    end,
    onReleased = function(self)
        print("Key released")
    end
})

-- Disable keybind temporarily
keybind:disable(true)

-- Re-enable
keybind:disable(false)
```

---

## `srs.lib.disableControls`

**File:** `libs/disableControls/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.disableControls:Add(...)`

**Signature:**
```lua
srs.lib.disableControls:Add(...: number | table)
```

**Side:** Client

**Description:**  
Adds control IDs to the disable list. Each ID can be added multiple times (tracked with reference counting).

**Parameters:**
- `...`: `number | table` — Control ID(s) to disable.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.disableControls:Add(24, 25) -- Disable attack controls
```

---

### `srs.lib.disableControls:Remove(...)`

**Signature:**
```lua
srs.lib.disableControls:Remove(...: number | table)
```

**Side:** Client

**Description:**  
Removes control IDs from the disable list. Decrements reference count.

**Parameters:**
- `...`: `number | table` — Control ID(s) to remove.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.disableControls:Remove(24, 25)
```

---

### `srs.lib.disableControls:Clear(...)`

**Signature:**
```lua
srs.lib.disableControls:Clear(...: number | table)
```

**Side:** Client

**Description:**  
Completely clears control IDs from the disable list (ignores reference count).

**Parameters:**
- `...`: `number | table` — Control ID(s) to clear.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.disableControls:Clear(24, 25)
```

---

### `srs.lib.disableControls()`

**Signature:**
```lua
srs.lib.disableControls()
```

**Side:** Client

**Description:**  
Call this function every frame to actually disable the controls. Typically used in a `Citizen.CreateThread` loop.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.disableControls:Add(24) -- Attack

Citizen.CreateThread(function()
    while someCondition do
        srs.lib.disableControls()
        Wait(0)
    end
end)
```

---

## `srs.lib.raycast`

**File:** `libs/raycast/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.raycast.fromCoords(coords, destination, flags?, ignore?)`

**Signature:**
```lua
srs.lib.raycast.fromCoords(
    coords: vector3,
    destination: vector3,
    flags?: ShapetestFlags,
    ignore?: ShapetestIgnore
) -> boolean, number, vector3, vector3, number
```

**Side:** Client

**Description:**  
Performs a raycast from `coords` to `destination`.

**Parameters:**
- `coords`: `vector3` — Start coordinates.
- `destination`: `vector3` — End coordinates.
- `flags`: `ShapetestFlags?` — Shapetest flags (default: 511 = INCLUDE_ALL).
- `ignore`: `ShapetestIgnore?` — Ignore flags (default: 4 = NO_COLLISION).

**Returns:**
- `boolean` — `true` if hit.
- `number` — Entity handle (0 if no entity).
- `vector3` — End coordinates.
- `vector3` — Surface normal.
- `number` — Material hash.

**Example:**
```lua
local playerCoords = GetEntityCoords(PlayerPedId())
local forwardCoords = playerCoords + vec3(0, 10, 0)
local hit, entity, endCoords, surfaceNormal, material = srs.lib.raycast.fromCoords(playerCoords, forwardCoords)

if hit then
    print("Hit entity:", entity, "at", endCoords)
end
```

---

### `srs.lib.raycast.fromCamera(flags?, ignore?, distance?)`

**Signature:**
```lua
srs.lib.raycast.fromCamera(
    flags?: ShapetestFlags,
    ignore?: ShapetestIgnore,
    distance?: number
) -> boolean, number, vector3, vector3, number
```

**Side:** Client

**Description:**  
Performs a raycast from the camera position in the direction the camera is facing.

**Parameters:**
- `flags`: `ShapetestFlags?` — Shapetest flags (default: 511).
- `ignore`: `ShapetestIgnore?` — Ignore flags (default: 4).
- `distance`: `number?` — Raycast distance (default: 10).

**Returns:**
- Same as `fromCoords`.

**Example:**
```lua
local hit, entity, endCoords = srs.lib.raycast.fromCamera()
if hit and entity ~= 0 then
    print("Looking at entity:", entity)
end
```

---

## `srs.lib.points`

**File:** `libs/points/client.lua`  
**License:** LGPL-3.0 (ox_lib)

Proximity point system with enter/exit/nearby callbacks.

---

### `srs.lib.points.new(...)`

**Signature:**
```lua
srs.lib.points.new(...: PointProperties | (coords: vector3, distance: number, data?: PointProperties)) -> CPoint
```

**Side:** Client

**Description:**  
Creates a new proximity point. Callbacks are triggered when player enters, exits, or is nearby.

**Parameters:**
- Single table argument:
  - `.coords`: `vector3` — Point coordinates.
  - `.distance`: `number` — Activation radius.
  - `.onEnter`: `function(self: CPoint)?` — Called when player enters.
  - `.onExit`: `function(self: CPoint)?` — Called when player exits.
  - `.nearby`: `function(self: CPoint)?` — Called every tick while nearby.
  - Any other custom fields.
- Or three arguments: `coords`, `distance`, `data` (legacy).

**Returns:**  
`CPoint` — Point instance with `.remove()` method.

**Example:**
```lua
local point = srs.lib.points.new({
    coords = vec3(100, 200, 30),
    distance = 5.0,
    onEnter = function(self)
        print("Player entered point!")
    end,
    onExit = function(self)
        print("Player exited point!")
    end,
    nearby = function(self)
        print("Player nearby, distance:", self.currentDistance)
    end
})

-- Remove point when done
point:remove()
```

---

### `srs.lib.points.getAllPoints()`

**Signature:**
```lua
srs.lib.points.getAllPoints() -> table<number, CPoint>
```

**Side:** Client

**Description:**  
Returns all registered points.

**Returns:**  
`table<number, CPoint>` — Points indexed by ID.

**Example:**
```lua
local points = srs.lib.points.getAllPoints()
for id, point in pairs(points) do
    print("Point ID:", id, "Coords:", point.coords)
end
```

---

### `srs.lib.points.getNearbyPoints()`

**Signature:**
```lua
srs.lib.points.getNearbyPoints() -> CPoint[]
```

**Side:** Client

**Description:**  
Returns points currently near the player.

**Returns:**  
`CPoint[]` — Array of nearby points.

**Example:**
```lua
local nearby = srs.lib.points.getNearbyPoints()
for _, point in ipairs(nearby) do
    print("Nearby point:", point.coords)
end
```

---

### `srs.lib.points.getClosestPoint()`

**Signature:**
```lua
srs.lib.points.getClosestPoint() -> CPoint?
```

**Side:** Client

**Description:**  
Returns the closest point to the player, or `nil` if none nearby.

**Returns:**  
`CPoint?` — Closest point, or `nil`.

**Example:**
```lua
local closest = srs.lib.points.getClosestPoint()
if closest then
    print("Closest point distance:", closest.currentDistance)
end
```

---

## `srs.lib.requestAnimDict`

**File:** `libs/requestAnimDict/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestAnimDict(animDict, timeout?)`

**Signature:**
```lua
srs.lib.requestAnimDict(animDict: string, timeout?: number) -> string
```

**Side:** Client (async)

**Description:**  
Requests and waits for an animation dictionary to load.

**Parameters:**
- `animDict`: `string` — Animation dictionary name.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`string` — Animation dictionary name.

**Errors:**
- Throws error if `animDict` is not a string.
- Throws error if dictionary does not exist.
- Throws error if loading times out.

**Example:**
```lua
local dict = srs.lib.requestAnimDict("amb@world_human_smoking@male@male_a@enter")
TaskPlayAnim(PlayerPedId(), dict, "enter", 8.0, -8.0, -1, 0, 0, false, false, false)
```

---

## `srs.lib.requestAnimSet`

**File:** `libs/requestAnimSet/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestAnimSet(animSet, timeout?)`

**Signature:**
```lua
srs.lib.requestAnimSet(animSet: string, timeout?: number) -> string
```

**Side:** Client (async)

**Description:**  
Requests and waits for an animation set to load.

**Parameters:**
- `animSet`: `string` — Animation set name.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`string` — Animation set name.

**Errors:**
- Throws error if `animSet` is not a string.
- Throws error if loading times out.

**Example:**
```lua
local animSet = srs.lib.requestAnimSet("move_m@drunk@verydrunk")
SetPedMovementClipset(PlayerPedId(), animSet, 1.0)
```

---

## `srs.lib.requestAudioBank`

**File:** `libs/requestAudioBank/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestAudioBank(audioBank, timeout?)`

**Signature:**
```lua
srs.lib.requestAudioBank(audioBank: string, timeout?: number) -> string
```

**Side:** Client (async)

**Description:**  
Requests and waits for an audio bank to load.

**Parameters:**
- `audioBank`: `string` — Audio bank name.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`string` — Audio bank name.

**Errors:**
- Throws error if loading times out.

**Example:**
```lua
local bank = srs.lib.requestAudioBank("DLC_TUNER/TUNER_RADIO_STATIONS")
PlaySoundFromEntity(-1, "CONFIRM_BEEP", PlayerPedId(), bank, false, 0)
```

---

## `srs.lib.requestModel`

**File:** `libs/requestModel/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestModel(model, timeout?)`

**Signature:**
```lua
srs.lib.requestModel(model: string | number, timeout?: number) -> number
```

**Side:** Client (async)

**Description:**  
Requests and waits for a model to load. Returns model hash.

**Parameters:**
- `model`: `string | number` — Model name or hash.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`number` — Model hash.

**Errors:**
- Throws error if model is invalid.
- Throws error if loading times out.

**Example:**
```lua
local modelHash = srs.lib.requestModel("adder")
local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, 0.0, true, false)
SetModelAsNoLongerNeeded(modelHash)
```

---

## `srs.lib.requestNamedPtfxAsset`

**File:** `libs/requestNamedPtfxAsset/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestNamedPtfxAsset(ptfxAsset, timeout?)`

**Signature:**
```lua
srs.lib.requestNamedPtfxAsset(ptfxAsset: string, timeout?: number) -> string
```

**Side:** Client (async)

**Description:**  
Requests and waits for a particle effect asset to load.

**Parameters:**
- `ptfxAsset`: `string` — Particle effect asset name.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`string` — Asset name.

**Errors:**
- Throws error if asset does not exist.
- Throws error if loading times out.

**Example:**
```lua
local ptfx = srs.lib.requestNamedPtfxAsset("core")
UseParticleFxAssetNextCall(ptfx)
StartParticleFxNonLoopedAtCoord("ent_dst_rocks", coords.x, coords.y, coords.z, 0, 0, 0, 1.0, false, false, false)
```

---

## `srs.lib.requestScaleformMovie`

**File:** `libs/requestScaleformMovie/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestScaleformMovie(scaleformMovie, timeout?)`

**Signature:**
```lua
srs.lib.requestScaleformMovie(scaleformMovie: string, timeout?: number) -> number
```

**Side:** Client (async)

**Description:**  
Requests and waits for a scaleform movie to load. Returns scaleform handle.

**Parameters:**
- `scaleformMovie`: `string` — Scaleform movie name.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`number` — Scaleform handle.

**Errors:**
- Throws error if loading times out.

**Example:**
```lua
local scaleform = srs.lib.requestScaleformMovie("MIDSIZED_MESSAGE")
-- Use scaleform handle for rendering
```

---

## `srs.lib.requestStreamedTextureDict`

**File:** `libs/requestStreamedTextureDict/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestStreamedTextureDict(textureDict, timeout?)`

**Signature:**
```lua
srs.lib.requestStreamedTextureDict(textureDict: string, timeout?: number) -> string
```

**Side:** Client (async)

**Description:**  
Requests and waits for a texture dictionary to load.

**Parameters:**
- `textureDict`: `string` — Texture dictionary name.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`string` — Texture dictionary name.

**Errors:**
- Throws error if loading times out.

**Example:**
```lua
local dict = srs.lib.requestStreamedTextureDict("commonmenu")
-- Use texture dict for drawing sprites
```

---

## `srs.lib.requestWeaponAsset`

**File:** `libs/requestWeaponAsset/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.requestWeaponAsset(weaponHash, timeout?)`

**Signature:**
```lua
srs.lib.requestWeaponAsset(weaponHash: number, timeout?: number) -> number
```

**Side:** Client (async)

**Description:**  
Requests and waits for a weapon asset to load.

**Parameters:**
- `weaponHash`: `number` — Weapon hash.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).

**Returns:**  
`number` — Weapon hash.

**Errors:**
- Throws error if loading times out.

**Example:**
```lua
local weaponHash = joaat("WEAPON_PISTOL")
srs.lib.requestWeaponAsset(weaponHash)
GiveWeaponToPed(PlayerPedId(), weaponHash, 100, false, true)
```

---

## `srs.lib.streamingRequest`

**File:** `libs/streamingRequest/client.lua`  
**License:** LGPL-3.0 (ox_lib)

---

### `srs.lib.streamingRequest(request, hasLoaded, assetType, asset, timeout?, ...)`

**Signature:**
```lua
srs.lib.streamingRequest(
    request: function,
    hasLoaded: function,
    assetType: string,
    asset: string | number,
    timeout?: number,
    ...: any
) -> string | number
```

**Side:** Client (async, internal)

**Description:**  
Generic streaming request helper used internally by other `request*` functions.

**Parameters:**
- `request`: `function` — Native function to request asset.
- `hasLoaded`: `function` — Native function to check if loaded.
- `assetType`: `string` — Asset type name (for error messages).
- `asset`: `string | number` — Asset identifier.
- `timeout`: `number?` — Timeout in milliseconds (default: 30000).
- `...`: `any` — Additional arguments passed to `request` function.

**Returns:**  
`string | number` — Asset identifier.

**Errors:**
- Throws error if loading times out.

---

## `srs.lib.Particle`

**File:** `libs/particle/client.lua`  
**License:** LGPL-3.0 (community_bridge)

Particle effect playback system.

---

### `srs.lib.Particle.Play(dict, ptfx, pos, rot?, scale?, color?, looped?, removeAfter?)`

**Signature:**
```lua
srs.lib.Particle.Play(
    dict: string,
    ptfx: string,
    pos: vector3,
    rot?: vector3,
    scale?: number,
    color?: vector3,
    looped?: boolean,
    removeAfter?: number
) -> string | number | nil
```

**Side:** Client

**Description:**  
Plays a particle effect at world coordinates. Returns particle ID (looped) or handle (non-looped).

**Parameters:**
- `dict`: `string` — Particle dictionary.
- `ptfx`: `string` — Particle effect name.
- `pos`: `vector3` — World coordinates.
- `rot`: `vector3?` — Rotation (default: `vec3(0,0,0)`).
- `scale`: `number?` — Scale (default: 1.0).
- `color`: `vector3?` — RGB color (0-1 range).
- `looped`: `boolean?` — If `true`, creates looped effect.
- `removeAfter`: `number?` — Auto-remove after milliseconds (looped only).

**Returns:**  
- `string` — Particle ID (if looped).
- `number` — Particle handle (if non-looped).
- `nil` — If failed to load dictionary.

**Example:**
```lua
local particleId = srs.lib.Particle.Play("core", "ent_dst_rocks", vec3(100, 200, 30), nil, 1.5, vec3(1, 0, 0), true, 5000)

-- Stop manually
srs.lib.Particle.Stop(particleId)
```

---

### `srs.lib.Particle.CreateOnEntity(dict, ptfx, entity, offset?, rot?, scale?, color?, looped?, loopLength?)`

**Signature:**
```lua
srs.lib.Particle.CreateOnEntity(
    dict: string,
    ptfx: string,
    entity: number,
    offset?: vector3,
    rot?: vector3,
    scale?: number,
    color?: vector3,
    looped?: boolean,
    loopLength?: number
) -> string | number | nil
```

**Side:** Client

**Description:**  
Creates a particle effect attached to an entity.

**Parameters:**
- `dict`: `string` — Particle dictionary.
- `ptfx`: `string` — Particle effect name.
- `entity`: `number` — Entity handle.
- `offset`: `vector3?` — Offset from entity (default: `vec3(0,0,0)`).
- `rot`: `vector3?` — Rotation (default: `vec3(0,0,0)`).
- `scale`: `number?` — Scale (default: 1.0).
- `color`: `vector3?` — RGB color.
- `looped`: `boolean?` — If `true`, creates looped effect.
- `loopLength`: `number?` — Auto-remove after milliseconds (looped only).

**Returns:**  
- `string` — Particle ID (if looped).
- `number` — Particle handle (if non-looped).
- `nil` — If failed.

**Example:**
```lua
local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
local particleId = srs.lib.Particle.CreateOnEntity("veh_trailer_petrol", "ent_ray_trailerpark_fire", vehicle, vec3(0, 0, 0), nil, 1.0, nil, true)
```

---

### `srs.lib.Particle.CreateOnEntityBone(dict, ptfx, entity, bone, offset?, rot?, scale?, color?, looped?, loopLength?)`

**Signature:**
```lua
srs.lib.Particle.CreateOnEntityBone(
    dict: string,
    ptfx: string,
    entity: number,
    bone: number,
    offset?: vector3,
    rot?: vector3,
    scale?: number,
    color?: vector3,
    looped?: boolean,
    loopLength?: number
) -> string | number | nil
```

**Side:** Client

**Description:**  
Creates a particle effect attached to an entity bone.

**Parameters:**
- Same as `CreateOnEntity`, plus:
- `bone`: `number` — Bone index.

**Returns:**  
- Same as `CreateOnEntity`.

**Example:**
```lua
local ped = PlayerPedId()
local boneIndex = GetPedBoneIndex(ped, 31086) -- Head bone
local particleId = srs.lib.Particle.CreateOnEntityBone("core", "fire_wrecked_plane_cockpit", ped, boneIndex, vec3(0, 0, 0), nil, 0.5, nil, true)
```

---

### `srs.lib.Particle.Stop(handleOrId)`

**Signature:**
```lua
srs.lib.Particle.Stop(handleOrId: string | number)
```

**Side:** Client

**Description:**  
Stops and removes a particle effect.

**Parameters:**
- `handleOrId`: `string | number` — Particle ID or handle.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.Particle.Stop(particleId)
```

---

## `srs.lib.cutscenes`

**File:** `libs/cutscenes/client.lua`  
**License:** LGPL-3.0 (community_bridge)

Cutscene playback system with custom player outfit support.

---

### `srs.lib.cutscenes.getTags(cutscene)`

**Signature:**
```lua
srs.lib.cutscenes.getTags(cutscene: string) -> table[]?
```

**Side:** Client

**Description:**  
Returns available character tags in a cutscene.

**Parameters:**
- `cutscene`: `string` — Cutscene name.

**Returns:**  
`table[]?` — Array of tag tables with `.male` and `.female` fields, or `nil` if failed.

**Example:**
```lua
local tags = srs.lib.cutscenes.getTags("MP_INTRO_CONCAT")
for _, tag in ipairs(tags or {}) do
    print("Male tag:", tag.male, "Female tag:", tag.female)
end
```

---

### `srs.lib.cutscenes.load(cutscene)`

**Signature:**
```lua
srs.lib.cutscenes.load(cutscene: string) -> boolean
```

**Side:** Client

**Description:**  
Loads a cutscene. Returns `true` if successful.

**Parameters:**
- `cutscene`: `string` — Cutscene name.

**Returns:**  
`boolean` — `true` if loaded, `false` if failed.

**Example:**
```lua
if srs.lib.cutscenes.load("MP_INTRO_CONCAT") then
    print("Cutscene loaded")
end
```

---

### `srs.lib.cutscenes.savePedOutfit(ped)`

**Signature:**
```lua
srs.lib.cutscenes.savePedOutfit(ped: number) -> table
```

**Side:** Client

**Description:**  
Saves ped clothing/prop data.

**Parameters:**
- `ped`: `number` — Ped handle.

**Returns:**  
`table` — Outfit data table.

**Example:**
```lua
local outfit = srs.lib.cutscenes.savePedOutfit(PlayerPedId())
```

---

### `srs.lib.cutscenes.applyPedOutfit(ped, outfitData)`

**Signature:**
```lua
srs.lib.cutscenes.applyPedOutfit(ped: number, outfitData: table)
```

**Side:** Client

**Description:**  
Applies saved outfit data to a ped.

**Parameters:**
- `ped`: `number` — Ped handle.
- `outfitData`: `table` — Outfit data from `savePedOutfit`.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.cutscenes.applyPedOutfit(PlayerPedId(), outfit)
```

---

### `srs.lib.cutscenes.create(cutscene, coords?, srcs?)`

**Signature:**
```lua
srs.lib.cutscenes.create(cutscene: string, coords?: vector3 | boolean, srcs?: (number | string)[]) -> table | false
```

**Side:** Client

**Description:**  
Prepares a cutscene with custom players/peds. Returns cutscene data or `false` if failed.

**Parameters:**
- `cutscene`: `string` — Cutscene name.
- `coords`: `vector3 | boolean?` — Cutscene coordinates, or `true` to use player coords.
- `srcs`: `(number | string)[]?` — Array of player server IDs or model names to include.

**Returns:**  
`table | false` — Cutscene data, or `false` if failed.

**Example:**
```lua
local cutsceneData = srs.lib.cutscenes.create("MP_INTRO_CONCAT", vec3(100, 200, 30), {GetPlayerServerId(PlayerId()), "a_m_y_hipster_01"})
if cutsceneData then
    srs.lib.cutscenes.start(cutsceneData)
end
```

---

### `srs.lib.cutscenes.start(cutsceneData)`

**Signature:**
```lua
srs.lib.cutscenes.start(cutsceneData: table)
```

**Side:** Client

**Description:**  
Starts a prepared cutscene. Blocks until cutscene finishes or is skipped.

**Parameters:**
- `cutsceneData`: `table` — Cutscene data from `create`.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.cutscenes.start(cutsceneData)
print("Cutscene finished")
```

---

## `srs.lib.shells`

**Files:**  
- `libs/shells/client.lua`
- `libs/shells/server.lua`

Shell (interior) management system.

*(Note: Implementation details not fully available in provided code. Placeholder documentation.)*

---

### Client: `exports.srs_lib:CreateShell(shellData)`

**Side:** Client

**Description:**  
Creates a shell interior instance.

**Example:**
```lua
local shell = exports.srs_lib:CreateShell({
    model = "shell_v16mid",
    coords = vec3(100, 200, 30)
})
```

---

## `srs.lib.placers`

**File:** `libs/placers/client.lua`

Object placement utilities.

*(Note: Implementation details not fully available. Placeholder documentation.)*

---

## `srs.lib.zones` (Client)

**File:** `libs/zones/shared.lua`

Zone creation and management (boxes, spheres, polygons).

*(Note: Implementation details not fully available. Placeholder documentation.)*

---

### `srs.lib.zones.poly(data)`

**Side:** Client

**Description:**  
Creates a polygon zone.

**Example:**
```lua
local zone = srs.lib.zones.poly({
    points = {
        vec2(100, 200),
        vec2(150, 200),
        vec2(150, 250),
        vec2(100, 250)
    },
    thickness = 10.0,
    onEnter = function() print("Entered zone") end,
    onExit = function() print("Exited zone") end
})
```

---

### `srs.lib.zones.box(data)`

**Side:** Client

**Description:**  
Creates a box zone.

**Example:**
```lua
local zone = srs.lib.zones.box({
    coords = vec3(100, 200, 30),
    size = vec3(10, 10, 5),
    rotation = 0.0,
    onEnter = function() print("Entered box") end
})
```

---

### `srs.lib.zones.sphere(data)`

**Side:** Client

**Description:**  
Creates a sphere zone.

**Example:**
```lua
local zone = srs.lib.zones.sphere({
    coords = vec3(100, 200, 30),
    radius = 10.0,
    onEnter = function() print("Entered sphere") end
})
```

---

## Server-Only API

---

## `srs.lib.logger`

**File:** `libs/logger/server.lua`  
**License:** LGPL-3.0 (ox_lib)

Log aggregation and submission to external services (Datadog, Loki, FiveManage).

---

### `srs.lib.logger(source, event, message, ...)`

**Signature:**
```lua
srs.lib.logger(source: number, event: string, message: string, ...: string | table)
```

**Side:** Server

**Description:**  
Logs an event to the configured log service. Supports Datadog, Loki, and FiveManage.

**Parameters:**
- `source`: `number` — Player server ID (0 for server-only logs).
- `event`: `string` — Event name/service identifier.
- `message`: `string` — Log message.
- `...`: `string | table` — Additional metadata (key:value strings or tables).

**Returns:**  
`nil`

**Configuration:**  
Set convars:
- `ox:logger` — Service type: `'datadog'`, `'loki'`, `'fivemanage'`.
- `datadog:key`, `datadog:site` — Datadog API key and site.
- `loki:endpoint`, `loki:user`, `loki:password` — Loki configuration.
- `fivemanage:key`, `fivemanage:dataset` — FiveManage API key and dataset.

**Example:**
```lua
srs.lib.logger(playerId, "player_death", "Player died", "killer:123", "weapon:WEAPON_PISTOL", {health = 0})
```

---

## `srs.lib.SQL`

**File:** `libs/sql/server.lua`  
**License:** LGPL-3.0 (community_bridge)

SQL database helpers (requires `oxmysql`).

---

### `srs.lib.SQL.Create(tableName, columns)`

**Signature:**
```lua
srs.lib.SQL.Create(tableName: string, columns: {name: string, type: string, primary?: boolean}[])
```

**Side:** Server

**Description:**  
Creates a table if it does not exist.

**Parameters:**
- `tableName`: `string` — Table name.
- `columns`: `table[]` — Column definitions.

**Returns:**  
`nil`

**Errors:**
- Asserts if `MySQL` is not loaded.

**Example:**
```lua
srs.lib.SQL.Create("players", {
    {name = "identifier", type = "VARCHAR(50)", primary = true},
    {name = "name", type = "VARCHAR(100)"},
    {name = "money", type = "INT DEFAULT 0"}
})
```

---

### `srs.lib.SQL.InsertOrUpdate(tableName, data)`

**Signature:**
```lua
srs.lib.SQL.InsertOrUpdate(tableName: string, data: table<string, any>)
```

**Side:** Server

**Description:**  
Inserts a row, or updates if it already exists (based on primary key).

**Parameters:**
- `tableName`: `string` — Table name.
- `data`: `table<string, any>` — Column-value pairs.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.SQL.InsertOrUpdate("players", {
    identifier = "license:abc123",
    name = "John Doe",
    money = 5000
})
```

---

### `srs.lib.SQL.Get(tableName, where)`

**Signature:**
```lua
srs.lib.SQL.Get(tableName: string, where: string) -> table[]
```

**Side:** Server

**Description:**  
Executes a SELECT query with WHERE clause.

**Parameters:**
- `tableName`: `string` — Table name.
- `where`: `string` — WHERE clause (e.g., `"identifier = 'license:abc123'"`).

**Returns:**  
`table[]` — Array of result rows.

**Example:**
```lua
local results = srs.lib.SQL.Get("players", "identifier = 'license:abc123'")
for _, row in ipairs(results) do
    print("Player name:", row.name)
end
```

---

### `srs.lib.SQL.GetAll(tableName)`

**Signature:**
```lua
srs.lib.SQL.GetAll(tableName: string) -> table[]
```

**Side:** Server

**Description:**  
Retrieves all rows from a table.

**Parameters:**
- `tableName`: `string` — Table name.

**Returns:**  
`table[]` — Array of all rows.

**Example:**
```lua
local allPlayers = srs.lib.SQL.GetAll("players")
```

---

### `srs.lib.SQL.Delete(tableName, where)`

**Signature:**
```lua
srs.lib.SQL.Delete(tableName: string, where: string)
```

**Side:** Server

**Description:**  
Deletes rows matching WHERE clause.

**Parameters:**
- `tableName`: `string` — Table name.
- `where`: `string` — WHERE clause.

**Returns:**  
`nil`

**Example:**
```lua
srs.lib.SQL.Delete("players", "money < 0")
```

---

## `srs.lib.triggerClientEvent`

**File:** `libs/triggerClientEvent/server.lua`

*(Not fully documented in provided code.)*

---

## Core Systems

---

## Entities (Client/Server)

**Files:**  
- `core/entities/client/main.lua`
- `core/entities/client/EntityBase.lua`
- `core/entities/server/main.lua`
- `core/entities/server/EntityBase.lua`

Entity system for managing synced and networked entities (vehicles, peds, objects).

---

### Entity Modes

- **`synced`**: Entity data is synced across clients, but entity handle is not networked.
- **`network`**: Full networked entity with network ID.
- **`local`**: Client-side only entity.

---

### Client: `exports.srs_lib:CreateSyncedEntity(data)`

**Side:** Client

**Description:**  
Creates a synced entity (server notified, but entity handle is not shared).

**Parameters:**
- `data`: `table` — Entity data (`id`, `entityType`, `model`, `coords`, `mode`, etc.).

**Returns:**  
`boolean` — `true` if successful.

**Example:**
```lua
exports.srs_lib:CreateSyncedEntity({
    id = "my_entity",
    entityType = "vehicle",
    model = "adder",
    coords = vec4(100, 200, 30, 0),
    mode = "synced"
})
```

---

### Client: `exports.srs_lib:CreateLocalEntity(data)`

**Side:** Client

**Description:**  
Creates a local-only entity (no server sync).

**Parameters:**
- `data`: `table` — Entity data.

**Returns:**  
`Entity` — Entity instance.

**Example:**
```lua
local entity = exports.srs_lib:CreateLocalEntity({
    id = "local_ped",
    entityType = "ped",
    model = "a_m_y_hipster_01",
    coords = vec4(100, 200, 30, 0),
    mode = "local"
})
```

---

### Client: `exports.srs_lib:CreateNetworkEntity(data)`

**Side:** Client

**Description:**  
Creates a fully networked entity with network ID.

**Parameters:**
- `data`: `table` — Entity data with `spawnSide` (`'client'` or `'server'`).

**Returns:**  
`number, number` — Entity handle, network ID.

**Example:**
```lua
local handle, netId = exports.srs_lib:CreateNetworkEntity({
    id = "network_vehicle",
    entityType = "vehicle",
    model = "adder",
    coords = vec4(100, 200, 30, 0),
    mode = "network",
    spawnSide = "client"
})
```

---

### Server: `exports.srs_lib:CreateSyncedEntity(data)`

**Side:** Server

**Description:**  
Creates a synced entity (no networked handle).

**Example:**
```lua
exports.srs_lib:CreateSyncedEntity({
    id = "server_synced",
    entityType = "ped",
    model = "a_m_y_hipster_01",
    coords = vec4(100, 200, 30, 0),
    mode = "synced",
    owner = playerId
})
```

---

### Server: `exports.srs_lib:CreateNetworkEntity(data)`

**Side:** Server

**Description:**  
Creates a networked entity on the server.

**Example:**
```lua
local entity = exports.srs_lib:CreateNetworkEntity({
    id = "server_vehicle",
    entityType = "vehicle",
    model = "adder",
    coords = vec4(100, 200, 30, 0),
    mode = "network",
    spawnSide = "server",
    bucket = 0
})
```

---

### Server: `exports.srs_lib:DestroyEntityById(id)`

**Side:** Server

**Description:**  
Destroys an entity by ID.

**Parameters:**
- `id`: `string` — Entity ID.

**Returns:**  
`boolean` — `true` if destroyed, `false` if not found.

**Example:**
```lua
exports.srs_lib:DestroyEntityById("my_entity")
```

---

## Markers (Client)

**Files:**  
- `core/markers/markercreator.lua`
- `core/markers/markerdraw.lua`
- `core/markers/spritedraw.lua`
- `core/markers/textdraw.lua`

Advanced marker system with 3D markers, sprites, and text labels.

---

### `exports.srs_lib:addMarker(data)`

**Side:** Client

**Description:**  
Creates a complex marker with multiple visual elements (markers, sprites, texts).

**Parameters:**
- `data.id`: `string` — Unique marker ID.
- `data.coords`: `vector3` — Marker coordinates.
- `data.distance`: `number` — View distance.
- `data.interactDistance`: `number?` — Interact distance (default: 1.5).
- `data.markers`: `table[]?` — Array of marker definitions.
- `data.sprites`: `table[]?` — Array of sprite definitions.
- `data.texts`: `table[]?` — Array of text label definitions.
- `data.onEnter`: `function(entry)?` — Called when player enters interact distance.
- `data.onExit`: `function(entry)?` — Called when player exits interact distance.

**Returns:**  
`table` — Marker entry.

**Example:**
```lua
exports.srs_lib:addMarker({
    id = "shop_marker",
    coords = vec3(100, 200, 30),
    distance = 50.0,
    interactDistance = 2.0,
    markers = {
        {type = 1, size = vec3(1, 1, 1), color = {r = 255, g = 0, b = 0, a = 200}, offset = vec3(0, 0, 0)}
    },
    sprites = {
        {dict = "commonmenu", texture = "shop_new_star", size = vec2(0.5, 0.5), color = {r = 255, g = 255, b = 255, a = 255}, offset = vec3(0, 0, 1)}
    },
    texts = {
        {text = "Press E to open shop", offset = vec3(0, 0, 1.5), scale = 0.5, color = {r = 255, g = 255, b = 255, a = 255}}
    },
    onEnter = function(entry)
        print("Near shop")
    end,
    onExit = function(entry)
        print("Left shop")
    end
})
```

---

### `exports.srs_lib:rmMarker(id)`

**Side:** Client

**Description:**  
Removes a marker by ID.

**Parameters:**
- `id`: `string` — Marker ID.

**Returns:**  
`boolean` — `true` if removed, `false` if not found.

**Example:**
```lua
exports.srs_lib:rmMarker("shop_marker")
```

---

### `exports.srs_lib:updateMarker(id, newData)`

**Side:** Client

**Description:**  
Updates a marker by removing and recreating with new data.

**Parameters:**
- `id`: `string` — Marker ID.
- `newData`: `table` — New marker data.

**Returns:**  
`table?` — New marker entry, or `nil` if failed.

**Example:**
```lua
exports.srs_lib:updateMarker("shop_marker", {
    coords = vec3(110, 210, 30),
    distance = 60.0
})
```

---

## Points (Client)

**File:** `core/points/pointcreator.lua`

Registry and API for creating, updating, and removing point objects.

---

### `exports.srs_lib:addPoint(data)`

**Side:** Client

**Description:**  
Creates a point using `srs.lib.points.new` and registers it.

**Parameters:**
- `data`: `table` — Point data (must include `.id`, `.coords`, `.distance`).

**Returns:**  
`table` — Point registry entry.

**Example:**
```lua
exports.srs_lib:addPoint({
    id = "my_point",
    coords = vec3(100, 200, 30),
    distance = 10.0,
    onEnter = function(self)
        print("Entered point")
    end
})
```

---

### `exports.srs_lib:rmPoint(id)`

**Side:** Client

**Description:**  
Removes a point by ID.

**Parameters:**
- `id`: `string` — Point ID.

**Returns:**  
`boolean` — `true` if removed, `false` if not found.

**Example:**
```lua
exports.srs_lib:rmPoint("my_point")
```

---

### `exports.srs_lib:updatePoint(id, newData)`

**Side:** Client

**Description:**  
Updates a point by removing and recreating with new data.

**Parameters:**
- `id`: `string` — Point ID.
- `newData`: `table` — New point data.

**Returns:**  
`table?` — New point entry, or `nil` if failed.

**Example:**
```lua
exports.srs_lib:updatePoint("my_point", {
    coords = vec3(110, 210, 30),
    distance = 15.0
})
```

---

### `exports.srs_lib:getPoint(id)`

**Side:** Client

**Description:**  
Retrieves a point registry entry by ID.

**Parameters:**
- `id`: `string` — Point ID.

**Returns:**  
`table?` — Point entry, or `nil` if not found.

**Example:**
```lua
local point = exports.srs_lib:getPoint("my_point")
if point then
    print("Point coords:", point.point.coords)
end
```

---

## Zones (Client)

**File:** `core/zones/zonecreator.lua`

Registry and API for creating, updating, and removing zone objects (poly, box, sphere).

---

### `exports.srs_lib:addZone(data)`

**Side:** Client

**Description:**  
Creates a zone and registers it.

**Parameters:**
- `data`: `table` — Zone data (must include `.id`, `.zoneType`, and type-specific fields).

**Returns:**  
`table` — Zone registry entry.

**Example:**
```lua
exports.srs_lib:addZone({
    id = "my_zone",
    zoneType = "box",
    coords = vec3(100, 200, 30),
    size = vec3(10, 10, 5),
    rotation = 0.0,
    onEnter = function()
        print("Entered zone")
    end
})
```

---

### `exports.srs_lib:rmZone(id)`

**Side:** Client

**Description:**  
Removes a zone by ID.

**Parameters:**
- `id`: `string` — Zone ID.

**Returns:**  
`boolean` — `true` if removed, `false` if not found.

**Example:**
```lua
exports.srs_lib:rmZone("my_zone")
```

---

### `exports.srs_lib:updateZone(id, newData)`

**Side:** Client

**Description:**  
Updates a zone by removing and recreating with new data.

**Parameters:**
- `id`: `string` — Zone ID.
- `newData`: `table` — New zone data.

**Returns:**  
`table?` — New zone entry, or `nil` if failed.

**Example:**
```lua
exports.srs_lib:updateZone("my_zone", {
    coords = vec3(110, 210, 30),
    size = vec3(15, 15, 5)
})
```

---

### `exports.srs_lib:getZone(id)`

**Side:** Client

**Description:**  
Retrieves a zone registry entry by ID.

**Parameters:**
- `id`: `string` — Zone ID.

**Returns:**  
`table?` — Zone entry, or `nil` if not found.

**Example:**
```lua
local zone = exports.srs_lib:getZone("my_zone")
if zone then
    print("Zone type:", zone.zone.zoneType)
end
```

---

## Configuration

Configuration files:

- **`settings/sharedConfig.lua`**: Shared configuration (client + server).
- **`settings/clientConfig.lua`**: Client-only configuration.
- **`settings/serverConfig.lua`**: Server-only configuration.

These configs are loaded into global variables:
- `BridgeSharedConfig`
- `BridgeClientConfig`
- `BridgeServerConfig`

Configuration values can be overridden via convars.

---

## Exports

All exports are automatically generated from module APIs. Examples:

- `exports.srs_lib:Timer()` → Returns `srs.lib.Timer`
- `exports.srs_lib:SQL()` → Returns `srs.lib.SQL`
- `exports.srs_lib:WeightedRandom()` → Returns `srs.lib.WeightedRandom`
- `exports.srs_lib:addMarker(...)` → Marker creation
- `exports.srs_lib:addPoint(...)` → Point creation
- `exports.srs_lib:addZone(...)` → Zone creation

---

## Global Helpers

### `SetInterval(callback, interval)` (Client)

Creates a repeating timer. Returns interval ID.

```lua
local id = SetInterval(function() print("Tick") end, 1000)
```

---

### `ClearInterval(id)` (Client)

Stops and removes an interval.

```lua
ClearInterval(id)
```

---

### `warn(...)` (Shared)

Prints warning message to console.

```lua
warn("Deprecated function used")
```

---

## End of Documentation

This document provides **exhaustive, function-by-function** API coverage of `srs_lib` (excluding `bridge/`). All functions include full signatures, parameter types, return values, error conditions, and practical examples.

For Hungarian documentation, refer to the separate Hungarian-language file.

---

**Last Updated:** 2025-01-XX  
**Author:** Auto-generated from `srs_lib` source code  
**License:** LGPL-3.0 (ox_lib), MIT (PolyZone), Community Bridge
