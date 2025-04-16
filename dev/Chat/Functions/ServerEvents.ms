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
	@concurrentList = import('Server.IP.concurrent')
	if(!is_array(@concurrentList)) { @concurrentList = array() }
	if(!array_index_exists(@concurrentList, @ip)) { array_set(@concurrentList, @ip, 0) }
	@concurrentList[@ip]++
	export('Server.IP.concurrent', @concurrentList)

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
	
# IP Check: record number of concurrent players connected
	@concurrentList = import('Server.IP.concurrent')
	if(!is_array(@concurrentList)) { @concurrentList = array() }
	if(!array_index_exists(@concurrentList, @ip)) { array_set(@concurrentList, @ip, 1) }
	@concurrentList[@ip]--
	if(@concurrentList[@ip] == 0) { array_remove(@concurrentList, @ip) }
	export('Server.IP.concurrent', @concurrentList)
	
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
			_discordBot_send_mc_chat('leave', '', @playerID['name'], @dcChannel)
		}
	}
}

# ----------------------------

bind('server_ping', array('id': 'Chat.Format.Ping'), null, @ping) {
	@blacklistIP = import('Chat.config.IPBlacklist')
	if(!is_array(@blacklistIP)) { @blacklistIP = array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()) }
	@time = time();
	@serverConfig = import('Chat.config.Server')
	@pinglevel = @serverConfig['Ping_Message_Level']
	# Repeated pings get special message
	@ip = reg_replace('[%][0]$', '', @ping['ip'])
	@iplastping = import('Chat.ping.IP.times')
	if(!is_array(@iplastping)) { @iplastping = array() }
	if(!array_index_exists(@iplastping, @ip)) {
		array_set(@iplastping, @ip, (@time - 10000))
	}
	@ignore = false
	if(array_contains(@serverConfig['Ping_Message_Ignore_IP'], @ip) || array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @ip)) { @ignore = true }
	@superignore = array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @ip)

# Blacklisted IPs: do not send any data about the server if possible, and don't send any ping messages.
	if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
		super_cancel();
		# ^ only affects server listings.
		_chat_pings_write_log(@ping, 'blacklist');
		if(@serverConfig['Ping_Blacklist_Console'] == true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist IP: '.@ip, false) }
		die();
	}
	foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
		@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
		if(string_starts_with(string(@ip), @startBlock)) {
			super_cancel();
			# ^ only affects server listings.
			_chat_pings_write_log(@ping, 'blacklist', false, @ISP);
			if(@serverConfig['Ping_Blacklist_Console'] == true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist '.color(5).'Block'.color(8).' IP: '.@ip, false) }
			die();
		}
	}
	export('Chat.ping.IP.times', @iplastping);
# Repeated pings (i.e. quick refreshes)? Yea, don't bother displaying those!
	if(@time < (@iplastping[@ip] + 7000)) {
		modify_event('motd', @serverConfig['Repeated_Ping_Message']);
		die();
	}
# Colorize MOTD
	if(@serverConfig['MOTD_Rainbow'] == true) {
		modify_event('motd', _rainbow(@ping['motd'], @serverConfig['MOTD_Rainbow_Type']));
	}
# Get player name(s) from IP database
	@ipdata = import('primus.database.IP');
	@msgdisplay = ''
	if(is_array(@ipdata)) {
		if(array_index_exists(@ipdata, @ip)) {
		# Do not display ping message to admins immediately after player quit
			foreach(@acc in @ipdata[@ip]) {
				@checktime = import('Server.player.'._getplayerID(@acc)['id'].'.last.quit', (@time - 20000))
				if(@time < (@checktime + 10000)) { die(); }
			}
			@players = array_implode(@ipdata[@ip], ', ')
			@msgdisplay = ' ('.color(3).@players.color(7).')'
		}
	}
# Ignored IP: Log internally, don't (immediately) message.
	if(@ignore == true) { 
		_chat_pings_write_log(@ping, 'ignore', @superignore);
		@pinglevel = 0 
	}
