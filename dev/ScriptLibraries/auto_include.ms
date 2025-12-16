proc _msg_Admins(string @name = 'CommandHelper', string @type = 'info', string @message, string @consoleData = '', @skipPlayer) {
	if(!@name) { @name = 'CH'; }
	@sendConsole = true;
	@sendPlayer = true;
	@logPath = 'Bot';
	@prefix = color(8).'['.color(3).@name.color(8).'] '.color('r');
	switch(@type) {
	case 'prefix':
	case 'info':
		@nc = 1
	case 'server':
		@prefix = color(6).'['.color(9).'Server'.color(6).'] '.color('r');
	case 'debug':
		@prefix .= color(14).'<debug> '.color('r');
	case 'error':
		@prefix .= color(12).'<error> '.color('r');
	case 'warning':
		@prefix .= color(6).'<Warning> '.color('r');
	case 'd':
	case 'bot':
		@prefix = color(8).'['.color(5).'Bot'.color(8).'] '.color('r');
	case '-':
	case 'none':
		@prefix = '';
	default:
		@prefix = @type;
	}
	@message = @prefix.@message;
	if(import('Server.config.messages.Console_Messages', true) != true) { @sendConsole = false; }
	if(@type == 'debug') {
		@sendConsole = false;
		@sendPlayer = false;
		if(import('Server.config.messages.Console_Debug') === true) { @sendConsole = true; }
	}
	if(@type == 'error') { 
		_write_file('Log-Error-Console.txt', '['.simple_date('MM-dd-yy HH:mm:ss', time()).']: '.@message.@consoleData.'\n', 'Append');
		@sendConsole = true;
	}
	if(@sendConsole === true) {
		console(@message.@consoleData, false);
	} else {
		_write_file('Log-Console.txt', '['.simple_date('MM-dd-yy HH:mm:ss', time()).']: '.@message.@consoleData.'\n', 'Append');
	}
	# Broadcast to MC server Admins, if available
	if(function_exists('all_players') && @sendPlayer === true) {
		foreach(@p in all_players()) {
			if(has_permission(@p, 'admin.messages.receive.'.@type) && @p != @skipPlayer) { tmsg(@p, @message); }
		}
	}
}

proc _load_yml_config(string @Script, string @config, int @minVersion = 0, @afterLoad = '') {
	if(!@config) { @config = 'Server'; }
	if(!@Script) { throw(CastException, 'Must provide Script Name.'); }
	@data = '';
	@pf = if(get_os() === 'WINDOWS', '\\', '/');
	try {
		@data = yml_decode(read(import('dir.lp').@pf.@Script.@pf.'Configs'.@pf.@config.'.yml'));
	} catch(IOException @ex) {
		_msg_Admins(@Script, 'error', color(12).@config.' Config file not recognized or found. ', @ex['message']);
		return(false);
	} catch(FormatException @ex) {
		_msg_Admins(@Script, 'error', color(12).@config.' Config\'s YML is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message'])); 
		return(false);
	} catch(Exception @ex) {
		_msg_Admins(@Script, 'error', color(12).'There was an error with the '.@config.' Config file. ', @ex['message']); 
		return(false);
	}
