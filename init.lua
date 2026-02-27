local RESOURCE_NAME = 'srs_lib'
local CURRENT_RESOURCE = GetCurrentResourceName()
local CONTEXT = IsDuplicityVersion() and 'server' or 'client'

if CURRENT_RESOURCE ~= RESOURCE_NAME and GetResourceState(RESOURCE_NAME) ~= 'started' then
	error('^1srs_lib must be started before this resource.^0', 0)
end

local LoadResourceFile = LoadResourceFile

local function loadLuaFile(path)
	local chunk = LoadResourceFile(RESOURCE_NAME, path)
	if not chunk then
		return nil
	end
	local fn, err = load(chunk, ('@@%s/%s'):format(RESOURCE_NAME, path), 't', _ENV)
	if not fn then
		error(('Error importing %s: %s'):format(path, err), 3)
	end
	return fn()
end

local function loadFirstExisting(paths)
	for i = 1, #paths do
		local value = loadLuaFile(paths[i])
		if value ~= nil then
			return value
		end
	end
end

local bridgeBootstrapLoaded = false
local bridgeModuleIndex
local bridgeRequireCache = {}

local function ensureBridgeBootstrap()
	if bridgeBootstrapLoaded then
		return
	end

	local sharedConfig = loadFirstExisting({
		'settings/sharedConfig.lua',
		'settings/bridge_shared_config.lua',
	}) or {}

	local clientConfig = loadFirstExisting({
		'settings/clientConfig.lua',
		'settings/bridge_client_config.lua',
	}) or {}

	local serverConfig = loadFirstExisting({
		'settings/serverConfig.lua',
		'settings/bridge_server_config.lua',
	}) or {}

	_ENV.BridgeSharedConfig = _ENV.BridgeSharedConfig or sharedConfig
	_ENV.BridgeClientConfig = _ENV.BridgeClientConfig or clientConfig
	_ENV.BridgeServerConfig = _ENV.BridgeServerConfig or serverConfig

	if not _ENV.Require then
		_ENV.Require = function(path, resourceName)
			resourceName = type(resourceName) == 'string' and resourceName or RESOURCE_NAME

			local mapped = path
			if resourceName == RESOURCE_NAME then
				if mapped:find('^modules/') then
					mapped = mapped:gsub('^modules/', 'bridge/')
				elseif mapped:find('^lib/') then
					mapped = mapped:gsub('^lib/', 'libs/')
				elseif mapped:find('^settings/') then
					mapped = mapped
				end

				if mapped == 'libs/utility/shared/callbacks.lua' then
					mapped = 'libs/callback/shared/callback.lua'
				end
			end

			if not mapped:match('%.lua$') then
				mapped = mapped .. '.lua'
			end

			local cacheKey = ('%s:%s'):format(resourceName, mapped)
			local cached = bridgeRequireCache[cacheKey]
			if cached ~= nil then
				return cached
			end

			local chunk = LoadResourceFile(resourceName, mapped)
			if not chunk then
				error(('Error loading file [%s]'):format(cacheKey), 2)
			end

			local fn, err = load(chunk, ('@@%s/%s'):format(resourceName, mapped), 't', _ENV)
			if not fn then
				error(('Error importing %s: %s'):format(mapped, err), 3)
			end

			local result = fn()
			bridgeRequireCache[cacheKey] = result
			return result
		end
	end

	bridgeBootstrapLoaded = true
end

local function getBridgeModuleIndex()
	if bridgeModuleIndex then
		return bridgeModuleIndex
	end
	bridgeModuleIndex = loadLuaFile('bridge/module_index.lua') or {}
	return bridgeModuleIndex
end

local moduleConfig = {
	lib = {
		addKeybind = { folder = 'addKeybind', useContext = true },
		anim = { folder = 'anim', useContext = true },
		array = { folder = 'array', useShared = true },
		class = { folder = 'class', useShared = true },
		cutscenes = { folder = 'cutscenes', useContext = true },
		disableControls = { folder = 'disableControls', useContext = true },
		callback = { folder = 'callback', useShared = true, useContext = true },
		getRelativeCoords = { folder = 'getRelativeCoords', useShared = true },
		grid = { folder = 'grid', useShared = true },
		locale = { folder = 'locale', useShared = true, useContext = true },
		logger = { folder = 'logger', useContext = true },
		Network = { folder = 'network', useShared = true, useContext = true },
		Particle = { folder = 'particle', useContext = true },
		placers = { folder = 'placers', useContext = true },
		points = { folder = 'points', useContext = true },
		print = { folder = 'print', useShared = true },
		raycast = { folder = 'raycast', useContext = true },
		require = { folder = 'require', useShared = true },
		requestAnimDict = { folder = 'requestAnimDict', useContext = true },
		requestAnimSet = { folder = 'requestAnimSet', useContext = true },
		requestAudioBank = { folder = 'requestAudioBank', useContext = true },
		requestModel = { folder = 'requestModel', useContext = true },
		requestNamedPtfxAsset = { folder = 'requestNamedPtfxAsset', useContext = true },
		requestScaleformMovie = { folder = 'requestScaleformMovie', useContext = true },
		requestStreamedTextureDict = { folder = 'requestStreamedTextureDict', useContext = true },
		requestWeaponAsset = { folder = 'requestWeaponAsset', useContext = true },
		SQL = { folder = 'sql', useContext = true },
		shells = { folder = 'shells', useShared = true, useContext = true },
		streamingRequest = { folder = 'streamingRequest', useContext = true },
		table = { folder = 'table', useShared = true },
		Timer = { folder = 'timer', useShared = true },
		triggerClientEvent = { folder = 'triggerClientEvent', useContext = true },
		Utils = { folder = 'utils', useShared = true },
		waitFor = { folder = 'waitFor', useShared = true },
		WeightedRandom = {
			folder = 'weightedRandom',
			files = {
				'shared.lua',
			}
		},
	},
	bridge = {
		Bank = { folder = 'bank', useShared = true, useContext = true },
	},
}

