resource_manifest_version '05cfa83c-a124-4cfa-a768-c24a5811d8f9'

dependency 'essentialmode'

client_scripts {
   'client/lib/i18n.lua',
   'client/locales/en.lua',
   'client/client.lua'
}

server_script "server/server.lua"