#Checks:
	if(!is_array(@data)) {
		_msg_Admins(@Script, 'error', @config.' config file is not formatted.');
		return(false);
	}
	if(@minVersion > 0) {
		if(!array_index_exists(@data, 'v')) { _msg_Admins(@Script, 'error', color(12).@config.' Config is too old, please update.') return('OldConfig'); }
		@cfgVersion = import(@Script.'.cfg.version');
		if(!is_array(@cfgVersion)) { @cfgVersion = array(); }
		if(!array_index_exists(@cfgVersion, @config)) { _msg_Admins(@Script, 'error', color(12).'Config version not present, please update.') return('OldConfig'); }
		if(@data['v'] < @cfgVersion[@config]) {
			_msg_Admins(@Script, 'error', color(12).@config.' Config for "'.@config.'" is outdated, please update.');
			return('OldConfig');
		}
	}
	if(array_index_exists(@data, 'Not_Configured')) {
		_msg_Admins(@Script, 'warning', color(14).@config.' Config file is still using the default values. Please configure it to your needs!');
		return(false);
	}
	switch(string(@config)) {
	case 'Experimental':
	case 'ex':
		@servercfg = import(@Script.'.config.Server');
		@data = array_merge(@data, @servercfg);
	}
	if(is_closure(@afterLoad)) { @data = @afterLoad(@data); }
	@loadTimes = import('cypher139.config.load.time');
	if(!is_array(@loadTimes)) { @loadTimes = array(); }
	if(!array_index_exists(@loadTimes, @Script)) { @loadTimes[@Script] = array(); }
	@loadTimes[@Script][@config] = time();
	export('cypher139.config.load.time', @loadTimes);
	export(@Script.'.config.'.@config, @data);
	return(@data);
}


proc _write_file(string @path, @content, @append, @option) {
	if(length(@path) < 5) { return(false); }
	if(!is_bytearray(@content)) {
		if(length(@content) <= 0) { return(false); }
	}
	#0: NOT this OS, 1: this OS
	@pf = if(get_os() === 'WINDOWS', array('/', '\\'), array('\\', '/'));
	@pfR = if(get_os() === 'WINDOWS', array('/', '\\\\'), array('\\\\', '/'));
	@path = reg_replace('['.@pfR[0].']', @pf[1], @path);
	# Prefix LocalPackages to path?
	if(string_starts_with(@path, '^lp')) {
		#Cmdline: Use parent if requested LP folder is current dir
		@lpcmd = if(in_cmdline_mode() && string_starts_with(@path, '^lp'.@pf[1].reg_match('[^'.@pfR[1].']+$', pwd())[0]), '../', pwd());
		@lp = if(in_cmdline_mode(), @lpcmd, sys_properties()['user.dir'].@pf[1].'plugins'.@pf[1].'CommandHelper'.@pf[1].'LocalPackages');
		@path = file_resolve(replace(@path, '^lp', @lp));
	}
	#check for need to resolve
	@pdcheck = reg_count('^'.if(get_os() === 'WINDOWS', '[A-Za-z]:\\\\', '/'), @path[0..1]);
	if(!@pdcheck) { @path = file_resolve(@path); }
	@pd = if(get_os() === 'WINDOWS', @path[0..1].'\\', '/');
	#backslash escapes on regex: must add extra backslash
	@pathparent = reg_replace('[^'.@pfR[1].']+$', '', @path);
	@pathlayout = reg_match('(.+)(['.@pfR[1].'].+)(['.@pfR[1].'].+)$', @path);
	@pathsplit = reg_split(@pfR[1], @path);
	array_remove(@pathsplit, 0);
	# console(@pathlayout);
	# 1 = root path, 2 = /parent, 3 = /filename or current dir
	if(!@append) { @append = 'default'; }
	@create = false;
	switch(to_lower(string(@append)[0])) {
	case 'c':
		@append = 'OVERWRITE';
		@create = true;
	case 'f':
	case 'o':
		@append = 'OVERWRITE';
	case 't':
	case 'a':
		@append = 'APPEND';
	default:
		@append = 'OVERWRITE';
	}
	if(extension_exists('CHFiles')) {
		#Create Parent folder(s);
		@pathbuild = @pd;
		for(@i = 0, @i < array_size(@pathsplit), @i++) {
			try {
				if(!is_dir(@pathbuild)) {
					create_dir(@pathbuild);
				}
			} catch(IOException @ex) {
				# You do not have permission to view folder. -- Most likely checking early in path in unprivileged directories outside of CH's base-dir
				if((@i + 1) == array_size(@pathsplit)) {
					# Entire path was unavailable to CH, stop here.
					console('[WriteFile:CHFiles] Create Parent Folder: '.@ex);
					return(false);
				}
			}
			@pathbuild .= @pf[1].@pathsplit[@i];
		}
		# File check:
		#	Append: if file does not exist make an empty file
		#	Create mode: stop if file exists
		try {
			if(file_exists(@path)) {
				if(@create === true) {
					return(false);
				}		
			} else {
				create_file(@path);
			}
		} catch(Exception @ex) {
			console('[WriteFile:CHFiles] Create file: '.@ex);
			return(false);
		}
		try {
			write_file(@path, @content, @append);
			return(true);
		} catch(Exception @ex) {
			msg('File not written, check console logs.');
			console('[WriteFile:CHFiles] Write file: '.@ex);
			return(false);
		}
	}
	if(extension_exists('CHFile')) {
		try {
			if(chf_file_exists(@path)) {
				if(@create === true) {
					return(false);
				}		
			} else {
				chf_create_file(@path, true);
			}
		} catch(Exception @ex) {
			console('[WriteFile:CHFile] Create file: '.@ex);
			return(false);
		}
		try {
			if(is_bytearray(@content)) {
				if(@option == 'gzip') {
					chf_write_gzip_binary(@path, @content, @append);
				} else {
					chf_write_binary(@path, @content, @append);
				}
			} else {
				chf_write(@path, @content, @append);
			}
			return(true);
		} catch(Exception @ex) {
			msg('File not written, check console logs.');
			console('[WriteFile:CHFile] Write file: '.@ex);
			return(false);
		}	
	}
	if(in_cmdline_mode()) {
		try {
			x_write(@path, @content, @append);
			return(true);
		} catch(Exception @ex) {
			msg('File not written, check console logs.');
			console('[WriteFile:Cmd] Write file: '.@ex);
			return(false);
		}
	} else {
		msg('[Write file] No writing method was found.');
		console(color(12).'[Write File] No writing method was found. '.color(6).'Please install the CHFiles or CHFile extension.');
		return(false);
	}
}

