#version 1.2-tmc
bind('player_command', array('id': 'cmdrepeat.cmd', 'priority': 'HIGH'), null, @cmdevent) {
	assign(@player, _cmd_getplayerID(player()))
	assign(@cmd, reg_split(' ', @cmdevent['command']))
	@dev = import('ch.player.'.@player['id'].'.dev.scripts.cmdrepeat')
	
	#Automatically remove extra slashes not recognized by CH Aliases or Registered Commands.
	# get_commands() is a huge array. sort into a single array:
	@allcmds = import('cmdrepeat.all.commands')
	if(!is_array(@allcmds)) {
		@allcmds = array()
		foreach(@v in get_commands()) {
			array_push(@allcmds, @v['name'])
			array_push_all(@allcmds, @v['aliases'])
		}
		export('cmdrepeat.all.commands', @allcmds)
	}
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
			# added @cmd[1] check to allow for not calling WorldEdit's "//" command with extra arguments
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
			# remove invalid arguments from WorldEdit's "//"
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
	if(is_alias(@cmd[0]), assign(@cmdcolor, 3), assign(@cmdcolor, 6))
	
	#Show command to the console if permitted to do so.
	assign(@consolecmdshow, import('cmdrepeat.console.command.show'))

	#Show command back to the player who issued the command, if permitted to do so.
	assign(@sendcmd, import('cmdrepeat.player.'.@player['id'].'.command.show.all'))
	if(@sendcmd == null,
			assign(@sendcmd, get_value('cmdrepeat.player.'.@player['id'].'.command.show.all'))
			export('cmdrepeat.player.'.@player['id'].'.command.show.all', @sendcmd)
	)
	
	assign(@lastcmd, array())
	assign(@lastcmd[0], 'Player Recent Commands')
	assign(@lastcmd[1], import('cmdrepeat.player.'.@player['id'].'.last.command.1'))
	assign(@lastcmd[2], import('cmdrepeat.player.'.@player['id'].'.last.command.2'))
	assign(@lastcmd[3], import('cmdrepeat.player.'.@player['id'].'.last.command.3'))
	
	#is this a new command or repeat command?
	switch(@cmd[0]){
		case '/.':
		case '/repeat':
		case '/\'':
			if(@consolecmdshow == true) {
				if(array_index_exists(@cmd, 1)) {
					if(is_numeric(@cmd[1]) && @cmd[1] < 4) {
						#123 repeat
						if(is_alias(@lastcmd[@cmd[1]]), assign(@cmdcolor, 3), assign(@cmdcolor, 6))
						if(@lastcmd[@cmd[1]] == '' || @lastcmd[@cmd[1]] == null, null,
							console(color(7).@player['display'].' repeated '.color(@cmdcolor).@lastcmd[@cmd[1]], false)
						)
					} else {
					#repeat cmd options
						console(color(7).@player['display'].' used '.color(@cmdcolor).@cmddisplay, false)
					}
				} else {
				#just repeat cmd used
					if(is_alias(@lastcmd[1]), assign(@cmdcolor, 3), assign(@cmdcolor, 6))
					if(@lastcmd[1]) {
						console(color(7).@player['display'].' repeated '.color(@cmdcolor).@lastcmd[1], false)
					}
				}
			}			
		case '//.':	
		#special alias for /repeat 2
			if(@consolecmdshow == true) {
				if(is_alias(@lastcmd[2]), assign(@cmdcolor, 3), assign(@cmdcolor, 6))
				if(@lastcmd[2] == '' || @lastcmd[2] == null, null,
					console(color(7).@player['display'].' repeated '.color(@cmdcolor).@lastcmd[2], false)
				)
			}
		default:
		#Save the last command this player used.
			if(@sendcmd == true) {
				if(has_permission(@player['name'], 'commandhelper.alias.see.is.alias'), null,
					assign(@cmdcolor, '7')
				)
				msg('> '.color(@cmdcolor).@cmddisplay)
			}
			if(@consolecmdshow == true) {
				console(color(7).@player['display'].' used '.color(@cmdcolor).@cmddisplay, false)
			}
			export('cmdrepeat.player.'.@player['id'].'.last.command.1', @cmddisplay)
			export('cmdrepeat.player.'.@player['id'].'.last.command.2', @lastcmd[1])
			export('cmdrepeat.player.'.@player['id'].'.last.command.3', @lastcmd[2])			
	}
}