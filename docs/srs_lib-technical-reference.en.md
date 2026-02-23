# srs_lib Technical Reference (EN)

## 0) Scope and language-page rules

- This document is **English-only** and intended as the source page for GitBook AI.
- Hungarian must be generated as a **separate page/file** (do not mix EN and HU in one page).
- This reference covers **all of `srs_lib` except `bridge/**`**.
- Bridge behavior is intentionally excluded here per requirements.

---

## 1) Resource overview

`srs_lib` is a FiveM Lua utility resource that provides:

- a lazy-loaded `srs.lib.*` API surface,
- callback RPC utilities (`srs.callback.*`),
- core systems for entities, points, zones, and markers,
- shared runtime helpers (class system, array/table utils, timers, logger, streaming request helpers, locale, etc.).

Primary entry point: `init.lua`.

Manifest: `fxmanifest.lua`.

---

## 2) Runtime architecture

## 2.1 Bootstrap (`init.lua`)

On load:

1. Validates startup order:
   - If another resource executes `@srs_lib/init.lua` while `srs_lib` is not started, it errors.
2. Detects side context:
   - `client` if not duplicity version,
   - `server` otherwise.
3. Creates global `srs`:
   - `srs.name`
   - `srs.context`
   - `srs.cache.resource`, `srs.cache.game`
   - client-only: `srs.cache.playerId`, `srs.cache.serverId`
4. Exposes globals:
   - `_ENV.srs = srs`
   - `_ENV.cache = srs.cache`
   - `_ENV.require = srs.lib.require` (after lazy require module is resolved)

## 2.2 Lazy loader model

- `srs.lib` is metatable-backed and lazy.
- First access to `srs.lib.<Module>` resolves files by module config:
  - optional `shared.lua`
  - optional side file (`client.lua` or `server.lua`)
- If module returns `nil`, loader attempts fallback to `rawget(_ENV.srs, <ModuleKey>)`.
- Failed module lookup is cached as `false` to avoid repeated disk access.

Note: this document excludes `srs.bridge` behavior details.

## 2.3 Global interval helpers

### `SetInterval(callbackOrId, interval?, ...) -> id?`

- If first argument is a function:
  - starts a repeating thread and returns numeric id.
- If first argument is an existing interval id:
  - updates interval period for that active timer.
- Errors if:
  - `interval` is not number,
  - callback type is invalid.

### `ClearInterval(id)`

- Stops a running interval by id.
- Errors if id type invalid or id does not exist.

### Alias

- `srs.TCE(...)` -> `srs.lib.triggerClientEvent(...)`.

---

## 3) Configuration and manifest

## 3.1 `fxmanifest.lua`

- `lua54 'yes'`
- `use_experimental_fxv2_oal 'yes'`
- `shared_scripts` include:
  - `init.lua`
  - `core/entities/behaviors/shared.lua`
- `server_scripts` include:
  - `@oxmysql/lib/MySQL.lua`
  - `core/entities/server/main.lua`
- `client_scripts` include:
  - `core/entities/client/main.lua`
  - `debug/commands.lua`
  - `core/points/pointcreator.lua`
  - `core/zones/zonecreator.lua`
  - `core/markers/markercreator.lua`
- `files` include lazy-loadable trees (`libs/**/shared.lua`, `libs/**/client.lua`, etc.) and supporting files.

## 3.2 Settings files

### `settings/sharedConfig.lua`

- `Lang` (default: `auto`)
- `DebugLevel` (default: `0`)
- `Notify` (default: `auto`)
- `HelpText` (default: `auto`)
- `Phone` (default: `auto`)
- `Skills` (default: `auto`)

### `settings/clientConfig.lua`

- `InputSystem` (default: `auto`)
- `MenuSystem` (default: `auto`)
- `ProgressBarSystem` (default: `auto`)
- `VehicleKey` (default: `auto`)
- `Fuel` (default: `auto`)
- `TargetSystem` (default: `auto`)
- `Debug` (default: `false`)