proc _register_sign_command(string @name, string @proc, array @options = array()) {
	if(@name == '' || @name == null) { return(false) }
	if(@proc == '' || @proc == null) { return(false) }
	@signCmds = import('cypher139.sign.Commands');
	@name = to_lower(@name);
	@rereg = array();
	if(!is_array(@signCmds)) { @signCmds = array() } 
	if(is_associative(@options)) { @options = array_normalize(@options) }
	if(!array_index_exists(@options, 0)) { @options = array('event', 'sign') }
	if(array_index_exists(@signCmds, @name)) { @rereg[] = @name; }
	#Register command
	@signCmds[@name] = array('proc': @proc, 'options': @options);
	export('cypher139.sign.Commands', @signCmds);
	if(array_size(@rereg) > 0) { console(color(14).'[Signs] '.color('r').'Re-registered sign commands: '.array_implode(@rereg, ', '), false); }
	return(true);
}

proc _register_poll_file(string @name, string @proc, string @path, array @options = array()) {
	if(!@name || !@proc) { return(false); }
	@rereg = array();
	@polls = import('cypher139.poll.files');
	if(!is_array(@polls)) { @polls = array(); }
	if(is_associative(@options)) { @options = array_normalize(@options); }
	if(array_index_exists(@polls, @name)) { @rereg[] = @name; }
	#Register file
	@polls[@name] = array('proc': @proc, 'last': time(), 'path': @path, 'options': @options);
	export('cypher139.poll.files', @polls);
	if(array_size(@rereg) > 0) { console(color(14).'[File Poll] '.color('r').'Re-registered files: '.array_implode(@rereg, ', '), false); }
	return(true);
}


