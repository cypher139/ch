######################################################
#
#   ReLoad: Fill blocks that have inventories in one click!
#   Main.ms: Startup code to be used by other areas of the script.
#   version 1.2-tmc
#
######################################################

#Name the script. This can be changed to fit the style of your server.
#This name is used in any chat messages, and all persistance values.
#Any name changes will also change what values are loaded/saved in persistance!
export('dispenserreloader.name', 'ReLoad')
export('dispenserreloader.version', '1.2-tmc')

#Include required backend functions
include('includes.library/reload-functions-Core.ms')

#Load server defaults into RAM
_reloader_get_server_defaults('startup')

#Startup extension check.
#SKcompat - worldedit
if(!extension_exists('SKCompat') || !extension_exists('CHWorldEdit') || !function_exists('sk_pos1')) {
	msg(color('c').'['.color(7).import('dispenserreloader.name').color('c').'] '.color('e').'SKCompat: '.color('c').'NOT Installed'.color(7).' Missing access to WorldEdit selection!  Area mode will be disabled without access to selection data.')
	msg(color(3).'Download the SKCompat extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions.')
	msg('\n'.moo(color(2).'https://letsbuild.net/jenkins/job/SKCompat/'.color('r')))
}
#CHVault - economy
if(!extension_exists('CHVault') || !function_exists('acc_add')) {
	msg(color('c').'['.color(7).import('dispenserreloader.name').color('c').'] '.color('e').'CHVault: '.color('c').'NOT Installed'.color(7).' Missing access to Vault! '.import('dispenserreloader.name').' is unable to access economy account data.')
	msg(color(3).'Download the CHVault extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions.')
	msg('\n'.moo(color(2).'https://letsbuild.net/jenkins/job/CHVault/'.color('r')))
}