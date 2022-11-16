#per gamemode inventory
#version 1.0-tmc
bind('gamemode_change', array(id: 'gamemode.change.inv'), null, @gmc) {
	assign(@name, 'gameMode')
	@dev = import('ch.player.'puuid(player(), 'dashless').'.developer')
	if(@dev == true) {
		msg(@gmc['player'].': Old mode: '.pmode(player()).'        New mode: '.@gmc['newmode'])
	}
	
	@gmpinv = get_value(@name.'player.'.puuid(player(), 'dashless').'.mode.inv')
	if(!is_array(@gmpinv)) { @gmpinv = array('use': false, 'SURVIVAL': array(), 'CREATIVE': array(), 'ADVENTURE': array(), 'SPECTATOR': array()) }

	if(@gmpinv['use'] == true) {
	#save old
		@gmpinv[pmode(player())] = pinv(player())
	#load new	
		clear_pinv(player())
		set_pinv(player(), @gmpinv[@gmc['newmode']])

		store_value(@name.'player.'.puuid(player(), 'dashless').'.mode.inv', @gmpinv)
	}
}