proc _array_string_contains(array @array, string @needle, string @matchType = 'default', @returnType = 'boolean', @doKeys) {
	if(!is_array(@array)) { throw('ms.lang.CastException', 'Not an Array given.') die(); }
	if(@needle == '') { throw('ms.lang.CastException', 'No string given.') die(); }
	@return = false;
	@returnArray = array();
	if(@doKeys != '') {	@array = array_keys(@array); }
	foreach(@haystack in @array) {
		switch(@matchType) {
		case 'min':
		# Minimum matching: If needle string size is less than haystring string size continue, as otherwise in this case it's 99% false positive.
		# i.e. ("everyone", "on") techincally it does contain 'on', but we were looking for the word "everyone" not words that can be made from it.
			if(length(@haystack) > length(@needle)) { continue(); }
		case 'exact':
			if(length(@haystack) != length(@needle)) { continue(); }
		}
		if(string_contains_ic(@haystack, @needle)) {
			@return = true;
			@returnArray[] = @haystack;
#			msg('i think '.@haystack.' is an option at: '.string_position(to_lower(@haystack), to_lower(@needle)));
		}
	} else {
		console('Empty array given');
	}
	switch(string(@returnType)) {
	case 'array':
		return(@returnArray);
	case 'boolean':
	case 'true':
	case 'false':
	default:
		return(@return);
	}
}

# String Capitalization or underscore removal features
proc _capitalize(@string, boolean @a = false, boolean @lower = true, boolean @u = true) {
	if(is_boolean(@string)) { @string = string(@string); }
	if(is_array(@string)) { @string = array_implode(@string, ' '); }
	if(!is_string(@string)) { throw('CastException', 'Expected string in _capitalize(), but received a '.typeof(@string)); }
	switch(length(@string)) {
	case 0:
		return(@string);
	case 1:
		return(to_upper(@string));
	default:	
		if(@lower) { @string = to_lower(@string); }
		if(@u) {
			if(reg_count('[_]', @string) > 0) {
				@string = replace(@string, '_', ' ');
			}
		}
		if(@a) {
			@astring = reg_split('\\s', @string);
			foreach(@k: @v in @astring) { @astring[@k] = to_upper(@v[0]).@v[cslice(1, length(@v) - 1)]; }
			@string = array_implode(@astring, ' ');
		} else {
			@string = to_upper(@string[0]).@string[cslice(1, length(@string) - 1)]
		}
		return(@string);
	}
}

# Is this a even number?
proc _is_even_number(@number, @round) {
	switch(@round) {
		case 'up':
		case 'ceil':
			@number = ceil(@number);
		case 'down':
		case 'integer':
		case 'int':
			@number = integer(@number);
		case 'round':
		case 'r':
		default:
			@number = integer(round(@number))	
	}
	return(@number % 2 === 0);
}

