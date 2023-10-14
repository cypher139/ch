#version 1.3-tmc
if(function_exists('player')) {
# Version for use on Minecraft server:
	set_uncaught_exception_handler(iclosure(@ex){
		@name = 'ch'
		@prefix = color('c').'['.color(7).@name.color('c').'] '
		@dev = false
		@q43u = 'An error has occured!'
		@pf = '/'
		@pf2 = '/'
		#backslash escapes on regex: must add extra backslash
		if(get_os() == 'WINDOWS') { @pf = '\\' @pf2 = '\\\\' }
		if(get_command_block() == null) { 
		#player
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
		@msgdev = @prefix.color(7).'Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].color(7).' - '.color('c').split('.', @ex['classType'])[-1].color(7).' - '.color(7).@ex['message']
		if(@dev == true) {msg(@msgdev)} else { if(ponline(player())) { msg(@msgplayer) } }
		console(@prefix.@q43u, false)
		console(@msgdev, false)
		foreach(@k: @trace in @ex['stackTrace']) {
			@pathprefix = '..'.@pf
			@pathdisplay = reg_split(@pf2.'CommandHelper'.@pf2, @trace['file'])[1]
			if(reg_count('LocalPackages'.@pf2, @pathdisplay) > 0) {	
				@pathprefix = '[LP]  '
				@pathdisplay = reg_split(@pf2.'LocalPackages'.@pf2, @trace['file'])[1]
			}
			if(reg_count(@pf2.'(.[^'.@pf2.']+)\\.library', @pathdisplay) > 0) {
				@pathdisplay = reg_match(@pf2.'(.[^'.@pf2.']+)\\.library', @pathdisplay)[1].'.library'.@pf.split('.library'.@pf, @pathdisplay)[-1]
			}
			@msg2 = color(9).@pathprefix.@pathdisplay.color(7).':'.color('a').@trace['line'].'.'.@trace['col'].color(8).'  '.@trace['id']
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
		@pf = '/'
		@pf2 = '/'
		#backslash escapes on regex: must add extra backslash
		if(get_os() == 'WINDOWS') { @pf = '\\' @pf2 = '\\\\' }
		@msgplayer = @prefix.color(7).'An error has occured! Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].'\n'.color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['message']
		@msgdev = @prefix.color(7).'Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'].color(7).' - '.color('c').split('.', @ex['classType'])[-1].color(7).' - '.color(7).@ex['message']
		console(@prefix.'An error has occured!', false)
		console(@msgdev, false)
		foreach(@k: @trace in @ex['stackTrace']) {
		# PWD: /home/user/chfolder
			@pathprefix = '..'.@pf
			@pathdisplay = reg_split(get_env()['PWD'].@pf2, @trace['file'])[1]
			if(reg_count('LocalPackages'.@pf2, @pathdisplay) > 0) {	
				@pathprefix = '[LP]  '
				@pathdisplay = reg_split(@pf2.'LocalPackages'.@pf2, @trace['file'])[1]
			}
			if(reg_count(@pf2.'(.[^'.@pf2.']+)\\.library', @pathdisplay) > 0) {
				@pathdisplay = reg_match(@pf2.'(.[^'.@pf2.']+)\\.library', @pathdisplay)[1].'.library'.@pf.split('.library'.@pf, @pathdisplay)[-1]
			}		
			@msg2 = color(9).@pathprefix.@pathdisplay.color(7).':'.color('a').@trace['line'].'.'.@trace['col'].color(8).'  '.@trace['id']
			console(@prefix.@msg2, false)
		}
		return(true)
	});
}