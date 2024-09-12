# Add listed IP(s) from cypher139's Chat script's IP ping messages to Chat's IP Blacklist file, upon using the configured emoji.

bind('discord_reaction_added', array('id': 'DiscordBot.Chat.IP.React', 'priority': 'MONITOR'), null, @discord) {
	if(is_null(import('Chat.config.dir'))) { die('Chat functions are not loaded, skipping') }
	array_set(@discord, 'time', time());
	@serverConfig = import('Chat.config.Server')
	@botconfig = import('DiscordBot.config.Bot')
# IP ping logs are only sent to the Primary guild.
	if(@discord['serverid'] != @botconfig['Primary_Guild']) { die() }
	@config = import('DiscordBot.config.'.@discord['serverid'])
	if(!array_index_exists(@config, 'Special_Emoji')) { die() }
	if(@discord['messageuserid'] != @botconfig['Bot_ID']) { die() }
# Check if channel is the ping log channel or log Channel
	@logChannel = ''
	if(array_index_exists(@config, 'Ping_Log_Channel')) { @logChannel = @config['Ping_Log_Channel'] } else { @logChannel = @config['Log_Channel'] }
	if(@discord['channelid'] == @logChannel || @discord['channel'] == @logChannel) {
# Check if emoji used if the configured emoji to act upon
	@doAction = '';
		# remove encasing <>, in case it is not included in config.
		foreach(@act: @em in @config['Special_Emoji']) {
			if(reg_replace('[<>]', '', @discord['emoji']) == reg_replace('[<>]', '', @em)) { 
				@doAction = @act
				break();
			}
		}
	} else {
		die()
	}
	@cacheID = import('DiscordBot.Chat.msg.IP.Review')
	if(!is_array(@cacheID)) { @cacheID = array() }
	
#Actions
	switch(string(@doAction)) {
	case 'PingGetISP':
		if(!array_index_exists(@cacheID, 'i')) { array_set(@cacheID, 'i', array()) }
	# Check if cache reports the message was already acted upon
		if(array_contains(@cacheID['i'], @discord['messageid'])) { die('i') }
	# Action IPs
		if(array_index_exists(@cacheID, @discord['messageid'])) {
			@msgIPData = array('ISP Database Lookup Results:')
		#Get IP datas
			foreach(@ip in @cacheID[@discord['messageid']]) {
				if(@serverConfig['Ping_Message_LookupIP_DB'] == true) {
					@ipdb = _chat_lookup_ip_db(@ip)
					@listIPData = '`'.@ip.'`: '
					if(@ipdb['cn'] != '') { @listIPData = @listIPData.':flag_'.to_lower(@ipdb['cn']).':' }
					if(@ipdb['rcn'] != '') { @listIPData = @listIPData.'(reg: :flag_'.to_lower(@ipdb['rcn']).':)' }
					# if(@ipdb['c'] != '') { @listIPData = @listIPData.' '.'Country: '.@ipdb['c'] }
					if(@ipdb['asn'] != '') { @listIPData = @listIPData.' '.'ASN: '.@ipdb['asn'] }
					if(@ipdb['aso'] != '') { @listIPData = @listIPData.' '.'ISP: '.@ipdb['aso'] }
					if(@listIPData != '`'.@ip.'`: ') {
						@msgIPData[] = @listIPData
					}
				}
			}
		#Log
			@s = ''
			if(array_size(@cacheID[@discord['messageid']]) > 1) { @s = 's' }
			_db_msg_Console(color(9).@discord['username'].color(10).' requested ISP data for IP'.@s.': '.color(7).array_implode(@cacheID[@discord['messageid']], ', '), @discord['serverid'])
			@cacheID['i'][] = @discord['messageid']
			export('DiscordBot.Chat.msg.IP.Review', @cacheID)
			discord_request('PUT', 'channels/'.@discord['channelid'].'/messages/'.@discord['messageid'].'/reactions/%F0%9F%AA%AA/@me', null, closure(@ex) { @react = 1 }, closure(@ex) { console('reaction failed: \n'.@ex) });
			_discordBot_send_message(array('content': array_implode(@msgIPData, '\n'), 'reference_id': @discord['messageid']), @discord['serverid'], 'bot', @discord['channelid'])
		} else {
			_discordBot_send_message('Sorry, The message selected is no longer in my review list!', @discord['serverid'], 'bot', @discord['userid'], 'dm')
			@cacheID['i'][] = @discord['messageid']
			export('DiscordBot.Chat.msg.IP.Review', @cacheID)
		}
	case 'PingBlacklist':
		if(!array_index_exists(@cacheID, 'c')) { array_set(@cacheID, 'c', array()) }
	# Check if cache reports the message was already acted upon
		if(array_contains(@cacheID['c'], @discord['messageid'])) { die('c') }
	# Action IPs
		if(array_index_exists(@cacheID, @discord['messageid'])) {
		#Get
			@blacklistIP = import('Chat.config.IPBlacklist')
			if(!is_array(@blacklistIP)) { array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()) }
		#Add
			foreach(@ip in @cacheID[@discord['messageid']]) {
				# remove v6's end "%0", ufw doesn't support.
				@blacklistIP['IP_Blacklist'][] = reg_replace('[%][0]$', '', @ip)
			}
		#Write
			_write_file(import('Chat.config.dir').'/IPBlacklist.yml', yml_encode(@blacklistIP, true), 'OVERWRITE')
		#Log
			@s = ''
			if(array_size(@cacheID[@discord['messageid']]) > 1) { @s = 's' }
			_db_msg_Console(color(9).@discord['username'].color(10).' blacklisted IP'.@s.': '.color(7).array_implode(@cacheID[@discord['messageid']], ', '), @discord['serverid'])
			@cacheID['c'][] = @discord['messageid']
			export('DiscordBot.Chat.msg.IP.Review', @cacheID)
			discord_request('PUT', 'channels/'.@discord['channelid'].'/messages/'.@discord['messageid'].'/reactions/%E2%9C%85/@me', null, closure(@ex) { @react = 1 }, closure(@ex) { console('reaction failed: \n'.@ex) });
		# Reload file - registers for auto loading.
		# -- File loading triggers the add to blacklist block file for host system use.
			@polls = import('cypher139.poll.files')
			if(!is_array(@polls)) { @polls = array() }
			if(!array_index_exists(@polls, 'IPBlacklist')) { _register_poll_file('IPBlacklist', '_chat_load_config', import('Chat.config.dir').'/IPBlacklist.yml') }
		} else {
			_discordBot_send_message('Sorry, The message selected is no longer in my review list! You\'ll need to manually add the IP address in question to the bot\'s blacklist file.', @discord['serverid'], 'bot', @discord['userid'], 'dm')
			@cacheID['c'][] = @discord['messageid']
			export('DiscordBot.Chat.msg.IP.Review', @cacheID)
		}
	default:
		die()
	}
}