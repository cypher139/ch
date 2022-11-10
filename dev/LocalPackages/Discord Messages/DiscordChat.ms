#version 1.2-tmc
#Configurable options

export('Chat.Discord.Channels.receive', array('general', 'minecraft', 'MC server', 'voice-chat', 'other'))
export('Chat.Discord.Channels.send', array('general', 'minecraft', 'MC server', 'voice-chat', 'other', 'botspam'))
export('Chat.Discord.Roles.colors', array('DiscordPurple': '8a00ff', 'Owner': 'fbff00', 'Modding Extraordinare': 'ff0000', 'Co-Owner': '1bae93', 'Server Admin': 'ba3e39', 'Most Active': 'f1c40f', 'Active Level 3': 'f1c40f', 'Active Level 2': 'f1c40f', 'Active Level 1': 'f1c40f', 'Member': '7289da'))
export('Chat.Discord.Roles.admins', array('DiscordPurple', 'Owner', 'Modding Extraordinare', 'Co-Owner', 'Server Admin'))
export('Chat.Discord.Console.receive', false)

#Prerequisites
discord_connect('discordCredentials', closure(){
	broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord');
#	discord_set_activity(DEFAULT, 'Minecraft');
})


#todo:
#discord_set_activity(DEFAULT, 'Minecraft')
#discord_member_get_roles(member) - make name colors somewhat match discord versions
#color() Additionally, any RGB colour can be used in the hex format '#rrggbb'. 

# proc to send message to discord. player, message

proc _send_discord_message(@message, @from, @channel) {

	if(@from == '', assign(@from, player()))
	if(@channel == '', assign(@channel, 'minecraft'))
	
	@message = strip_colors(@message)

	switch(@from) {
	case 'none':
		assign(@sendmsg, @message)
	case 'server':
		assign(@sendmsg, '['.@from.'] '.@message)
	case 'death':
		assign(@sendmsg, ':skull_crossbones: '.@message)
	default:
		assign(@sendmsg, '`['.@from.']` '.@message)
	}
	discord_broadcast(@channel, associative_array(content: @sendmsg))
}


#bind player chat, call proc
bind('player_chat', array(id: 'message.to.Discord'), null, @chat) {
	assign(@channel, 'minecraft')
	@allowedChannels = import('Chat.Discord.Channels.send')
# Automatically chat on last channel a message was received on.
	@lastmsg1 = import('Chat.Discord.last.msg.1')
	if(is_array(@lastmsg1)) {
		if(array_index_exists(@lastmsg1, 'channel')) {
			@channel = @lastmsg1['channel']
		}	
	}
	if(!array_contains(@allowedChannels, @channel)) {assign(@channel, 'minecraft')}

	assign(@sendmsg, @chat['message'])
#dev tmsg(@chat['player'], reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat['message']))
#channel override
	if(reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat['message']) == 1) {
	#remove channel mention from message content	
		assign(@sendmsg, reg_split('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1])
	#returns 'channel' in '#channel message text'
		assign(@channel, reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @chat['message'])[1])[1])
#dev		tmsg(@chat['player'], @sendmsg.' channel name:'.@channel)
		modify_event('message', @sendmsg)
	}
# Final Channel check: If not in allowed list, switch channel to default
	if(!array_contains(@allowedChannels, @channel)) {assign(@channel, 'minecraft')}
	_send_discord_message(@sendmsg, player(), @channel)
}


#bind discord message, send as broadcast
bind('discord_message_received', array(id: 'message.from.Discord'), null, @discord) {

	@allowedChannels = import('Chat.Discord.Channels.receive')

	if(array_contains(@allowedChannels, @discord['channel']) == true) {
		export('Chat.Discord.last.msg.3', import('Chat.Discord.last.msg.2'))
		export('Chat.Discord.last.msg.2', import('Chat.Discord.last.msg.1'))
		export('Chat.Discord.last.msg.1', @discord)
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
	#Set username color based on data previously set from Discord colors
	#keys system gives roles alphabetically, not server's order
		@usernamecolor = 3
		@rolecolors = import('Chat.Discord.Roles.colors')
		@adminroles = import('Chat.Discord.Roles.admins')
		foreach(@role in @adminroles) {
			if(array_contains_ic(@adminroles, @role)) {
				@isAdmin = true
			}
		}
#dev		broadcast(discord_member_get_roles(@discord['username']))
		foreach(@role in @userroles) {
		#admin colors
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
	}
}


bind('player_quit', array(id: 'Discord.message.quit'), null, @quit) {
	assign(@playerID, _getplayerID(player()))
	_send_discord_message('- part: '.@playerID['name'], 'none')
}

bind('player_death', array(id: 'Discord.message.death'), null, @death) {
	_send_discord_message(@death['death_message'], 'death')
}
	
bind('player_join', array(id: 'Discord.message.login'), null, @login) {
	assign(@playerID, _getplayerID(player()))
	_send_discord_message('+ join: '.@playerID['name'], 'none')
}