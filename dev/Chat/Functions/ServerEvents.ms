#version 1.3-tmc
bind('player_join', array('id': 'Chat.Format.Join', 'priority': 'HIGH'), null, @login) {
	@serverConfig = import('Chat.config.Server')
	@playerID = _getplayerID(player())
	@ip = pinfo(player())[3]
	@ipnumbers = reg_replace('\\.*:*', '', @ip)
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
	if(has_permission(@playerID['name'], 'essentials.silentjoin')) { @dcChannel = 'admin' }
	switch(@serverConfig['Join_Message']) {
		case 'default':
		case 'Default':
			@joinmsg = @login['join_message']
		case 'admin':
			@sendMsg = false
			if(array_contains(pgroup(@playerID['name']), 'admin') || @dcChannel == 'admin') { 
				@type = 'admin'
				@joinmsg = 'Admin '.@playerID['name'].' joined server'
				_chat_msg_Admins(@joinmsg)
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

# IP Check: record number of concurrent players connected	
	export('Server.IP.'.@ipnumbers.'.concurrent', import('Server.IP.'.@ipnumbers.'.concurrent') + 1)

# Send Join Message to Minecraft
	if(@sendMsg == true) { modify_event('join_message', @joinmsg) } else { modify_event('join_message', null) }
# Send Join message to Discord (if enabled)
 	if(is_proc('_discordBot_send_mc_chat')) { 
		if(@sendMsg == true || @serverConfig['Join_Message'] == 'admin') {
			set_timeout(2000, closure(
				if(array_contains(all_players(), @playerID['name'])) {
					_discordBot_send_mc_chat(@playerID['name'], 'none', @dcChannel, 'join') }
			));
		}
	}
}

bind('player_quit', array('id': 'Chat.Format.Quit'), null, @quit) {
	@time = time()
	@serverConfig = import('Chat.config.Server')
	@playerID = _getplayerID(player())
	@ip = pinfo(player())[3]
	@ipnumbers = reg_replace('\\.*:*', '', @ip)
	@sendMsg = true
	@type = 'none'
	
# IP Check: record number of concurrent players connected
	@ipcon = import('Server.IP.'.@ipnumbers.'.concurrent')
	if(@ipcon <= 0) { @ipcon = 0 } else { @ipcon = @ipcon - 1 }
	export('Server.IP.'.@ipnumbers.'.concurrent', @ipcon)
	
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
				_chat_msg_Admins(@quitmsg)
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
			_discordBot_send_mc_chat(@playerID['name'], 'none', @dcChannel, 'leave')
		}
	}
}


#Ignored IP pings notification
set_cron('59 23 * * *', closure(){ 
	@count = 0
	@serverConfig = import('Chat.config.Server')
	@iplog = get_value('Server.pings.log.ignore.IP')
	@useMsg = false
	if(!is_array(@iplog)) { die(); }
	if(array_size(@iplog) == 0) { die(); }
	@Message = color(6).'['.color(9).'Server'.color(6).'] '.color(14).simple_date('[MM/dd]', time()).color(7).' Ignored IP ping report:'
	@checktime = (time() - 86400000)
	foreach(@ipnum: @times in @iplog) {
		if(@ipnum == 'ip') { continue(); }
		if(array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @iplog['ip'][@ipnum])) { continue(); }
		@count = 0
		foreach(@data in @times) {
			if(@checktime > @data) { continue(); }
			@count++			
		}
		if(@count > 0) {
			@useMsg = true
			@s = ''
			if(@count > 1) { @s = 's' }
			@Message = @Message.'\n'.'%format%'.color(9).@iplog['ip'][@ipnum].color(7).'%format%   '.color(12).@count.color(7).' ping'.@s
		}
	}
	if(@useMsg == true) {
		if(@serverConfig['Ping_Message_Discord'] == true && @serverConfig['Ping_Message_Level'] > 1) {
			if(is_proc('_discordBot_send_message')) { _discordBot_send_message(replace(@Message, '%format%', '`'), '', 'admin') }
		}
		if(@serverConfig['Ping_Message_Console'] == true && @serverConfig['Ping_Message_Level'] > 0) { console(replace(@Message, '%format%', ''), false) }
	}
});

