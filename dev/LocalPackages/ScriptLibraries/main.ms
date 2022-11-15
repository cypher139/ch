#server startup: set database
if(is_array(get_value('primus.database.UUID'))) {
	export('primus.database.UUID', get_value('primus.database.UUID'))
} else {
	export('primus.database.UUID', array('testid': array(1, 5, 10)))
}

#Setup Dev messages and update player database
bind('player_join', array(id: 'cypher139.login'), null, @login) {
#Event playername may sometimes return null? more testing needed
	assign(@player, player())
	@puuid = puuid(@player, 'dashless')

#Are you a dev for Cypher's scripts on this server?
	#Older scripts / blanket enable/Disable.
	export('ch.player.'.@puuid.'.developer', get_value('ch.player.'.@puuid.'.developer'))
	#Newer scripts, look for array(scriptname: true/false)
	@scriptdev = get_value('ch.player.'.@puuid.'.dev.scripts')
	if(!is_array(@scriptdev)) { @scriptdev = array() }
	export('ch.player.'.@puuid.'.dev.scripts', @scriptdev)

#Rei's minimap: Enable radar for everything, and cavemapping.
# Uncomment to use
#	modify_event('join_message', color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color('e').color('f').color('a').@login['join_message'])
	
	#Setup Player UUID Database
	@uuiddata = import('primus.database.UUID')
	#entry found	
	if(array_index_exists(@uuiddata, @puuid)) {
							#Name, World location, Nickname
		@uuiddata[@puuid] = array(pinfo(@player)[0], pinfo(@player)[1], pinfo(@player)[4])
	} else {
	#entry not found
		#if array key not set, @array[key] does not work
		array_set(@uuiddata, @puuid, array(pinfo(@player)[0], pinfo(@player)[1], pinfo(@player)[4]))
		broadcast(color(7).'Welcome '.color('a').player().color(7).' to the server! It\'s their first time here!')
	}
	store_value('primus.database.UUID', @uuiddata)
	export('primus.database.UUID', @uuiddata)
}