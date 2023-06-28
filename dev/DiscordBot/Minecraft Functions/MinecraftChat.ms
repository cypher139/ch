#version 1.3-tmc

#Send Minecraft Player message to Discord
bind('player_chat', array('id': 'DiscordBot.mc.Send'), null, @chat) {
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild'])
	@channel = @config['Default_Channel']
	@sendmsg = @chat['message']
	
	# Automatically chat on last channel a message was received on.
	@lastmsg = import('DiscordBot.'.@botconfig['Primary_Guild'].'.last.message')
	if(!is_array(@lastmsg)) { @lastmsg = array() }
	foreach(@message in @lastmsg) {
		if(array_index_exists(@message, 'channel')) {
			if(!array_contains(@config['Channels_Send'], @message['channel'])) { continue() }
			if(time() < (@message['time'] + 234567)) {
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
	# Final Channel check: If not in allowed list, switch channel to default
	if(!array_contains(@config['Channels_Send'], @channel)) { @channel = @config['Default_Channel'] }
	_discordBot_send_message(@sendmsg, player(), @channel, '', @botconfig['Primary_Guild'])
}

bind('player_death', array('id': 'DiscordBot.mc.Death', 'priority': 'MONITOR'), null, @death) {
	@counter = get_value('DeathCount.players.death.counter')[puuid(@death['player'], 'dashless')] + 1
	switch(@counter) {
		case '':
		case null:
			@dc = ''
			msg(color('e').'['.color(6).'DeathCount'.color('e').'] '.color(7).'The Reaper\'s memory loss has been cured!')
		case 0:
			@dc = ''
		default:
			@dc = '[#'.@counter.'] '
	}
	
	if(has_bind('Chat.msg.Death')) {
		@death['death_message'] = strip_colors(@death['death_message'])
		@death['death_message'] = reg_replace('^\\[#[0-9]+\\]\\s', '', @death['death_message'])
	}

	if(@death['killer'] != null) {
		if(has_bind('Chat.msg.Death')) {
			@pvpmsg = @death['death_message']
		} else {
			@weapon = pinv(@death['killer'], null)
			if(@weapon == null) { 
				@weapon = 'Hand' 
			} else {
				@weapon = _capitalize(string(@weapon['name']), null, null, 'all')
			}
			@pvpmsg = array(
				@death['killer'].' killed '.@death['player'].' wielding '.@weapon, 
				@death['killer'].' slays '.@death['player'].' with a '.@weapon, 
				@death['killer'].' hunts '.@death['player'].' down with a '.@weapon, 
				@death['player'].' took a leap of faith but landed on '.@death['killer'].'\'s '.@weapon, 
				'Score '.@death['killer'].' +1 - '.@death['player'].' 0', 
				@death['player'].' was fragged by '.@death['killer'], 
				@death['player'].' is now redstone thanks to '.@death['killer'].'\'s '.@weapon, 
				@death['killer'].' slapped '.@death['player'].' around a bit too hard.'
			)
			@pvpmsg = array_get_rand(@pvpmsg)
		}
		_discordBot_send_message(@dc.'\n'.':put_litter_in_its_place: '.@pvpmsg, 'death')
	} else {
		_discordBot_send_message(@dc.@death['death_message'], 'death')
	}
}
# :people_wrestling: :put_litter_in_its_place: 

bind('server_command', array('id': 'DiscordBot.mc.Send.Console', 'priority': 'MONITOR'), array('prefix': 'say', 'type': 'console'), @event) {
	if(@event['prefix'] == @event['command']) { console(color(4).'You need to actually say something with say!', false) die() }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild'])
	@sendmsg = reg_replace('^[Ss][Aa][Yy]\\s', '', @event['command'])
	@channel = @config['Default_Channel']
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
	_discordBot_send_message(@sendmsg, 'Server', @channel, '', @botconfig['Primary_Guild'])
}	