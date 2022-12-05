#version 1.2-tmc
#Configurable options

#Include required backend functions
include('includes.library/chatfunctions.ms')


export('Chat.Discord.Channels.receive', array('general', 'news', 'minecraft', 'MC server', 'voice-chat', 'other', 'cross-server-chat', 'cross-server', 'mctest'))
export('Chat.Discord.Channels.send', array('general', 'minecraft', 'suggestions', 'MC server', 'voice-chat', 'other', 'botspam', 'cross-server-chat', 'cross-server', 'mctest'))
export('Chat.Discord.Roles.colors', array('DiscordPurple': '8a00ff', 'Owner': 'fbff00', 'Modding Extraordinare': 'ff0000', 'Co-Owner': '1bae93', 'Server Admin': 'ba3e39', 'Most Active': 'f1c40f', 'Active Level 3': 'f1c40f', 'Active Level 2': 'f1c40f', 'Active Level 1': 'f1c40f', 'Member': '7289da'))
export('Chat.Discord.Roles.admins', array('DiscordPurple', 'Owner', 'Modding Extraordinare', 'Co-Owner', 'Server Admin'))
export('Chat.Discord.Console.receive', false)
export('Chat.Discord.Broadcast.URLs', false)

#Prerequisites
discord_connect('discordCredentials', closure(){
	broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord');
	if(get_value('Chat.Discord.Console.receive') == true) {
		export('Chat.Discord.Console.receive', true)
		console('[Chat] Console will now receive chat Messages from Discord Users.', false)
	} else {
		export('Chat.Discord.Console.receive', false)
		console('[Chat] Console no longer receives chat Messages from Discord Users.', false)
	}
#	discord_set_activity('DEFAULT', string('Minecraft'));
})

/*
discord_connect('discordCredentials2', closure(){
	broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord #2');
#	discord_set_activity('DEFAULT', string('Minecraft'));
})
*/

#todo:
#discord_set_activity(DEFAULT, 'Minecraft')
#discord_member_get_roles(member) - make name colors somewhat match discord versions
#color() Additionally, any RGB colour can be used in the hex format '#rrggbb'. 

#Send Minecraft Player message to Discord
bind('player_chat', array(id: 'Chat.Discord.msg.Send'), null, @chat) {
	assign(@channel, 'minecraft')
	@allowedChannels = import('Chat.Discord.Channels.send')
	assign(@sendmsg, @chat['message'])
	
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
		assign(@sendmsg, reg_split('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1])
		# returns 'channel' in '#channel message text'
		assign(@channel, reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1])[1])
#dev		tmsg(@chat['player'], @sendmsg.' channel name:'.@channel)
		modify_event('message', @sendmsg)
	}
	# Final Channel check: If not in allowed list, switch channel to default
	if(!array_contains(@allowedChannels, @channel)) {assign(@channel, 'minecraft')}
	_send_discord_message(@sendmsg, player(), @channel)
}


#Send Discord User message to Minecraft Players.
bind('discord_message_received', array(id: 'Chat.Discord.msg.Receive'), null, @discord) {
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
				if(@num == 0) { @filenum = 'File: ' } else { @filenum = 'File #'.(@num + 1).': ' }
				@discord['message'] = @discord['message'].@filenum.@attach['filename'].'  '
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
		assign(@sendmsg, color(@usernamecolor).'['.@discord['username'].'] '.color(7).@discord['message'])
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


bind('player_death', array(id: 'Chat.Discord.msg.Death', priority: 'MONITOR'), null, @death) {
	
	assign(@counter, get_value('DeathCount.players.death.counter')[puuid(@death['player'], 'dashless')] + 1)

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

	if(@death['killer'] != null) {
		@weapon = pinv(@death['killer'], null)
		if(@weapon == null) { 
			@kweapon = 'Hand' 
		} else {
			@kweapon = _capitalize(string(@weapon['name']), null, null, 'all')
		}	
		@pvpmsg = array(@death['killer'].' killed '.@death['player'].' wielding '.@kweapon, 
			@death['killer'].' slays '.@death['player'].' with a '.@kweapon, 
			@death['player'].' needs more practice and was killed by '.@death['killer'], 
			@death['killer'].' hunts '.@death['player'].' down with a '.@kweapon, 
			@death['player'].' took a leap of faith but landed on '.@death['killer'].'\'s '.@kweapon, 
			'Score '.@death['killer'].' +1 - '.@death['player'].' 0', 
			@death['player'].' was fragged by '.@death['killer'], 
			@death['player'].' is now redstone thanks to '.@death['killer'].'\'s '.@kweapon, 
			@death['killer'].' slapped '.@death['player'].' around a bit too hard.'
		)
		_send_discord_message(@dc.'\n'.':put_litter_in_its_place: '.array_get_rand(@pvpmsg), 'death')
	} else {
		_send_discord_message(@dc.@death['death_message'], 'death')
	}
}
# :people_wrestling: :put_litter_in_its_place: 