#version 1.3-tmc

#Console Deaths = amount of times server started / alias reloads
store_value('DeathCount.console.death.counter', get_value('DeathCount.console.death.counter')++)

#Player Deaths
bind('player_death', array('id': 'DeathTP.event', 'priority': 'MONITOR'), null, @death) {
	x_new_thread('DeathStats.'.@death['player'], closure(@player = @death['player'], @drops = @death['drops']){
		@uuid = puuid(@player, 'dashless')
		@dev = import('ch.player.'.@uuid.'.developer')
		
	# Save death point for /back
		@here = ploc(@player)
		@pdloc = get_value('player.'.@uuid.'.last.death.location')
		if(!is_array(@pdloc)) { @pdloc = array(@here) }
		array_insert(@pdloc, @here, 0)
		if(array_index_exists(@pdloc, 10)) { array_remove(@pdloc, 10) }
		store_value('player.'.@uuid.'.last.death.location', @pdloc)
		tmsg(@player, color(7).'Use the '.color('c').'/back'.color(7).' command to return to your death point.')
		
	# Save inventory
		@pddrops = get_value('player.'.@uuid.'.last.death.drops')
		if(!is_array(@pddrops)) { @pddrops = array(@drops) }
		array_insert(@pddrops, @drops, 0)
		if(array_index_exists(@pddrops, 10)) { array_remove(@pddrops, 10) }
		store_value('player.'.@uuid.'.last.death.drops', @pddrops)
		
	# Save number of times died
		@dc = get_value('DeathCount.players.death.counter')
		if(!is_array(@dc)) { @dc = array() }
		if(array_index_exists(@dc, @uuid)) {
			@dc[@uuid] = @dc[@uuid] + 1
		} else {
			#if array key not set, @array[key] does not work
			array_set(@dc, @uuid, 1)
		}
		store_value('DeathCount.players.death.counter', @dc)
	});
}