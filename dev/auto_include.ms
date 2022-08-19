#===============================================================================
#
#   auto_incude.ms - includes for CommandHelper
#
#===============================================================================

#default samples
#Returns the distance between two blocks, or any other 3d points, for that matter
proc(_3d_distance, @arr1, @arr2,
    return(
        floor(
            sqrt(
                add(
                    pow(subtract(@arr2[0], @arr1[0]), 2),
                    pow(subtract(@arr2[1], @arr1[1]), 2),
                    pow(subtract(@arr2[2], @arr1[2]), 2)
                )
            )
        )
    )
)

#Given two blocks, iterates through all the blocks inside the cuboid, and calls the 
#user defined function on them. The used defined procedure should accept 3 parameters,
#the x, y, and z coordinates of the block.
proc(_iterate_cuboid, @b1, @b2, @proc_name,
    for(assign(@x, min(@b1[0], @b2[0])), lte(@x, max(@b1[0], @b2[0])), inc(@x),
        for(assign(@y, min(@b1[1], @b2[1])), lte(@y, max(@b1[1], @b2[1])), inc(@y),
            for(assign(@z, min(@b1[2], @b2[2])), lte(@z, max(@b1[2], @b2[2])), inc(@z),
                call_proc(@proc_name, @x, @y, @z)
            )
        )
    )
)



#---------
proc(_bc, @label, @str,
    broadcast(concat(color(yellow), '[', color(gold), @label, color(yellow), '] ', color(white), @str))
)

#is this a even number?
    proc(_is_even_number, @number, return(mod(@number, 2) == 0))


#-----------------
#misc



proc(_msgAdmins, @msg, @consolemsg, @cmconcat, @hideplayer,
	if(@consolemsg == '' || @consolemsg == null || @consolemsg == 'msg', assign(@consolemsg, @msg))
	if(@cmconcat == 'yes', assign(@consolemsg, @msg.@consolemsg))
	console(@consolemsg, false)
	foreach(all_players(), @p,
		if(has_permission(@p, 'commandhelper.alias.admin.message') && @p != @hideplayer, 
			tmsg(@p, @msg)
		)
	)
)

proc(_capitalize, @string,
	assign(@l1, to_upper(@string[0]))
	assign(@length, length(@string) - 1)
	assign(@newstring, @l1.@string[cslice(1, @length)])
	return(@newstring)
)

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

proc(_getnick, @player,
	
	assign(@player, pinfo(@player)[0])
	assign(@nick, pinfo(@player)[4])

	if(@player == @nick, return(@player), return(@nick))
)
	

proc(_rainbow, @msg, @type,
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
)


#-----

#ichat +healthbar replacement

proc(_healthbar, @player, @char,
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
)
	

#Code generation
proc(_codegen, @codelength, @codetype, @codetype2,
#How to use:
# call _codegen(NUMBER, type 1, type 2)
# The number determines how long the code is, and the 2 types determine which types of characters you want. 
# Accepted types are lower (lowercase), upper (UPPERCASE), number (numbers), & full (lower, upper, and number)

#checks
	assign(@string, array())
	if(@codelength == '', 
		assign(@codelength, 7)
	)
	if(@codetype == '', 
		assign(@codetype, full)
	)

#the characters
	assign(@lower, array(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z))
	assign(@upper, array(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z))
	assign(@number, array(1,2,3,4,5,6,7,8,9))
	assign(@full, array(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,1,2,3,4,5,6,7,8,9))

#set 1
	switch(@codetype,
	'lower',
		assign(@chars, array_get(@lower)),
	'upper',
		assign(@chars, array_get(@upper)),
	'number',
		assign(@chars, array_get(@number)),
	'full',
		assign(@chars, array_get(@full)),
	msg('Fail: Invalid code type given')
	)
#set 2	
	if(@codetype2 !== '',
		switch(@codetype2,
		'lower',
			assign(@chars2, array_get(@lower)),
		'upper',
			assign(@chars2, array_get(@upper)),
		'number',
			assign(@chars2, array_get(@number)),
		'full',
			assign(@chars2, array_get(@full)),
		die('Fail: Invalid code type given')
		)
		foreach(@chars2, @i,
			array_push(@chars, @i)
		)
	)
#generating code
	for(assign(@i, 0), @i < @codelength, @i++,
		assign(@string[@i], @chars[rand(array_size(@chars))])
	)
	assign(@string, array_implode(@string, ''))

	return(@string)
)





proc(_idcheck, @id, @id2, @option1,

	if(reg_count('('.@id.')(:[0-9]*)?', @id2) > 0,
	return(true),	
	return(false)
	)
)
	






#Death messages

#include('LocalPackages/deathmsg.ms')
