resource_manifest_version '05cfa83c-a124-4cfa-a768-c24a5811d8f9'
resource_version '2.0'

client_scripts {
   'client/lib/i18n.lua',
   'client/locales/en.lua',
   'config.lua',
   'client/vehicle.lua',
   'client/client.lua'
}

server_script {
   'client/lib/i18n.lua',
   'client/locales/en.lua',
   'config.lua',
   'server/server.lua'
}