# Admin Ping Messages:
	@adminPingMessage = color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Received ping from %fi%'.@ip.@msgdisplay.'%fi% %IPDB%%links%'
	if(@serverConfig['Ping_Message_LookupIP_DB'] == true) {
		@ipdb = _chat_lookup_ip_db(@ping['ip']);
		if(is_array(@ipdb)) {
			@listIPData = ''
			@cnFlag = ''
			if(@ipdb['cn'] != '') { @cnFlag = ':flag_'.to_lower(@ipdb['cn']).':' }
			if(@ipdb['rcn'] != '') { @cnFlag .= '(reg: :flag_'.to_lower(@ipdb['rcn']).':)' }
			# if(@ipdb['c'] != '') { @listIPData .= ' '.'Country: '.@ipdb['c'] }
			if(@ipdb['asn'] != '') {
				@listIPData .= ' ASN: '.@ipdb['asn']
				@addemoji = 0
				if(array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb['asn'])) {
					if(@blacklistIP['Discovered_ASNs'][@ipdb['asn']] > 0) { @addemoji = 1 } else { @addemoji = 3 }
				}
				if(array_index_exists(@blacklistIP, 'Spam_Player_ASNs')) {
					if(array_contains(@blacklistIP['Spam_Player_ASNs'], @ipdb['asn'])) { @addemoji = 4 }
				}
				if(array_index_exists(@blacklistIP, 'Auto_Blacklist_ASNs')) {
					if(array_contains(@blacklistIP['Auto_Blacklist_ASNs'], @ipdb['asn'])) {
						@addemoji = 2
						@blacklistIP['IP_Blacklist'][] = @ip
						export('Chat.config.IPBlacklist', @blacklistIP);
					}
				}
				if(@addemoji > 0) { @listIPData .= '%fe%%a'.@addemoji.'%%fs%' }
			} else { @listIPData = 'No ASN Found' }
			if(@ipdb['aso'] != '') { @listIPData .= ' ISP: '.@ipdb['aso'] }
			if(@listIPData == '') { @adminPingMessage = replace(@adminPingMessage, '%IPDB%', '') } else {
				@adminPingMessage = replace(@adminPingMessage, '%IPDB%', '  '.@cnFlag.'%fs%'.to_lower(@listIPData).'%fe%')
			}
		} else {
			@adminPingMessage = replace(@adminPingMessage, '%IPDB%', '')
		}
	} else { @adminPingMessage = replace(@adminPingMessage, '%IPDB%', '') }
	if(@serverConfig['Ping_Message_Console'] == true && @pinglevel > 0) {
		@cMsg = @adminPingMessage
		foreach(@key: @rep in array('fi': '', 'fs': '', 'fe': '', 'links': '', 'a1': ' <ASN Known>', 'a2': ' <Auto Added IP to Blacklist>', 'a3': ' <Past ASN>', 'a4': ' <ASN: Known MC Spam>')) {
			@cMsg = replace(@cMsg, '%'.@key.'%', @rep)
		}
		console(@cMsg, false)
	}
	if(@serverConfig['Ping_Message_Discord'] == true && @pinglevel > 1) {
		@IPList = array(@ip)
		@lookup = ''
		@IPType = 4
		if(string_contains(@ip, ':')) { @IPType = 6 }
		if(array_index_exists(@serverConfig, 'Ping_Message_Lookup_Links', @IPType)) {
			foreach(@link: @url in @serverConfig['Ping_Message_Lookup_Links'][@IPType]) {
				@url2 = replace(@url, '%IP%', @ip)
				@lookup .= ' ['.@link.'](<'.@url2.'>)'
			}
		}
		if(is_proc('_discordBot_broadcast')) {
			@dMsg = @adminPingMessage
			foreach(@key: @rep in array('fi': '`', 'fs': '[', 'fe': ']', 'links': @lookup, 'a1': ':exclamation:', 'a2': ':no_entry_sign:', 'a3': ':recycle:', 'a4': ':toilet:')) {
				@dMsg = replace(@dMsg, '%'.@key.'%', @rep)
			}
			_discordBot_broadcast('bot', '--ping', @dMsg, 'bot', closure(@msgID){
				@cacheID = import('DiscordBot.bot.msg.IP.Review')
				if(!is_array(@cacheID)) { @cacheID = array() }
				array_set(@cacheID, @msgID, @IPList)
				array_set(@cacheID, 'lastedit', time())
				if(array_size(@cacheID) > 400) {
					@key = array_keys(@cacheID)
					array_remove(@key, 'c')
					array_remove(@cacheID, array_sort(@key, 'NUMERIC')[0])
				}
				export('DiscordBot.bot.msg.IP.Review', @cacheID)
				return(true)
			});
		}
	}
}