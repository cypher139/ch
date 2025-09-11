bind('server_ping', array('id': 'ipbl.Monitor.Ping', 'priority': 'HIGH'), null, @ping) {
	@blacklistIP = import('ipbl.config.IPBlacklist');
	if(!is_array(@blacklistIP)) { @blacklistIP = array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()); }
	@time = time();
	@serverConfig = import('ipbl.config.Server');
	@pinglevel = @serverConfig['Ping_Message_Level'];
	# Repeated pings get special message
	@ip = reg_replace('[%][0]$', '', @ping['ip']);
	@iplastping = import('ipbl.ping.IP.times');
	if(!is_array(@iplastping)) { @iplastping = array(); }
	@iplastping[@ip] = (@time - 10000);
	@ignore = false;
	if(array_contains(@serverConfig['Ping_Message_Ignore_IP'], @ip) || array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @ip)) { @ignore = true; }
	@superignore = array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @ip);

# Blacklisted IPs: do not send any data about the server if possible, and don't send any ping messages.
	if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
		super_cancel();
		# ^ only affects server listings.
		_ipbl_pings_write_log(@ping, 'blacklist');
		if(@serverConfig['Ping_Blacklist_Console'] === true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist IP: '.@ip, false); }
		die();
	}
	foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
		@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
		if(string_starts_with(string(@ip), @startBlock)) {
			super_cancel();
			# ^ only affects server listings.
			_ipbl_pings_write_log(@ping, 'blacklist', false, @ISP);
			if(@serverConfig['Ping_Blacklist_Console'] === true) { console(color(9).'['.color(12).'Server'.color(9).'] '.color(8).'Ping from Blacklist '.color(5).'Block'.color(8).' IP: '.@ip, false); }
			die();
		}
	}
	export('ipbl.ping.IP.times', @iplastping);
# Get player name(s) from IP database
	@ipdata = import('primus.database.IP');
	@msgdisplay = '';
	if(is_array(@ipdata)) {
		if(array_index_exists(@ipdata, @ip)) {
		# Do not display ping message to admins immediately after player quit
			foreach(@acc in @ipdata[@ip]) {
				@checktime = import('Server.player.'._getplayerID(@acc)['id'].'.last.quit', (@time - 20000));
				if(@time < (@checktime + 10000)) { die(); }
			}
			@players = array_implode(@ipdata[@ip], ', ');
			@msgdisplay = ' ('.color(3).@players.color(7).')';
		}
	}
# Ignored IP: Log internally, don't (immediately) message.
	if(@ignore === true) { 
		_ipbl_pings_write_log(@ping, 'ignore', @superignore);
		@pinglevel = 0 
	}
