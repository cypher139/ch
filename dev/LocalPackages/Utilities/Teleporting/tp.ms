#version 1.1-tmc
bind('player_teleport', array(id: 'TP.event'), null, @tp) {
	assign(@oloc1, get_value('player.'.puuid(player(), 'dashless').'.last.loc.1'))
	store_value('player.'.puuid(player(), 'dashless').'.last.loc.1', @tp['from'])
	store_value('player.'.puuid(player(), 'dashless').'.last.loc.2', @oloc1)
}
