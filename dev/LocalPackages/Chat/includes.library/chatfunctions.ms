proc _chat_is_even_number(@number) { return(mod(@number, 2) == 0) }

proc _chat_getplayerID(@option1) {
	@pid = array()
	if(@option1 == '~console'){
		@pid = array(display: 'Console', name: '~console', id: 'console', nick: 'Server Console')
	} else {
	@pid['display'] = pinfo(@option1)[0];
	@pid['name'] = pinfo(@option1)[0];
	@pid['id'] = puuid(@option1, 'dashless');
	@pid['nick'] = pinfo(@option1)[4];
	}
	#Bedrock to Java players come in with name ".NAME", remove dot
	if(reg_count('^[\\.].*', @pid['name']) == 1, 
		assign(@pid['display'], reg_replace('^[\\.]','', @pid['name']))
	)
	return(@pid)
}

proc _msgAdmins(@msg, @consolemsg, @cmconcat, @hideplayer) {
	if(@consolemsg == '' || @consolemsg == null || @consolemsg == 'msg', assign(@consolemsg, @msg))
	if(@cmconcat == 'yes', assign(@consolemsg, @msg.@consolemsg))
	console(@consolemsg, false)
	foreach(all_players(), @p,
		if(has_permission(@p, 'commandhelper.alias.admin.message') && @p != @hideplayer, 
			tmsg(@p, @msg)
		)
	)
}

/*
proc _capitalize(@string) {
	assign(@l1, to_upper(@string[0]))
	assign(@length, length(@string) - 1)
	assign(@newstring, @l1.@string[cslice(1, @length)])
	return(@newstring)
}

*/
#supposed to work but doesnt:
#proc(_capitalize, @string,
#	assign(@l1, to_upper(@string[0]))
#	assign(@newstring, @l1.@string[1..])
#	return(@newstring)
#)

proc _getplayer(@name) {
	assign(@chars, length(@name))
#returns the real player's name
	assign(@isfound, false)
	foreach(all_players(), @player,
		#if(@chars < length(@player),
			if(equals_ic(@name, substr(@player, 0, @chars)),
				assign(@isfound, true)
				broadcast(1)
			)
		#)
		if(pinfo(@player)[4] != @player,
			assign(@nick, pinfo(@player)[4])
			if(equals_ic(@nick, substr(@name, 0, @chars)),
				assign(@isfound, true)
				assign(@return, @player) 
				broadcast(2)	
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
	
	assign(@player, pinfo(@player)[0])
	assign(@nick, pinfo(@player)[4])

	if(@player == @nick, return(@player), return(@nick))
}
	

proc _rainbow(@msg, @type, @returntype) {
	if(@msg == '') { return(color('c').'You didn\'t say anything!!') }
	assign(@msg, strip_colors(@msg))
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
#			assign(@string, @string.'\u0026'.array(6,7,9,a,b,c,d,e,f)[rand(9)].substr(@msg, @i, @i + 1))

#ichat +healthbar replacement
proc _healthbar(@player, @fchar, @echar) {
	if(@fchar == '' || @fchar == null) { @fullchar = '|' } else { @fullchar = @fchar }
	if(@echar == '' || @echar == null) { @emptychar = '.' } else { @emptychar = @echar }
	@mchar = ':'
	if(is_numeric(@player)) { @phealth = @player } else { @phealth = ceil(pinfo(@player)[5]) }
	@phealthodd = ceil(@phealth / 2)
	@healthbar = array(0,0,0,0,0,0,0,0,0,0,0)
	#dead.
	if(@phealth == 0) { @color = 8 }
	#red: 1-4 hearts
	if(@phealth >= 1 && @phealth <= 8) { @color = 4 }
	#yellow: 5-7 hearts
	if(@phealth >= 9 && @phealth <= 15) { @color = 'e' }
	#green: 8-10 hearts
	if(@phealth >= 16 && @phealth <= 20) { @color = 2 }
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
#msg(@healthbar)
	return(array_implode(@healthbar, ''))
}

proc _send_discord_message(@message, @from, @channel, @option) {

	if(@from == '', assign(@from, player()))
	if(@channel == '', assign(@channel, 'minecraft'))
	
	@message = strip_colors(@message)

	switch(to_lower(@from)) {
	case 'none':
		assign(@sendmsg, @message)
	case 'server':
		assign(@sendmsg, '['.@from.'] '.@message)
	case 'death':
		assign(@sendmsg, ':skull_crossbones: '.@message)
		
	case 'command':
		assign(@sendmsg, ':desktop: '.@message)
	default:
		assign(@sendmsg, '`['.@from.']` '.@message)
	}
	if(function_exists('discord_broadcast')) {
		try(
			discord_broadcast(@channel, associative_array('content': @sendmsg))
		,@fail,
#			msg(@fail)
			_msgAdmins(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'A message queued to Discord was not sent: '.@fail['message'])
		)
	}
}