### `settings/serverConfig.lua`

- `MaxInventorySlots` (default: `50`)
- `LogSystem` (default: `none`)
- `WebhookURL` (default: `""`)
- `FivemerrApiKey` (default: `""`)
- `EmbedLogo` (default: CDN URL)

## 3.3 Relevant convars

- `ox:callbackTimeout` (callback timeout, default 300000 ms)
- `ox:locale` (locale key, default `en`)
- `ox:printlevel`, `ox:printlevel:<resource>`
- `ox:logger` plus backend-specific logger convars

---

## 4) Public API reference

## 4.1 Shared APIs (`client + server`)

## Module: `srs.lib.class`

### `srs.lib.class(name, super?) -> classTable`

- Creates class table with constructor pipeline and inheritance.
- Instance utilities include:
  - `obj:isClass(class)`
  - `obj:instanceOf(class)`
- Supports private state access through `obj.private` (method context).

Example:
```lua
local Actor = srs.lib.class('Actor')
function Actor:constructor(id) self.id = id end
local a = Actor:new('npc_1')
```

## Module: `srs.lib.array`

Class-like array wrapper.

Core methods:

- `constructor(...)`
- `from(iter)`
- `at(index)`
- `merge(...)`
- `every(testFn)`
- `fill(value, start?, endIndex?)`
- `filter(testFn)`
- `find(testFn, last?)`
- `findIndex(testFn, last?)`
- `indexOf(value, last?)`
- `forEach(cb)`
- `includes(element, fromIndex?)`
- `join(separator?)`
- `map(cb)`
- `pop()`
- `push(...)`
- `reduce(reducer, initialValue?, reverse?)`
- `reverse()`
- `shift()`
- `slice(start?, finish?)`
- `toReversed()`
- `unshift(...)`
- `isArray(tbl)` (static)

Returns vary by method (array, element, boolean, number, etc.); behavior follows JS-like collection operations adapted to Lua.

Example:
```lua
local arr = srs.lib.array:new(1, 2, 3)
local doubled = arr:map(function(v) return v * 2 end)
```

## Module: `srs.lib.getRelativeCoords`

### `srs.lib.getRelativeCoords(coords, rotation, offset) -> vector3|vector4`

- Calculates offset position relative to given world coords/rotation.
- Supports heading or full rotation vectors depending inputs.

Example:
```lua
local p = srs.lib.getRelativeCoords(GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()), vec3(1.0, 0.0, 0.0))
```

## Module: `srs.lib.grid`

### `getCellPosition(point) -> number, number`
### `getCell(point) -> table`
### `getNearbyEntries(point, filter?) -> table`
### `addEntry(entry) -> entry`
### `removeEntry(entry) -> boolean`

Spatial partition helper used by points/zones.

Example:
```lua
local entries = srs.lib.grid.getNearbyEntries(GetEntityCoords(PlayerPedId()))
```

## Module: `srs.lib.locale` + `locale(...)`

### `locale(key, ...) -> string|nil`
### `srs.lib.getLocales() -> table`
### `srs.lib.locale(key?) -> string|table`
### `srs.lib.getLocale(resource, key) -> any`

Localization lookup and dictionary access.

Example:
```lua
local title = locale('ui.title')
```

## Module: `srs.lib.require`

### `srs.lib.require(modName) -> any`
### `srs.lib.load(filePath, env?) -> any`
### `srs.lib.loadJson(filePath) -> table`

- Implements custom `package.searchpath` semantics for resource-local loading.
- Circular dependency guard exists.
- Raises detailed errors for not found modules.

Example:
```lua
local cfg = srs.lib.loadJson('config.settings')
```

## Module: `srs.lib.table`

Extends Lua `table` namespace with helpers, including:

- `table.contains`
- `table.matches`
- `table.deepclone`
- `table.merge`
- `table.shuffle`
- `table.map`
- `table.freeze`
- `table.isfrozen`

