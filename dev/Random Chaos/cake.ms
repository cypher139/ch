#version 1.2-tmc
bind('player_interact', array('id': 'cake', 'priority': 'HIGH'), array('block': 'CAKE'), @cake) {
  	if(@cake['action'] == 'right_click_block' || @cake['action'] == 'left_click_block') {
		@here = ploc(@cake['player']) 
		if(has_permission(@cake['player'], 'commandhelper.alias.cake.use')) {
		# Can use, heals player.	
			set_phealth(@cake['player'], 20)
			set_phunger(@cake['player'], 20)
			set_ponfire(@cake['player'], 0)
			set_peffect(@cake['player'], 'POISON', 1, 0)
			set_peffect(@cake['player'], 'WATER_BREATHING', 3, 120, false, false)
			msg(color(8).'['.color(6).'Cake'.color(8).'] '.color('a').' Health restored.')
		} else {
		# Can't use :P
			@puuid = puuid(@cake['player'], 'dashless')
			export('player.'.@puuid.'.cake.nocake.used', true)
			@taskid = import('player.'.@puuid.'.cake.task.id', 0)
			if(@taskid != 0) { clear_task(@taskid) }
			@newtask = set_timeout(10000, closure(){
				export('player.'.@puuid.'.cake.nocake.used', false)
			});
			export('player.'.@puuid.'.cake.task.id', @newtask)
			cancel()
			switch(rand(1,10)) {
			case 1:
				set_peffect(@cake['player'], 'JUMP_BOOST', -16, 300)
			case 2:
				set_peffect(@cake['player'], 'NAUSEA', 1)
			case 4:
				set_peffect(@cake['player'], 'INSTANT_DAMAGE', 1, 1)
			case 5:
				set_peffect(@cake['player'], 'POISON', 3, 100)
			case 6:
				lightning(@here)
				set_phealth(@cake['player'], 0)
			case 3:
			default:
				set_pheld_slot(@cake['player'], rand(0,8))
			}
		}
	}
}

bind('player_death', array('id': 'cake.message', 'priority': 'HIGH'), null, @death) {
	if(import('player.'.puuid(@death['player'], 'dashless').'.cake.nocake.used') == true) {
		modify_event('death_message', color(8).@death['player'].color(7).' just learned that the cake is a '.color(12).'lie!!')
		export('player.'.puuid(@death['player'], 'dashless').'.cake.nocake.used', false)
		consume()
	}
}