bind('server_ping', array('id': 'Chat.Format.Ping'), null, @ping) {
	@blacklistIP = import('Chat.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
	@time = time();
	@serverConfig = import('Chat.config.Server')
	@pinglevel = @serverConfig['Ping_Message_Level']
	# Repeated pings get special message
	@ipnumbers = reg_replace('\\.*:*', '', @ping['ip'])
	@iplastping = import('Chat.ping.IP.'.@ipnumbers, (@time - 10000))
	@ignore = false
	if(array_contains(@serverConfig['Ping_Message_Ignore_IP'], @ping['ip']) || array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @ping['ip'])) { @ignore = true }
	@superignore = array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @ping['ip'])

# Blacklisted IPs: do not send any data about the server if possible, and don't send any ping messages.
	if(array_contains(@blacklistIP['IP_Blacklist'], @ping['ip'])) {
		super_cancel();
		# ^ only affects server listings.
		_chat_pings_write_log(@ping, 'blacklist');
		if(@serverConfig['Ping_Blacklist_Console'] == true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist IP: '.@ping['ip'], false) }
		die();
	}
	foreach(@block in @blacklistIP['IP_Block_Blacklist']) {
		@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
		if(string_starts_with(string(@ping['ip']), @startBlock)) {
			super_cancel();
			# ^ only affects server listings.
			_chat_pings_write_log(@ping, 'blacklist');
			if(@serverConfig['Ping_Blacklist_Console'] == true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist '.color(5).'Block'.color(8).' IP: '.@ping['ip'], false) }
			die();
		}
	}
# Repeated pings (i.e. quick refreshes)? Yea, don't bother displaying those!
	if(@time < (@iplastping + 7000)) {
		modify_event('motd', @serverConfig['Repeated_Ping_Message']);
		export('Chat.ping.IP.'.@ipnumbers, @time);
		die();
	}
	export('Chat.ping.IP.'.@ipnumbers, @time)
# Colorize MOTD
	if(@serverConfig['MOTD_Rainbow'] == true) {
		modify_event('motd', _rainbow(@ping['motd'], @serverConfig['MOTD_Rainbow_Type']));
	}
# Get player name(s) from IP database
	@ipdata = import('primus.database.IP');
	@msgdisplay = ''
	if(is_array(@ipdata)) {
		if(array_index_exists(@ipdata, @ipnumbers)) {
		# Do not display ping message to admins immediately after player quit
			foreach(@acc in @ipdata[@ipnumbers]) {
				@checktime = import('Server.player.'._getplayerID(@acc)['id'].'.last.quit', (@time - 20000))
				if(@time < (@checktime + 10000)) { die(); }
			}
			@players = array_implode(@ipdata[@ipnumbers], ', ')
			@msgdisplay = ' ('.color(3).@players.color(7).')'
		}
	}
# Ignored IP: Log internally, don't (immediately) message.
	if(@ignore == true) { 
		_chat_pings_write_log(@ping, 'ignore', @superignore);
		@pinglevel = 0 
	}
# Admin Ping Messages:
	@adminPingMessage = color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Received ping from %format%'.@ping['ip'].@msgdisplay.'%format%'
	if(@serverConfig['Ping_Message_Discord'] == true && @pinglevel > 1) {
		if(is_proc('_discordBot_send_message')) { _discordBot_send_message(replace(@adminPingMessage, '%format%', '`'), '', 'admin') }
	}
	if(@serverConfig['Ping_Message_Console'] == true && @pinglevel > 0) { console(replace(@adminPingMessage, '%format%', ''), false) }
}