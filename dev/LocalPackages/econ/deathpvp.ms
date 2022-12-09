bind('player_death', array('id': 'econ.death'), null, @death) {
	@player = _getplayerID(player())
	@dev = get_value('ch.player.'.@player['id'].'.developer')
	
	#PvP: get $100 for killing another player
	@pay = 100

	if(@death['killer'] != null) {
		if(function_exists('acc_subtract')) {
			acc_subtract(@player['name'], @pay)
			tmsg(@player, color('c')._getplayerID(@death['killer'])['nick'].' killed you. You lost $'.@pay.'.')
			acc_add(@death['killer'], @pay)
			tmsg(@opponent, color('a').'You killed '.@player['nick'].' and earned $'.@pay.' from him.')
		}
	}	
	#modify vanilla death messages
#	@deathmsg = _deathmsg(@player[name], @death[cause], @death[death_message])
#	modify_event('death_message', @deathmsg)
}