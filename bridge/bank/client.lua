
local config = require 'settings'
config = config.bank

if config.customAdapter then
    return require(config.customAdapter)
end

local adapterFolder

if GetResourceState(config.resources.esx.name) == 'started' then
    adapterFolder = 'ox_target'
elseif GetResourceState(config.resources.qb.name) == 'started' then
    adapterFolder = 'qb_target'
elseif GetResourceState(config.resources.qbx.name) == 'started' then
    adapterFolder = 'sleepless_interact'
else
    error('No supported target resource found.')
end

local adapter = require(('bridge.target.%s.client'):format(adapterFolder))

return adapter
