#version 1.3-tmc
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
# Should we take action on multiple accounts using the same IP address?
	if(@serverConfig['Check_Multiple_Accs_IP'] == true) {
	# How many accounts can be connected with the same IP address at any given time?
		if(@serverConfig['Concurrent_Accs_IP'] == import('Server.IP.'.@ipnumbers.'.concurrent')) {
			consume();
			modify_event('kickmsg', 'Too many Accounts are using this IP address.');
			modify_event('result', 'KICK_OTHER');
			@otherplayers = array()
			foreach(@accname in all_players()) {
				if(pinfo(@accname)[3] = @login['ip']) {
					array_push(@otherplayers, pinfo(@accname)[0])
				}
			}
			@players = '%f'.array_implode(@otherplayers, ', ').'%f'
			@adminPingMessage = @msgPrefix.color(7).'`'.@login['player'].'` tried to connect with IP '.@login['ip'].'; however '.@serverConfig['Concurrent_Accs_IP'].' accounts are already connected using the same IP address: '.@players
			if(@serverConfig['Ping_Message_Discord'] == true) { 
				if(is_proc('_discordBot_send_message')) { _discordBot_send_message(replace(@adminPingMessage, '%f', '`'), 'none', '', 'admin') }
			}
			if(@serverConfig['Ping_Message_Console'] == true) { console(replace(@adminPingMessage, '%f', ''), false) }
			die();
		}
	# If many accounts have previously connected using the same IP address, should we automatically kick joins from this IP?
		if(@serverConfig['Kick_Multiple_Accs_IP'] == true) {
			if(array_index_exists(@ipdata, @ipnumbers) && !array_index_exists(@serverConfig['Kick_Multiple_Accs_IP_Whitelist'], @login['ip'])) {
				if(array_size(@ipdata[@ipnumbers]) > @serverConfig['Allowed_Account_Amount']) {
					consume();
					modify_event('kickmsg', 'This server does not allow players to use multiple Alternate Accounts.');
					modify_event('result', 'KICK_OTHER');
					@adminPingMessage = @msgPrefix.color(7).'IP '.@login['ip'].' tried to connect; this server does not allow more than '.@serverConfig['Allowed_Account_Amount'].' accounts using the same IP address. '.@playersMsg
					if(@serverConfig['Ping_Message_Discord'] == true) { 
						if(is_proc('_discordBot_send_message')) { _discordBot_send_message(replace(@adminPingMessage, '%f', '`'), 'none', '', 'admin') }
					}
					if(@serverConfig['Ping_Message_Console'] == true) { console(replace(@adminPingMessage, '%f', ''), false) }
				}
			}
		}
	}
# Blacklisted IPs: Disallow Login
# Note that this does not handle 'lost connection' logins, as CH events do not fire that early in login process
	if(array_contains(@blacklistIP['IP_Blacklist'], @login['ip'])) {
		consume()
		modify_event('kickmsg', 'You have been Banned.');
		modify_event('result', 'KICK_OTHER');
		@adminPingMessage = @msgPrefix.color(7).'IP '.@login['ip'].' tried to connect using a Blacklisted IP address. '.@playersMsg
		if(@serverConfig['Ping_Message_Discord'] == true) { 
			if(is_proc('_discordBot_send_message')) { _discordBot_send_message(replace(@adminPingMessage, '%f', '`'), 'none', '', 'admin') }
		}
		if(@serverConfig['Ping_Message_Console'] == true) { console(replace(@adminPingMessage, '%f', ''), false) }
	}
	foreach(@block in @blacklistIP['IP_Block_Blacklist']) {
		@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
		if(string_starts_with(string(@login['ip']), @startBlock)) {
			consume()
			modify_event('kickmsg', 'You have been Banned.')
			modify_event('result', 'KICK_OTHER')
			@adminPingMessage = @msgPrefix.color(7).'IP '.@login['ip'].' tried to connect using an IP address that is part of a Blacklisted IP Block. '.@playersMsg
			if(@serverConfig['Ping_Message_Discord'] == true) { 
				if(is_proc('_discordBot_send_message')) { _discordBot_send_message(replace(@adminPingMessage, '%f', '`'), 'none', '', 'admin') }
			}
			if(@serverConfig['Ping_Message_Console'] == true) { console(replace(@adminPingMessage, '%f', ''), false) }
		}
	}
}