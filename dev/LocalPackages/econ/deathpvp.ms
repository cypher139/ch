bind(player_death, array(id: 'econ.death'), null, @death,
	assign(@player, _getplayerID(player()))
	assign(@dev, get_value('ch.player.'.@player[id].'.developer'))
	
	#PvP: get $100 for killing another player
	assign(@pay, 100)
	assign(@odmsplit, reg_split(' ', @death[death_message]))
	assign(@pvp, false)
	#pvp: who did it?
	foreach(@odmsplit, @word, 
		if(array_contains_ic(all_players(), @word) && nequals_ic(@player[name], @word), 
			assign(@opponent, @word) assign(@pvp, true)
		)
	)
	if(@pvp == 'true',
#		acc_subtract(@player[name], @pay)
		tmsg(@player, color(c)._getnick(@opponent).' killed you. You lost $'.@pay.'.')
#		acc_add(@opponent, @pay)
		tmsg(@opponent, color(a).'You killed '._getnick(@player[name]).' and earned $'.@pay.' from him.')
	)

	#modify vanilla death messages
#	assign(@deathmsg, _deathmsg(@player[name], @death[cause], @death[death_message]))
#	modify_event('death_message', @deathmsg)
	
)