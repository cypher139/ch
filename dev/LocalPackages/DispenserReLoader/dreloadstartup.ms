######################################################
#
#   ReLoad: Fill chests or dispensers, or furnaces in one click!
#   Main.ms: Startup code to be used by other areas of the script.
#   version 1.1-tmc
#
######################################################

#Name the script. This can be changed to fit the style of your server.
#This name is used in any chat messages, and all persistance values.
#Any name changes will also change what values are loaded/saved in persistance!
export('dispenserreloader.name', 'ReLoad')
export('dispenserreloader.version', '1.1-tmc')

#Startup extension check.
#SKcompat - worldedit
if(extension_exists('SKCompat'), null,
	msg(color(c).'['.color(7).import('dispenserreloader.name').color(c).'] '.color(e).'SKCompat: '.color(c).'NOT Installed'.color(7).' Missing access to WorldEdit selection!  Area mode will be disabled without access to selection data.')
	msg(color(3).'Download the SKCompat extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions.')
	msg('\n'.moo(color(2).'http://forum.enginehub.org/threads/where-did-worldedit-and-worldguard-functions-go.15844/'.color(r)))
)
#CHVault - economy
if(extension_exists('CHVault') || function_exists(acc_add), null,
	msg(color(c).'['.color(7).import('dispenserreloader.name').color(c).'] '.color(e).'CHVault: '.color(c).'NOT Installed'.color(7).' Missing access to Vault! '.import('dispenserreloader.name').' is unable to access economy account data.')
	msg(color(3).'Download the CHVault extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions.')
	msg('\n'.moo(color(2).'http://forum.enginehub.org/threads/where-did-worldedit-and-worldguard-functions-go.15844/'.color(r)))
)
