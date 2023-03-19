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
		@loadcfg = yml_decode(read(import('Chat.config.dir').'/'.@cfgtype.'.yml'))
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
	case 'Death_Messages':
		if(!is_array(@loadcfg)) { 
			_chat_msg_Admins('Death Messages List file is not properly formatted.') 
			return(false)
		}
	case 'Server':
		if(array_index_exists(@loadcfg, 'Not_Configured')) {
			_chat_msg_Admins(color(12).'[Chat - Server] Server Config file is still using the default values. Please configure it to your needs!')
			return(false)
		}
	case 'Discord':
		if(!is_proc('db_msg_Admins')) { 
			_chat_msg_Admins(color(12).'[Chat] To interact with Discord server install the DiscordBot script!')
			return(false)
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
	@colors = array(6,7,9,'a','b','c','d','e','f')
	switch(@type) {
		case 'all':
			@colors = array(0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f')
		case 'ps2':
			@colors = array(3,7,8,9,'b','d','f')
		# case 'normal':
		#Standard Rainbow chat: This will select a new random color for every letter in the message.
		# case 'doubles':
		#selects a new random color for every other character in the message.
		# case 'words':
		#selects a new random color for every word in the message.
		# default:
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
proc _healthbar(@health, string @fullchar = '|', string @emptychar = '.') {
	@mchar = ':'
	if(is_numeric(@health)) { 
		@health = ceil(@health)
	} else { 
		if(function_exists('pinfo')) {
			@health = ceil(pinfo(@health)[5])
		} else {
			return('No data given')
		}
	}
	@healthodd = ceil(@health / 2)
	@healthbar = array(0,0,0,0,0,0,0,0,0,0,0)
	#dead.
	if(@health == 0) { @color = 8 }
	#red: 1-4 hearts
	if(@health >= 1 && @health <= 8) { @color = 4 }
	#yellow: 5-7 hearts
	if(@health >= 9 && @health <= 15) { @color = 14 }
	#green: 8-10 hearts
	if(@health >= 16 && @health <= 20) { @color = 2 }
	#blue: Somehow, more than 10 hearts
	if(@health >= 21) { @color = 11 }
	#for each heart (2 phealth points):
	foreach(@k: @v in @healthbar) {
		if(@k == 0) { continue() }
		if(@k <= @healthodd) { @char = @fullchar }
		#middle char:
		# mod(@number, 2) == 0
		if(@health % 2 == 1 && @k == @healthodd) { @char = @mchar } 
		if(@k > @healthodd) { 
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

proc _chat_mc_broadcast(@msg, @args) {
	if(function_exists('broadcast')) {
		if(@args == '' || @args == null) { @args = all_players() }
		broadcast(@msg, @args)
	} else {
		console(@msg, false)
	}
}

proc _chat_death_msg_format(@player, @msg, @opponent, @weapon) {
	if(@player == '' || @player == null) { return(color('d').'FAIL (no player?)') }
	if(@msg == '' || @msg == null) { return(color('d').'FAIL (what death?)') }
#Death message colors.
	#Color of victim's name.
	@colorplayer = '&7'
	#Color of message.
	@colormsg = '&c'
	#Color of alternate item, such as the person/entity who killed the victim.
	@coloralt = '&9'
	#Color of weapon used in a PvP battle
	@colorweapon = '&3'	
#Format %Variables% found in message
	@return = reg_replace('\\%dm_weapon\\%', @weapon, @msg)
	@return = reg_replace('\\%dm_opponent\\%', @opponent, @return)
	@return = reg_replace('\\%dm_player\\%', @player, @return)
	@return = reg_replace('\\%dm_color_alt\\%', @coloralt, @return)
	@return = reg_replace('\\%dm_color_msg\\%', @colormsg, @return)
	@return = reg_replace('\\%dm_color_player\\%', @colorplayer, @return)
	@return = reg_replace('\\%dm_color_weapon\\%', @colorweapon, @return)

	return(@return)
}


	#todo: pvp type: return random action on damager (name provided as message)
	
	#pvp idea, some hit (weighted random) does a random action, liek even teleporting to a makeshift airborne arena
	# make healthbar appears to each involved player?
	
	
proc _wish_finder(@type, @message, @player, @option1) {
	@name = 'Wish'
	try(@dev = import('ch.player.'.puuid(@player, 'dashless').'.dev.scripts.wish'),@fail, @dev = false)
	@primaryword = import('wish.words.primary', 'wish')
	@secondaryword = import('wish.words.secondary', 'i')
	if(@option1 == '') { @usesecondaryword = true } else { @usesecondaryword = false } 
	
	if(@message == '' || @message  == null) { return(array('wish': 'fail', 'message': 'Message Not Given')) }
	if(@type == '' || @type  == null) { return(array('wish': 'fail', 'message': 'Type Not Given')) }
	if(@player == '' || @player == null) { return(array('wish': 'fail', 'message': 'Player Not Given')) } else {
#Load Last Chat	
		switch(@type) {
		case 'chat':
		case 'game':
		case 'minecraft':
			try( 
				@player = player(@player)
			,@fail,
				return(array('wish': 'fail', 'message': 'Player Name Not Found'))
			)
			@lastchatter = import('wish.last.player.chat')
		case 'discord':
			@lastchatter = import('Chat.Discord.last.message')
		}
	}
	if(!is_array(@lastchatter)) { @lastchatter = array(array('player': '~default1', 'message': '0')) }
	
	@messagewords = reg_split(' ', @message)
	@iswish = false
	@target = false
	@ifound = false
	#Detect First Trigger Word. if not found in message, ignore event.
	#accounts for out-of-order trigger words, i.e. i <bad word> wish or i <arguments>, that is my wish
	if(array_contains_ic(@messagewords, @primaryword)) {
		@ifound = true
		if(@usesecondaryword == false) { @iswish = true }
	}
	#Detect Second Trigger Word. if not found in message, ignore event.
	if(@ifound == true && array_contains_ic(@messagewords, @secondaryword) && @usesecondaryword == true) {
		@iswish = true
	}
	if(@iswish == false) { return(array('wish': false, 'message': 'Not a Wish')) }


	if(@dev == true) { msg(color(7).'[DEV] msg: '.color('f').@messagewords) }


	@registeredactions = array('kick', 'die', 'kill', 'dead', 'off', 'dust', 'death', 'fly', 'flew', 'google', 'googling', 'explode', 'explosion', 'friend', 'friends', 'artist', 'poop')
	@action == ''
	@otherplayer = ''
	foreach(@word in @messagewords) {
	#Find Other Player Name
		if(array_contains_ic(all_players(), @word)) { @otherplayer = player(@word) }
	#Find if a Supported action was mentioned
		if(array_contains_ic(@registeredactions, @word)) { @action = to_lower(@word) }
#		if(@dev == true) { msg(color(7).'[DEV] gameplay: '.color('r').'Word #'.@key.': "'.@word.'"') }
	}
	if(@action == '') { return(array('wish': false, 'message': 'registered action not found')) }


# Find target player to perform action on:
	foreach(@key: @word in @messagewords) {
	# If another player was specified in the message, override checks and use that.
		if(@otherplayer != '') {
			@target = @otherplayer
			@targettype = 3
			break()
		}
	#You were Referring to a recent player
		if(reg_count('^[YyFfUuIi][^\\W][OoUuDd]*[UuIi]*[Oo]*[CcTt]*[YySs]*$', @word) > 0) {
		#yo, you, fu, idiot/s/cy. no y or i or f.
		switch(@type) {
		case 'chat':
		case 'game':
			#Checking recent chat for last player name who chatted
			foreach(@v in @lastchatter) {
				if(@v['player'] != @player) {
					if(!ponline(@v['player'])) { continue() }
					@target = @v['player']
					@targettype = 1
				}
			}	
			# If the player was were hit by a player in the last minute, use that player as target.
			@pvpr = import('Wish.player.'.puuid(@player, 'dashless').'recent.PvP.damage', array('damager': @player, 'time': 123456789))
			if(time() < @pvpr['time'] + 45000) {
				@target = @pvpr['damager']
				@targettype = 2
			}
			# No match, redirect to yourself.
			if(@target == false) {
				@target = @player
				@targettype = 0
				if(@dev == true) { msg(color(7).'[DEV] player: '.color('f').'No other players online, or no players matching that name! Using @player') }
			}
			break(2)
		case 'discord':
		#check recent discord chat for match username
		#check if is mc or discord username
		export('test', 'test')
		}
		}
	# Referring to yourself
		if(reg_count('^[IiMm]+[eE]*$', @word) > 0) {
		#i, me
			if(@dev == true) { msg(color(7).'[DEV] player: '.color('f').'It\'s all on you man.') }
			@target = @player
			@targettype = 0
		}
	}	
		
if(@dev == true) {
	msg(color(7).'[DEV] last chat: '.color('r').@lastchatter[0]['player'].':  '.@lastchatter[0]['message'])
	msg(color(7).'[DEV] gameplay: '.color(3).array('wish': @iswish, 'target': @target, 'targettype': @targettype, 'action': @action))
}
return(array('wish': @iswish, 'target': @target, 'action': @action, 'message': 'Success'))
}



proc _wish_granter(@action, @target, @player, @option1) {
	@name = 'Wish'
	@prefix = color('e').'['.color(6).@name.color('e').'] '.color(6)
	@dev = import('ch.player.'.puuid(@player, 'dashless').'.dev.scripts.wish')
	if(@action == '' || @action  == null) { return(array('success': 'fail', 'message': 'Action Not Given')) }
	if(@target == '' || @target == null) { 
		@target = player()
	} else {
		try( 
			@target = player(@target)
		,@fail,
			return(array('success': 'fail', 'message': 'target Name Not Found'))
		)
	}

	@returnmsg = @prefix.color(6).@player.'s wish was refused.'
	switch(to_lower(@action)) {
	# Only one action is performed per proc call
		case 'kick':
			if(@target == player()) { @kickmsg = @prefix.@player.'s wish has been granted' } else { @kickmsg = @prefix.'Your wish has been granted.' }
			pkick(@target, @kickmsg)
		case 'die':
		case 'kill':
		case 'dead':
		case 'dust':
		case 'death':
			@returnmsg = @prefix.color(6).@player.'\'s wish has been granted.'
			set_timeout(1000, closure(pkill(@target)))
		case 'fly':
		case 'flew':
		case 'off':
			@returnmsg = @prefix.color(6).@player.'s wish has been granted.'
			runas('~console', /rocket @target)
		case 'google':
		case 'googling':
			@returnmsg = @prefix.color(6).@player.'s wish has been granted.'
			@gkey = ''
			foreach(@key: @word in @messagewords) {
				if(@word == 'google',
					@gkey = @key
					#Break, in case the search query contains "google", in which case we need the first instance of "google" here.
					break()
				)
			}
			msg('g'.@gkey)
			msg(array_size(@messagewords))
			@skey1 = @gkey + 1
			@skey2 = array_size(@messagewords) - 1
			@skey3 = @messagewords[cslice(@gkey + 1, array_size(@messagewords) - 1)]
			msg(@skey3)
			@googlemsg = array_implode(@skey3, '+')
			@returnmsg = @prefix.color(6).'Googling: '.color(3).array_implode(@skey3)
#not working, keeps 403ing/TOS
#				http_request('https://cse.google.com/cse?cx=partner-pub-9300639326172081%3Aqi7dvj9mh31&ie=UTF-8&num=5&output=xml_no_dtd&safe=high&q='.@googlemsg, closure(@response){
#				      console(@response['body']);
#				});
		case 'explode':
		case 'explosion':
			@returnmsg = @prefix.color(6).@player.'s wish has been granted.'
			@ploc = ploc(@target)
			@ploc[1] = @ploc[1] + 1
			@ploc['y'] = @ploc['y'] + 1
			explosion(@ploc, 4, false)
		case 'friend':
		case 'friends':
			@returnmsg = @prefix.color(6).@player.'s wish has been granted.'
			@ploc = ploc(@target)
			spawn_entity('CREEPER', 2, @ploc)
		case 'artist':
			@returnmsg = @prefix.color(6).@player.'s wish has been granted.'
			@ploc = ploc(@target)
			@ploc[1] = @ploc[1] + 1
			@ploc['y'] = @ploc['y'] + 1
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'black')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'red')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'green')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'brown')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'blue')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'purple')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'cyan')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'light_gray')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'gray')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'pink')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'lime')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'yellow')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'light_blue')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'magenta')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'orange')); })
			spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'white')); })
		case 'poop':
			drop_item(@target, array('name': 'DIRT', 'qty': 3, 'meta': null), true)
			@returnmsg = @prefix.color(6).@player.'s wish has been granted.'
#No Action Found
		default:
			return(array('success': false, 'message': 'Action Not Found'))
	}
	play_sound(puuid(@player), array('sound': 'ENTITY_EXPERIENCE_ORB_PICKUP', 'volume': '16'))
	play_sound(puuid(@target), array('sound': 'ENTITY_EXPERIENCE_ORB_PICKUP', 'volume': '16'))
	return(array('success': true, 'message': @returnmsg))
}




####
# Load configs
_chat_load_config('Server');