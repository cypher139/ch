#version 1.0-tmc
#Handle commands from Discord Users
# discord: userid, username, nickname, channel, message, id, attachments {{url, filename, description}}
	
	
proc _chat_process_batchfile(@lines, @discord, @dm, @listonly) {
	@config = import('Chat.config.Discord')	
	@options = parse_args(@lines[0])
	if(array_index_exists(@options, 0)) {
		foreach(@opt in @options) {
			if(reg_count('^[-][-]+', @opt) == 0) { continue() }
			switch(reg_replace('^[-][-]+', '', @opt)) {
			case 'pm':
			case 'dm':
			case 'message':
				@dm = 'dm'
			case 'b':
			case 'broad':
			case 'broadcast':
				@dm = 'broadcast'
				
			}
		}
	}
	if(@dm == '') { @dm = 'broadcast' }
	if(is_array(@discord)) {
		if(!array_index_exists(@discord, 'userid')) {
			console('[Chat - Discord] Required data array not given to Command Handler!', false)
			return(false)
		}
	} else {
		console('[Chat - Discord] Required data array not given to Command Handler!', false)
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
			console(@i.'lineargs')
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
		console(@line)
		# No Prefix
		if(reg_count(@config['CMD_Command_Prefix'], @line) == 0) { console(@i.'no prefix') continue() }
		@discord['message'] = @line
		@return = _chat_handlecommand(@discord, @senddm, 'batch')
		array_push(@returns, @return)
	}
	return(@returns)
}		
		


proc _chat_handlecommand(@discord, @dm, @cmdfrom) {
	@config = import('Chat.config.Discord')
	if(is_array(@discord)) {
		if(!array_index_exists(@discord, 'userid')) {
			console('[Chat - Discord] Required data array not given to Command Handler!', false)
			return(false)
		} else {
			if(!array_index_exists(@discord, 'time')) {
				array_set(@discord, 'time', time())
			}
		}
	} else {
		console('[Chat - Discord] Required data array not given to Command Handler!', false)
		return(false)
	}
	@return = ''
	
	# Include Commands Actions
	include_dir('command.library')
	switch(@dm) {
	case 'dm':
	case 'pm':
	case 'message':
		@dm = 'dm'
		array_set(@discord, 'SendChannel', @discord['userid'])
	case '':
	default:
		@dm = 'broadcast'
		array_set(@discord, 'SendChannel', @discord['channel'])
	}
	array_set(@discord, 'UseDM', @dm)
	
	switch(@cmdfrom) {
	case 'dm':
		@cmdfrom = ' in DM'
	case 'batch':
		@cmdfrom = ' (via Batch file)'
	default:
		@cmdfrom = ''
	}
	
	@membersID = import('server.Discord.members.ID')
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
	}
	@membersnames = import('server.Discord.members.names')
	if(!array_contains(@membersnames, @discord['userid'])) {
		array_set(@membersnames, @discord['username'], @discord['userid'])
	}
/*	
	# Find if this is a wish or normal chat.
*/	

#Check User Permissions
	#to  check: does get roles work in a dm
	@userType = 'User'
	try (
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
		foreach(@role in @userroles) {
			if(array_contains_ic(@config['Role_Admins'], @role)) {
				@userType = 'Admin'
				break()
			}
		}
	)
#Compute cmd list
	@aliaseslist = array()
	@admincommandlist = array()
# List of Admin Only commands:
	@admincommandlist = import('Chat.Discord.Command.List.Admin', array())
	@aliaseslist = import('Chat.Discord.Command.List.Alias', array())
	@actions = import('Chat.Discord.Command.List', array())
	@commandlist = array_keys(@actions)
/*
	console(@admincommandlist)
	console(@aliaseslist)
	console(@commandlist)
*/
# Extract Command
	@command = parse_args(reg_replace(@config['CMD_Command_Prefix'], '', @discord['message']))
# No Command Given
	if(!array_index_exists(@command, 0)) {
		_send_discord_message(array('embeds': array(array('description': 'Ooooh! I can\'t wait to see what command you enter next!', 'footer': array('text': '...or not'), 'image': 'https://media.tenor.com/hrg1biY9FbsAAAAC/awesome-minions.gif'))), 'none', @discord['SendChannel'], @discord['UseDM'])	
		return('NoCmdGiven')
	}
#No mentions
	@command[0] = reg_replace('@', '', @command[0])
# Setup Arguments
	if(array_index_exists(@command, 1)) {
		@args = @command[cslice(1, array_size(@command) - 1)]
	} else {
		@args = array()
	}
