#version 1.3-tmc
if(function_exists('player')) {
# Version for use on Minecraft server:
	set_uncaught_exception_handler(iclosure(@ex){
		@name = 'ch'
		@prefix = color('c').'['.color(7).@name.color('c').'] '
		if(get_command_block() == null) { 
		#player
			@q43u = 'An error has occured!' 
			try {
				@dev = import('ch.player.'.puuid(player(), 'dashless').'.developer')
			} catch(PlayerOfflineException @ex2) {
				@dev = false
			}
		} else { 
			@q43u = 'Error occurred in CommandBlock at '.array_normalize(get_command_block())[0..3]
			@dev = false
		}
		@msgplayer = @prefix.color(7).'An error has occured! Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].'\n'.color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['message']
		@msgdev = @prefix.color(7).'Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].' - '.color('c').split('.', @ex['classType'])[-1].' - '.color(7).@ex['message']
		if(@dev == true) {msg(@msgdev)} else { if(ponline(player())) { msg(@msgplayer) } }
		console(@prefix.@q43u, false)
		console(@msgdev, false)
		foreach(@k: @trace in @ex['stackTrace']) {
			@pathdisplay = reg_split('\\/CommandHelper\\/', @trace['file'])[1]
			if(reg_count('/(.[^/]+)\\.library', @pathdisplay) > 0) {
				@pathdisplay = reg_match('/(.[^/]+)\\.library', @pathdisplay)[1].'.library/'.split('.library/', @pathdisplay)[-1]
			}		
			@msg2 = color(9).'../'.@pathdisplay.color(7).':'.color('a').@trace['line'].'.'.@trace['col'].color(8).'  '.@trace['id']
			console(@prefix.@msg2, false)
			if(@dev == true) {msg(@msg2)}
		}
		return(true)
	});
} else {
# Version for use in Command Line: 
	set_uncaught_exception_handler(iclosure(@ex){
		@name = 'ch'
		@prefix = color('c').'['.color(7).@name.color('c').'] '
		@msgplayer = @prefix.color(7).'An error has occured! Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].'\n'.color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['message']
		@msgdev = @prefix.color(7).'Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].' - '.color('c').split('.', @ex['classType'])[-1].' - '.color(7).@ex['message']
		console(@prefix.'An error has occured!', false)
		console(@msgdev, false)
		foreach(@k: @trace in @ex['stackTrace']) {
		# PWD: /home/user/chfolder
			@pathdisplay = reg_split(get_env()['PWD'].'\\/', @trace['file'])[1]
			if(reg_count('/(.[^/]+)\\.library', @pathdisplay) > 0) {
				@pathdisplay = reg_match('/(.[^/]+)\\.library', @pathdisplay)[1].'.library/'.split('.library/', @pathdisplay)[-1]
			}		
			@msg2 = color(9).'../'.@pathdisplay.color(7).':'.color('a').@trace['line'].'.'.@trace['col'].color(8).'  '.@trace['id']
			console(@prefix.@msg2, false)
		}
		return(true)
	});
}