#version 1.1-tmc
bind('player_death', array(id: 'DeathTP.event'), null, @death) {
	assign(@dev, get_value('ch.player.'.puuid(player(), 'dashless').'.developer'))
	#save death point for /back
	assign(@here, ploc(@death['player']))
	assign(@oloc1, get_value('player.'.puuid(player(), 'dashless').'.last.death.loc.1'))
	store_value('player.'.puuid(player(), 'dashless').'.last.death.loc.1', @here)
	store_value('player.'.puuid(player(), 'dashless').'.last.death.loc.2', @oloc1)
	tmsg(@death['player'], color(7).'Use the '.color('c').'/back'.color(7).' command to return to your death point.')
	
	#save inventory
	if(@dev == true) {msg('Drops:'.@death['drops'])}
	assign(@odrops1, get_value('player.'.puuid(player(), 'dashless').'.last.death.drops.1'))
	store_value('player.'.puuid(player(), 'dashless').'.last.death.drops.1', @death['drops'])
	store_value('player.'.puuid(player(), 'dashless').'.last.death.drops.2', @odrops1)
}