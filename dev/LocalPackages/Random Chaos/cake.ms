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