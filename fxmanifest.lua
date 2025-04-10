fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'DM Arena Script'
version '1.0.0'

client_scripts {
    'client/client.lua',
    'client/menu.js',
    'client/menu.html'
}

server_script 'server/server.lua'

ui_page 'client/menu.html'

files {
    'client/menu.html',
    'client/menu.css',
    'client/menu.js'
}

exports {
    'IsInDMArena'
}