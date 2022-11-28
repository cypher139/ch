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
#Area mode: uses WordlEdit selection data.
	#SKCompat available in multiple versions; best to check for functionality instead.
if(!function_exists('sk_pos1')) {
	msg(color('c').'['.color(7).import('dispenserreloader.name').color('c').'] '.color('c').import('dispenserreloader.name').' is missing access to WorldEdit selections!'.color(7).' Area mode is disabled without access to selection data.')
	msg(color(3).'Download the SKCompat extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions.')
	msg('\n'.moo(color(2).'https://letsbuild.net/jenkins/job/SKCompat/'.color('r')))
}
#Economy - Charges fees for usage of script
if(!function_exists('acc_add')) {
	msg(color('c').'['.color(7).import('dispenserreloader.name').color('c').'] '.color('c').import('dispenserreloader.name').' is missing access to economy functions and account data!'.color(7).' All script functions will be unable to utilize your server economy!')
	msg(color(3).'Download the CHVault extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions.')
	msg('\n'.moo(color(2).'https://letsbuild.net/jenkins/job/CHVault/'.color('r')))
}

#export usable fuel items array
export('dispenserreloader.fuel.items', _reloader_get_fuel_items())