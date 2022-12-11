#server startup: set UUID and IP databases
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

# String Capitalization or underscore removal features
proc _capitalize(@string, @lower, @u, @a) {
	if(@lower == '' || @lower == null) { @string = to_lower(@string) }
	if(@u == '' || @u == null) {
		if(reg_count('[_]', @string) > 0) {
			@string = reg_replace('_', ' ', @string)
		}
	}
	if(@a == '' || @a == null) {
		@string = to_upper(@string[0]).@string[cslice(1, length(@string) - 1)]
	} else {
		@astring = reg_split('\\s', @string)
#		console(@astring)
		foreach(@k: @v in @astring) { @astring[@k] = to_upper(@v[0]).@v[cslice(1, length(@v) - 1)] }
		@string = array_implode(@astring, ' ')
	}
	return(@string)
}

#is this a even number?
proc _is_even_number(@number) {return(mod(@number, 2) == 0)}


#Find player UUID when given a player NAME.
#returns array of name, displayname, nickname, and UUID
proc _getplayerID(@option1) {
	@pid = array()
	@uuiddata = import('primus.database.UUID')
	if(reg_count('^~?console$', @option1) > 0) {
		@pid = array('display': 'Console', 'name': '~console', 'id': 'console', 'nick': 'Server Console')
	} else {
		try(
			@pid['id'] = puuid(@option1, 'dashless');
		,@fail,
			#puuid throws exception if not found.
			#if ID not found: search uuid for playername
			foreach(@k: @v in @uuiddata) {
				if(equals_ic(@option1, @v[0])) { 
					@pid['id'] = @k
					break()
				}
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
	if(reg_count('^[\\.].*', @pid['name']) == 1) {
		@pid['display'] = reg_replace('^[\\.]', '', @pid['name'])
	}
	return(@pid)
}

#Find player NAME when given a UUID.
proc _getplayerName(@findID) {
 	@pid = array()
	@uuiddata = import('primus.database.UUID')
	if(reg_count('^~?console$', @findID) > 0) {
		@pid = array('display': 'Console', 'name': '~console', 'id': 'console', 'nick': 'Server Console')
	} else {
		try(
		#throws exception if player offline
			@pid['name'] = player(@findID)
			@pid['display'] = player(@findID) 
			@pid['nick'] = pinfo(@pid['name'])[4]
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
					break()
				}
			}
		)
		if(!array_index_exists(@pid, 'name')) {
			@pid = array('display': 'null', 'name': null, 'id': null, 'nick': 'ID not Valid')
		}
	}
	return(@pid)
}