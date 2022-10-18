#version 1.1-tmc
bind('player_command', array(id: 'cmdrepeat.cmd'), null, @cmdevent) {
	assign(@player, _cmd_getplayerID(player()))
	assign(@cmd, reg_split(' ', @cmdevent['command']))
	
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
						console(color(7).@player['display'].' used '.color(@cmdcolor).@cmdevent['command'], false)
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
				msg('> '.color(@cmdcolor).@cmdevent['command'])
			}
			if(@consolecmdshow == true) {
				console(color(7).@player['display'].' used '.color(@cmdcolor).@cmdevent['command'], false)
			}
			export('cmdrepeat.player.'.@player['id'].'.last.command.1', @cmdevent['command'])
			export('cmdrepeat.player.'.@player['id'].'.last.command.2', @lastcmd[1])
			export('cmdrepeat.player.'.@player['id'].'.last.command.3', @lastcmd[2])			
	}
}