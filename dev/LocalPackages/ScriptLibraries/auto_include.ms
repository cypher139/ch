#server startup: set database
if(is_array(get_value('primus.database.UUID'))) {
	export('primus.database.UUID', get_value('primus.database.UUID'))
} else {
	export('primus.database.UUID', array())
}

# String Capitalization or underscore removal features
proc _capitalize(@string, @lower, @u) {
	if(@lower == '' || @lower == null) { @string = to_lower(@string) }
	assign(@l1, to_upper(@string[0]))
	assign(@length, length(@string) - 1)
	assign(@newstring, @l1.@string[cslice(1, @length)])
	if(@u == '' || @u == null) {
		if(reg_count('[_]', @newstring) > 0) {
			@newstring = reg_replace('_', ' ', @newstring)
		}
	}
	return(@newstring)
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

#Find player UUID when given a player NAME.
#returns array of name, displayname, nickname, and UUID
proc _getplayerID(@option1) {
	@pid = array()
	@uuiddata = import('primus.database.UUID')
	if(@option1 == '~console'){
		@pid = array(display: 'Console', name: '~console', id: 'console', nick: 'Server Console')
	} else {
		try(
			@pid['id'] = puuid(@option1, 'dashless');
		,@fail,
			#puuid throws exception if not found.
			#if ID not found: search uuid for playername
			foreach(@k: @v in @uuiddata) {
				if(equals_ic(@option1, @v[0])) { @pid['id'] = @k }
			}
		)
		#not sure what to return yet
		if(!array_index_exists(@pid, 'id')) {
			@pid['id'] = null
		}
			
		#if found in database
		if(array_index_exists(@uuiddata, @pid['id'])) {
			@pid['name'] = @uuiddata[@pid['id']][0]
			@pid['display'] = @uuiddata[@pid['id']][0]
			if(ponline(@pid['name']) == true) {
				@pid['nick'] = pinfo(@pid['name'])[4];
			} else {
				@pid['nick'] = @uuiddata[@pid['id']][2]	
			}
		} else {
		#not found in database
			if(ponline(@option1) == true) {
				@pid['display'] = pinfo(@option1)[0];
				@pid['name'] = pinfo(@option1)[0];
				@pid['nick'] = pinfo(@option1)[4];
			} else {
				@pid['display'] = @option1
				@pid['name'] = @option1
				@pid['nick'] = 'Player Offline'		
			}
		}
	}
	#Bedrock to Java players come in with name ".NAME", remove dot
	if(reg_count('^[\\.].*', @pid['name']) == 1, 
		assign(@pid['display'], reg_replace('^[\\.]','', @pid['name']))
	)
	return(@pid)
}

proc _getnick(@player) {
	
	assign(@player, pinfo(@player)[0])
	assign(@nick, pinfo(@player)[4])

	if(@player == @nick, return(@player), return(@nick))
}

#Find player NAME when given a UUID.
proc _getplayerName(@findID) {
 	@pid = array()
	@uuiddata = import('primus.database.UUID')
	if(@option1 == '~console'){
		@pid = array(display: 'Console', name: '~console', id: 'console', nick: 'Server Console')
	} else {
		try(
		#throws exception if player offline
			@pid['name'] = player(@findID)
			@pid['display'] = player(@findID) 
			@pid['nick'] = pinfo(@player)[4]
			@pid['id'] = @findID
		,@fail,
			#puuid/player throws exception if not found.
			#if ID not found: search uuid for playername
			foreach(@k: @v in @uuiddata) {
				if(equals_ic(@findID, @k)) { 
					@pid['id'] = @k 
					@pid['name'] = @v[0] 
					@pid['display'] = @v[0] 
					@pid['nick'] = @v[2] 
				}
			}
		)
		if(!array_index_exists(@pid, 'name')) {
			@pid = array(display: 'null', name: null, id: null, nick: 'ID not Valid')
		}
	}
	return(@pid)
}