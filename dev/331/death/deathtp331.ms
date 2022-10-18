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