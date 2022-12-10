#===============================================================================
#
#   auto_include.ms - includes for CommandHelper
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

#include('LocalPackages/Utilities/DiscordChat.ms')


#---------
proc _bc(@label, @str) {
    broadcast(concat(color('yellow'), '[', color('gold'), @label, color('yellow'), '] ', color('white'), @str))
}


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

#Death messages
#include('LocalPackages/deathmsg.ms')