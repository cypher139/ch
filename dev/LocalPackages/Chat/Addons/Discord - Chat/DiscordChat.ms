#version 1.3-tmc
#Configurable options

#Include required backend functions
#include('includes.library/chatfunctions.ms')



#todo:
#discord_set_activity(DEFAULT, 'Minecraft')
#discord_member_get_roles(member) - make name colors somewhat match discord versions
#color() Additionally, any RGB colour can be used in the hex format '#rrggbb'. 

#Send Minecraft Player message to Discord
bind('player_chat', array('id': 'Chat.Discord.msg.Send'), null, @chat) {
	@channel = 'minecraft'
	@allowedChannels = import('Chat.Discord.Channels.send')
	@sendmsg = @chat['message']
	
	# Automatically chat on last channel a message was received on.
	@lastmsg = import('Chat.Discord.last.msg.1')
	if(is_array(@lastmsg)) {
		if(array_index_exists(@lastmsg, 'channel')) {
			if(time() < (@lastmsg['time'] + 234567)) {
				@channel = @lastmsg['channel']
			}	
		}
	}
#dev tmsg(@chat['player'], reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat['message']))
	# Specify a channel name as first word in chat - Channel override
	if(reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat['message']) == 1) {
		# remove channel mention from message content	
		@sendmsg = reg_split('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1]
		# returns 'channel' in '#channel message text'
		@channel = reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1])[1]
#dev		tmsg(@chat['player'], @sendmsg.' channel name:'.@channel)
		modify_event('message', @sendmsg)
	}
	# Final Channel check: If not in allowed list, switch channel to default
	if(!array_contains(@allowedChannels, @channel)) { @channel = 'minecraft' }
	_send_discord_message(@sendmsg, player(), @channel)
}


#Send Discord User message to Minecraft Players.
bind('discord_message_received', array('id': 'Chat.Discord.msg.Receive'), null, @discord) {
	@allowedChannels = import('Chat.Discord.Channels.receive')
#	broadcast(@discord, all_players())
	#temp array setup
	/*
	@membersID = get_value('server.Discord.members.ID')
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('server.Discord.members.ID', @membersID)
	}
	*/

	if(array_contains(@allowedChannels, @discord['channel']) == true) {
		if(reg_count('^.+\\/\\/tenor\\.com\\/view', @discord['message']) > 0 && import('Chat.Discord.Broadcast.URLs') == false) {
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
		export('Chat.Discord.last.msg.3', import('Chat.Discord.last.msg.2'))
		export('Chat.Discord.last.msg.2', import('Chat.Discord.last.msg.1'))
		array_set(@discord, 'time', time())
		export('Chat.Discord.last.msg.1', @discord)
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
	#Set username color based on data previously set from Discord colors
	#keys system gives roles alphabetically, not server's order
		@usernamecolor = 3
		@rolecolors = import('Chat.Discord.Roles.colors')
		@adminroles = import('Chat.Discord.Roles.admins')
		@isAdmin = false
		foreach(@role in @userroles) {
			if(array_contains_ic(@adminroles, @role)) {
				@isAdmin = true
				break()
			}
		}
#dev		broadcast(discord_member_get_roles(@discord['username']))
		foreach(@role in @userroles) {
			if(array_contains_ic(array_keys(@rolecolors), @role)) {
				#admin colors: ensure an admin role gets picked for color
				if(@isAdmin == true && !array_contains_ic(@adminroles, @role)) {
					continue()
				}		
				@usernamecolor = '#'.@rolecolors[@role]
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
		if(array_index_exists(@discord, 'attachments', 0, 'filename') && import('Chat.Discord.Broadcast.URLs') == true) {
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
			msg(color('e').'['.color('gold').'DeathCount'.color('e').'] '.color(7).'The Reaper\'s memory loss has been cured!')
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
	@channel = 'minecraft'
	# Automatically chat on last channel a message was received on.
	@lastmsg = import('Chat.Discord.last.msg.1')
	if(is_array(@lastmsg)) {
		if(array_index_exists(@lastmsg, 'channel')) {
			if(time() < (@lastmsg['time'] + 234567)) {
				@channel = @lastmsg['channel']
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