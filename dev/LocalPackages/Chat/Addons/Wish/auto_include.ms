#version 1.9-tmc

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