# Admin Ping Messages:
	@adminPingMessage = color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Received ping from %fi%'.@ip.@msgdisplay.'%fi% %IPDB%%links%';
	if(@serverConfig['Ping_Message_LookupIP_DB'] === true) {
		@ipdb = _geoip_lookup(@ping['ip']);
		if(is_array(@ipdb)) {
			@listIPData = '';
			@cnFlag = '';
			if(@ipdb[@ip]['cn'] != '') { @cnFlag = ':flag_'.to_lower(@ipdb[@ip]['cn']).':'; }
			if(@ipdb[@ip]['rcn'] != '') { @cnFlag .= ', reg: :flag_'.to_lower(@ipdb[@ip]['rcn']).': '; }
			# if(@ipdb[@ip]['c'] != '') { @listIPData .= ' '.'Country: '.@ipdb[@ip]['c']; }
			if(@ipdb[@ip]['asn'] != '') {
				@listIPData .= ' ASN: '.@ipdb[@ip]['asn']
				@addemoji = 0
				if(array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb[@ip]['asn'])) {
					if(@blacklistIP['Discovered_ASNs'][@ipdb[@ip]['asn']] > 0) { @addemoji = 1; } else { @addemoji = 3; }
				}
				if(array_index_exists(@blacklistIP, 'Spam_Player_ASNs')) {
					if(array_contains(@blacklistIP['Spam_Player_ASNs'], @ipdb[@ip]['asn'])) { @addemoji = 4; }
				}
				if(array_index_exists(@blacklistIP, 'Auto_Blacklist_ASNs')) {
					if(array_contains(@blacklistIP['Auto_Blacklist_ASNs'], @ipdb[@ip]['asn'])) {
						@addemoji = 2
						@blacklistIP['IP_Blacklist'][] = @ip;
						export('ipbl.config.IPBlacklist', @blacklistIP);
						_ipbl_save_config(@blacklistIP);
					}
				}
				if(@addemoji > 0) { @listIPData .= '%fe%%a'.@addemoji.'%%fs%'; }
			} else { @listIPData = 'No ASN Found' }
			if(@ipdb[@ip]['aso'] != '') { @listIPData .= ' | '.@ipdb[@ip]['aso']; }
			if(@listIPData == '') { @adminPingMessage = replace(@adminPingMessage, '%IPDB%', ''); } else {
				@adminPingMessage = replace(@adminPingMessage, '%IPDB%', '  '.@cnFlag.'%fs%'.to_lower(@listIPData).'%fe%');
			}
		} else {
			@adminPingMessage = replace(@adminPingMessage, '%IPDB%', '');
		}
	} else { @adminPingMessage = replace(@adminPingMessage, '%IPDB%', '') }
	if(@serverConfig['Ping_Message_Console'] === true && @pinglevel > 0) {
		@cMsg = @adminPingMessage;
		foreach(@key: @rep in array('fi': '', 'fs': '', 'fe': '', 'links': '', 'a1': ' <ASN Known>', 'a2': ' <Auto Added IP to Blacklist>', 'a3': ' <Past ASN>', 'a4': ' <ASN: Known MC Spam>')) {
			@cMsg = replace(@cMsg, '%'.@key.'%', @rep);
		}
		console(@cMsg, false);
	}
	if(@serverConfig['Ping_Message_Discord'] === true && @pinglevel > 1) {
		@IPList = array(@ip);
		@lookup = '';
		@IPType = 4
		if(string_contains(@ip, ':')) { @IPType = 6; }
		if(array_index_exists(@serverConfig, 'Ping_Message_Lookup_Links', @IPType)) {
			foreach(@link: @url in @serverConfig['Ping_Message_Lookup_Links'][@IPType]) {
				@url2 = replace(@url, '%IP%', @ip);
				@lookup .= ' ['.@link.'](<'.@url2.'>)';
			}
		}
		if(is_proc('_discordBot_broadcast')) {
			@dMsg = @adminPingMessage;
			foreach(@key: @rep in array('fi': '`', 'fs': '[', 'fe': ']', 'links': @lookup, 'a1': ':exclamation:', 'a2': ':no_entry_sign:', 'a3': ':recycle:', 'a4': ':toilet:')) {
				@dMsg = replace(@dMsg, '%'.@key.'%', @rep);
			}
			_discordBot_broadcast('bot', '--ping', @dMsg, 'bot', closure(@msgID){
				@cacheID = import('DiscordBot.bot.msg.IP.Review');
				if(!is_array(@cacheID)) { @cacheID = array(); }
				@cacheID[@msgID] = @IPList;
				@cacheID['lastedit'] = time();
				if(array_size(@cacheID) > 400) {
					@selectKey = array_keys(@cacheID);
					array_sort(@selectKey, 'NUMERIC');
					_db_msg_Console('[ping] IP review msg Cache ('.array_size(@cacheID).'): picked: '.@selectKey[0].'   '.@selectKey[1], 'debug');
					array_remove(@cacheID, @selectKey[0]);
					array_remove(@cacheID, @selectKey[1]);
				}
				export('DiscordBot.bot.msg.IP.Review', @cacheID);
				return(true);
			});
		}
	}
}

bind('player_login', array('id': 'ipbl.Monitor.Login', 'priority': 'HIGH'), null, @event) {	
	@serverConfig = import('ipbl.config.Server');
	@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()));
	@ipdata = import('primus.database.IP');
	@ip = reg_replace('[%][0]$', '', @event['ip']);
	if(!is_array(@ipdata)) { @ipdata = array(); }
	@players = '';
	@playersMsg = '';
	@msgPrefix = color(6).'['.color(9).'Server'.color(6).'] ';
	if(array_index_exists(@ipdata, @ip)) {
		@players = array_implode(@ipdata[@ip], ', ');
		@playersMsg = '(Account names: %f'.color(3).@players.'%f)';
	}
	@kickMsg = '';
	@kickPlayer = false;
	@adminMsg = @msgPrefix.'Message Not Given';
	@kickType = '0';
