#Console Deaths = amount of times server started / alias reloads
store_value('DeathCount.console.death.counter', get_value('DeathCount.console.death.counter')++)

#Player Deaths: save various infos.
bind('player_death', array('id': 'DeathTP.event', 'priority': 'MONITOR'), null, @death) {
	x_new_thread('DeathStats.'.@death['player'], closure(@player = @death['player'], @drops = @death['drops']){
		@uuid = puuid(@player, 'dashless')
		@dev = import('ch.player.'.@uuid.'.developer')
		@mode = string(pmode(@player))[0]
	# Save death point for /back [per mode]
		@here = ploc(@player)
		@pdloc = get_value('player.'.@uuid.'.last.death.location')
		if(!is_array(@pdloc)) { @pdloc = array() }
		if(!array_index_exists(@pdloc, @mode)) { array_set(@pdloc, @mode, array(@here)) }
		array_insert(@pdloc[@mode], @here, 0)
		if(array_index_exists(@pdloc, @mode, 10)) { array_remove(@pdloc[@mode], 10) }
		store_value('player.'.@uuid.'.last.death.location', @pdloc)
		tmsg(@player, color(7).'Use the '.color(12).'/back'.color(7).' command to return to your death point.')
		
	# Save inventory [per mode]
		@pddrops = get_value('player.'.@uuid.'.last.death.drops')
		if(!is_array(@pddrops)) { @pddrops = array() }
		if(!array_index_exists(@pddrops, @mode)) { array_set(@pddrops, @mode, array(@drops)) }
		array_insert(@pddrops[@mode], @drops, 0)
		if(array_index_exists(@pddrops, @mode, 10)) { array_remove(@pddrops[@mode], 10) }
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