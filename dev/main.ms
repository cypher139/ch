######################################################
#
#   Main.ms file. This file is run when the server
#   starts up, or the plugin is reloaded. It can be used
#   as an opportunity to register events or do other things
#   when the server initially starts.
#
######################################################

#/mode proc

proc(_set_S, @player, @msg, @name,
    set_pmode(@player, 'SURVIVAL')	
    if(@msg == 'yes',
	if(@name == '', assign(@name, gameMode))
	tmsg(@player, concat(color(yellow), '[', color(gold), @name, color(yellow), '] ', color(white), 'Changed to ', color(c), 'Survival', color(white), ' gamemode'))
	)
)

proc(_set_C, @player, @msg, @name, 
    set_pmode(@player, 'CREATIVE')
    if(@msg == 'yes',
	if(@name == '', assign(@name, gameMode))
	tmsg(@player, concat(color(yellow), '[', color(gold), @name, color(yellow), '] ', color(white), 'Changed to ', color(b), 'Creative', color(white), ' gamemode'))
	)
)

bind(plugin_message_received, array(id: 'new.test'), null, @event,
	console(@event)
)

#binds
#-------
bind(player_join, array(id: 'login'), null, @login,
	#event playername may return null for some unknown reason
	assign(@player, player())

#Get player group
	assign(@group, pgroup(@player)[0])
	store_value(@player.'.group', @group)

#Are you a dev? Lets export the dev value!!!!!
	assign(@dev, get_value('ch.player.'.@player.'.developer'))
	export('ch.player.'.@player.'.developer', @dev)

#Console info
 	set_timeout(2000,closure(console(color(3).player().color(r).' connected with'.color(7).' IP: '.color(a).pinfo(player())[3].color(7).' hostname: '.pinfo(player())[10], false)))

#Rei's minimap: Enable radar for everything, and cavemapping.
#	msg(color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color(e).color(f))
	modify_event('join_message', color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color(e).color(f).color(a).'+ join'.color(7).': '.@player)

)

#-----

bind(player_death, array(id: 'death'), null, @death,
	assign(@player, player())
	assign(@dev, get_value(@player.'.script.developer'))
	#save death point for /back
	assign(@here, ploc(@player))
	store_value(@player.'.deathpoint', @here)
	tmsg(@player, color(7).'Use the \'/back\' command to return to your death point.')
	
	#PvP: get $100 for killing another player
	assign(@pay, 100)
	assign(@odmsplit, reg_split(' ', @death[death_message]))
	assign(@pvp, false)
	#pvp: who did it?
	foreach(@odmsplit, @word, 
		if(array_contains_ic(all_players(), @word) && nequals_ic(@player, @word), 
			assign(@opponent, @word) assign(@pvp, true)
		)
	)
	if(@pvp == 'true',
#		acc_subtract(@player, @pay)
		tmsg(@player, color(c)._getnick(@opponent).' killed you. You lost $'.@pay.'.')
#		acc_add(@opponent, @pay)
		tmsg(@opponent, color(a).'You killed '._getnick(@player).' and earned $'.@pay.' from him.')
	)

	#modify vanilla death messages
#	assign(@deathmsg, _deathmsg(@player, @death[cause], @death[death_message]))
#	modify_event('death_message', @deathmsg)
	
	#save inventory
	#if(@dev == 'yes', msg(@death[drops]))
	store_value(@player.'.last.death.drops', @death[drops])

)


#ploc returns new world position, so not going to work
#bind(world_changed, array(id: 'world'), null, @world,
#        assign(@player, player())
#        if(@world[to] == @world[from]) { return() }
#
#        if(@world[to] == 'adventure',
#                assign(@sp, get_value(@player.'.adventure.savepoint'))
#                if(@sp == null || @sp == '', die())
#                set_timeout(5000, closure(
#					set_ploc(@player, @sp)
#				))
#				msg(color(7).'Returning to your previous savepoint in 5 seconds.')
#       )
#        if(@world[from] == 'adventure',
#				assign(@ploc, ploc(@player))
#                store_value(@player.'.adventure.savepoint', @ploc)
#                msg(@ploc)
#        )
#)


bind(player_quit, array(id: 'quit'), null, @quit,
	assign(@player, player())
	modify_event('message', color(c).'- part'.color(7).': '.@player)	
)


bind(player_interact, array(id: 'cake'), array(block:92), @cake,
  	if(@cake['action'] == 'right_click_block' || @cake['action'] == 'left_click_block',
		assign(@here, ploc(@cake[player])) 
        	lightning(@here)
#		explosion(@here)
		pkill(@cake[player])
		msg(color(c).'The cake is a LIE!!')
	)
#msg(@cake)
cancel()
)

bind(server_ping, array(id: 'ping'), null, @ping,
	console(color(6).'['.color(9).'Notification'.color(6).'] '.color(7).'Received ping from '.@ping[ip], false)
	modify_event('motd', _rainbow(@ping[motd], doubles))
)

#-----

#---
