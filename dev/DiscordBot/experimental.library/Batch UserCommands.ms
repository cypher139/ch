# Experimental support for commands via uploading batch files. 
# Currently not finished or worked on for some time, so moved to experimental.

# temp defines for code analysis
@discord = array()
@dm = false

## Auto includes:
proc _discordBot_process_batchfile(@lines, @discord, @dm, @listonly) {
	@config = import('DiscordBot.config.Bot')	
	@options = parse_args(@lines[0])
	if(array_index_exists(@options, 0)) {
		foreach(@opt in @options) {
			if(reg_count('^[-][-]+', @opt) == 0) { continue() }
			switch(reg_replace('^[-][-]+', '', @opt)) {
			case 'pm':
			case 'dm':
			case 'message':
				@dm = true
			case 'b':
			case 'broad':
			case 'broadcast':
				@dm = false
				
			}
		}
	}
	if(@dm == '') { @dm = false }
	if(is_array(@discord)) {
		if(!array_index_exists(@discord, 'userid')) {
			_db_msg_Console('Required data array not given to Command Handler!', @discord['serverid'], 'debug')
			return(false)
		}
	} else {
		_db_msg_Console('Required data array not given to Command Handler!', @discord['serverid'], 'debug')
		return(false)
	}
	@return = ''
	@returns = array()
	@senddm = @dm
	# return returns?
	@nextline = false
	foreach(@i: @line in @lines) {
		@senddm = @dm
		if(@i == 0) {continue()}
		# No comments
		if(reg_count('^[#/]+', @line) > 0) { continue() }
		# Command arguments
		if(reg_count('^[-][-]+', @line) > 0) {
			@linearg = parse_args(reg_replace('[-][-]', '', @line))
			if(array_index_exists(@linearg, 0)) {
			_db_msg_Console(@i.'lineargs', @discord['serverid'], 'debug')
				foreach(@j: @arg in @linearg) {
					switch(@arg) {
					#if --prev true/false, if last command returned match then run this, else no.
					case 'prev':
					case 'previous':
					case 'return':
						if(@i != 1 && string(to_lower(@linearg[(@j + 1)])) != string(@returns[-1])) { @nextline = true break() }
					case 'dm':
						@senddm = 'dm'
					case 'broadcast':
						@senddm = 'broadcast'
					case 'catch':
					case 'else':
					#run if preceding was false
						if(@i != 1 && string(@returns[-1]) == 'true') { @nextline = true break() }
					default:
						if(reg_count(@config['CMD_Command_Prefix'], @arg) > 0) { 
							#end of options
							@line = 'ch.'.reg_split(@config['CMD_Command_Prefix'], @line)[1]		
							break()
						}
					}						
				}
			}
		}
		if(@nextline == true) {
			@nextline = false
			continue()
		}
		_db_msg_Console(@line, @discord['serverid'], 'debug')
		# No Prefix
		if(reg_count(@config['CMD_Command_Prefix'], @line) == 0) { _db_msg_Console(@i.'no prefix', @discord['serverid'], 'debug') continue() }
		@discord['message'] = @line
		@return = _discordBot_handlecommand(@discord, @senddm, 'batch')
		@returns[] = @return
	}
	return(@returns)
}		

## Usercommands:
		if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
			@returns = array()
			foreach(@i: @attach in @discord['attachments']) {
				if(reg_count('[.][Tt][Xx][Tt]$', @attach['filename']) > 0) {
					#istxt
					#make http call
					# variables scoped, does not provide edits back.
					http_request(@attach['url'], array('blocking': true, 'success': closure(@data) {
						export('debug_data_'.@i, @data);
						if(@data['error'] == false) {
						#is first line approved batch #!Chat_Command_Batch
						
						# CMD_Default_Channel for broadcast option
						
							if(reg_count('^#!Chat_Command_Batch', @data['body']) > 0) {
								@commands = reg_split('\r?\n', @data['body'])
								@commands[0] = reg_replace('^#!Chat_Command_Batch', '', @commands[0])
								# send to proc
								@return = _discordBot_process_batchfile(@commands, @discord, @dm)
							}
						} else {
							_db_msg_Console('Processing Batch file failed: '.@data, @discord['serverid'])
						}
					}));

	# return array of returns?

	# returns array:
					# error: false, reponseCode: 200, responseText: OK, body: all attachment file's lines
					# variables scoped, does not provide edits back.
					# crashes server if closure returns commands
					
				}
			}
		}