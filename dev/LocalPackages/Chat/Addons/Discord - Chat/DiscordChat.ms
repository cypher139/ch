#version 1.3-tmc

#Send Minecraft Player message to Discord
bind('player_chat', array('id': 'Chat.Discord.msg.Send'), null, @chat) {
	@config = import('Chat.config.Discord')
	@channel = @config['Default_Channel']
	@sendmsg = @chat['message']
	
	# Automatically chat on last channel a message was received on.
	@lastmsg = import('Chat.Discord.last.message')
	if(is_array(@lastmsg)) {
		if(array_index_exists(@lastmsg, 0, 'channel')) {
			if(time() < (@lastmsg[0]['time'] + 234567)) {
				@channel = @lastmsg[0]['channel']
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
	_send_discord_message(@sendmsg, player(), @channel)
}


#Send Discord User message to Minecraft Players.
bind('discord_message_received', array('id': 'Chat.Discord.msg.Receive'), null, @discord) {
	@config = import('Chat.config.Discord')
	#Setup list of server members
	@membersID = get_value('server.Discord.members.ID')
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('server.Discord.members.ID', @membersID)
	}

	if(array_contains(@config['Channels_Receive'], @discord['channel']) == true) {
		array_set(@discord, 'time', time())
	#Message Formatting
		if(reg_count('^.+\\/\\/tenor\\.com\\/view', @discord['message']) > 0 && @config['URL_Broadcast'] == false) {
			@discord['message'] = '<Sent a GIF>'
		}
		if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
			if(@discord['message'] == '') {			
				@discord['message'] = '<Sent a file> '
			} else {
				@discord['message'] = @discord['message'].'\n <Also attached file:> '
			}
			foreach(@num: @attach in @discord['attachments']) {
				if(@num == 0) { @filenum = 'File: ' } else { @filenum = '  File #'.(@num + 1).': ' }
				@discord['message'] = @discord['message'].@filenum.@attach['filename']
			}
		}
	#Save Recent Messages for reference	
		@lastmsgs = import('Chat.Discord.last.message')
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		array_insert(@lastmsgs, @discord, 0)
		if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
		export('Chat.Discord.last.message', @lastmsgs)
		
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
	#Set username color based on data previously set from Discord colors
	#keys system gives roles alphabetically, not server's order
		@usernamecolor = 3
		@isAdmin = false
		foreach(@role in @userroles) {
			if(array_contains_ic(@config['Role_Admins'], @role)) {
				@isAdmin = true
				break()
			}
		}
#dev		broadcast(discord_member_get_roles(@discord['username']))
		foreach(@role in @userroles) {
			if(array_contains_ic(array_keys(@config['Role_Colors']), @role)) {
				#admin colors: ensure an admin role gets picked for color
				if(@isAdmin == true && !array_contains_ic(@config['Role_Admins'], @role)) {
					continue()
				}		
				@usernamecolor = '#'.@config['Role_Colors'][@role]
#dev				broadcast(@role, all_players())
				#Only go with first role found
				break()
			}
		}
	#Send			
		@sendmsg = color(@usernamecolor).'['.@discord['username'].'] '.color(7).@discord['message']
		broadcast(@sendmsg, all_players())
		if(import('Chat.Discord.Console.receive') == true) {
			console(@sendmsg, false)
		}
		if(array_index_exists(@discord, 'attachments', 0, 'filename') && @config['URL_Broadcast'] == true) {
			foreach(@num: @attach in @discord['attachments']) {
				broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], all_players())
			}
		}
	}
}


bind('player_death', array('id': 'Chat.Discord.msg.Death', 'priority': 'MONITOR'), null, @death) {
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
		_send_discord_message(@dc.'\n'.':put_litter_in_its_place: '.@pvpmsg, 'death')
	} else {
		_send_discord_message(@dc.@death['death_message'], 'death')
	}
}
# :people_wrestling: :put_litter_in_its_place: 

bind('server_command', array('id': 'Chat.Discord.msg.Send.Console', 'priority': 'MONITOR'), array('prefix': 'say', 'type': 'console'), @event) {
	if(@event['prefix'] == @event['command']) { console(color(4).'You need to actually say something with say!', false) die() }
	@sendmsg = reg_replace('^[Ss][Aa][Yy]\\s', '', @event['command'])
	@channel = import('Chat.config.Discord')['Default_Channel']
	# Automatically chat on last channel a message was received on.
	@lastmsg = import('Chat.Discord.last.message')
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
	_send_discord_message(@sendmsg, 'Server', @channel)
}	