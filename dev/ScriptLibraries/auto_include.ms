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
	@pf = '/'
	@notpf = '\\\\'
	@pathdrive = '/'
	#backslash escapes on regex: must add extra backslash
	if(get_os() == 'WINDOWS') { @pf = '\\\\' @notpf = '/' @pathdrive = @path[0..1].'\\' }
	@path = reg_replace('['.@notpf.']', @pf, @path)
	@pathparent = reg_replace('[^'.@pf.']+$', '', @path)
	@pathlayout = reg_match('(.+)(['.@pf.'].+)(['.@pf.'].+)$', @path)
	@pathsplit = reg_split(@pf, @path)
	array_remove(@pathsplit, 0)
	# console(@pathlayout)
	# 1 = root path, 2 = /parent, 3 = /filename or current dir
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
		#Create Parent folder(s)
		@pathbuild = @pathdrive
		for(@i = 0, @i < array_size(@pathsplit), @i++) {
			try {
				if(!is_dir(@pathbuild)) {
					create_dir(@pathbuild)
				}
			} catch(IOException @ex) {
				# You do not have permission to view folder. -- Most likely checking early in path in unprivileged directories outside of CH's base-dir
				if((@i + 1) == array_size(@pathsplit)) {
					# Entire path was unavailable to CH, stop here.
					console('Create Parent Folder: '.@ex)
					return(false)
				}
			}
			@pathbuild = @pathbuild.@pf.@pathsplit[@i]
		}
		# File check: 
		#	Append: if file does not exist make an empty file 
		#	Create mode: stop if file exists
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

proc _hex_to_rgb(@num, @string = false) {
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
	if(@string == true) { @results = @results['r'].', '.@results['g'].', '.@results['b'] }
	return(@results)
}

proc _rgb_to_hex(@R, @G, @B, @prefix = '') {
	if(is_array(@R)) {
		if(array_size(@R) != 3) {
			throw('ms.lang.CastException', 'Not enough array elements present.')
		}
		if(@G != null) { @prefix = @G }
		@checkarray = array('r', 'g', 'b')
		foreach(@k: @v in @R) {
			if(is_associative(@R) && !array_contains(@checkarray, @k)) { throw('ms.lang.CastException', 'Unsupported array index given.') }
			if(@v > 255) { throw('ms.lang.CastException', 'Unsupported RGB code given. ('.@k.')') }
			switch(@k) {
			case 0:
			case 'r':
				@R = @v
			case 1:
			case 'g':
				@G = @v
			case 2:
			case 'b':
				@B = @v
			}
		}
	} else {
		if(@R == null) { @R = 0 @G = 0 @B = 0 }
		if(reg_count('\\D+', @R) > 0) {
			@new = reg_split('\\D+', @R)
			if(array_size(@new) != 3) {	throw('ms.lang.CastException', 'Not enough array elements present. (2)') }
			@R = @new[0]
			@G = @new[1]
			@B = @new[2]
		}
		if(@R > 255 || @R == null) { throw('ms.lang.CastException', 'Unsupported RGB code given. (3)') }
		if(@G > 255 || @G == null) { throw('ms.lang.CastException', 'Unsupported RGB code given. (4)') }
		if(@B > 255 || @B == null) { throw('ms.lang.CastException', 'Unsupported RGB code given. (5)') }
	}
	@results = to_radix(@R, 16).to_radix(@G, 16).to_radix(@B, 16)
	if(@prefix != '') { @results = @prefix.@results }
	return(@results)
}

proc _register_sign_command(string @name, string @proc, array @options = array()) {
	if(@name == '' || @name == null) { return(false) }
	if(@proc == '' || @proc == null) { return(false) }
	@signCmds = import('cypher139.sign.Commands')
	@name = to_lower(@name)
	if(!is_array(@signCmds)) { @signCmds = array() } 
	if(is_associative(@options)) { @options = array_normalize(@options) }
	if(!array_index_exists(@options, 0)) { @options = array('event', 'sign') }
	if(array_index_exists(@signCmds, @name)) {
		console(color('c').'[Signs] A command named '.@name.' was already registered!')
	}
	#Register command
	array_set(@signCmds, @name, array('proc': @proc, 'options': @options))
	export('cypher139.sign.Commands', @signCmds)
}


