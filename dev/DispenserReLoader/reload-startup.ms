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
include('modules.library/Core.ms')

#Load server defaults into RAM
_reloader_get_server_defaults('startup')

#Startup extension checks.
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
#Cypher libraries, check for required libraries
if(!is_proc('_getplayerID')) {
	msg(color('c').'['.color(7).import('dispenserreloader.name').color('c').'] '.color('c').import('dispenserreloader.name').' is missing access to player Names and UUIDs!'.color(7).' All script functions will be unable to function!!')
	msg(color(3).'Download the ScriptLibraries folder from the GitHub and save it to <server root>/plugins/CommandHelper/LocalPackages.')
	msg('\n'.moo(color(2).'https://github.com/cypher139/ch/tree/release/dev/ScriptLibraries/'.color('r')))
	die();
}


#export usable fuel items array
export('dispenserreloader.fuel.items', _reloader_get_fuel_items())

#Set Exception Handler if not present
#Note: This is set across all CommandHelper scripts!
@reloader_ex = iclosure(@ex){
	@name = import('dispenserreloader.name', 'ReLoad')
	@prefix = color('c').'['.color(7).@name.color('c').'] '
	@dev = false
	try {
		@dev = import('ch.player.'.puuid(player(), 'dashless').'.dev.scripts.reload')
	} catch(PlayerOfflineException @ex2) {
		@dev = false
	}
	@msgplayer = @prefix.color(7).'An error has occured! Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].'\n'.color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['message']
	@msgdev = @prefix.color(7).'Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].' - '.color('c').split('.', @ex['classType'])[-1].' - '.color(7).@ex['message']
	if(@dev == true) {msg(@msgdev)} else { if(ponline(player())) { msg(@msgplayer) } }
	console(@msgdev, false)
	foreach(@k: @trace in @ex['stackTrace']) {
		@pathdisplay = reg_split('\\/CommandHelper\\/', @trace['file'])[1]
		if(reg_count('/(.[^/]+)\\.library', @pathdisplay) > 0) {
			@pathdisplay = reg_match('/(.[^/]+)\\.library', @pathdisplay)[1].'.library/'.split('.library/', @pathdisplay)[-1]
		}		
		@msg2 = color(9).'../'.@pathdisplay.color(7).':'.color('a').@trace['line'].'.'.@trace['col'].color('r').'  '.@trace['id']
		console(@prefix.@msg2, false)
		if(@dev == true) {msg(@msg2)}
	}
	return(true)
}

@q2u5 = set_uncaught_exception_handler(closure());
if(!is_null(@q2u5)) {
  set_uncaught_exception_handler(@q2u5);
} else {
  set_uncaught_exception_handler(@reloader_ex);
}