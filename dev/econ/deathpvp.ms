bind('player_death', array('id': 'econ.death'), null, @death) {
	@player = _getplayerID(player())
	@dev = get_value('ch.player.'.@player['id'].'.developer')
	
	#PvP: get $100 for killing another player
	@pay = 100

	if(@death['killer'] != null) {
		if(function_exists('acc_subtract')) {
			acc_subtract(@player['id'], @pay)
			tmsg(@player['id'], color('c')._getplayerID(@death['killer'])['nick'].' killed you. You lost $'.@pay.'.')
			acc_add(@death['killer'], @pay)
			tmsg(@death['killer'], color('a').'You killed '.@player['nick'].' and earned $'.@pay.' from him.')
		}
	}	
}