local function buildModuleFiles(namespace, key)
	local config = moduleConfig[namespace][key]
	if not config then
		if namespace == 'bridge' then
			local keyLower = tostring(key):lower()
			if keyLower == 'zones' then
				return nil
			end

			local index = getBridgeModuleIndex()
			local entry = index[keyLower]
			if not entry then
				return nil
			end

			local files = {}
			local list = entry[CONTEXT] or {}
			for i = 1, #list do
				files[i] = list[i]
			end
			return files
		end

		return nil
	end

	local root = ('%s/%s'):format(namespace == 'lib' and 'libs' or 'bridge', config.folder)

	if config.files then
		local files = {}
		for i = 1, #config.files do
			files[i] = ('%s/%s'):format(root, config.files[i])
		end
		return files
	end

	local files = {}
	if config.useShared then
		files[#files + 1] = ('%s/shared.lua'):format(root)
	end
	if config.useContext then
		files[#files + 1] = ('%s/%s.lua'):format(root, CONTEXT)
	end

	return files
end

local function loadModule(namespace, cacheTable, key)
	local files = buildModuleFiles(namespace, key)
	if not files then
		return nil
	end

	if namespace == 'bridge' then
		ensureBridgeBootstrap()
	end

	local result
	local loaded = false

	for i = 1, #files do
		local file = files[i]
		local chunk = LoadResourceFile(RESOURCE_NAME, file)
		if chunk then
			loaded = true
			local fn, err = load(chunk, ('@@%s/%s'):format(RESOURCE_NAME, file), 't', _ENV)
			if not fn then
				error(('Error importing module (%s/%s): %s'):format(namespace, key, err), 3)
			end
			local returned = fn()
			if returned ~= nil then
				result = returned
			end
		end
	end

	if not loaded then
		return nil
	end

	if result == nil then
		result = rawget(_ENV.srs, key)
	end

	cacheTable[key] = result or false
	return result
end

local function createNamespace(namespace, cacheTable)
	return setmetatable(cacheTable, {
		__index = function(self, key)
			local module = loadModule(namespace, self, key)
			if module == false then
				return nil
			end
			return module
		end
	})
end

local srs = {
	name = RESOURCE_NAME,
	context = CONTEXT,
}

_ENV.srs = srs

srs.cache = {
	resource = CURRENT_RESOURCE,
	game = GetGameName(),
}

if CONTEXT == 'client' then
	srs.cache.playerId = PlayerId()
	srs.cache.serverId = GetPlayerServerId(srs.cache.playerId)
end

_ENV.cache = srs.cache

srs.lib = createNamespace('lib', {})
srs.bridge = createNamespace('bridge', {})

local intervals = {}

function SetInterval(callback, interval, ...)
	interval = interval or 0

	if type(interval) ~= 'number' then
		return error(('Interval must be a number. Received %s'):format(json.encode(interval)))
	end

	local cbType = type(callback)

	if cbType == 'number' and intervals[callback] then
		intervals[callback] = interval or 0
		return
	end

	if cbType ~= 'function' then
		return error(('Callback must be a function. Received %s'):format(cbType))
	end

	local args = { ... }
	local id

	Citizen.CreateThreadNow(function(ref)
		id = ref
		intervals[id] = interval or 0
		repeat
			interval = intervals[id]
			Wait(interval)

			if interval < 0 then break end
			callback(table.unpack(args))
		until false
		intervals[id] = nil
	end)

	return id
end

function ClearInterval(id)
	if type(id) ~= 'number' then
		return error(('Interval id must be a number. Received %s'):format(json.encode(id)))
	end

	if not intervals[id] then
		return error(('No interval exists with id %s'):format(id))
	end

	intervals[id] = -1
end

srs.TCE = function(...)
	return srs.lib.triggerClientEvent(...)
end

local moduleRequire = srs.lib.require
_ENV.require = moduleRequire

setmetatable(srs, {
	__index = function(_, key)
		return srs.lib[key]
	end
})
