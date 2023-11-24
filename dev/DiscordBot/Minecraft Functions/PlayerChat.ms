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
	# Automatically chat on last channel a message was received on. [Primary Guild only]
	@lastmsg = import('DiscordBot.'.@botconfig['Primary_Guild'].'.last.message')
	if(!is_array(@lastmsg)) { @lastmsg = array() }
	foreach(@message in @lastmsg) {
		if(array_index_exists(@message, 'channel')) {
			if(!array_contains(@config['Channels_Send'], @message['channel'])) { continue() }
			if(time() < (@message['time'] + 234567) && has_permission(player(), 'DiscordBot.chat.channel.'.@message['channel'])) {
				@channel = @message['channel']
			}	
		}
	}
	# Specify a channel name as first word in chat - Channel override
	if(reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat['message']) == 1) {
		# remove channel mention from message content
		@sendmsg = reg_split('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1]
		# returns 'channel' in '#channel message text'
		@channel = reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1])[1]
		modify_event('message', @sendmsg)
	}

	_discordBot_send_mc_chat(@sendmsg, player(), @channel)
}

# :people_wrestling: :put_litter_in_its_place: 

bind('server_command', array('id': 'DiscordBot.mc.Send.Console', 'priority': 'MONITOR'), array('prefix': 'say', 'type': 'console'), @event) {
	if(@event['prefix'] == @event['command']) { console(color(4).'You need to actually say something with say!', false) die() }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild'])
	@sendmsg = reg_replace('^[Ss][Aa][Yy]\\s', '', @event['command'])
	@channel = @config['Minecraft_Channel']
	# Automatically chat on last channel a message was received on.
	@lastmsg = import('DiscordBot.'.@botconfig['Primary_Guild'].'.last.message')
	if(is_array(@lastmsg)) {
		if(array_index_exists(@lastmsg, 0, 'channel')) {
			if(time() < (@lastmsg[0]['time'] + 234567)) {
				@channel = @lastmsg[0]['channel']
			}	
		}
	}
	# Specify a channel name as first word in chat - Channel override
	if(reg_count('^(#+[a-zA-Z0-9-_]{1,})', @sendmsg) == 1) {
		# returns 'channel' in '#channel message text'
		@channel = reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @sendmsg)[1])[1]
		# remove channel mention from message content	
		@sendmsg = reg_split('^(#+[a-zA-Z0-9-_]{1,})', @sendmsg)[1]
	}
	_discordBot_send_mc_chat(@sendmsg, 'Server', @channel)
}	