#check ************ : @here cmd @here does it remove "@here cmd" due to index shift

	if(is_string(@command[0])) { @command[0] = to_lower(@command[0]) }
	if(array_index_exists(@args, 0)) { 
# Remove mention in arguments 
		@rmargs = array()
		foreach(@i: @entry in @args) {
			if(_array_string_contains(@config['Banned_Mentions'], @entry)) {
				array_push(@rmargs, @entry)
				array_remove(@args, @i)
			}
		}
		if(array_index_exists(@rmargs, 0)) {
			@rmargs = array_implode(array_unique(@rmargs), ', ')
			_msgAdmins(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Removed "'.@rmargs.'" from '.@discord['username'].'\'s command arguments.')
			discord_broadcast(@config['Log_Channel'], 'Removed `'.@rmargs.'` from '.@discord['username'].'\'s command arguments.')	
			if(@config['Message_On_Mention'] == true) { discord_private_message(@discord['userid'], '[Chat] Mention(s) `'.@rmargs.'` are not allowed on the server.') }
		}
		@commanddismc = 'Args: '.color(9).array_implode(@args, ', ')
		@commanddisdc = 'Args: `'.array_implode(@args, '`  `').'`' 
		if(!array_index_exists(@args, 0)) { @commanddisdc = '' }	
	} else { @commanddismc = '' @commanddisdc = '' }
	
# Deny Admin commands	
	if(array_contains_ic(@admincommandlist, @command[0]) && @userType != 'Admin') {
		console('[Discord] '.@discord['username'].' tried to use an admin command'.@cmdfrom.': '.color(3).@command[0].'  '.color('r').@commanddismc, false)
		_send_discord_message(@discord['username'].' tried to use admin command'.@cmdfrom.': `'.@command[0].'`  '.strip_colors(@commanddisdc), 'admin', '')
		return('NotAdmin')
	}

# make 1 letter aliases

# Execute command action 
	if(array_index_exists(@actions, @command[0])) {
		@return = @actions[@command[0]](@discord, @args);
	} else {
		_send_discord_message('I have no idea what that command was about, try help.', 'command', @discord['SendChannel'], @discord['UseDM'])
		@lastmsgs = get_value('Chat.Discord.last.cmd.not.found')
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		@fail = array('time': time(), 'user': @discord['username'], 'command': @command[0], 'args': @args)
		array_insert(@lastmsgs, @fail, 0)
		if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
		store_value('Chat.Discord.last.cmd.not.found', @lastmsgs)
		console('[Discord] '.@discord['username'].' tried to use non-existent command'.@cmdfrom.': '.color('e').@command[0].'  '.color('r').@commanddismc, false)
		return('NotACmd')
	}

/*
should get array closure return. chat procs need to return to closure
auto includes messages final message, unless true/false. multiple messages need to be handled by action
ex.:	_send_discord_message(return, 'discord', @discord['SendChannel'], @discord['UseDM'])
return may be an array or string too
nocmd return: 		_send_discord_message('A required command module is not installed.', 'command', @discord['SendChannel'], @discord['UseDM']) returnfalse
*/
console('ret: '.@return)
console('retis: '.is_string(@return))
#Save Recent Messages and Returns for reference	
	array_set(@discord, 'return', @return)
	@lastmsgs = import('Chat.Discord.last.cmd.message')
	if(!is_array(@lastmsgs)) { @lastmsgs = array() }
	array_insert(@lastmsgs, @discord, 0)
	if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
	export('Chat.Discord.last.cmd.message', @lastmsgs)

	@lastmsgs = import('Chat.Discord.last.cmd.message.return')
	if(!is_array(@lastmsgs)) { @lastmsgs = array() }
	array_insert(@lastmsgs, @return, 0)
	if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
	export('Chat.Discord.last.cmd.message.return', @lastmsgs)
	
#Send Messages
	if(is_string(@return)) {
		if(@return == 'NoCmd') {
			_send_discord_message('A required command module is not installed.', 'command', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'pong') {
			@timeElapsed = (time() - @discord['time'])
			_send_discord_message('Pong! ('.(@timeElapsed / 1000).')', 'command', @discord['SendChannel'], @discord['UseDM']) 
			@return = true
		} else {
			_send_discord_message(@return, 'discord', @discord['SendChannel'], @discord['UseDM'])
			@return = true
		}
	} else if(is_array(@return)) {
		if(array_index_exists(@return, 'content') || array_index_exists(@return, 'embeds')) {
			_send_discord_message(@return, 'discord', @discord['SendChannel'], @discord['UseDM'])
			@return = true
		} else {
			_send_discord_message(@discord['username'].'\'s command `'.@command[0]'` failed: '.@return, 'admin', '')
			@return = false
		}
	}
# Send Log Messages and End.
	if(@return == true) { @colorret = 3 @retdisplay = '' } else { @colorret = 'c' @retdisplay = ' (Failed)' }
	console('[Discord] '.@discord['username'].' used command'.@cmdfrom.': '.color(@colorret).@command[0].'  '.color('r').@commanddismc.color('r').@retdisplay, false)
	_send_discord_message(@discord['username'].' used command'.@cmdfrom.' `'.@command[0].'`  '.strip_colors(@commanddisdc).@retdisplay, 'admin', '')
	return(@return)
}