bind('player_join', array(id: 'cmdrepeat.login'), null, @login) {
	#event playername may return null for some unknown reason
	assign(@player, _cmd_getplayerID(player()))

	export('cmdrepeat.player.'.@player['id'].'.command.show.all', get_value('cmdrepeat.player.'.@player['id'].'.command.show.all'))
}


bind('player_command', array(id: 'cmdrepeat.cmd'), null, @cmdevent) {
	assign(@player, _cmd_getplayerID(player()))
	assign(@cmd, reg_split(' ', @cmdevent['command']))

	#List cmd used, with CH aliases showing as a different color.
	if(is_alias(@cmd[0]), assign(@cmdcolor, 3), assign(@cmdcolor, 6))

	#show command to the console if permitted to do so.
	assign(@consolecmdshow, import('cmdrepeat.console.command.show'))
	if(@consolecmdshow == true,
		console(color(7).@player['display'].' used '.color(@cmdcolor).@cmdevent['command'], false)
	)
	#show command back to the player who issued the command, if permitted to do so.
	assign(@sendcmd, import('cmdrepeat.player.'.@player['id'].'.command.show.all'))
	if(@sendcmd == null,
			assign(@sendcmd, get_value('cmdrepeat.player.'.@player['id'].'.command.show.all'))
			export('cmdrepeat.player.'.@player['id'].'.command.show.all', @sendcmd)
	)

	#Save the last command this player used.
	switch(@cmd[0]){
		case '/.':
		case '/repeat':
		case '/\'':
			assign(@nowhere, 'somewhere')
		default:
			if(@sendcmd == true) {
				if(has_permission(@player['name'], 'commandhelper.alias.see.is.alias'), null,
					assign(@cmdcolor, '7')
				)
				msg('> '.color(@cmdcolor).@cmdevent['command'])
				export('cmdrepeat.player.'.@player['id'].'.last.command', @cmdevent['command'])
			}
	}
}