# Should we take action on multiple accounts using the same IP address?
	if(@serverConfig['Check_Multiple_Accs_IP'] === true) {
	# How many accounts can be connected with the same IP address at any given time?
		@concurrentList = import('Server.IP.concurrent');
		if(!is_array(@concurrentList)) { @concurrentList = array(); }
		if(!array_index_exists(@concurrentList, @ip)) { @concurrentList[@ip] = 0; }
		if(@serverConfig['Concurrent_Accs_IP'] == @concurrentList[@ip]) {
			@kickPlayer = true;
			@kickMsg = 'Too many Accounts are using this IP address.';
			@kickType .= '1';
			@otherplayers = array();
			foreach(@accname in all_players()) {
				if(pinfo(@accname)[3] = @event['ip']) {
					@otherplayers[] = pinfo(@accname)[0]
				}
			}
			@players = '%f'.array_implode(@otherplayers, ', ').'%f';
			@adminMsg = color(7).'%f'.@event['player'].'%f tried to connect with IP %f'.color(9).@ip.color(7).'%f; however '.@serverConfig['Concurrent_Accs_IP'].' accounts are already connected using the same IP address: '.@players
		}
	# If many accounts have previously connected using the same IP address, should we automatically kick joins from this IP?
		if(@serverConfig['Kick_Multiple_Accs_IP'] === true) {
			if(array_index_exists(@ipdata, @ip) && !array_index_exists(@serverConfig['Kick_Multiple_Accs_IP_Whitelist'], @ip)) {
				if(array_size(@ipdata[@ip]) > @serverConfig['Allowed_Account_Amount']) {
					@kickPlayer = true;
					@kickMsg = 'This server does not allow players to use multiple Alternate Accounts.';
					@kickType .= '2';
					@adminMsg = color(7).'%f'.@event['player'].'%f tried to connect; this server does not allow more than '.@serverConfig['Allowed_Account_Amount'].' accounts using the same IP address. (IP: %f'.color(9).@ip.'%f) '.color(7).@playersMsg
				}
			}
		}
	}
# Blacklisted IPs: Disallow Login
# Note that this does not handle 'lost connection' logins, as CH events do not fire that early in login process
	if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
		@kickPlayer = true;
		@kickMsg = 'You have been Banned.';
		@kickType .= '3';
		@adminMsg = color(7).@event['player'].' tried to connect using '.color(12).'Blacklisted IP address:  '.color(9).@ip.' '.color(7).@playersMsg
	}
	foreach(@block in @blacklistIP['IP_Block_Blacklist']) {
		@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
		if(string_starts_with(string(@ip), @startBlock)) {
			@kickPlayer = true;
			@kickMsg = 'You have been Banned.';
			@kickType .= '4';
			@adminMsg = color(7).@event['player'].' tried to connect using IP address '.color(9).@ip.color(7).' that is part of a '.color(12).'Blacklisted IP Block. '.color(7).@playersMsg
		}
	}
#Handle Player Kick and Admin messages
	if(@kickPlayer === true) {
		consume();
		modify_event('kickmsg', @kickMsg);
		modify_event('result', 'KICK_OTHER');
		if(is_proc('_primus_database_add')) { _primus_database_add(@event['player'], 'ip', @ip, @event['hostname']); }
		if(@serverConfig['Ping_Message_Discord'] === true) { 
			if(is_proc('_discordBot_broadcast')) { _discordBot_broadcast('bot', '--admin', @msgPrefix.'['.@kickType.'] '.replace(@adminMsg, '%f', '`')); }
		}
		if(@serverConfig['Ping_Message_Console'] === true) { console(@msgPrefix.'['.@kickType.'] '.replace(@adminMsg, '%f', ''), false); }
	}	
}

# Concurrent IP Check: record number of concurrent players connected
bind('player_join', array('id': 'ipbl.Monitor.Join', 'priority': 'MONITOR'), null, @event) {
	@serverConfig = import('ipbl.config.Server');
	@ip = reg_replace('[%][0]$', '', pinfo(player())[3]);
	@concurrentList = import('Server.IP.concurrent');
	if(!is_array(@concurrentList)) { @concurrentList = array(); }
	if(!array_index_exists(@concurrentList, @ip)) { @concurrentList[@ip] = 0; }
	@concurrentList[@ip]++;
	export('Server.IP.concurrent', @concurrentList);
}
bind('player_quit', array('id': 'ipbl.Monitor.Quit', 'priority': 'MONITOR'), null, @event) {
	@serverConfig = import('ipbl.config.Server');
	@ip = reg_replace('[%][0]$', '', pinfo(player())[3]);
	@concurrentList = import('Server.IP.concurrent');
	if(!is_array(@concurrentList)) { @concurrentList = array(); }
	if(!array_index_exists(@concurrentList, @ip)) { @concurrentList[@ip] = 1; }
	@concurrentList[@ip]--;
	if(@concurrentList[@ip] == 0) { array_remove(@concurrentList, @ip); }
	export('Server.IP.concurrent', @concurrentList);
}