`rawset` is patched to protect frozen tables.

Example:
```lua
local merged = table.merge({ a = 1 }, { b = 2 })
```

## Module: `srs.lib.Timer`

### `Create(durationMs, onEnd?, id?) -> timerInstance`
### `GetActiveTimers() -> table`
### `GetActiveTimerCount() -> number`
### `GetTimerById(id) -> timerInstance|nil`
### `ClearTimers(triggerCallbacks?, resourceName?)`

Timer instance methods:

- `ForceEnd(triggerCallback?) -> boolean`
- `IsFinished() -> boolean`
- `IsActive() -> boolean`
- `GetTimeLeft(format?) -> number`
- `GetEndTime() -> number|nil`

Example:
```lua
local t = srs.lib.Timer.Create(5000, function() print('done') end, 'job:1')
```

## Module: `srs.lib.Utils`

### `GenId(prefix?) -> string`

Generates ids like `srs_<prefix>_<counter>`.

Example:
```lua
local id = srs.lib.Utils.GenId('zone')
```

## Module: `srs.lib.waitFor`

### `srs.lib.waitFor(cb, errMessage?, timeout?) -> any`

- Polls until callback returns non-nil.
- Throws on timeout (unless timeout disabled by caller convention).

Example:
```lua
local result = srs.lib.waitFor(function()
    return GlobalState.ready and true or nil
end, 'ready timeout', 3000)
```

## Module: `srs.lib.WeightedRandom`

### `create(items, resetOnEmpty?, id?) -> instance`
### `getById(id) -> instance|nil`
### `clearById(id)`
### `clearAll()`

Internally dispatches to linear/binary strategy by item count threshold.

Also available strategies:

- `WeightedRandom.Linear` (export + class methods)
- `WeightedRandomBinary` (export + class methods)

Example:
```lua
local wr = srs.lib.WeightedRandom.create({
    a = { weight = 10, value = 'common' },
    b = { weight = 1, value = 'rare' }
}, true, 'loot')
```

## Module: `srs.lib.zones`

### `poly(data) -> zone`
### `box(data) -> zone`
### `sphere(data) -> zone`
### `getAllZones() -> table`
### `getCurrentZones() -> table`
### `getNearbyZones() -> table`

Zone instances expose methods like `remove()` and `contains(...)`.

Example:
```lua
local z = srs.lib.zones.sphere({
    id = 'safezone',
    coords = vec3(0.0, 0.0, 72.0),
    radius = 15.0
})
```

## Module: `srs.lib.Network` (shared surface)

### `GetEntityFromNetId(netId) -> entityHandle|0`
### `GetNetIdFromEntity(handle) -> netId|0`
### `RequestControlOfEntity(handle) -> boolean`

`RequestControlOfEntity` is client-focused but exposed on shared module key.

Example:
```lua
local netId = srs.lib.Network.GetNetIdFromEntity(vehicle)
```

---

## 4.2 Client APIs

## Module: `srs.callback` (client side)

### `srs.callback(event, delayOrFalse, cb, ...)`
### `srs.callback.await(event, delayOrFalse, ...) -> ...`
### `srs.callback.register(name, cb)`

- Uses net events `__srs_cb_*`.
- Validates callback names through shared callback registry event.
- Timeout controlled by `ox:callbackTimeout`.

Example:
```lua
local ok, data = srs.callback.await('my:server:cb', false, 123)
```

## Module: `srs.lib.addKeybind`

### `srs.lib.addKeybind(data) -> keybindObject`

Expected data fields include:

- `name`, `description`, `defaultMapper`, `defaultKey`
- optional callbacks (`onPressed`, `onReleased`)

Returned object methods:

- `getCurrentKey()`
- `isControlPressed()`
- `disable(toggle)`

