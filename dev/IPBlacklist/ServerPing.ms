bind('server_ping', array('id': 'ipbl.Format.Ping'), null, @ping) {
	@blacklistIP = import('ipbl.config.IPBlacklist')
	if(!is_array(@blacklistIP)) { @blacklistIP = array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()) }
	@time = time();
	@serverConfig = import('ipbl.config.Server')
	@pinglevel = @serverConfig['Ping_Message_Level']
	# Repeated pings get special message
	@ip = reg_replace('[%][0]$', '', @ping['ip']);
	@iplastping = import('ipbl.ping.IP.times')
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
		_ipbl_pings_write_log(@ping, 'blacklist');
		if(@serverConfig['Ping_Blacklist_Console'] == true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist IP: '.@ip, false) }
		die();
	}
	foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
		@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
		if(string_starts_with(string(@ip), @startBlock)) {
			super_cancel();
			# ^ only affects server listings.
			_ipbl_pings_write_log(@ping, 'blacklist', false, @ISP);
			if(@serverConfig['Ping_Blacklist_Console'] == true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist '.color(5).'Block'.color(8).' IP: '.@ip, false) }
			die();
		}
	}
	export('ipbl.ping.IP.times', @iplastping);
# Repeated pings (i.e. quick refreshes)? Yea, don't bother displaying those!
	if(@time < (@iplastping[@ip] + 7000)) {
		modify_event('motd', @serverConfig['Repeated_Ping_Message']);
		die();
	}
# Colorize MOTD
	if(@serverConfig['MOTD_Rainbow'] == true && is_proc('_rainbow')) {
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
		_ipbl_pings_write_log(@ping, 'ignore', @superignore);
		@pinglevel = 0 
	}
# Admin Ping Messages:
	@adminPingMessage = color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Received ping from %fi%'.@ip.@msgdisplay.'%fi% %IPDB%%links%'
	if(@serverConfig['Ping_Message_LookupIP_DB'] == true) {
		@ipdb = _geoip_lookup(@ping['ip']);
		if(is_array(@ipdb)) {
			@listIPData = ''
			@cnFlag = ''
			if(@ipdb[@ip]['cn'] != '') { @cnFlag = ':flag_'.to_lower(@ipdb[@ip]['cn']).':' }
			if(@ipdb[@ip]['rcn'] != '') { @cnFlag .= ', reg: :flag_'.to_lower(@ipdb[@ip]['rcn']).': ' }
			# if(@ipdb[@ip]['c'] != '') { @listIPData .= ' '.'Country: '.@ipdb[@ip]['c'] }
			if(@ipdb[@ip]['asn'] != '') {
				@listIPData .= ' ASN: '.@ipdb[@ip]['asn']
				@addemoji = 0
				if(array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb[@ip]['asn'])) {
					if(@blacklistIP['Discovered_ASNs'][@ipdb[@ip]['asn']] > 0) { @addemoji = 1 } else { @addemoji = 3 }
				}
				if(array_index_exists(@blacklistIP, 'Spam_Player_ASNs')) {
					if(array_contains(@blacklistIP['Spam_Player_ASNs'], @ipdb[@ip]['asn'])) { @addemoji = 4 }
				}
				if(array_index_exists(@blacklistIP, 'Auto_Blacklist_ASNs')) {
					if(array_contains(@blacklistIP['Auto_Blacklist_ASNs'], @ipdb[@ip]['asn'])) {
						@addemoji = 2
						@blacklistIP['IP_Blacklist'][] = @ip
						export('ipbl.config.IPBlacklist', @blacklistIP);
						_ipbl_save_config();
					}
				}
				if(@addemoji > 0) { @listIPData .= '%fe%%a'.@addemoji.'%%fs%' }
			} else { @listIPData = 'No ASN Found' }
			if(@ipdb[@ip]['aso'] != '') { @listIPData .= ' | '.@ipdb[@ip]['aso'] }
			if(@listIPData == '') { @adminPingMessage = replace(@adminPingMessage, '%IPDB%', '') } else {
				@adminPingMessage = replace(@adminPingMessage, '%IPDB%', '  '.@cnFlag.'%fs%'.to_lower(@listIPData).'%fe%');
			}
		} else {
			@adminPingMessage = replace(@adminPingMessage, '%IPDB%', '');
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
					@selectKey = array_keys(@cacheID)
					array_remove(@cacheID, @selectKey[1])
					array_remove(@cacheID, @selectKey[0])
				}
				export('DiscordBot.bot.msg.IP.Review', @cacheID);
				return(true);
			});
		}
	}
}