fx_version 'cerulean'
game 'gta5'

author 'sirius'
description 'SSS Resource'
version '1.0.0'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

files {
    'init.lua',
    'settings/*.lua',
    'libs/**/shared.lua',
    'libs/**/client.lua',
    'bridge/**/*.lua',
    'core/entities/client/EntityBase.lua',
    'core/markers/markerdraw.lua',
    'core/markers/spritedraw.lua',
    'core/markers/textdraw.lua',
}

shared_scripts {
    'init.lua',
    'core/entities/behaviors/shared.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'core/entities/server/main.lua',
}

client_scripts {
    'core/entities/client/main.lua',
    'debug/commands.lua',
    'core/points/pointcreator.lua',
    'core/zones/zonecreator.lua',
    'core/markers/markercreator.lua',
}

dependencies {
    '/server:6116',
    '/onesync',
}
