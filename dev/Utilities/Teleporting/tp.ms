#version 1.1-tmc
bind('player_teleport', array('id': 'TP.event'), null, @tp) {
	@uuid = puuid(player(), 'dashless')
	@lastloc = get_value('player.'.@uuid.'.last.location')
	if(!is_array(@lastloc)) { @lastloc = array(@tp['from']) }
	array_insert(@lastloc, @tp['from'], 0)
	if(array_index_exists(@lastloc, 10)) { array_remove(@lastloc, 10) }
	store_value('player.'.@uuid.'.last.location', @lastloc)
}