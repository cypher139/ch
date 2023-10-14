#Setup Dev messages and update player database
bind('player_join', array('id': 'cypher139.login'), null, @login) {
#Event playername may sometimes return null? more testing needed
	@player = player()
	@puuid = puuid(@player, 'dashless')
	@jointime = time()
	export('Server.player.'.@puuid.'.last.join', @jointime)

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
	_primus_database_add(@player, 'uuid');
# Setup Player IP Database
	_primus_database_add(@player, 'ip');
}