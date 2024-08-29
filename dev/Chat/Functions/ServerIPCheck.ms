bind('player_login', array('id': 'Chat.Server.Login.Monitor', 'priority': 'HIGH'), null, @login) {	
	@serverConfig = import('Chat.config.Server')
	@blacklistIP = import('Chat.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
	@ipdata = import('primus.database.IP');
	@ipnumbers = reg_replace('\\.*:*', '', @login['ip']);
	if(!is_array(@ipdata)) { @ipdata = array() }
	@players = ''
	@playersMsg = ''
	@msgPrefix = color(6).'['.color(9).'Server'.color(6).'] '
	if(array_index_exists(@ipdata, @ipnumbers)) {
		@players = array_implode(@ipdata[@ipnumbers], ', ')
		@playersMsg = '(Account names: %f'.color(3).@players.'%f)'
	}
	@kickMsg = ''
	@kickPlayer = false
	@adminMsg = @msgPrefix.'Message Not Given'
	@kickType = '0'
# Should we take action on multiple accounts using the same IP address?
	if(@serverConfig['Check_Multiple_Accs_IP'] == true) {
	# How many accounts can be connected with the same IP address at any given time?
		@concurrentList = import('Server.IP.concurrent')
		if(!is_array(@concurrentList)) { @concurrentList = array() }
		if(!array_index_exists(@concurrentList, @ipnumbers)) { array_set(@concurrentList, @ipnumbers, 0) }
		if(@serverConfig['Concurrent_Accs_IP'] == @concurrentList[@ipnumbers]) {
			@kickPlayer = true
			@kickMsg = 'Too many Accounts are using this IP address.'
			@kickType = @kickType.'1'
			@otherplayers = array()
			foreach(@accname in all_players()) {
				if(pinfo(@accname)[3] = @login['ip']) {
					@otherplayers[] = pinfo(@accname)[0]
				}
			}
			@players = '%f'.array_implode(@otherplayers, ', ').'%f'
			@adminMsg = color(7).'%f'.@login['player'].'%f tried to connect with IP %f'.color(9).@login['ip'].color(7).'%f; however '.@serverConfig['Concurrent_Accs_IP'].' accounts are already connected using the same IP address: '.@players
		}
	# If many accounts have previously connected using the same IP address, should we automatically kick joins from this IP?
		if(@serverConfig['Kick_Multiple_Accs_IP'] == true) {
			if(array_index_exists(@ipdata, @ipnumbers) && !array_index_exists(@serverConfig['Kick_Multiple_Accs_IP_Whitelist'], @login['ip'])) {
				if(array_size(@ipdata[@ipnumbers]) > @serverConfig['Allowed_Account_Amount']) {
					@kickPlayer = true
					@kickMsg = 'This server does not allow players to use multiple Alternate Accounts.'
					@kickType = @kickType.'2'
					@adminMsg = color(7).'%f'.@login['player'].'%f tried to connect; this server does not allow more than '.@serverConfig['Allowed_Account_Amount'].' accounts using the same IP address. (IP: %f'.color(9).@login['ip'].'%f) '.color(7).@playersMsg
				}
			}
		}
	}
# Blacklisted IPs: Disallow Login
# Note that this does not handle 'lost connection' logins, as CH events do not fire that early in login process
	if(array_contains(@blacklistIP['IP_Blacklist'], @login['ip'])) {
		@kickPlayer = true
		@kickMsg = 'You have been Banned.'
		@kickType = @kickType.'3'
		@adminMsg = color(7).@login['player'].' tried to connect using '.color(12).'Blacklisted IP address:  '.color(9).@login['ip'].' '.color(7).@playersMsg
	}
	foreach(@block in @blacklistIP['IP_Block_Blacklist']) {
		@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
		if(string_starts_with(string(@login['ip']), @startBlock)) {
			@kickPlayer = true
			@kickMsg = 'You have been Banned.'
			@kickType = @kickType.'4'
			@adminMsg = color(7).@login['player'].' tried to connect using IP address '.color(9).@login['ip'].color(7).' that is part of a '.color(12).'Blacklisted IP Block. '.color(7).@playersMsg
		}
	}
#Handle Player Kick and Admin messages
	if(@kickPlayer == true) {
		consume();
		modify_event('kickmsg', @kickMsg);
		modify_event('result', 'KICK_OTHER');
		if(is_proc('_primus_database_add')) { _primus_database_add(@login['player'], 'ip', @login['ip'], @login['hostname']) }
		if(@serverConfig['Ping_Message_Discord'] == true) { 
			if(is_proc('_discordBot_send_message')) { _discordBot_send_message(@msgPrefix.'['.@kickType.'] '.replace(@adminMsg, '%f', '`'), 'bot', 'admin') }
		}
		if(@serverConfig['Ping_Message_Console'] == true) { console(@msgPrefix.'['.@kickType.'] '.replace(@adminMsg, '%f', ''), false) }
	}	
}