#Random Code Generation
proc _codegen(@length = 7, @t1 = 'full', @t2) {
# Character types: lowercase ("lower"), uppercase ("upper"), number ("num"), symbol ('sym'), full (all alphanumeric characters) or all (Full + symbols).
# Extra character types: 8bit or 16bit for their respective numbers.

#--- User Input Checks
	@string = array();
	@chars = array();
	@opt = array();
	if(!@t1) { @t1 = 'full'; }
	if(is_array(@t1)) {
		if(is_associative(@t1)) {
			@opt = array_normalize(@t1);
		} else {
			@opt = @t1;
		}
	} else {
		@opt = array(@t1);
		if(@t2) { @opt[] = @t2; }
	}
	if(is_numeric(@length)) {
		@length = integer(@length);
	} else if(!@length) { 
		@length = 7;
	}
	# Thread limit: Using main server thread may produce slowdowns for large code numbers.
	if(x_get_current_thread() == 'Server thread') {
		if(@length > 512) { @length = 512; }
	}
	@numlimit = array();
	
#--- List of Characters
	@lower = array('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z');
	@upper = array('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z');
	@number = array('1','2','3','4','5','6','7','8','9');
	@full = array_merge(@lower, @upper, @number);
	@symbol = array('!', '@', '#', '$', '%', '^', '&', '*', '+', '-', '/', '\\', '~', '?');
	@all = array_merge(@full, @symbol);
	
#--- Character Sets
	@j = 0;
	foreach(@i: @o in @opt) {
		if(@i > 3) { break(); }
		@j++;
		@useChars = array();
		@b = false;
		if(!is_numeric(@o)) { @o = to_lower(@o); }
		switch(@o){
		case 'lower':
		case 'l':
		case 'low':
		case 0:
			@useChars = @lower[];
		case 'upper':
		case 'u':
		case 'up':
		case 1:
			@useChars = @upper[];
		case 'number':
		case 'n':
		case '#':
		case 'num':
		case 2:
			@useChars = @number[];
		case 'full':
		case 'f':
		case 3:
			@useChars = @full[];
		case 'swear':
		case 'symbol':
		case 'sym':
		case 's':
		case 4:
			@useChars = @symbol[];
		case 'all':
		case 'a':
		case 5:
			@useChars = @all[];
		case 'read':
		case 6:
			@useChars = array_merge(@lower, @number);
			array_remove_values(@useChars, 'i');
			array_remove_values(@useChars, 'l');
			array_remove_values(@useChars, 'o');
		case 'n8':
		case '8bit':
			if(@i > 0) { return('8-bit Not supported as type #'.@j); }
			@number[] = 0;
			@useChars = @number[];
			@length = 3;
			@numlimit = array(2,5,5);
			@b = true;
		case 'n16':
		case '16bit':
			if(@i > 0) { return('16-bit Not supported as type #'.@j); }
			@number[] = 0;
			@useChars = @number[];
			@length = 5;
			@numlimit = array(6,5,5,3,5);
			@b = true;
		default:
			return('Invalid code type given ('.@j.')');
		}
		@chars = array_merge(@chars, @useChars);
		if(@b) { break(); }
	}
	
#--- Generate code
	array_resize(@string, @length);
	foreach(@i: @char in @string) {
		if(array_index_exists(@numlimit, 0)) {
			@string[@i] = @chars[rand(@numlimit[@i])];
		} else {
			@string[@i] = @chars[rand(array_size(@chars))];
		}
	}
	return(array_implode(@string, ''));
}

proc _progressbar(@value, @size, @chars, @colormode = 'over', @fillempty = true) {
	if(!is_array(@size)) { @size = array(); }
	if(!is_array(@chars)) { @chars = array(); }
	#min, max, bar length
	if(is_associative(@size) || array_size(@size) != 3) { @size = array(0, 20, 10); }
	#Full, partial, empty
	if(is_associative(@chars) || array_size(@chars) != 3) { @chars = array('|', ':', '.'); }
	if(is_numeric(@value)) {
		#Negative not supported
		if(@value < 0) { return(color(11).string_multiply(@chars[2], @size[2])); }
		@value = ceil(@value);
	} else {
		if(function_exists('pinfo')) {
			try {
				@value = ceil(pinfo(@value)[5]);
			} catch(Exception @ex) {
				@value = 'NotFound';
			}
		}
	}
	if(!is_numeric(@value)) { throw('CastException', 'Non-Numeric value given to the progress bar.'); }
	@bar = '';
	@colors = array();
	@colorIndex = 0;
	@getColorIndex = iclosure(@ex) {
		@c = 0;
		switch(@ex) {
		case 0:
			@c = 0;
		case 1..20:
			@c = 1;
		case 21..35:
			@c = 2;
		case 36..40:
			@c = 3;
		case 41..50:
			@c = 4;
		case 51..60:
			@c = 5;
		case 61..75:
			@c = 6;
		case 76..80:
			@c = 7;
		case 81..100:
			@c = 8;
		default:
			@c = 9;
		}
		return(@c);
	}
	# Set Colors to use:
	# 0, 1-20, 21-35, 36-40, 41-50, 51-60, 61-75, 76-80, 81-100, 101+%
	switch(@colormode){
	case 'rainbow':
		@colors = array(8, 12, 6, 14, 10, 11, 9, 13, 13, 5);
	case 'under':
	case 'r-under':
		@colors = array(8, 2, 2, 14, 14, 14, 14, 4, 4, 11);
	case 0..15:
	case 'f':
		array_resize(@colors, 10, @colormode);
		@colors[0] = 8;
		@colors[9] = 11;
	case 'r-over':
	case 'over':
	default:
		@colors = array(8, 4, 4, 14, 14, 14, 14, 2, 2, 11);
	}
	@colorIndex = @getColorIndex(integer((@value / @size[1]) * 100));
	@sectorPts = @size[1] / @size[2];
	@fillLength = @value / @sectorPts;
	@multiColor = string_starts_with(@colormode, 'r');
# Assemble Bar
	#Full
	if(!@multiColor) { @bar .= color(@colors[@colorIndex]); }
	@bar .= string_multiply(@chars[0], integer(@fillLength));
	#Middle
	if(is_double(@fillLength)) {
		if(@fillLength - integer(@fillLength) > .4) { @bar .= @chars[1]; }
	}
	#Empty
	if(@fillempty && length(strip_colors(@bar)) < @size[2]) { 
		if(@multiColor) { 
			@bar .= string_multiply(@chars[2], @size[2] - length(@bar)); 
		} else {
			@bar .= string_multiply(color(@colors[0]).@chars[2], @size[2] - length(strip_colors(@bar))); 
		}
	}
# Colorize and Return Bar
	if(!@multiColor) {
		return(@bar);
	} else if(@colorIndex === 9) {
		# Out of range
		return(color(@colors[9]).@bar);
	} else {
		# Add Colors for each position
		@bar2 = '';
		foreach(@i: @c in split('', @bar)) {
			@j = @i + 1;
			#empty
			if(@c === @chars[2]) {
				@bar2 .= color(@colors[0]).@c;
				continue();
			}
			@posPercent = integer((@sectorPts * @j) / @size[1] * 100);
			@bar2 .= color(@colors[@getColorIndex(@posPercent)]).@c;
		}
		return(@bar2);
	}
}


