fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AETHRALETH'
description 'Zonenbasierte ESX-Schussmeldungen: wahlweise LoveRP EmergencyDispatch oder ox_lib'
version '1.3.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

-- Die zweite Abhaengigkeit ist absichtlich dynamisch: je nach Config
-- ist NUR emergencydispatch ODER ox_lib notwendig, niemals beides.
dependency 'es_extended'