Example:
```lua
local key = srs.lib.addKeybind({
    name = 'openmenu',
    description = 'Open menu',
    defaultMapper = 'keyboard',
    defaultKey = 'F6',
    onPressed = function() print('pressed') end
})
```

## Module: `srs.lib.anim`

### `play(id, entity, animDict, animName, blendIn, blendOut, duration, flag, playbackRate, onComplete) -> id|nil`
### `stop(id) -> boolean`

`onComplete(success, reason)` receives completion state/reason.

Example:
```lua
local animId = srs.lib.anim.play(nil, PlayerPedId(), 'missfam5_yoga', 'a2_pose', 8.0, -8.0, 2500, 49, 1.0)
```

## Module: `srs.lib.cutscenes`

### `getTags(cutscene) -> table`
### `load(cutscene) -> boolean`
### `savePedOutfit(ped) -> table`
### `applyPedOutfit(ped, outfitData)`
### `create(cutscene, coords, srcs) -> table|false`
### `start(cutsceneData)`

Example:
```lua
local c = srs.lib.cutscenes.create('MP_INTRO_CONCAT', true, {})
if c then srs.lib.cutscenes.start(c) end
```

## Module: `srs.lib.disableControls`

### `Add(...|table)`
### `Remove(...|table)`
### `Clear(...|table)`
### `srs.lib.disableControls()` (callable metatable)

Example:
```lua
srs.lib.disableControls:Add(24, 25)
srs.lib.disableControls()
```

## Module: `srs.lib.Particle`

### `Stop(handleOrId)`
### `Play(dict, ptfx, pos, rot?, scale?, color?, looped?, removeAfter?) -> handle|id`
### `CreateOnEntity(dict, ptfx, entity, offset?, rot?, scale?, color?, looped?, loopLength?) -> handle|id`
### `CreateOnEntityBone(dict, ptfx, entity, bone, offset?, rot?, scale?, color?, looped?, loopLength?) -> handle|id`

Example:
```lua
local fx = srs.lib.Particle.Play('core', 'ent_sht_electrical_box', GetEntityCoords(PlayerPedId()), nil, 1.0)
```

## Module: `srs.lib.placers`

### `placeObject(object, distance?, snapToGround?, allowedMats?, offset?) -> coords|nil, heading|nil`
### `stopPlacing()`

Example:
```lua
local coords, heading = srs.lib.placers.placeObject('prop_tool_box_04', 5.0, true)
```

## Module: `srs.lib.points`

### `new(data)` or `new(coords, distance, data?) -> point`
### `getAllPoints() -> table`
### `getNearbyPoints() -> table`
### `getClosestPoint() -> point|nil`

Point objects support enter/exit/nearby callbacks and `remove()`.

Example:
```lua
local p = srs.lib.points.new({
    id = 'atm_point',
    coords = vec3(150.0, -1040.0, 29.0),
    distance = 2.0
})
```

## Module: `srs.lib.raycast`

### `fromCoords(coords, destination, flags?, ignore?) -> hit, entityHit, endCoords, surfaceNormal, materialHash`
### `fromCamera(flags?, ignore?, distance?) -> hit, entityHit, endCoords, surfaceNormal, materialHash`

Example:
```lua
local hit, entity, pos = srs.lib.raycast.fromCamera(511, 4, 10.0)
```

## Module: streaming requests

- `srs.lib.streamingRequest(requestFn, hasLoadedFn, assetType, asset, timeout?, ...)`
- `srs.lib.requestAnimDict(animDict, timeout?)`
- `srs.lib.requestAnimSet(animSet, timeout?)`
- `srs.lib.requestAudioBank(audioBank, timeout?)`
- `srs.lib.requestModel(model, timeout?)`
- `srs.lib.requestNamedPtfxAsset(name, timeout?)`
- `srs.lib.requestScaleformMovie(name, timeout?)`
- `srs.lib.requestStreamedTextureDict(name, timeout?)`
- `srs.lib.requestWeaponAsset(weaponType, timeout?, weaponResourceFlags?, extraWeaponComponentFlags?)`

