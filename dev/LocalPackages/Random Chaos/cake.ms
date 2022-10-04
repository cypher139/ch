#version 1.0-tmc
bind('player_interact', array(id: 'cake'), array(block: 'CAKE'), @cake) {
  	if(@cake['action'] == 'right_click_block' || @cake['action'] == 'left_click_block') {
		assign(@here, ploc(@cake['player'])) 
		lightning(@here)
#		explosion(@here)
		pkill(@cake['player'])
		msg(color('7').'The cake is a '.color('red').'LIE!!')
	}
#msg(@cake)
cancel()
}