discord_connect('discordCredentials', closure(){
	broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord');
#	discord_set_activity(DEFAULT, 'Minecraft');
})

#discord_set_activity(DEFAULT, 'Minecraft')

# proc to send message to discord. player, message

proc(_send_discord_message, @message, @from, @channel,

	if(@from == '', assign(@from, player()))
	if(@channel == '', assign(@channel, 'botspam'))

	if(@from == 'none'){
		assign(@sendmsg, @message)
	} else {
		assign(@sendmsg, '['.@from.'] '.@message)
	}
	discord_broadcast(@channel, associative_array(content: @sendmsg))
)


#bind player chat, call proc
bind(player_chat, array(id: 'message.to.Discord'), null, @chat,

assign(@channel, 'botspam')
assign(@sendmsg, @chat[message])
#dev tmsg(@chat[player], reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat[message]))
#channel override
	if(reg_count('^(#+[a-zA-Z0-9-_]{1,})', @chat[message]) == 1) { 
		assign(@sendmsg, reg_split('^(#+[a-zA-Z0-9-_]{1,})', @chat[message]))
		assign(@channel, reg_split('[#]', reg_match('^(#+[a-zA-Z0-9-_]{1,})', @chat[message])[1])[1])
#dev		tmsg(@chat[player], @sendmsg.' channel name:'.@channel)
		_send_discord_message(@sendmsg[1], player(), @channel)
		modify_event('message', @sendmsg[1])
	} else {
	_send_discord_message(@chat[message], player(), @channel)
	}
)


#bind discord message, send as broadcast
bind(discord_message_received, array(id: 'message.from.Discord'), null, @discord,

	assign(@allowedChannels, array('general', 'mc server', 'other'))

	if(array_contains(@allowedChannels, @discord[channel]) == true, 
	assign(@sendmsg, '['.@discord[username].'] '.@discord[message])
		broadcast(@sendmsg, all_players())
	)
)


bind(player_quit, array(id: 'Discord.message.quit'), null, @quit,
	assign(@playerID, _getplayerID(player()))
	_send_discord_message('- part: '.@playerID[name], 'none')
)

bind(player_death, array(id: 'Discord.message.death'), null, @death,
	assign(@player, _getplayerID(player()))
	_send_discord_message(@death[death_message], 'Server')
)
	
bind(player_join, array(id: 'Discord.message.login'), null, @login,
	assign(@player, _getplayerID(player()))
	_send_discord_message('+ join: '.@player[name], 'none')
)