#version 1.1-tmc
bind('player_join', array('id': 'Chat.Format.Join'), null, @login) {
	@playerID = _getplayerID(player())

#Console info
 	set_timeout(2000, closure(console(color(3).player().color('r').' connected with'.color(7).' IP: '.color('a').pinfo(player())[3].color(7).' hostname: '.pinfo(player())[10], false)))

#Join Message
	@joinmsg = color('a').'+ join'.color(7).': '.@playerID['display']
	
#Rei's minimap: Enable radar for everything, and cavemapping.
	@enablereimap = true
#	color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color('e').color('f'))
	if(@enablereimap == true) {
		modify_event('join_message', color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color('e').color('f').@joinmsg)
	} else {
		modify_event('join_message', @joinmsg)
	}
	
# Send Join message to Discord as well (if enabled)
	_send_discord_message('+ join: '.@playerID['name'], 'none')	
}

bind('player_quit', array('id': 'Chat.Format.Quit'), null, @quit) {
	@playerID = _getplayerID(player())
#Quit Message
	@quitmsg = color('c').'- part'.color(7).': '.@playerID['display']
	modify_event('message', @quitmsg)
# Send Quit message to Discord as well (if enabled)
	_send_discord_message('- part: '.@playerID['name'], 'none')
}

bind('server_ping', array('id': 'Chat.Format.Ping'), null, @ping) {
	#Colorize MOTD
	modify_event('motd', _rainbow(@ping['motd'], 'words'))
	
	#Get playername from IP database
	@ipdata = import('primus.database.IP')
	@msgdisplay = ''
	if(is_array(@ipdata)) {
		#entry found	
		@ipnumbers = reg_replace('\\.*:*', '', @ping['ip'])
		if(array_index_exists(@ipdata, @ipnumbers)) {
			@players = array_implode(@ipdata[@ipnumbers], ', ')
			@msgdisplay = ' ('.color(3).@players.color(7).')'
		}
	}
	console(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Received ping from '.@ping['ip'].@msgdisplay, false)
}