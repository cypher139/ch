export('chHelperz.console.command.show', get_value('chHelperz.console.command.show'))

proc _ch_getplayerID(@option1) {
	@pid = array()
	if(@option1 == '~console'){
		@pid = array(display: 'Console', name: '~console', id: 'console', nick: 'Server Console')
	} else {
	@pid[display] = pinfo(@option1)[0];
	@pid[name] = pinfo(@option1)[0];
	@pid[id] = puuid(@option1, dashless);
	@pid[nick] = pinfo(@option1)[4];
	}
	#Bedrock to Java players come in with name ".NAME", remove dot
	if(reg_count('^[\\.].*', @pid[name]) == 1, 
		assign(@pid[display], reg_replace('^[\\.]','', @pid[name]))
	)
	return(@pid)
}


bind('player_join', array(id: 'chHelperz.login'), null, @login) {
	#event playername may return null for some unknown reason
	assign(@player, _ch_getplayerID(player()))

	export('chHelperz.player.'.@player[id].'.command.show.all', get_value('chHelperz.player.'.@player[id].'.command.show.all'))
}


bind('player_command', array(id: 'chHelperz.cmd'), null, @cmdevent) {
	assign(@player, _ch_getplayerID(player()))
	assign(@cmd, reg_split(' ', @cmdevent[command]))

	#List cmd used, with CH aliases showing as a different color.
	if(is_alias(@cmd[0]), assign(@cmdcolor, 3), assign(@cmdcolor, 6))

	#show command to the console if permitted to do so.
	assign(@consolecmdshow, import('chHelperz.console.command.show'))
	if(@consolecmdshow == true,
		console(color(7).@player[display].' used '.color(@cmdcolor).@cmdevent[command], false)
	)
	#show command back to the player who issued the command, if permitted to do so.
	assign(@sendcmd, import('chHelperz.player.'.@player[id].'.command.show.all'))
	if(@sendcmd == null,
			assign(@sendcmd, get_value('chHelperz.player.'.@player[id].'.command.show.all'))
			export('chHelperz.player.'.@player[id].'.command.show.all', @sendcmd)
	)

	#Save the last command this player used.
	switch(@cmd[0]){
		case '/.':
		case '/repeat':
		case '/\'':
			msg(no)
		default:
			if(@sendcmd == true) {
				if(has_permission(@player[name], 'commandhelper.alias.see.is.alias'), null,
					assign(@cmdcolor, '7')
				)
				msg('> '.color(@cmdcolor).@cmdevent[command])
				export('chHelperz.player.'.@player[id].'.last.command', @cmdevent[command])
			}
	}
}