Example:
```lua
local modelHash = srs.lib.requestModel('prop_bin_01a', 5000)
```

## Module: locale client extensions

### `srs.lib.getLocaleKey() -> string`
### `srs.lib.setLocale(key)`

Example:
```lua
srs.lib.setLocale('en')
```

## Module: `srs.lib.shells` (client)

### Key methods

- `EventAdd(eventName, callback)`
- `addInteriorObject(shell, objectData)`
- `setupInterior(shell)`
- `setupExterior(shell)`
- `clearInterior(shell)`
- `clearExterior(shell)`
- `new(data)`
- `enter(id, entranceId)`
- `exit(id, exitId)`
- `inside() -> shellId|nil`

Net listeners:

- `srs_lib:shells:create`
- `srs_lib:shells:createBulk`
- `srs_lib:shells:enter`
- `srs_lib:shells:exit`
- `srs_lib:shells:addObjects`
- `srs_lib:shells:removeObjects`

Example:
```lua
local shellId = srs.lib.shells.inside()
```

---

## 4.3 Server APIs

## Module: `srs.callback` (server side)

### `srs.callback(event, playerId, cb, ...)`
### `srs.callback.await(event, playerId, ...) -> ...`
### `srs.callback.register(name, cb)` where `cb(source, ...)`

Validates player target and callback lifecycle.

Example:
```lua
local result = srs.callback.await('my:client:cb', source, 'arg')
```

## Module: `srs.lib.triggerClientEvent`

### `srs.lib.triggerClientEvent(eventName, targetIds, ...)`

- `targetIds` can be single id or list.
- Uses packed internal trigger path.

Example:
```lua
srs.lib.triggerClientEvent('my:event', { source }, { ok = true })
```

## Module: `srs.lib.SQL`

### `Create(tableName, columns)`
### `InsertOrUpdate(tableName, data)`
### `Get(tableName, where) -> rows`
### `GetAll(tableName) -> rows`
### `Delete(tableName, where)`

Requires `oxmysql` / `MySQL` object.

Example:
```lua
local row = srs.lib.SQL.Get('characters', { citizenid = 'ABC123' })
```

## Module: `srs.lib.logger`

### `srs.lib.logger(source, event, message, ...)`

- Backend chosen by `ox:logger` (`datadog`, `fivemanage`, `loki`).
- Batches request payloads.

Example:
```lua
srs.lib.logger(source, 'bank:deposit', 'Deposit completed', 'amount=5000')
```

## Module: `srs.lib.Network` (server useful method)

### `WaitForCreate(handle, deadlineMs?) -> boolean`

Example:
```lua
local ok = srs.lib.Network.WaitForCreate(vehicle, 5000)
```

## Module: `srs.lib.shells` (server)

### Key methods

- `new(data)`
- `create(data)`
- `createBulk(shells)`
- `enter(src, shellId, entranceId)`
- `exit(src, shellId, exitId)`
- `get(shellId)`
- `inside(src)`
- `addObjects(shellId, objects)`
- `removeObjects(shellId, objectIds)`

Server listeners:

- `srs_lib:shells:enter`
- `srs_lib:shells:exit`

Example:
```lua
srs.lib.shells.enter(source, 'motel_101', 'entrance')
```

---

## 5) Core systems and exports

## 5.1 Entity behaviors (`core/entities/behaviors/shared.lua`)

### Functions

- `Behaviors.register(name, fn)`
- `Behaviors.unregister(name)`
- `Behaviors.trigger(name, entity, event, params, ...)`

### Exports

- `registerEntityBehavior`
- `unregisterEntityBehavior`
- `triggerEntityBehavior`

Example:
```lua
exports['srs_lib']:registerEntityBehavior('door', function(entity, event)
    -- behavior logic
end)
```

## 5.2 Entity system

### Client exports (`core/entities/client/main.lua`)