#-----------
# Minecraft only functions:

#Find player UUID when given a player NAME.
#returns array of name, displayname, nickname, and UUID
proc _getplayerID(@findID, @retType = 'array', @dashType = 'dashless') {
	if(function_exists('player')) {
		@pid = array();
		@uuiddata = import('primus.database.UUID');
		if(!is_array(@uuiddata)) { @uuiddata = array(); }
		if(reg_count('^~?console$', @findID) > 0 || reg_count('^~?[Ss]erver$', @findID) > 0) {
			@pid = array('display': 'Console', 'name': '~console', 'id': 'console', 'nick': 'Server Console');
		} else {
			try {
				@pid['id'] = puuid(@findID, 'dashless');
			} catch(Exception @ex) {
				#puuid throws exception if not found.
				#if ID not found: search uuid for playername
				foreach(@k: @v in @uuiddata) {
					if(equals_ic(@findID, @v[0])) { 
						@pid['id'] = @k;
						break();
					}
				}
			}
			#not sure what to return yet
			if(!array_index_exists(@pid, 'id')) { @pid['id'] = null; }
				
			#if found in database
			if(array_index_exists(@uuiddata, @pid['id'])) {
				@pid['name'] = @uuiddata[@pid['id']][0];
				@pid['display'] = @uuiddata[@pid['id']][0];
				if(ponline(@pid['name']) === true) {
					@pid['nick'] = pinfo(@pid['name'])[4];
				} else {
					@pid['nick'] = @uuiddata[@pid['id']][2];
				}
			} else {
			#not found in database
				if(ponline(@findID) === true) {
					@pid['display'] = pinfo(@findID)[0];
					@pid['name'] = pinfo(@findID)[0];
					@pid['nick'] = pinfo(@findID)[4];
				} else {
					@pid['display'] = @findID;
					@pid['name'] = @findID;
					@pid['nick'] = 'Player Offline'		
				}
			}
		}
		#Bedrock to Java players come in with name ".NAME", remove dot
		if(reg_count('^[\\.].*', @pid['name']) == 1) {
			@pid['display'] = reg_replace('^[\\.]', '', @pid['name']);
		}
		switch(string(@retType)) {
		case 'true':
		case 'false':
		case 'boolean':
			if(@pid['id'] == null) { return(false); } else { return(true); }
		case 'string':
		case 'id':
			return(@pid['id']);
		case 'array':
			return(@pid);
		}
	} else {
		return('Running in Command Line');
	}
}

