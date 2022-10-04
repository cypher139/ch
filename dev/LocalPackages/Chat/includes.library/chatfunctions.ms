#is this a even number?
    proc(_is_even_number, @number, return(mod(@number, 2) == 0))


proc _chat_getplayerID(@option1) {
	@pid = array()
	if(@option1 == '~console'){
		@pid = array(display: 'Console', name: '~console', id: 'console', nick: 'Server Console')
	} else {
	@pid['display'] = pinfo(@option1)[0];
	@pid['name'] = pinfo(@option1)[0];
	@pid['id'] = puuid(@option1, dashless);
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

proc _capitalize(@string) {
	assign(@l1, to_upper(@string[0]))
	assign(@length, length(@string) - 1)
	assign(@newstring, @l1.@string[cslice(1, @length)])
	return(@newstring)
}

#supposed to work but doesnt:
#proc(_capitalize, @string,
#	assign(@l1, to_upper(@string[0]))
#	assign(@newstring, @l1.@string[1..])
#	return(@newstring)
#)

proc(_getplayer, @name,
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
)

proc _getnick(@player) {
	
	assign(@player, pinfo(@player)[0])
	assign(@nick, pinfo(@player)[4])

	if(@player == @nick, return(@player), return(@nick))
}
	

proc _rainbow(@msg, @type) {
#fabulous light colors: 6abcdef
	if(@msg == '', return(color(c).'You didn\'t say anything!!'))
	assign(@msg, strip_colors(@msg))
	if(@type == '' || @type == null,
		assign(@type, 'normal')
	)
#Standard Rainbow chat: This will select a new random color for every letter in the message.
	if(@type == 'normal',
		assign(@string, '')
		for(assign(@i, 0), @i < length(@msg), @i++,
			assign(@string, @string.'\u00a7'.array(6,7,9,a,b,c,d,e,f)[rand(9)].substr(@msg, @i, @i + 1))
		)
		return(@string)
	)

#This selects a new random color for every other character in the message.
	if(@type == 'doubles',
		assign(@string, '')
		for(assign(@i, 0), @i < length(@msg), @i++,
			if(_is_even_number(@i) == true,
				assign(@color, array(6,7,9,a,b,c,d,e,f)[rand(9)])
			)
			assign(@string, @string.color(@color).substr(@msg, @i, @i + 1))
		)
		return(@string)
	)


#This uses all the minecraft colors, not just specific colors.
	if(@type == 'all',
		assign(@string, '')
		for(assign(@i, 0), @i < length(@msg), @i++,
			assign(@string, @string.'\u00a7'.array(0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f)[rand(16)].substr(@msg, @i, @i + 1))
		)
		return(@string)
	)
}


#-----

#ichat +healthbar replacement

proc _healthbar(@player, @char) {
	if(@char == '' || @char == null, assign(@char, '|'))
	assign(@phealth, pinfo(@player)[5])
	assign(@1, 0)
	@color = array()
	for(assign(@i, 0), @i < 20, @i++,
		@color[@i] = 2
		#dead.
		if(@phealth == 0,
			assign(@color[@i], 8)
		) 
		#red: 1-4 hearts
		if(gte(@phealth, 1) && lte(@phealth, 8),
			assign(@color[@i], 4)
		) 
		#yellow: 5-7 hearts
		if(gte(@phealth, 9) && lte(@phealth, 15),
			assign(@color[@i], e)
		) 
		#green: 8-10 hearts
		if(gte(@phealth, 16) && lte(@phealth, 20),
			assign(@color[@i], 2)
		) 
		#missing health
		if(gte(@i, @phealth),
			assign(@color[@i], 8)
		)
	)

	assign(@healthbar, color(@color[0]).@char.color(@color[2]).@char.color(@color[4]).@char.color(@color[6]).@char.color(@color[8]).@char.color(@color[10]).@char.color(@color[12]).@char.color(@color[14]).@char.color(@color[16]).@char.color(@color[18]).@char)


	return(@healthbar)
}