proc _array_string_contains(array @array, string @needle, string @matchType = 'default', @returnType = 'boolean', @doKeys) {
	if(!is_array(@array)) { throw('ms.lang.CastException', 'Not an Array given.') die() }
	if(array_size(@array) == 0) { return(false) }
	if(@needle == '') { return(false) }
	if(@doKeys != '') {	@array = array_keys(@array) }
	@return = false
	@returnArray = array()
	foreach(@haystack in @array) {
		switch(@matchType) {
		case 'min':
		# Minimum matching: If needle string size is less than haystring string size continue, as otherwise in this case it's 99% false positive.
		# i.e. ("everyone", "on") techincally it does contain 'on', but we were looking for the word "everyone" not words that can be made from it.
			if(length(@haystack) > length(@needle)) { continue() }
		case 'exact':
			if(length(@haystack) != length(@needle)) { continue() }
		}
		if(string_contains_ic(@haystack, @needle)) {
			@return = true
			@returnArray[] = @haystack
#			msg('i think '.@haystack.' is an option at: '.string_position(to_lower(@haystack), to_lower(@needle)))
		}
	}
	switch(string(@returnType)) {
	case 'array':
		return(@returnArray)
	case 'boolean':
	case 'true':
	case 'false':
	default:
		return(@return)
	}
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
proc _getplayerID(@findID, @retType = 'array', @dashType = 'dashless') {
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
		switch(string(@retType)) {
		case 'true':
		case 'false':
		case 'boolean':
			if(@pid['id'] == null) { return(false) } else { return(true) }
		case 'string':
		case 'id':
			return(@pid['id'])
		case 'array':
			return(@pid)
		}
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

proc _primus_database_add(@player, @type, @data, @option) {
	if(@player == '' || @player == null) { return('No Player Given') }
	@update = false
	switch(@type) {
	case 'uuid':
	# Setup Player UUID Database
		if(@data == '' || @data == null) { @data = puuid(@player, 'dashless') }
		@uuiddata = import('primus.database.UUID')
		#entry found	
		if(array_index_exists(@uuiddata, @data)) {
								#Name, World location, Nickname
			@uuiddata[@data] = array(pinfo(@player)[0], pinfo(@player)[1], pinfo(@player)[4])
		} else {
		#entry not found
			#if array key not set, @array[key] does not work
			array_set(@uuiddata, @data, array(pinfo(@player)[0], pinfo(@player)[1], pinfo(@player)[4]))
			broadcast(color(7).'Welcome '.color('a').player().color(7).' to the server! It\'s their first time here!')
		}
		@update = true
		if(@update == true) {
			store_value('primus.database.UUID', @uuiddata)
			export('primus.database.UUID', @uuiddata)
		}
	case 'ip':		
	# Setup Player IP Database
		@ipdata = import('primus.database.IP')
		if(!array_index_exists(@ipdata, '_ip')) { array_set(@ipdata, '_ip', array()) }
		if(!array_index_exists(@ipdata, '_hostname')) { array_set(@ipdata, '_hostname', array()) }
		#entry found
		if(@data == '' || @data == null) { @data = pinfo(@player)[3] }
		if(@option == '' || @option == null) { @option = pinfo(@player)[10] }
		@ipnumbers = reg_replace('\\.*:*', '', @data)
		if(array_index_exists(@ipdata, @ipnumbers)) {
			#IP entry found
			if(array_contains(@ipdata[@ipnumbers], @player)) {
				#both IP and player found
				tmsg(@player, color('a').'Welcome back'.color(7).' to the server, glad you are here!')
			} else {
				#IP entry found, but player not found
				array_push(@ipdata[@ipnumbers], @player)
				@update = true
			}
		} else {
			#IP entry not found
			array_set(@ipdata, @ipnumbers, array(@player))
			@update = true
		}
		if(@update == true) {
			array_set(@ipdata['_ip'], @ipnumbers, @data)
			array_set(@ipdata['_hostname'], @ipnumbers, @option)
			store_value('primus.database.IP', @ipdata)
			export('primus.database.IP', @ipdata)
		}
	default:
		return('Unsupported Action')
	}
	return(true)
}