#Find player NAME when given a UUID.
proc _getplayerName(@findID) {
	if(function_exists('player')) {
		@pid = array();
		@uuiddata = import('primus.database.UUID');
		if(reg_count('^~?console$', @findID) > 0 || reg_count('^~?[Ss]erver$', @findID) > 0) {
			@pid = array('display': 'Console', 'name': '~console', 'id': 'console', 'nick': 'Server Console');
		} else {
			try {
			#throws exception if player offline
				@pid['name'] = player(@findID);
				@pid['display'] = player(@findID);
				@pid['nick'] = pinfo(@pid['name'])[4]
				@pid['id'] = @findID;
			} catch(Exception @ex) {
				#puuid/player throws exception if not found.
				#if ID not found: search uuid for playername
				foreach(@k: @v in @uuiddata) {
					if(equals_ic(@findID, @k)) { 
						@pid['id'] = @k;
						@pid['name'] = @v[0];
						@pid['display'] = @v[0];
						@pid['nick'] = @v[2];
						break();
					}
				}
			}
			if(!array_index_exists(@pid, 'name')) {
				@pid = array('display': 'null', 'name': null, 'id': null, 'nick': 'ID not Valid');
			}
		}
		return(@pid);
	} else {
		return('Running in Command Line');
	}
}

proc _primus_database_add(@player, @type, @data, @option) {
	if(@player == '' || @player == null) { return('No Player Given'); }
	if(function_exists('player')) {
		@update = false;
		switch(@type) {
		case 'uuid':
		# Setup Player UUID Database
			if(@data == '' || @data == null) { @data = puuid(@player, 'dashless'); }
			@uuiddata = import('primus.database.UUID');
			#entry found	
			if(array_index_exists(@uuiddata, @data)) {
									#Name, World location, Nickname
				@uuiddata[@data] = array(pinfo(@player)[0], pinfo(@player)[1], pinfo(@player)[4]);
			} else {
			#entry not found
				#if array key not set, @array[key] does not work
				@uuiddata[@data] = array(pinfo(@player)[0], pinfo(@player)[1], pinfo(@player)[4]);
				broadcast(color(7).'Welcome '.color('a').player().color(7).' to the server! It\'s their first time here!');
			}
			@update = true;
			if(@update === true) {
				store_value('primus.database.UUID', @uuiddata);
				export('primus.database.UUID', @uuiddata);
			}
		case 'ip':		
		# Setup Player IP Database
			@ipdata = import('primus.database.IP');
			if(!array_index_exists(@ipdata, '_hostname')) { @ipdata['_hostname'] = array(); }
			#entry found
			if(@data == '' || @data == null) { @data = pinfo(@player)[3]; }
			if(@option == '' || @option == null) { @option = pinfo(@player)[10]; }
			@ip = reg_replace('[%][0]$', '', @data);
			if(array_index_exists(@ipdata, @ip)) {
				#IP entry found
				if(array_contains(@ipdata[@ip], @player)) {
					#both IP and player found
					tmsg(@player, color('a').'Welcome back'.color(7).' to the server, glad you are here!');
				} else {
					#IP entry found, but player not found
					array_push(@ipdata[@ip], @player);
					@update = true;
				}
			} else {
				#IP entry not found
				@ipdata[@ip] = array(@player);
				@update = true;
			}
			if(@update === true) {
				@ipdata['_hostname'][@ip] = @option;
				store_value('primus.database.IP', @ipdata);
				export('primus.database.IP', @ipdata);
			}
		default:
			return('Unsupported Action');
		}
		return(true);
	} else {
		return('Running in Command Line');
	}
}