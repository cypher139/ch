
# Minecraft only server function:
if(!in_cmdline_mode()) {
	#Minecraft server startup: set UUID and IP databases
	if(is_array(get_value('primus.database.UUID'))) {
		export('primus.database.UUID', get_value('primus.database.UUID'))
	} else {
		export('primus.database.UUID', array('testid': array(1, 5, 10)))
	}
	if(is_array(get_value('primus.database.IP'))) {
		export('primus.database.IP', get_value('primus.database.IP'))
	} else {
		export('primus.database.IP', array(1000123: array()))
	}
}
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

# Listen for custom sign commands
bind('player_interact', array('id': 'cypher139.sign.cmd'), null, @event) {
	if(@event['action'] != 'right_click_block' && @event['action'] != 'left_click_block') { return() }

#Check for Clicking on a sign
	# Pre 1.13 if(reg_count('(63|68)(:[0-9]*)?', @event['block']) > 0) {
	if(string_ends_with(@event['block'], '_SIGN')) {
		@signCmds = import('cypher139.sign.Commands')
		if(!is_array(@signCmds)) { return() } 
		@signtext = get_sign_text(@event['location'])
		@command = reg_replace('\\[\\]', '', to_lower(@signtext[0]))
		if(array_index_exists(@signCmds, @command)) {
			@options = array_deep_clone(@signCmds[@command]['options'])
			foreach(@index: @option in @options) {
				if(@option == 'event') { @options[@index] = @event }
				if(@option == 'player') { @options[@index] = player() }
				if(@option == 'sign') { @options[@index] = @signtext }
				if(@option == 'sign1') { @options[@index] = @signtext[1] }
				if(@option == 'sign2') { @options[@index] = @signtext[2] }
				if(@option == 'sign3') { @options[@index] = @signtext[3] }
			}
			call_proc_array(@signCmds[@command]['proc'], @options)
		}
	}
}