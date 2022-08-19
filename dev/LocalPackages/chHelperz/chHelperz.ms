export('chHelperz.console.command.show', get_value('chHelperz.console.command.show'))

bind(player_join, array(id: 'chHelperz.login'), null, @login,
	#event playername may return null for some unknown reason
	assign(@player, player())

	export('chHelperz.player.'.@player.'.command.show.all', get_value('chHelperz.player.'.@player.'.command.show.all'))
)


bind(player_command, array(id: 'chHelperz.cmd'), null, @cmdevent,
	assign(@player, player())
	assign(@cmd, reg_split(' ', @cmdevent[command]))

	#List cmd used, with CH aliases showing as a different color.
	if(is_alias(@cmd[0]), assign(@cmdcolor, 3), assign(@cmdcolor, 6))

	#show command to the console if permitted to do so.
	assign(@consolecmdshow, import('chHelperz.console.command.show'))
	if(@consolecmdshow == true,
		console(color(7).@player.' used '.color(@cmdcolor).@cmdevent[command], false)
	)
	#show command back to the player who issued the command, if permitted to do so.
	assign(@sendcmd, import('chHelperz.player.'.@player.'.command.show.all'))
	if(@sendcmd == null,
			assign(@sendcmd, get_value('chHelperz.player.'.@player.'.command.show.all'))
			export('chHelperz.player.'.@player.'.command.show.all', @sendcmd)
	)
	if(@sendcmd == true && @cmd[0] != '/.',
		if(has_permission(@player, 'commandhelper.alias.see.is.alias'), null,
			assign(@cmdcolor, '7')
		)
		msg('> '.color(@cmdcolor).@cmdevent[command])
	)
	#Save the last command this player used.
	switch(@cmd[0]){
		case '/.':
		case '/repeat':
		case '/\'':
		msg(no)
		default:
		export('chHelperz.player.'.@player.'.last.command', @cmdevent[command])
	}
)
