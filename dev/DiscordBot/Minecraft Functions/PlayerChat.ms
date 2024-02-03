proc _db_get_last_channel(@guild, @channel) {
	@config = import('DiscordBot.config.'.@guild)
	@cacheMsgs = import('DiscordBot.'.@guild.'.Cache.Messages')
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array('messages': array()) }
	foreach(@message in @cacheMsgs['messages']) {
		if(array_index_exists(@message, 'channel')) {
			if(!array_contains(@config['Channels_Send'], @message['channel']) && !array_contains(@config['Channels_Send'], @message['channelid'])) { continue() }
			if(time() < (@message['time'] + 234567) && has_permission(player(), 'DiscordBot.chat.channel.'.@message['channel'])) {
				@channel = @message['channel']
				break()
			}	
		}
	}
	return(@channel)
}

#Send Minecraft Player message to Discord
bind('player_chat', array('id': 'DiscordBot.mc.Send'), null, @chat) {
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild'])
	@channel = null
	@sendmsg = @chat['message']
	@playerID = _getplayerID(player(), 'id')
	#[Anti Spam] Do not send chat to Discord if player just logged on, avoids insta spam and disconnect bots.
	@jointime = import('Server.player.'.@playerID.'.last.join', 13000)
	if(@jointime > (time() - 10000)) { 
		_db_msg_Console(player().' sent a message before the message timeout passed.', 'bot') 
		die()
	}
	# Specify a channel name as first word in chat - Channel override
	if(reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat['message']) == 1) {
		# remove channel mention from message content
		@sendmsg = reg_split('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1]
		# returns 'channel' in '#channel message text'
		@channel = reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1])[1]
		modify_event('message', @sendmsg)
	} else {
	# Automatically chat on last channel a message was received on. [Primary Guild only]
		@channel = _db_get_last_channel(@botconfig['Primary_Guild'], @channel)
	}
	_discordBot_send_mc_chat(@sendmsg, player(), @channel)
}
#Send Console chat to Discord
bind('server_command', array('id': 'DiscordBot.mc.Send.Console', 'priority': 'MONITOR'), array('prefix': 'say', 'type': 'console'), @event) {
	if(@event['prefix'] == @event['command']) { console(color(4).'You need to actually say something with say!', false) die() }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild'])
	@sendmsg = reg_replace('^[Ss][Aa][Yy]\\s', '', @event['command'])
	@channel = @config['Minecraft_Channel']
	# Specify a channel name as first word in chat - Channel override
	if(reg_count('^(#+[a-zA-Z0-9-_]{1,})', @sendmsg) == 1) {
		# returns 'channel' in '#channel message text'
		@channel = reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @sendmsg)[1])[1]
		# remove channel mention from message content
		@sendmsg = reg_split('^(#+[a-zA-Z0-9-_]{1,})', @sendmsg)[1]
	} else {
	# Automatically chat on last channel a message was received on. [Primary Guild only]
		@channel = _db_get_last_channel(@botconfig['Primary_Guild'], @channel)
	}
	_discordBot_send_mc_chat(@sendmsg, 'Server', @channel)
}	