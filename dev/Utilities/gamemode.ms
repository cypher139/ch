#Per Game Mode Inventories / Game Mode Lock Enforcement
#version 2.0-tmc
bind('gamemode_change', array('id': 'gamemode.listener', 'priority': 'HIGH'), null, @gmc) {
	@name = 'gameMode'
	@uuid = puuid(@gmc['player'], 'dashless')
	@dev = import('ch.player.'.@uuid.'.dev.scripts.gamemode')
	if(@dev == true) {
		msg(@gmc['player'].': Old mode: '.pmode(player()).'        New mode: '.@gmc['newmode'])
	}
	#Game Mode Lock Enforcement
	@userlock = import(@name.'.player.'.@uuid.'.lock')
	if(@userlock == true) {
		tmsg(@gmc['player'], color(13).'['.color(9).@name.color(13).'] '.color(5).'Someone just tried to change your gamemode to '.to_lower(@gmc['newmode']).'!')
		cancel()
		die()
	}
	
	#Per Game Mode Inventories
	@gmpinv = get_value(@name.'.player.'.@uuid.'.mode.inv')
	if(!is_array(@gmpinv)) { @gmpinv = array('use': false, 'SURVIVAL': array(), 'CREATIVE': array(), 'ADVENTURE': array(), 'SPECTATOR': array()) }

	if(@gmpinv['use'] == true) {
	# Save Current Mode's Inventory
		@gmpinv[pmode(player())] = pinv(player())
	# Load New Mode's previous inventory
		clear_pinv(player())
		set_pinv(player(), @gmpinv[@gmc['newmode']])
		store_value(@name.'.player.'.@uuid.'.mode.inv', @gmpinv)
	}
}