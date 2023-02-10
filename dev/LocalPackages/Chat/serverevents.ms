#version 1.2-tmc
bind('player_join', array('id': 'Chat.Format.Join', 'priority': 'HIGH'), null, @login) {
	@serverConfig = import('Chat.config.Server')
	@playerID = _getplayerID(player())
	@ip = pinfo(player())[3]
	@ipnumbers = reg_replace('\\.*:*', '', @ip)
# Console info
 	set_timeout(2000, closure(console(color(3).player().color('r').' connected with'.color(7).' IP: '.color('a').pinfo(player())[3].color(7).' hostname: '.pinfo(player())[10], false)))

# Setup Join Message
	@joinmsg = ''
	switch(@serverConfig['Join_Message']) {
		case 'default':
		case 'Default':
			@joinmsg = @login['join_message']
		case 'none':
		case false:
		case null:
		case '':
			modify_event('join_message', null)
			# _send_discord_message('Admin '.@playerID['name'].' stealthily joined server', 'admin', '', 'join')
			die()
		case 'example':
		case 'test':
			@joinmsg = color('a').'+ join'.color(7).': '.@playerID['display']
		default:
			@joinmsg = reg_replace('\\%player\\%', @playerID['name'], @serverConfig['Join_Message'])
			@joinmsg = reg_replace('\\%nick\\%', @playerID['display'], @joinmsg)
	}
	
# Minimap: Enable radar for everything, and cavemapping. (Codes set for Rei's Minimap)
	if(@serverConfig['Enable_Advanced_Map'] == true) { @joinmsg = color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color('e').color('f').@joinmsg }

# IP Check: record number of concurrent players connected	
	export('Server.IP.'.@ipnumbers.'.concurrent', import('Server.IP.'.@ipnumbers.'.concurrent') + 1)

# Send Message	
	modify_event('join_message', @joinmsg)
# Send Join message to Discord as well (if enabled)
	_send_discord_message(@playerID['name'], 'none', '', 'join')
}

bind('player_quit', array('id': 'Chat.Format.Quit'), null, @quit) {
	@serverConfig = import('Chat.config.Server')
	@playerID = _getplayerID(player())
	@ip = pinfo(player())[3]
	@ipnumbers = reg_replace('\\.*:*', '', @ip)
	
# IP Check: record number of concurrent players connected
	@ipcon = import('Server.IP.'.@ipnumbers.'.concurrent')
	if(@ipcon <= 0) { @ipcon = 0 } else { @ipcon = @ipcon - 1 }
	export('Server.IP.'.@ipnumbers.'.concurrent', @ipcon)
	
# Setup Quit Message
	@quitmsg = ''
	switch(@serverConfig['Leave_Message']) {
		case 'default':
		case 'Default':
			@quitmsg = @quit['message']
		case 'none':
		case false:
		case null:
		case '':
			modify_event('message', null)
			# _send_discord_message('Admin '.@playerID['name'].' stealthily left server', 'admin', '', 'leave')
			die()
		case 'example':
		case 'test':
			@quitmsg = color('c').'- part'.color(7).': '.@playerID['display']
		default:
			@quitmsg = reg_replace('\\%player\\%', @playerID['name'], @serverConfig['Leave_Message'])
			@quitmsg = reg_replace('\\%nick\\%', @playerID['display'], @quitmsg)
	}

	modify_event('message', @quitmsg)
	export('Server.player.'.@playerID['id'].'.last.quit', time())
# Send Quit message to Discord as well (if enabled)
	_send_discord_message(@playerID['name'], 'none', '', 'leave')
}

bind('server_ping', array('id': 'Chat.Format.Ping'), null, @ping) {
	@serverConfig = import('Chat.config.Server')
	# Repeated pings get special message
	@ipnumbers = reg_replace('\\.*:*', '', @ping['ip'])
	@iplastping = import('Chat.ping.IP.'.@ipnumbers, (time() - 10000))
	if(time() < (@iplastping + 7000)) {
		modify_event('motd', @serverConfig['Repeated_Ping_Message'])
		export('Chat.ping.IP.'.@ipnumbers, time())
		die()
	}
	export('Chat.ping.IP.'.@ipnumbers, time())
	# Colorize MOTD
	if(@serverConfig['MOTD_Rainbow'] == true) {
		modify_event('motd', _rainbow(@ping['motd'], @serverConfig['MOTD_Rainbow_Type']))
	}
	# Get player name(s) from IP database
	@ipdata = import('primus.database.IP')
	@msgdisplay = ''
	if(is_array(@ipdata)) {
		if(array_index_exists(@ipdata, @ipnumbers)) {
		# Do not display ping message to admins immediately after player quit
			foreach(@acc in @ipdata[@ipnumbers]) {
				@checktime = import('Server.player.'._getplayerID(@acc)['id'].'.last.quit', (time() - 20000))
				if(time() < (@checktime + 10000)) {
					die()
				}
			}
			@players = array_implode(@ipdata[@ipnumbers], ', ')
			@msgdisplay = ' ('.color(3).@players.color(7).')'
		} else {
			if(array_contains(@serverConfig['Ping_Message_Ignore_IP'], @ping['ip'])) { die() }
		}
	} else {
		if(array_contains(@serverConfig['Ping_Message_Ignore_IP'], @ping['ip'])) { die() }
	}
	# Admin Ping Messages:
	@adminPingMessage = color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Received ping from '.@ping['ip'].@msgdisplay
	if(@serverConfig['Ping_Message_Discord'] == true) {
		_send_discord_message(@adminPingMessage, 'none', '', 'admin')
	}
	if(@serverConfig['Ping_Message_Console'] == true) {
		console(@adminPingMessage, false)
	}
}