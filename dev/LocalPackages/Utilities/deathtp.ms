#version 1.1-tmc
bind('player_death', array(id: 'DeathTP.event'), null, @death) {
	assign(@player, _getplayerID(player()))
	assign(@dev, get_value('ch.player.'.@player[id].'.developer'))
	#save death point for /back
	assign(@here, ploc(@player[name]))
	store_value('player.'.@player[id].'.last.death.loc', @here)
	tmsg(@player[name], color(7).'Use the \'/back\' command to return to your death point.')
	
	#save inventory
	if(@dev == true) {msg(@death[drops])}
	store_value('player.'.@player[id].'.last.death.drops', @death[drops])

}