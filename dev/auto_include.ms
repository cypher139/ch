#===============================================================================
#
#   auto_incude.ms - includes for CommandHelper
#
#===============================================================================

#default samples
#Returns the distance between two blocks, or any other 3d points, for that matter
proc _3d_distance(@arr1, @arr2) {
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
}

#Given two blocks, iterates through all the blocks inside the cuboid, and calls the 
#user defined function on them. The used defined procedure should accept 3 parameters,
#the x, y, and z coordinates of the block.
proc _iterate_cuboid(@b1, @b2, @proc_name) {
    for(assign(@x, min(@b1[0], @b2[0])), lte(@x, max(@b1[0], @b2[0])), inc(@x),
        for(assign(@y, min(@b1[1], @b2[1])), lte(@y, max(@b1[1], @b2[1])), inc(@y),
            for(assign(@z, min(@b1[2], @b2[2])), lte(@z, max(@b1[2], @b2[2])), inc(@z),
                call_proc(@proc_name, @x, @y, @z)
            )
        )
    )
}

include('LocalPackages/Utilities/getplayerID.ms')
#include('LocalPackages/Utilities/DiscordChat.ms')


#---------
proc _bc(@label, @str) {
    broadcast(concat(color('yellow'), '[', color('gold'), @label, color('yellow'), '] ', color('white'), @str))
}

#is this a even number?
    proc _is_even_number(@number) {return(mod(@number, 2) == 0)}


#-----------------
#misc



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
#                message pass:disable pass:disable _ to ' '
proc _capitalize(@string, @lower, @u) {
	if(@lower == '' || @lower == null) { @string = to_lower(@string) }
	assign(@l1, to_upper(@string[0]))
	assign(@length, length(@string) - 1)
	assign(@newstring, @l1.@string[cslice(1, @length)])
	if(@u == '' || @u == null) {
		if(reg_count('[_]', @newstring) > 0) {
			@newstring = reg_replace('_', ' ', @newstring)
		}
	}
	return(@newstring)
}

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

proc _rainbow(@msg, @type) {
#fabulous light colors: 6abcdef
	if(@msg == '', return(color('c').'You didn\'t say anything!!'))
	assign(@msg, strip_colors(@msg))
	if(@type == '' || @type == null,
		assign(@type, 'normal')
	)
#Standard Rainbow chat: This will select a new random color for every letter in the message.
	if(@type == 'normal',
		assign(@string, '')
		for(assign(@i, 0), @i < length(@msg), @i++,
			assign(@string, @string.'\u00a7'.array(6,7,9,'a','b','c','d','e','f')[rand(9)].substr(@msg, @i, @i + 1))
		)
		return(@string)
	)

#This selects a new random color for every other character in the message.
	if(@type == 'doubles',
		assign(@string, '')
		for(assign(@i, 0), @i < length(@msg), @i++,
			if(_is_even_number(@i) == true,
				assign(@color, array(6,7,9,'a','b','c','d','e','f')[rand(9)])
			)
			assign(@string, @string.color(@color).substr(@msg, @i, @i + 1))
		)
		return(@string)
	)


#This uses all the minecraft colors, not just specific colors.
	if(@type == 'all',
		assign(@string, '')
		for(assign(@i, 0), @i < length(@msg), @i++,
			assign(@string, @string.'\u00a7'.array(0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f')[rand(16)].substr(@msg, @i, @i + 1))
		)
		return(@string)
	)
}


#-----



#Death messages
#include('LocalPackages/deathmsg.ms')