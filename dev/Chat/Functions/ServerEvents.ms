bind('server_ping', array('id': 'Chat.Format.Ping'), null, @ping) {
	@time = time();
	@serverConfig = import('Chat.config.Server');
	# Repeated pings get special message
	@ip = reg_replace('[%][0]$', '', @ping['ip']);
	@iplastping = import('ipbl.ping.IP.times')
	if(!is_array(@iplastping)) { @iplastping = array() }
	if(!array_index_exists(@iplastping, @ip)) {
		array_set(@iplastping, @ip, (@time - 10000))
	}
	@ignore = false
	if(array_contains(@serverConfig['Static_Ping_Message_To_IP'], @ip)) { die() }
# Repeated pings (i.e. quick refreshes)? Yea, don't bother displaying those!
	if(@time < (@iplastping[@ip] + 7000)) {
		modify_event('motd', @serverConfig['Repeated_Ping_Message']);
		die();
	}
# Colorize MOTD
	if(@serverConfig['MOTD_Rainbow'] == true && is_proc('_rainbow')) {
		modify_event('motd', _rainbow(@ping['motd'], @serverConfig['MOTD_Rainbow_Type']));
	}
}

bind('player_join', array('id': 'Chat.Format.Join', 'priority': 'HIGH'), null, @login) {
	@serverConfig = import('Chat.config.Server')
	@playerID = _getplayerID(player())
	@ip = reg_replace('[%][0]$', '', pinfo(player())[3])
	@consolemsg = color(3).player().color('r').' connected with'.color(7).' IP: '.color('a').@ip.color(7).' hostname: '.pinfo(player())[10]
	@jointime = time()
	export('Server.player.'.@playerID['id'].'.last.join', @jointime)
	@sendMsg = true
	@type = 'none'
# Console info
 	console(@consolemsg, false)

# Setup Join Message
	@joinmsg = ''
	@dcChannel = ''
	try(if(has_permission(@playerID['name'], 'essentials.silentjoin')) { @dcChannel = '--admin' })
	switch(@serverConfig['Join_Message']) {
		case 'default':
		case 'Default':
			@joinmsg = @login['join_message']
		case 'admin':
			@sendMsg = false
			if(array_contains(pgroup(@playerID['name']), 'admin') || @dcChannel == '--admin') { 
				@type = 'admin'
				@joinmsg = 'Admin '.@playerID['name'].' joined server'
				_msg_Admins('', '-', @joinmsg)
			}
		case 'none':
		case false:
		case null:
		case '':
			@sendMsg = false
		case 'example':
		case 'test':
			@joinmsg = color('a').'+ join'.color(7).': '.@playerID['display']
		default:
			@joinmsg = replace(@serverConfig['Join_Message'], '%player%', @playerID['name'])
			@joinmsg = replace(@joinmsg, '%nick%', @playerID['display'])
	}
	
# Minimap: Enable radar for everything, and cavemapping. (Codes set for Rei's Minimap)
	if(@serverConfig['Enable_Advanced_Map'] == true) { @joinmsg = color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color('e').color('f').@joinmsg }

# Send Join Message to Minecraft
	if(@sendMsg == true) { modify_event('join_message', @joinmsg) } else { modify_event('join_message', null) }
# Send Join message to Discord (if enabled)
 	if(is_proc('_discordBot_send_mc_chat')) { 
		if(@sendMsg == true || @serverConfig['Join_Message'] == 'admin') {
			set_timeout(2000, closure(
				if(array_contains(all_players(), @playerID['name'])) {
					_discordBot_send_mc_chat('join', '', @playerID['name'], @dcChannel) }
			));
		}
	}
}

# ----------------------------

bind('player_quit', array('id': 'Chat.Format.Quit'), null, @quit) {
	@time = time()
	@serverConfig = import('Chat.config.Server')
	@playerID = _getplayerID(player())
	@ip = reg_replace('[%][0]$', '', pinfo(player())[3])
	@sendMsg = true
	@type = 'none'
	
# Setup Quit Message
	@quitmsg = ''
	@dcChannel = ''
	if(has_permission(@playerID['name'], 'essentials.silentquit')) { @dcChannel = 'admin' }
	switch(@serverConfig['Leave_Message']) {
		case 'default':
		case 'Default':
			@quitmsg = @quit['message']
		case 'admin':
			@sendMsg = false
			if(array_contains(pgroup(@playerID['name']), 'admin') || @dcChannel == 'admin') { 
				@type = 'admin'
				@quitmsg = 'Admin '.@playerID['name'].' left server'
				_msg_Admins('', 'none', @quitmsg)
			}
		case 'none':
		case false:
		case null:
		case '':
			@sendMsg = false
		case 'example':
		case 'test':
			@quitmsg = color('c').'- part'.color(7).': '.@playerID['display']
		default:
			@quitmsg = replace(@serverConfig['Leave_Message'], '%player%', @playerID['name'])
			@quitmsg = replace(@quitmsg, '%nick%', @playerID['display'])
	}

# Immediate logout check, don't send message if so
	@jointime = import('Server.player.'.@playerID['id'].'.last.join', 3000)
	if(@jointime > (@time - 2000)) { @sendMsg = false }

# Send Quit message to Minecraft
	if(@sendMsg == true) { modify_event('message', @quitmsg) } else { modify_event('message', null) }
	export('Server.player.'.@playerID['id'].'.last.quit', @time)
# Send Quit message to Discord as well (if enabled)
	if(is_proc('_discordBot_send_mc_chat')) { 
		if(@sendMsg == true || @type == 'admin') {
			_discordBot_send_mc_chat('leave', '', @playerID['name'], @dcChannel)
		}
	}
}