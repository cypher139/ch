#version 1.2-tmc
bind('player_command', array('id': 'cmdrepeat.cmd', 'priority': 'HIGH'), null, @cmdevent) {
	@player = _getplayerID(player())
	@cmd = reg_split(' ', @cmdevent['command'])
	@dev = import('ch.player.'.@player['id'].'.dev.scripts.cmdrepeat')
	
	#Automatically remove extra slashes not recognized by CH Aliases or Registered Commands.
	@allcmds = import('cmdrepeat.all.commands')
	#Remove extra slashes and beginning spaces
	if(!is_alias(@cmd[0])) {
		if(!array_contains(@allcmds, reg_replace('^\\/', '', @cmd[0]))) {
			if(@dev == true) { msg('r') }
		# Remove empty command slash
			if(@cmd[0] == '/' && !array_index_exists(@cmd, 1)) {
				if(@dev == true) { msg('r - "/"') }
				cancel()
				die()
			}
		# Space after slash check
			if(reg_count('^\\/*$', @cmd[0]) > 0 && array_index_exists(@cmd, 1)) {
			# Added @cmd[1] check to allow for not calling WorldEdit's "//" command with extra arguments
			# Remove space after slash
				array_remove(@cmd, 0)
				@cmd[0] = '/'.@cmd[0]
				if(@dev == true) { msg('r "/ "') }
				modify_event('command', array_implode(@cmd, ' '))
			}
		# Extra Slashes
			if(reg_count('^\\/\\/+', @cmd[0]) > 0) {
				#Remove extra slash
				@cmd[0] = reg_replace('^\\/\\/+', '\\/', @cmd[0])
				if(@dev == true) { 
					msg('now: '.@cmd[0])
					msg('a:  <'.array_implode(@cmd, ' ').'>')
				}
				modify_event('command', array_implode(@cmd, ' '))
			}
		} else {
			# Remove invalid arguments from WorldEdit's "//"
			if(reg_count('^\\/\\/$', @cmd[0]) > 0 && array_index_exists(@cmd, 1)) {
				array_remove(@cmd, 0)
				@cmd[0] = '/'.@cmd[0]
				if(@dev == true) { msg('r-we "/ "') }
				modify_event('command', array_implode(@cmd, ' '))
			}
		}
	}
	@cmddisplay = array_implode(@cmd, ' ')
	if(@dev == true) { msg('o: '.@cmdevent['command'].'    n:'.@cmddisplay) }
	
	#List cmd used, with CH aliases showing as a different color.
	@cmdcolor = 7
	if(is_alias(@cmd[0])) { @cmdcolor = 3 } else { @cmdcolor = 6 }
	
	#Show command to the console if permitted to do so.
	@consolecmdshow = import('cmdrepeat.console.command.show')

	#Show command back to the player who issued the command, if permitted to do so.
	@sendcmd = import('cmdrepeat.player.'.@player['id'].'.command.show.all')
	if(@sendcmd == null) {
		@sendcmd = get_value('cmdrepeat.player.'.@player['id'].'.command.show.all')
		export('cmdrepeat.player.'.@player['id'].'.command.show.all', @sendcmd)
	}
	
	@lastcmd = import('cmdrepeat.player.'.@player['id'].'.last.command')
	if(!is_array(@lastcmd)) { @lastcmd = array() }

	# Convert Number start at 1 to 0
	if(array_index_exists(@cmd, 1)) {
		if(is_numeric(@cmd[1]) && @cmd[1] < 10 && @cmd[1] > 0) { @cmd[1] = @cmd[1] - 1 }
	}
	# Is this a new command or repeat command?
	switch(@cmd[0]){
		case '/.':
		case '/repeat':
		case '/\'':
			if(@consolecmdshow == true) {
				if(array_index_exists(@cmd, 1)) {
					if(is_numeric(@cmd[1]) && @cmd[1] < 9) {
						# Repeat Command
						if(array_index_exists(@lastcmd, @cmd[1])) {
							if(is_alias(@lastcmd[@cmd[1]])) { @cmdcolor = 3 } else { @cmdcolor = 6 }
							console(color(7).@player['display'].' repeated '.color(@cmdcolor).@lastcmd[@cmd[1]], false)
						}
					} else {
					# Repeat options
						console(color(7).@player['display'].' used '.color(@cmdcolor).@cmddisplay, false)
					}
				} else {
				# Repeat Last command
					if(array_index_exists(@lastcmd, 0)) {
						if(is_alias(@lastcmd[0])) { @cmdcolor = 3 } else { @cmdcolor = 6 }
						console(color(7).@player['display'].' repeated '.color(@cmdcolor).@lastcmd[0], false)
					}
				}
			}			
		case '//.':	
		# Special alias for /repeat 2
			if(@consolecmdshow == true && array_index_exists(@lastcmd, 1)) {
				if(is_alias(@lastcmd[1])) { @cmdcolor = 3 } else { @cmdcolor = 6 }
				console(color(7).@player['display'].' repeated '.color(@cmdcolor).@lastcmd[1], false)
			}
		default:
		# Save the last command this player used.
			if(@consolecmdshow == true) {
				console(color(7).@player['display'].' used '.color(@cmdcolor).@cmddisplay, false)
			}
			if(@sendcmd == true) {
				if(!has_permission(@player['name'], 'commandhelper.alias.see.is.alias')) { @cmdcolor = 7 }
				msg('> '.color(@cmdcolor).@cmddisplay)
			}			
			array_insert(@lastcmd, @cmddisplay, 0)
			if(array_index_exists(@lastcmd, 10)) { array_remove(@lastcmd, 10) }
			export('cmdrepeat.player.'.@player['id'].'.last.command', @lastcmd)
			export('cmdrepeat.player.'.@player['id'].'.last.command.1', @cmddisplay)		
	}
}