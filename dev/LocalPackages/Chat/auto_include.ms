### Core Startup
export('chatmodifier.name', 'Chat')
if(in_cmdline_mode() == true) {
	export('chatmodifier.version', '1.0-tmc-cmd')
	export('Chat.config.dir', file_resolve(pwd().'/Configs'))
	export('Chat.logs.dir', file_resolve(pwd().'/Logs'))
} else {
	export('chatmodifier.version', '1.0-tmc')
	export('Chat.config.dir', file_resolve(sys_properties()['user.dir'].'/plugins/CommandHelper/LocalPackages/'.import('chatmodifier.name').'/Configs'))
	export('Chat.logs.dir', file_resolve(sys_properties()['user.dir'].'/plugins/CommandHelper/LocalPackages/'.import('chatmodifier.name').'/Logs'))
}

### Functions

proc _chat_is_even_number(@number) { return(mod(@number, 2) == 0) }

proc _chat_msg_Admins(@msg, @consolemsg, @cmconcat, @hideplayer) {
	if(@consolemsg == '' || @consolemsg == null || @consolemsg == 'msg') { @consolemsg = @msg }
	if(@cmconcat != '') { @consolemsg = @msg.@consolemsg }
	console(@consolemsg, false)
	#Broadcast to MC server, if available
	if(function_exists('all_players')) {
		foreach(@p in all_players()) {
			if(has_permission(@p, 'commandhelper.alias.admin.message') && @p != @hideplayer) { tmsg(@p, @msg) }
		}
	}
}

proc _is_Command(@line) {
	return(string_starts_with(@line, '~'));
}

proc _chat_load_config(@cfgtype) { 
	if(@cfgtype == '' || @cfgtype == null) { @cfgtype = 'Server' }
	@loadcfg = ''
	try {
		@loadcfg = yml_decode(read(import('Chat.config.dir').'/'.@cfgtype.'_config.yml'))
	} catch(IOException @ex) {
		_chat_msg_Admins(color(12).'[Chat] '.@cfgtype.' Config file could not be read. ', @ex['message'], true)
		return(false)
	} catch(FormatException @ex) {
		_chat_msg_Admins(color(12).'[Chat] '.@cfgtype.' Config file is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']), true) 
		return(false)
	} catch(Exception @ex) {
		_chat_msg_Admins(color(12).'[Chat] There was an error with the '.@cfgtype.' Config file. ', @ex['message'], true) 
		return(false)
	}
#Checks:
	switch(string(@cfgtype)) {
	case 'Server':
		if(array_index_exists(@loadcfg, 'Not_Configured')) {
			_chat_msg_Admins(color(12).'[Chat - Server] Server Config file is still using the default values. Please configure it to your needs!')
			return(false)
		}
	case 'Discord':
		if(!function_exists('discord_connect')) { 
			console('CHDiscord extension not installed!')
			return(false)
		}
		if(array_contains(@loadcfg['Channels_Receive'], 'default')) {
			_chat_msg_Admins(color(12).'[Chat - Discord] Config file is still using default values. Please configure it in order to use various Discord features.') 
			return(false)
		}
		if(@loadcfg['VC_Role_ID'] == 123) {
			_chat_msg_Admins(color(14).'[Chat - Discord] Voice Chat Config is still using defaults. Please configure it in order to use the VC Role Ping feature.') 
		}
		if(@loadcfg['Welcome_Text_Channel_Name'] == 'default') {
			_chat_msg_Admins(color(14).'[Chat - Discord] Member Config is still using defaults. Please configure it in order to use the Welcome Message feature.') 
		}
	case 'Experimental':
	case 'ex':
		@servercfg = import('Chat.config.Server')
		@loadcfg = array_merge(@loadcfg, @servercfg)
		if(array_contains(@loadcfg['CS_Server_1_Channels'], 'default')) {
			_chat_msg_Admins(color(14).'[Chat - Discord] Cross server Config is still using default values. Please configure it in order to use Cross-Server chat features.') 
		}
	}
	export('Chat.config.'.@cfgtype, @loadcfg)
	return(@loadcfg)
}

