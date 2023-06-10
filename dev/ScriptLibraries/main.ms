#setup some values
_read_essentials_usermap()
#Setup Dev messages and update player database
bind('player_join', array('id': 'cypher139.login'), null, @login) {
#Event playername may sometimes return null? more testing needed
	@player = player()
	@puuid = puuid(@player, 'dashless')

# Are you a dev for Cypher's scripts on this server?
# Enables dev message settings.
	@ds = get_value('ch.player.'.@puuid.'.dev.scripts')
	@dsall = null
	if(!is_array(@ds)) { @ds = array() }
	if(array_contains(@ds, 'all')) { @dsall = true} else { @dsall = false }
	#Older scripts / blanket enable/Disable.
	export('ch.player.'.@puuid.'.developer', @dsall)
	#Newer scripts, look for ...scripts.scriptname
	foreach(@script in @ds) {
		export('ch.player.'.@puuid.'.dev.scripts.'.@script, true)
	}
	export('ch.player.'.@puuid.'.dev.scripts', @ds)

# Setup Player UUID Database
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
		
# Setup Player IP Database
	@ipdata = import('primus.database.IP')
	#entry found	
	@ipnumbers = reg_replace('\\.*:*', '', pinfo(@player)[3])
	if(array_index_exists(@ipdata, @ipnumbers)) {
		#IP entry found
		if(array_contains(@ipdata[@ipnumbers], @player)) {
			#both IP and player found
			msg(color('a').'Welcome back'.color(7).' to the server, glad you are here!')
		} else {
			#IP entry found, but player not found
			array_push(@ipdata[@ipnumbers], @player)
		}
	} else {
		#IP entry not found
		array_set(@ipdata, @ipnumbers, array(@player))
	}
	store_value('primus.database.IP', @ipdata)
	export('primus.database.IP', @ipdata)
}