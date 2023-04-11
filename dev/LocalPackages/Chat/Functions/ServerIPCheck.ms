#version 1.2-tmc
bind('player_login', array('id': 'Chat.Server.Login.Monitor', 'priority': 'HIGH'), null, @login) {	
	@serverConfig = import('Chat.config.Server')

# Should we take action on multiple accounts using the same IP address?
	if(@serverConfig['Check_Multiple_Accs_IP'] == true) {
		@ipnumbers = reg_replace('\\.*:*', '', @login['ip'])
	# How many accounts can be connected with the same IP address at any given time?
		if(@serverConfig['Concurrent_Accs_IP'] == import('Server.IP.'.@ipnumbers.'.concurrent')) {
			consume()
			modify_event('kickmsg', 'Too many Accounts are using this IP address.')
			modify_event('result', 'KICK_OTHER')
			@players = array()
			foreach(@accname in all_players()) {
				if(pinfo(@accname)[3] = @login['ip']) {
					array_push(@players, pinfo(@accname)[0])
				}
			}
			@adminPingMessage = color(6).'['.color(9).'Server'.color(6).'] '.color(7).'`'.@login['player'].'` tried to connect with IP '.@login['ip'].'; however '.@serverConfig['Concurrent_Accs_IP'].' accounts are already connected using the same IP address: '.@players
			if(@serverConfig['Ping_Message_Discord'] == true) { 
				if(is_proc('_send_discord_message')) {
					_send_discord_message(@adminPingMessage, 'none', '', 'admin')
				}
			}
			if(@serverConfig['Ping_Message_Console'] == true) { console(@adminPingMessage, false) }
			die()
		}
# If many accounts have previously connected using the same IP address, should we automatically kick joins from this IP?
		if(@serverConfig['Kick_Multiple_Accs_IP'] == true) {
			@ipdata = import('primus.database.IP')
			if(is_array(@ipdata)) {
				if(array_index_exists(@ipdata, @ipnumbers) && !array_index_exists(@serverConfig['Kick_Multiple_Accs_IP_Whitelist'], @login['ip'])) {
					if(array_size(@ipdata[@ipnumbers]) > @serverConfig['Allowed_Account_Amount']) {
						@players = array_implode(@ipdata[@ipnumbers], ', ')
						consume()
						modify_event('kickmsg', 'This server does not allow players to use multiple Alternate Accounts.')
						modify_event('result', 'KICK_OTHER')
						@adminPingMessage = color(6).'['.color(9).'Server'.color(6).'] '.color(7).'IP '.@login['ip'].' tried to connect; this server does not allow more than '.@serverConfig['Allowed_Account_Amount'].' accounts using the same IP address. (Account names: '.color(3).@players.')'
						if(@serverConfig['Ping_Message_Discord'] == true) { 
							if(is_proc('_send_discord_message')) {
								_send_discord_message(@adminPingMessage, 'none', '', 'admin')
							}
						}
						if(@serverConfig['Ping_Message_Console'] == true) { console(@adminPingMessage, false) }
					}
				}
			}
		}
	}
}