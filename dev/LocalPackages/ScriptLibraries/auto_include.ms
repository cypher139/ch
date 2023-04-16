if(in_cmdline_mode() == false) {
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

proc _write_file(@path, @content, @mode, @option) {
	if(@path == '' || @content == '') { return(false) }
	if(@mode == '') { @mode = 'default' }
	@mode = to_upper(@mode)
	@create = false
	switch(@mode[0]) {
		case 'C':
		@mode = 'OVERWRITE'
		@create = true
		case 'O':
		@mode = 'OVERWRITE'
		case 'A':
		@mode = 'APPEND'
		default:
		@mode = 'OVERWRITE'
	}
	if(extension_exists('CHFiles')) {
		try {
			if(file_exists(@path)) {
				if(@create == true) {
					return(false)
				}		
			} else {
				create_file(@path)
			}
		} catch(Exception @ex) {
			console('Create file: '.@ex)
			return(false)
		}
		try {
			write_file(@path, @content, @mode)
			return(true)
		} catch(Exception @ex) {
			msg('File not written, check console logs.')
			console('Write file: '.@ex)
			return(false)
		}
	}
	if(extension_exists('CHFile')) {
		try {
			if(chf_file_exists(@path)) {
				if(@create == true) {
					return(false)
				}		
			} else {
				chf_create_file(@path, true)
			}
		} catch(Exception @ex) {
			console('Create file: '.@ex)
			return(false)
		}
		try {		
			chf_write(@path, @content, @mode)
			return(true)
		} catch(Exception @ex) {
			msg('File not written, check console logs.')
			console('Write file: '.@ex)
			return(false)
		}	
	}
	if(in_cmdline_mode()) {
		try {
			x_write(@path, @content, @mode)  
			return(true)
		} catch(Exception @ex) {
			msg('File not written, check console logs.')
			console('Write file: '.@ex)
			return(false)
		}
	} else {
		msg('[Write file] No writing method was found.') 
		console(color('c').'[Write file] No writing method was found. '.color(6).'Please install the CHFiles or CHFile extension.') 
		return(false)
	}
}

proc _hex_to_rgb(@num) {
	@num = reg_replace('#', '', @num)
	if(length(@num) == 3) {
		@num = reg_split('(?<=\\G.)', @num)
		@num[0] = @num[0].@num[0]
		@num[1] = @num[1].@num[1]
		@num[2] = @num[2].@num[2]
	} else if(length(@num) == 6) {
		@num = reg_split('(?<=\\G..)', @num)
	} else {
		throw('ms.lang.CastException', 'Unsupported Hex code given.')
	}
	@results = array('r': parse_int(@num[0], 16), 'g': parse_int(@num[1], 16), 'b': parse_int(@num[2], 16))
	return(@results)
}


proc _array_string_contains(@array, @string, @doKeys) {
	if(!is_array(@array)) { throw('ms.lang.CastException', 'Not an Array given.') die() }
	if(array_size(@array) == 0) { return(false) }
	if(@string == '') { return(false) }
	if(@doKeys != '') {
		@array = array_keys(@array)
	}
	@return = false
	foreach(@var in @array) {
		 if(string_contains_ic(@var, @string)) {
			@return = true
#			msg('i think '.@var.' is an option at: '.string_position(to_lower(@var), to_lower(@string)))
		}
	}
	return(@return)
}

proc _array_string_match(@array, @string) {
	if(!is_array(@array)) { throw('ms.lang.CastException', 'Not an Array given.') die() }
	@return = array()
	foreach(@var in @array) {
		 if(string_contains_ic(@var, @string)) {
			@return[] = @var
#			msg('i think '.@var.' is an option at: '.string_position(to_lower(@var), to_lower(@string)))
		}
	}
	return(@return)
}

proc _read_essentials_usermap(@option1) {
#Check for Essentials player UUID database, and import it.
	@file = ''
	@floodgateprefix = '_'
	try {
		@file = parse_args(reg_replace('\\n', ' ', read(file_resolve(sys_properties()['user.dir'].'/plugins/Essentials/usermap.csv'))))
	} catch(Exception @ex) {
		console('[read essentials usermap] '.@ex['message'])
		return(false)
	}
	try {
		@floodgateprefix = string(yml_decode(read(file_resolve(sys_properties()['user.dir'].'/plugins/floodgate/config.yml')))['username-prefix'])
	} catch(Exception @ex) {
		@floodgateprefix = '_'
	}
	@euuid = associative_array()
	# playername (lowercase), uuid (dashes)
	foreach(@line in @file) {
		@data = reg_split(',', @line)
		array_set(@euuid, reg_replace('-', '', @data[1]), reg_replace('^_', @floodgateprefix, @data[0]))
	}
#	msg('3 '.@euuid)
	export('primus.database.Essentials.usermap', @euuid)
	return(@euuid)
}

# String Capitalization or underscore removal features
proc _capitalize(@string, @lower, @u, @a) {
	if(!is_string(@string)) { @string = string(@string) }
	if(@lower == '' || @lower == null || @lower == true) { @string = to_lower(@string) }
	if(@u == '' || @u == null || @u == true) {
		if(reg_count('[_]', @string) > 0) {
			@string = reg_replace('_', ' ', @string)
		}
	}
	if(@a == '' || @a == null || @a == false) {
		@string = to_upper(@string[0]).@string[cslice(1, length(@string) - 1)]
	} else {
		@astring = reg_split('\\s', @string)
#		console(@astring)
		foreach(@k: @v in @astring) { @astring[@k] = to_upper(@v[0]).@v[cslice(1, length(@v) - 1)] }
		@string = array_implode(@astring, ' ')
	}
	return(@string)
}

# Is this a even number?
proc _is_even_number(@number, @round) {
	switch(@round) {
		case 'up':
		case 'ceil':
			@number = ceil(@number)
		case 'down':
		case 'integer':
		case 'int':
			@number = integer(@number)
		case 'round':
		case 'r':
		default:
			@number = integer(round(@number))	
	}
	return(@number % 2 == 0)
}


#Find player UUID when given a player NAME.
#returns array of name, displayname, nickname, and UUID
proc _getplayerID(@findID) {
	if(function_exists('player')) {
		@pid = array()
		@uuiddata = import('primus.database.UUID')
		if(!is_array(@uuiddata)) { @uuiddata = array() }
		if(reg_count('^~?console$', @findID) > 0 || reg_count('^~?[Ss]erver$', @findID) > 0) {
			@pid = array('display': 'Console', 'name': '~console', 'id': 'console', 'nick': 'Server Console')
		} else {
			try {
				@pid['id'] = puuid(@findID, 'dashless');
			} catch(Exception @ex) {
				#puuid throws exception if not found.
				#if ID not found: search uuid for playername
				foreach(@k: @v in @uuiddata) {
					if(equals_ic(@findID, @v[0])) { 
						@pid['id'] = @k
						break()
					}
				}
			}
			#not sure what to return yet
			if(!array_index_exists(@pid, 'id')) { @pid['id'] = null }
				
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
				if(ponline(@findID) == true) {
					@pid['display'] = pinfo(@findID)[0];
					@pid['name'] = pinfo(@findID)[0];
					@pid['nick'] = pinfo(@findID)[4];
				} else {
					@pid['display'] = @findID
					@pid['name'] = @findID
					@pid['nick'] = 'Player Offline'		
				}
			}
		}
		#Bedrock to Java players come in with name ".NAME", remove dot
		if(reg_count('^[\\.].*', @pid['name']) == 1) {
			@pid['display'] = reg_replace('^[\\.]', '', @pid['name'])
		}
		return(@pid)
	} else {
		return('Running in Command Line')
	}
}

#Find player NAME when given a UUID.
proc _getplayerName(@findID) {
	if(function_exists('player')) {
		@pid = array()
		@uuiddata = import('primus.database.UUID')
		if(reg_count('^~?console$', @findID) > 0 || reg_count('^~?[Ss]erver$', @findID) > 0) {
			@pid = array('display': 'Console', 'name': '~console', 'id': 'console', 'nick': 'Server Console')
		} else {
			try {
			#throws exception if player offline
				@pid['name'] = player(@findID)
				@pid['display'] = player(@findID) 
				@pid['nick'] = pinfo(@pid['name'])[4]
				@pid['id'] = @findID
			} catch(Exception @ex) {
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
			}
			if(!array_index_exists(@pid, 'name')) {
				@pid = array('display': 'null', 'name': null, 'id': null, 'nick': 'ID not Valid')
			}
		}
		return(@pid)
	} else {
		return('Running in Command Line')
	}
}