/*
proc _getplayer(@name) {
	@chars = length(@name)
#returns the real player's name
	@isfound = false
	foreach(all_players(), @player,
		#if(@chars < length(@player),
			if(equals_ic(@name, substr(@player, 0, @chars)),
				@isfound = true
				# broadcast(1)
			)
		#)
		if(pinfo(@player)[4] != @player,
			@nick = pinfo(@player)[4]
			if(equals_ic(@nick, substr(@name, 0, @chars)),
				@isfound = true
				@return = @player 
				# broadcast(2)	
			)
		)
		if(@isfound == true,
			return(@player)
		,
			if(ponline(@name) == false, return(null))
			return(pinfo(@name)[0])
		)
	)
}

proc _getnick(@player) {
	
	@player = pinfo(@player)[0]
	@nick = pinfo(@player)[4]

	if(@player == @nick, return(@player), return(@nick))
}
*/	

proc _rainbow(@msg, @type, @returntype) {
	if(@msg == '') { return(color('c').'You didn\'t say anything!!') }
	@msg = strip_colors(@msg)
	switch(@type) {
		case 'all':
			@colors = array(0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f')
		case 'ps2':
			@colors = array(3,7,8,9,'b','d','f')
		case 'normal':
		#Standard Rainbow chat: This will select a new random color for every letter in the message.
		case 'doubles':
		#selects a new random color for every other character in the message.
		case 'words':
		#selects a new random color for every word in the message.
		default:
		#fabulous light colors: 6abcdef
			@colors = array(6,7,9,'a','b','c','d','e','f')
	}
	@i = 0
	@string = ''
	#words: color first word.
	@color = array_get_rand(@colors)
	foreach(@k: @char in @msg) {
#	msg('k:'.@k)
	#words: need to change color on whitespace only, everyone else continue() if punctuation / spaces, as don't need to colorize those.
		if(@type == 'words') { 
			@regc = '\\S'
			#set initial color, since foreach only starts at first whitespace.
			if(@k == 0) { 
				if(@returntype == '' || @returntype == null) {	
					@string = color(@color)
				} else {
					@string = '\u0026'.@color
				}
			}
		} else { 
			@regc = '\\W'
		}
		#Not an approved color change character, save and continue
		if(reg_count(@regc, @char) > 0) {
			@string = @string.@char
			continue()
		}

		if(@type == 'doubles') {
			if(_is_even_number(@i) == true) { @color = array_get_rand(@colors) }
		} else {
			@color = array_get_rand(@colors)
		}
		#chat() crashes client if color() is used, with "illegal characters in chat', switch to unicode char
		if(@returntype == '' || @returntype == null) {		
			@colortype = color(@color)
		} else {
			@colortype = '\u0026'.@color
		}
#		msg('"'.@char.'" :'.@i.'    c: <'.@color.'>')
		@string = @string.@colortype.@char
		#counter for actual characters encountered, for doubles
		@i++
	}
	return(@string)
}

#fabulous light colors: 6abcdef
#			@string, @string.'\u0026'.array(6,7,9,a,b,c,d,e,f)[rand(9)].substr(@msg, @i = @i + 1)

#ichat +healthbar replacement
proc _healthbar(@player, @fchar, @echar) {
	if(@fchar == '' || @fchar == null) { @fullchar = '|' } else { @fullchar = @fchar }
	if(@echar == '' || @echar == null) { @emptychar = '.' } else { @emptychar = @echar }
	@mchar = ':'
	if(is_numeric(@player)) { 
		@phealth = ceil(@player)
	} else { 
		if(function_exists('pinfo')) {
			@phealth = ceil(pinfo(@player)[5])
		} else {
			return('No data given')
		}
	}
	@phealthodd = ceil(@phealth / 2)
	@healthbar = array(0,0,0,0,0,0,0,0,0,0,0)
	#dead.
	if(@phealth == 0) { @color = 8 }
	#red: 1-4 hearts
	if(@phealth >= 1 && @phealth <= 8) { @color = 4 }
	#yellow: 5-7 hearts
	if(@phealth >= 9 && @phealth <= 15) { @color = 14 }
	#green: 8-10 hearts
	if(@phealth >= 16 && @phealth <= 20) { @color = 2 }
	#blue: Somehow, more than 10 hearts
	if(@phealth >= 21) { @color = 11 }
	#for each heart (2 phealth points):
	foreach(@k: @v in @healthbar) {
		if(@k == 0) { continue() }
		if(@k <= @phealthodd) { @char = @fullchar }
		#middle char:
		if(_is_even_number(@phealth) == false && @k == @phealthodd) { @char = @mchar } 
		if(@k > @phealthodd) { 
			@color = 0 
			@char = @emptychar
		}
		@healthbar[@k] = color(@color).@char
	}
	array_remove(@healthbar, 0)
	return(array_implode(@healthbar, ''))
}

proc _message_check_ban_mentions(@message, @from, @option) {
	@config = import('Chat.config.Server')
# Check if player said banned Discord mention
	@msga = parse_args(@message)
	@msgban = ''
	if(in_cmdline_mode() == false) { @from = _getplayerID(@from) }
	@prefix = color(6).'['.color(9).'Server'.color(6).'] '
	foreach(@entry in @config['Banned_Mentions']) {
		if(_array_string_contains(@msga, @entry)) {
			if(function_exists('player')) {
				@prevmentions = get_value('server.player.'.@from['id'].'all.ping.mention')
				store_value('server.player.'.@from['id'].'.all.ping.mention', @prevmentions + 1)
				if(array_contains(get_offline_players(), @from['name'])) { 
					if(@config['Message_On_Mention'] == true) { tmsg(@from['name'], color('c').'[Chat] Do not mention "'.@entry.'".') }
					if(@config['Kick_On_Mention'] == true) { 
						pkick(@from['name'], '[Chat] Do not mention "'.@entry.'".')
						@msgbantype = 'kicked'
						if(@prevmentions > @config['Ban_On_Mention_Number'] && @config['Ban_On_Repeat_Mention'] == true) {
							set_pbanned(@from['name'], true, '[Chat] You have used disallowed mentions several times.')
							@msgbantype = 'banned'
						}
						@msgban = '  Offending player `'.@player.'` was '.@msgbantype.'.'
					}
				}
				_chat_msg_Admins(@prefix.color(7).'Message from '.@from['display'].' contained a mention of "'.@entry.'".'.@msgban)
			} else {
				if(@config['Message_On_Mention'] == true) { 
					try {
						discord_private_message(@from, '[Chat] Do not mention "'.@entry.'".')
					} catch(Exception @ex) {
						console(@prefix.'Could not DM user: '. @ex, false)
					}
				}
				_chat_msg_Admins(@prefix.color(7).'Message from '.@from.' contained a mention of "'.@entry.'".')
			}		
			return(array('mention': @entry, 'kickmsg': @msgban))
		}
	}
return(null)
}

# new error message: :dp: +

proc _send_discord_message(@message, @from, @channel, @type, @option) {
	if(!function_exists('discord_broadcast') || !function_exists('discord_private_message')) { return(false) }
	@config = import('Chat.config.Discord')
	@normalmessage = 0
	if(@message == '') { return(false) }
	if(@from == '' || is_array(@from)) { 
		if(function_exists('player')) { 
			@from = player()
		} else {
			@from = 'none'
		}
	}	
	if(@channel == '') { @channel = @config['Default_Channel'] }
	if(@type == '') { @type = 'broadcast' }
	if(is_array(@message)) {
		if(array_index_exists(@message, 'content')) {
			@message['content'] = strip_colors(@message['content'])
			@count = reg_count('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @message['content'])
		}
	} else {
		@message = strip_colors(@message)
		@count = reg_count('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @message)
	
	}
	@split = array()
	@checkmention = null
	@sendmsg = ''
	# Check if player said banned mention
	if(is_array(@message)) {
	console('msg: array')
		if(array_index_exists(@message, 'content')) {
			console('msg: content')
			@checkmention = _message_check_ban_mentions(@message['content'], @from)
			@sendmsg = @message['content']
		} else if(array_index_exists(@message, 'embeds')) {
			console('msg: embed only')
				@sendmsg == ''
		} else {
			console('msg: unsupported array')
			@type = 'admin'
			@sendmsg = 'A message queued to Discord was not sent: Array Content or Embeds was not given.'
		}
	} else { 
		@checkmention = _message_check_ban_mentions(@message, @from)
		@sendmsg = @message
	}
	if(@checkmention != null && @type != 'admin') {
		@type = 'admin'
		@sendmsg = 'A message queued to Discord was not sent: Message contained a mention of "`'.@checkmention['mention'].'`". '.@checkmention['kickmsg']
	}
	
	switch(to_lower(@from)) {
	case 'admin':
	case 'log':
		@channel = @config['Log_Channel']
	case 'none':
	case 'cross':
	case 'discord':
		@normalmessage = 1
	case 'server':
	case 'console':
		@sendmsg = '['.@from.'] '.@sendmsg
	case 'death':
		@sendmsg = ':skull_crossbones: '.@sendmsg
	case 'command':
		@sendmsg = ':desktop: '.@sendmsg
	case 'confirm':
		@sendmsg = ':white_check_mark: '.@sendmsg
	default:
	# Minecraft Player chat
		@sendmsg = '`['.@from.']` '.@sendmsg
	}
# Split messages longer than 2000 chars
	if(reg_count('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @sendmsg) > 1 && !is_array(@message)) {
		for(@i = 1, @i <= @count, @i++) {
			@match = reg_match('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @sendmsg)[0]
			array_push(@split, @match)
			@sendmsg = @sendmsg[cslice(length(@match), (length(@sendmsg) - 1))]
		}
	}
	
	switch(@type){
	case 'admin':
	case 'log':
		@channel = @config['Log_Channel']
		# console('[Chat - Discord] '.@sendmsg, false)
	}
	
	try {	
		switch(@type){
		case 'admin':
		case 'broadcast':
		case 'b':
		case 'log':
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) { 
					if(@i == (array_size(@split) - 1)) {
						if(is_array(@message)) {
							if(array_index_exists(@message, 'embeds')) {
								@msg = array('content': @msg, 'embeds': @message['embeds'])
							}
						}
					}						
					discord_broadcast(@channel, @msg)
				}
			} else {
				if(is_array(@message)) {
					if(array_index_exists(@message, 'embeds')) {
						if(@sendmsg == '') {
							@sendmsg = array('embeds': @message['embeds'])
						} else {
							@sendmsg = array('content': @sendmsg, 'embeds': @message['embeds'])
						}
					}
				}
				discord_broadcast(@channel, @sendmsg)
			}
			return(true)
		case 'pm':
		case 'dm':
		case 'message':
		case 'private':
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) { 
					if(@i == (array_size(@split) - 1)) {
						if(is_array(@message)) {
							if(array_index_exists(@message, 'embeds')) {
								@msg = array('content': @msg, 'embeds': @message['embeds'])
							}
						}
					}						
					discord_private_message(@channel, @msg)
				}
			} else {
				if(is_array(@message)) {
					if(array_index_exists(@message, 'embeds')) {
						if(@sendmsg == '') {
							@sendmsg = array('embeds': @message['embeds'])
						} else {
							@sendmsg = array('content': @sendmsg, 'embeds': @message['embeds'])
						}
					}
				}
				discord_private_message(@channel, @sendmsg)
			}
			return(true)
		case 'broadcast_embed':
		case 'embed':
			if(@option == '') { @option = 'the cool bot' }
			@sayicons = array('https://cdn.discordapp.com/emojis/511919341093257266.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919341118160912.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919341281738773.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919340740673536.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919340837404672.webp?size=48&quality=lossless') 
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) { 
					@option = @option.' (Message '.(@i + 1).' of '.array_size(@split).')'
					discord_broadcast(@channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @msg, 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': @option)))))
				}
			} else {
				discord_broadcast(@channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @sendmsg))))
			}
			return(true)	
		case 'join':
			discord_broadcast(@channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': '<:join:1066426544387543080> Joined:', 'description': @sendmsg))))
			return(true)
		case 'leave':
		case 'quit':
			discord_broadcast(@channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': ' <:leave:1066426677481197618> Left: ', 'description': @sendmsg))))
			return(true)
		}
	} catch(Exception @ex) {
	#			msg(@ex)
		_chat_msg_Admins(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'A message queued to Discord was not sent: '.@ex['message'])
		return(false)
	}
	
}

proc _chat_dc_add_member(@discord) {
	@membersID = import('server.Discord.members.ID', get_value('server.Discord.members.ID'))
	if(!is_array(@membersID)) { @membersID = array() }
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('server.Discord.members.ID', @membersID)
		export('server.Discord.members.ID', @membersID)
	}
	@membersnames = import('server.Discord.members.names', get_value('server.Discord.members.names'))
	if(!is_array(@membersnames)) { @membersnames = array() }
	if(!array_contains(@membersnames, @discord['userid'])) {
		array_set(@membersnames, @discord['username'], @discord['userid'])
		store_value('server.Discord.members.names', @membersnames)
		export('server.Discord.members.names', @membersnames)
	}
}

proc _chat_mc_broadcast(@msg, @args) {
	if(function_exists('broadcast')) {
		if(@args == '' || @args == null) { @args = all_players() }
		broadcast(@msg, @args)
	} else {
		# console('Bot Service is not running on a Minecraft server! Broadcast messages will be redirected to the console.', false)
		console(@msg, false)
	}
}