- `CreateSyncedEntity(data)`
- `CreateLocalEntity(data)`
- `CreateNetworkEntity(data)`

### Server exports (`core/entities/server/main.lua`)

- `CreateSyncedEntity(data)`
- `CreateNetworkEntity(data)`
- `DestroyEntityById(id)`

### Internal callback channels

- `srs_lib:entities:register`
- `srs_lib:entities:destroy`
- `srs_lib:entities:getSyncedEntities`
- `srs_lib:entities:setSetters`

Example:
```lua
local entity = exports['srs_lib']:CreateSyncedEntity({
    id = 'crate_1',
    model = `prop_box_wood02a`
})
```

## 5.3 Marker creator (`core/markers/markercreator.lua`)

### Functions

- `addMarker(data)`
- `rmMarker(id)`
- `updateMarker(id, newData)`

### Exports

- `addMarker`
- `rmMarker`
- `updateMarker`

Uses draw helpers from:

- `markerdraw.lua`
- `spritedraw.lua`
- `textdraw.lua`

Example:
```lua
exports['srs_lib']:addMarker({ id = 'job_marker', coords = vec3(0,0,72), type = 'marker' })
```

## 5.4 Point creator (`core/points/pointcreator.lua`)

### Functions + exports

- `addPoint(data)`
- `rmPoint(id)`
- `updatePoint(id, newData)`
- `getPoint(id)`

Returns stored registry entry objects.

Example:
```lua
exports['srs_lib']:addPoint({ id = 'p1', coords = vec3(0,0,72), distance = 2.0 })
```

## 5.5 Zone creator (`core/zones/zonecreator.lua`)

### Functions + exports

- `addZone(data)`
- `rmZone(id)`
- `updateZone(id, newData)`
- `getZone(id)`

`zoneType` dispatch:

- `box` -> `srs.lib.zones.box`
- `sphere` -> `srs.lib.zones.sphere`
- fallback -> `srs.lib.zones.poly`

Example:
```lua
exports['srs_lib']:addZone({
    id = 'z1',
    zoneType = 'sphere',
    coords = vec3(0,0,72),
    radius = 4.0
})
```

---

## 6) Locale assets

`locales/*.json` provide per-language dictionaries.

Behavior:

- loaded via locale module at runtime,
- selected by `ox:locale` and `srs.lib.setLocale` (client),
- consumable with `locale('key.path', ...)`.

---

## 7) Compatibility wrappers in `libs/utility/shared`

- `callbacks.lua`: callback adapter layer for legacy utility callsites.
- `ids.lua`: id generation helpers (uppercase/lowercase/number/random patterns).
- `prints.lua`: maps legacy print calls to `srs.lib.print` methods.

---

## 8) Known caveats (from code analysis)

- `libs/weightedRandom/shared.lua` writes into `srs.WeightedRandom.*`; this assumes `srs.WeightedRandom` container exists at runtime through load order/side effects.
- `libs/callback/shared.lua` has a permissive `isCallbackValid` fallback expression that can evaluate truthy due resource string fallback.
- `libs/callback/shared.lua` unregister branch writes as if callback owner were table, while stored owner is resource name string.

These should be validated in runtime tests before public docs are finalized.

---

## 9) Coverage checklist (non-bridge)

This page was generated from full code traversal of:

- `init.lua`, `fxmanifest.lua`
- `settings/*.lua`
- `libs/**/*.lua` (all modules)
- `core/**/*.lua` (entities, behaviors, points, zones, markers)
- `locales/*.json`

Bridge directory intentionally excluded.

---

## 10) Suggested GitBook page split (do not mix languages)

Recommended final page structure:

1. `srs_lib-technical-reference.en` (this file content)
2. `srs_lib-technical-reference.hu` (translated, separate page)
3. Optional:
   - `srs_lib-api-client.en`
   - `srs_lib-api-server.en`
   - `srs_lib-core-systems.en`

Keep EN and HU strictly separated per page.
