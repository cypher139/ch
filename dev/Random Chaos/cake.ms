#version 1.1-tmc
bind('player_interact', array(id: 'cake', priority: 'HIGH'), array(block: 'CAKE'), @cake) {
  	if(@cake['action'] == 'right_click_block' || @cake['action'] == 'left_click_block') {
		export('player.'.puuid(@cake['player'], 'dashless').'.death.cake', true)
		assign(@here, ploc(@cake['player'])) 
		lightning(@here)
#		explosion(@here)
#Any setup for player_death event must be done before this point!
		set_phealth(@cake['player'], 0)
#		msg(color('7').'The cake is a '.color('red').'LIE!!')
		cancel()
	}
}

bind('player_death', array(id: 'cake.message', priority: 'HIGH'), null, @death) {
	if(import('player.'.puuid(@death['player'], 'dashless').'.death.cake') == true) {
		modify_event('death_message', color(8).@death['player'].color(7).' just learned that the cake is a '.color('red').'lie!!')
		export('player.'.puuid(@death['player'], 'dashless').'.death.cake', false)
		consume()
	}
}
