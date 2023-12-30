#version 1.0-tmc
bind('pressure_plate_activated', array(id: 'triangle.teleporter', priority: 'MONITOR'), null, @ratchet) {
@uuid = puuid(player(), 'dashless')
@dev = import('ch.player.'.@uuid.'.dev.scripts.tp')
@prefix = color('#ffcc00').'['.color(7).'Teleporter'.color('#ffcc00').'] '
# 2 modes: mode 1: teleport on press. mode 2: on press say warpname on hotbar, warp on release
if(@ratchet['macrotype'] != 'player') { console('whut?') }
if(reg_count('^.+_PRESSURE_PLATE', get_block(@ratchet['location'])) == 0) {
#collecting event data
	@otherblocks = get_value('ch.dev.data.event.pressure_plate.types')
	if(!is_array(@otherblocks)) { @otherblocks = array() }
	if(!array_contains(@otherblocks, get_block(@ratchet['location']))) { 
		@otherblocks[] = get_block(@ratchet['location'])
		store_value('ch.dev.data.event.pressure_plate.types', @otherblocks)
		console(color('c').'New: '.color(8).' pressure_plate_activated event occured on a '.get_block(@ratchet['location']))
		console(color(8).'Current types found:  '.array_implode(@otherblocks, ', '))
	}
	if(@dev == true) { msg(color('c').'Note: '.color(8).'pressure_plate_activated event occured on a '.get_block(@ratchet['location'])) }
	die()
}
#msg(@ratchet)

@allteleporters = get_value('server.Teleporters.registered')
if(!is_array(@allteleporters)) { @allteleporters = array() }

#location array: key is x.y.z all whole numbers
@implodeloc = integer(@ratchet['location']['x']).'.'.integer(@ratchet['location']['y']).'.'.integer(@ratchet['location']['z'])

# Save command
if(import('player.'.@uuid.'.command.setteleporter') == true) {

	@setcoords = import('player.'.@uuid.'.command.setteleporter.coords')
	@setoptions = import('player.'.@uuid.'.command.setteleporter.options')
	store_value('server.Teleporters.registered.undo', @allteleporters)
	
	if(array_index_exists(@allteleporters, pworld(), @implodeloc)) {
		@allteleporters[pworld()][@implodeloc] = array('location': @setcoords, 'registrar': player(), 'name': @setoptions['name'], 'activetime': @setoptions['time'], 'allowedGroups': null, 'uses': 0)
	} else {
		array_set(@allteleporters[pworld()], @implodeloc, array('location': @setcoords, 'registrar': player(), 'name': @setoptions['name'], 'activetime': @setoptions['time'], 'allowedGroups': null, 'uses': 0))
	}
	store_value('server.Teleporters.registered', @allteleporters)
	export('player.'.@uuid.'.command.setteleporter', false)
	msg(@prefix.color(6).'Teleporter Bound and Online!')
	die()
}

# Info command
if(import('player.'.@uuid.'.command.setteleporter.info') == true) {
	if(array_index_exists(@allteleporters, pworld(), @implodeloc)) {
		msg(@prefix.'Teleporter at: '.integer(@ratchet['location']['x']).', '.integer(@ratchet['location']['y']).', '.integer(@ratchet['location']['z']))
		msg(color(3).' Name: '.@allteleporters[pworld()][@implodeloc]['name'])
		msg(color(6).' Warps to: '. array_implode(@allteleporters[pworld()][@implodeloc]['location'], ', '))
		msg(color(9).' Registered by: '.@allteleporters[pworld()][@implodeloc]['registrar'].'       Used '.@allteleporters[pworld()][@implodeloc]['uses'].' times')
		msg(color(8).' Active times: '. @allteleporters[pworld()][@implodeloc]['activetime'])
	#	msg(color(8).' Allowed Groups: '. @allteleporters[pworld()][@implodeloc]['allowedGroups'])
	} else {
		msg(@prefix.color(6).'Teleporter not Registered.')
	}
	export('player.'.@uuid.'.command.setteleporter.info', false)
	die()
}

#Teleport
#if stepped on plate registered in array, teleport to location given
if(array_index_exists(@allteleporters, pworld(), @implodeloc, 'location')) {
	#time check
	if(reg_count(':', @allteleporters[pworld()][@implodeloc]['activetime']) > 0) {
		@tptime = split(':', @allteleporters[pworld()][@implodeloc]['activetime'])
		if(get_world_time(pworld()) < @tptime[0] || get_world_time(pworld()) > @tptime[1]) {
			die(color(6).'Teleporter is out of order. Come back another time!')
		}
	}
	set_ploc(@allteleporters[pworld()][@implodeloc]['location'])
	@allteleporters[pworld()][@implodeloc]['uses'] = @allteleporters[pworld()][@implodeloc]['uses'] + 1
	store_value('server.Teleporters.registered', @allteleporters)

	@tpmsg = color(6).'You have been Teleported!'
	if(@allteleporters[pworld()][@implodeloc]['name'] != null) {
		@tpmsg = color(6).'You have used the "'.color(9).@allteleporters[pworld()][@implodeloc]['name'].color(6).'" Teleporter!'
	}
	msg(@tpmsg)
}

# msg(get_commands()['warp'])

#spawn particle
#name: if underscore change to space
#update command: use remove but with new data
#3 second delay, but do particles immediately, teleporting in 3..2...1
#can get file from essentials warps?


}