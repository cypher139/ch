#version 1.2-tmc
bind('player_death', array(id: 'DeathTP.event'), null, @death) {
	x_new_thread('DeathStats.'@death['player'], closure(@player = @death['player'], @drops = @death['drops']){
		assign(@uuid, puuid(@player, 'dashless'))
		assign(@dev, import('ch.player.'.@uuid.'.developer'))
		#save death point for /back
		assign(@here, ploc(@player))
		assign(@oloc1, get_value('player.'.@uuid.'.last.death.loc.1'))
		assign(@oloc2, get_value('player.'.@uuid.'.last.death.loc.2'))
		store_value('player.'.@uuid.'.last.death.loc.1', @here)
		store_value('player.'.@uuid.'.last.death.loc.2', @oloc1)
		store_value('player.'.@uuid.'.last.death.loc.3', @oloc2)
		tmsg(@player, color(7).'Use the '.color('c').'/back'.color(7).' command to return to your death point.')
		
		#save inventory
		assign(@odrops1, get_value('player.'.@uuid.'.last.death.drops.1'))
		assign(@odrops2, get_value('player.'.@uuid.'.last.death.drops.2'))
		store_value('player.'.@uuid.'.last.death.drops.1', @drops)
		store_value('player.'.@uuid.'.last.death.drops.2', @odrops1)
		store_value('player.'.@uuid.'.last.death.drops.3', @odrops2)
		
		#save number of times died
		store_value('player.'.@uuid.'.death.counter', get_value('player.'.@uuid.'.death.counter') + 1)
	});
}