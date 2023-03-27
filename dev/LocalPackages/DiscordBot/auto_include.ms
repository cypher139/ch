### Core Startup
if(in_cmdline_mode()) {
	export('DiscordBot.version', '1.0-tmc-cmd')
	export('DiscordBot.config.dir', file_resolve(pwd().'/Configs'))
	export('DiscordBot.logs.dir', file_resolve(pwd().'/Logs'))
} else {
	export('DiscordBot.version', '1.0-tmc')
	export('DiscordBot.config.dir', file_resolve(sys_properties()['user.dir'].'/plugins/CommandHelper/LocalPackages/DiscordBot/Configs'))
	export('DiscordBot.logs.dir', file_resolve(sys_properties()['user.dir'].'/plugins/CommandHelper/LocalPackages/DiscordBot/Logs'))
}

### Functions

proc _db_msg_Admins(@msg, @consolemsg, @cmconcat, @hideplayer) {
	if(@consolemsg == '' || @consolemsg == null || @consolemsg == 'msg') { @consolemsg = @msg }
	if(@cmconcat != '') { @consolemsg = @msg.@consolemsg }
	console(@consolemsg, false)
	#Broadcast to MC server, if available
	if(function_exists('all_players')) {
		foreach(@p in all_players()) {
			if(has_permission(@p, 'commandhelper.alias.admin.message') && @p != @hideplayer) { tmsg(@p, @msg) }
		}
	}
}

/*
proc _is_Command(@line) {
	return(string_starts_with(@line, '~'));
}
*/

proc _db_load_config(@cfgtype, @prefix = 'DiscordBot') { 
	if(@cfgtype == '' || @cfgtype == null) { @cfgtype = 'Discord' }
	@loadcfg = ''
	try {
		@loadcfg = yml_decode(read(import(@prefix.'.config.dir').'/'.@cfgtype.'.yml'))
	} catch(IOException @ex) {
		_db_msg_Admins(color(12).'[Chat] '.@cfgtype.' Config file could not be read. ', @ex['message'], true)
		return(false)
	} catch(FormatException @ex) {
		_db_msg_Admins(color(12).'[Chat] '.@cfgtype.' Config file is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']), true) 
		return(false)
	} catch(Exception @ex) {
		_db_msg_Admins(color(12).'[Chat] There was an error with the '.@cfgtype.' Config file. ', @ex['message'], true) 
		return(false)
	}
#Checks:
	switch(string(@cfgtype)) {
	case 'Server':
		if(array_index_exists(@loadcfg, 'Not_Configured')) {
			_db_msg_Admins(color(12).'[Chat - Server] Server Config file is still using the default values. Please configure it to your needs!')
			return(false)
		}
	case 'Discord':
		if(!function_exists('discord_connect')) { 
			console('CHDiscord extension not installed!')
			return(false)
		}
		if(array_contains(@loadcfg['Channels_Receive'], 'default')) {
			_db_msg_Admins(color(12).'[Chat - Discord] Config file is still using default values. Please configure it in order to use various Discord features.') 
			return(false)
		}
		if(@loadcfg['VC_Role_ID'] == 123) {
			_db_msg_Admins(color(14).'[Chat - Discord] Voice Chat Config is still using defaults. Please configure it in order to use the VC Role Ping feature.') 
		}
		if(@loadcfg['Welcome_Text_Channel_Name'] == 'default') {
			_db_msg_Admins(color(14).'[Chat - Discord] Member Config is still using defaults. Please configure it in order to use the Welcome Message feature.') 
		}
	case 'Experimental':
	case 'ex':
		@dcfg = import('DiscordBot.config.Discord')
		@loadcfg = array_merge(@loadcfg, @dcfg)
		if(array_contains(@loadcfg['CS_Server_1_Channels'], 'default')) {
			_db_msg_Admins(color(14).'[Chat - Discord] Cross server Config is still using default values. Please configure it in order to use Cross-Server chat features.') 
		}
	}
	export(@prefix.'.config.'.@cfgtype, @loadcfg)
	return(@loadcfg)
}

proc _db_message_check_ban_mentions(@message, @from, @option) {
	@config = import('Chat.config.Server', _db_load_config('Server'))
# Check if player said banned Discord mention
	@msga = parse_args(@message)
	@msgban = ''
	if(in_cmdline_mode() == false) { @from = _getplayerID(@from) }
	@prefix = color(6).'['.color(9).'Server'.color(6).'] '
	foreach(@entry in @config['Banned_Mentions']) {
		if(_array_string_contains(@msga, @entry)) {
			if(function_exists('player')) {
				@prevmentions = get_value('server.player.'.@from['id'].'all.ping.mention')
				store_value('server.player.'.@from['id'].'.all.ping.mention', @prevmentions + 1)
				if(array_contains(get_offline_players(), @from['name'])) { 
					if(@config['Message_On_Mention'] == true) { tmsg(@from['name'], color('c').'[Chat] Do not mention "'.@entry.'".') }
					if(@config['Kick_On_Mention'] == true) { 
						pkick(@from['name'], '[Chat] Do not mention "'.@entry.'".')
						@msgbantype = 'kicked'
						if(@prevmentions > @config['Ban_On_Mention_Number'] && @config['Ban_On_Repeat_Mention'] == true) {
							set_pbanned(@from['name'], true, '[Chat] You have used disallowed mentions several times.')
							@msgbantype = 'banned'
						}
						@msgban = '  Offending player `'.@player.'` was '.@msgbantype.'.'
					}
				}
				_db_msg_Admins(@prefix.color(7).'Message from '.@from['display'].' contained a mention of "'.@entry.'".'.@msgban)
			} else {
				if(@config['Message_On_Mention'] == true) { 
					try {
						discord_private_message(@from, '[Chat] Do not mention "'.@entry.'".')
					} catch(Exception @ex) {
						console(@prefix.'Could not DM user: '. @ex, false)
					}
				}
				_db_msg_Admins(@prefix.color(7).'Message from '.@from.' contained a mention of "'.@entry.'".')
			}		
			return(array('mention': @entry, 'kickmsg': @msgban))
		}
	}
return(null)
}

# new error message: :dp: +

proc _send_discord_message(@message, @from, @channel, @type, @option) {
	if(!function_exists('discord_broadcast') || !function_exists('discord_private_message')) { return(false) }
	@config = import('DiscordBot.config.Discord')
	@normalmessage = 0
	@count = 0
	if(@message == '') { return(false) }
	if(@from == '' || is_array(@from)) { 
		if(function_exists('player')) { 
			@from = player()
		} else {
			@from = 'none'
		}
	}
	if(@channel == '') { @channel = @config['Default_Channel'] }
	if(@type == '') { @type = 'broadcast' }
	if(is_array(@message)) {
		if(array_index_exists(@message, 'content')) {
			@message['content'] = strip_colors(@message['content'])
			@count = reg_count('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @message['content'])
		}
	} else {
		@message = strip_colors(@message)
		@count = reg_count('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @message)
	
	}
	@split = array()
	@checkmention = null
	@sendmsg = ''
	# Check if player said banned mention	
	if(is_array(@message)) {
	console('msg: array')
		if(array_index_exists(@message, 'content')) {
			console('msg: content')
			@checkmention = _db_message_check_ban_mentions(@message['content'], @from)
			@sendmsg = @message['content']
		} else if(array_index_exists(@message, 'embeds')) {
			console('msg: embed only')
				@sendmsg == ''
		} else {
			console('msg: unsupported array')
			@type = 'admin'
			@sendmsg = 'A message queued to Discord was not sent: Array Content or Embeds was not given.'
		}
	} else { 
		@checkmention = _db_message_check_ban_mentions(@message, @from)
		@sendmsg = @message
	}
	if(@checkmention != null && @type != 'admin') {
		@type = 'admin'
		@sendmsg = 'A message queued to Discord was not sent: Message contained a mention of "`'.@checkmention['mention'].'`". '.@checkmention['kickmsg']
	}
	switch(to_lower(@from)) {
	case 'admin':
	case 'log':
		@channel = @config['Log_Channel']
	case 'none':
	case 'cross':
	case 'discord':
		@normalmessage = 1
	case 'server':
	case 'console':
		@sendmsg = '['.@from.'] '.@sendmsg
	case 'death':
		@sendmsg = ':skull_crossbones: '.@sendmsg
	case 'command':
		@sendmsg = ':desktop: '.@sendmsg
	case 'confirm':
		@sendmsg = ':white_check_mark: '.@sendmsg
	default:
	# Minecraft Player chat
		@sendmsg = '`['.@from.']` '.@sendmsg
	}
# Split messages longer than 2000 chars
	if(reg_count('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @sendmsg) > 1 && !is_array(@message)) {
		for(@i = 1, @i <= @count, @i++) {
			@match = reg_match('[\\s\\S]{1,1999}(?:\\s|\\S|$)', @sendmsg)[0]
			array_push(@split, @match)
			@sendmsg = @sendmsg[cslice(length(@match), (length(@sendmsg) - 1))]
		}
	}	
	switch(@type){
	case 'admin':
	case 'log':
		@channel = @config['Log_Channel']
		# console('[Chat - Discord] '.@sendmsg, false)
	}	
	try {	
		switch(@type){
		case 'admin':
		case 'broadcast':
		case 'b':
		case 'log':
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) { 
					if(@i == (array_size(@split) - 1)) {
						if(is_array(@message)) {
							if(array_index_exists(@message, 'embeds')) {
								@msg = array('content': @msg, 'embeds': @message['embeds'])
							}
						}
					}						
					discord_broadcast(@channel, @msg)
				}
			} else {
				if(is_array(@message)) {
					if(array_index_exists(@message, 'embeds')) {
						if(@sendmsg == '') {
							@sendmsg = array('embeds': @message['embeds'])
						} else {
							@sendmsg = array('content': @sendmsg, 'embeds': @message['embeds'])
						}
					}
				}
				discord_broadcast(@channel, @sendmsg)
			}
			return(true)
		case 'pm':
		case 'dm':
		case 'message':
		case 'private':
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) { 
					if(@i == (array_size(@split) - 1)) {
						if(is_array(@message)) {
							if(array_index_exists(@message, 'embeds')) {
								@msg = array('content': @msg, 'embeds': @message['embeds'])
							}
						}
					}						
					discord_private_message(@channel, @msg)
				}
			} else {
				if(is_array(@message)) {
					if(array_index_exists(@message, 'embeds')) {
						if(@sendmsg == '') {
							@sendmsg = array('embeds': @message['embeds'])
						} else {
							@sendmsg = array('content': @sendmsg, 'embeds': @message['embeds'])
						}
					}
				}
				discord_private_message(@channel, @sendmsg)
			}
			return(true)
		case 'broadcast_embed':
		case 'embed':
			if(@option == '') { @option = 'the cool bot' }
			@sayicons = array('https://cdn.discordapp.com/emojis/511919341093257266.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919341118160912.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919341281738773.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919340740673536.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919340837404672.webp?size=48&quality=lossless') 
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) { 
					@option = @option.' (Message '.(@i + 1).' of '.array_size(@split).')'
					discord_broadcast(@channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @msg, 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': @option)))))
				}
			} else {
				discord_broadcast(@channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @sendmsg))))
			}
			return(true)	
		case 'join':
			discord_broadcast(@channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': '<:join:1066426544387543080> Joined:', 'description': @sendmsg))))
			return(true)
		case 'leave':
		case 'quit':
			discord_broadcast(@channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': ' <:leave:1066426677481197618> Left: ', 'description': @sendmsg))))
			return(true)
		}
	} catch(Exception @ex) {
	#			msg(@ex)
		_db_msg_Admins(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'A message queued to Discord was not sent: '.@ex['message'])
		return(false)
	}
	
}

proc _discordBot_dc_add_member(@discord) {
	@membersID = import('DiscordBot.members.ID', get_value('DiscordBot.members.ID'))
	if(!is_array(@membersID)) { @membersID = array() }
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('DiscordBot.members.ID', @membersID)
		export('DiscordBot.members.ID', @membersID)
	}
	@membersnames = import('DiscordBot.members.names', get_value('DiscordBot.members.names'))
	if(!is_array(@membersnames)) { @membersnames = array() }
	if(!array_contains(@membersnames, @discord['userid'])) {
		array_set(@membersnames, @discord['username'], @discord['userid'])
		store_value('DiscordBot.members.names', @membersnames)
		export('DiscordBot.members.names', @membersnames)
	}
}

proc _db_mc_broadcast(@msg, @args) {
	if(function_exists('broadcast')) {
		if(!is_array(@args) && @args != '' && @args != null) { 
			if(@args == 'players' || @args == 'player') { 
				@args = all_players() 
			} else if(!array_contains(all_players(), @args)) {
				console('[DiscordBot] A Message Broadcast to Minecraft players failed: Players given were not found.', false)
				return(false)
			}
		}
		broadcast(@msg, @args)
	} else {
		if(import('DiscordBot.debug.broadcast.Console.msg') != true) {
			console('[DiscordBot] Bot Service is not running on a Minecraft server! Messages to broadcast to Minecraft players will be redirected to the console.', false)
			export('DiscordBot.debug.broadcast.Console.msg', true)
		}
		console(@msg, false)
	}
	return(true)
}

#### Command Functions

proc _discordBot_WelcomeRolesFinder(@option) {
@name = 'Discord'
	@return = array('msg': '', 'amount': '', 'list': array())
	#View Welcome or No roles.
	if(reg_count('^[WwNn]', @option) > 0) {
		@suffix = ''
		if(reg_count('^[Ww]', @option) > 0) {
			@suffix = 'welcomeroles'
			@return['msg'] = 'members were detected as having only the Welcome Roles.'
		}
		if(reg_count('^[Nn]', @option) > 0) {	
			@suffix = 'none'
			@return['msg'] = 'members were detected as having 0 roles.'
		}
		@roles = get_value('DiscordBot.members.roles.'.@suffix)
		if(is_array(@roles)) {
			@return['amount'] = array_size(@roles)
		} else {
			@return['msg'] = 'Please run the command before trying to view results!'
			return(@return)
		}
		@membernames = get_value('DiscordBot.members.names')
		if(!is_array(@membernames)) { die('plz fill members.names array') }
		foreach(@username: @userid in @membernames) {
			if(array_contains(@roles, @userid)) {
				array_push(@return['list'], @username.' <'.@userid.'>')
			}
		}
		return(@return)
	}
	
	#Save Who Has Roles
	@config = import('DiscordBot.config.Discord')
	if(@config['Welcome_Text_Channel_Name'] == '' || @config['Welcome_Text_Channel_ID'] == '') { die() }

	@membernames = get_value('DiscordBot.members.names')
	if(!is_array(@membernames)) { die('plz fill members.names array') }
	@memberroles = get_value('DiscordBot.members.roles')
	if(!is_array(@memberroles)) { die('plz fill members.roles array') }
	if(!is_array(@config['Welcome_Roles'])) { die('plz fill welcome roles config') }
	@results = array()
	@sortWR = array_sort(@config['Welcome_Roles'], 'NUMERIC')
	@usersnoroles = array()
	@userswelcomeroles = array()
	foreach(@username: @userid in @membernames) {
	try {
		@userroles = array_normalize(@memberroles[@userid])
	} catch(IndexOverflowException @ex) {
		try {
#		msg('No saved roles for: '.@username)
			@userroles = discord_member_get_roles(@userid)
			if(!array_index_exists(@userroles, 0)) {
				array_push(@usersnoroles, @userid)
				continue()
			} else {
				console('[Discord] User '.@userid.' : discord said roles: '.@userroles, false)
			}
		} catch(NotFoundException @ex) {
			console('[Discord] User '.@username.' "'.@userid.'" was not found on server.', false)
			continue()
		}
	}
		# member.roles: id: array(rolename: roleid)
	#has JUST the welcome roles awarded (amount wise)	
#	msg('ur:'.array_size(@userroles))
		if(array_size(@userroles) == array_size(@sortWR)) {
			#sort arrays so roles are in same key order
			@sortUR = array_sort(@userroles, 'NUMERIC')

			foreach(@key: @roleid in @sortWR) {
				if(@roleid == @sortUR[@key]) {
					array_push(@results, true)
				} else {
					array_push(@results, false)
				}
			}
			if(array_every(@results, closure(@value) { return(@value) }) == true) {
#				msg(@username.' <'.@userid.'> has just the Welcome Roles.')
				array_push(@userswelcomeroles, @userid)
			}
			@results = array()
		}
	}
	array_set(@return, 'zero', array_size(@usersnoroles))
	array_set(@return, 'welcome', array_size(@userswelcomeroles))
	store_value('DiscordBot.members.roles.welcomeroles', @userswelcomeroles)
	store_value('DiscordBot.members.roles.none', @usersnoroles)
	return(@return)	
}

proc _discordBot_lb_update_database(@args) {
#check for import leaderboard, and import (database lastedittime)
	@config = import('DiscordBot.config.Discord')
	@leaderboard = import('DiscordBot.Leaderboard', array('lastedit': 0));
	@lastsave = import('DiscordBot.Leaderboard.last.save', time());
	if(@leaderboard['lastedit'] > @lastsave) {
		# console('[Discord] Saved Leaderboard Database.', false)
		store_value('DiscordBot.Leaderboard', @leaderboard)
		@saveoldroles = import('DiscordBot.debug.roles.Leaderboard.undo')
		if(is_array(@saveoldroles)) {
			store_value('DiscordBot.debug.roles.Leaderboard.undo', @saveoldroles)
		}
		export('DiscordBot.Leaderboard.last.save', time())
		_write_file(import('DiscordBot.logs.dir').'/Leaderboard_'.reg_replace('\\s', '_', @leaderboard['guild']['name']).'.json', json_encode(@leaderboard), 'OVERWRITE')
	}
	# } else { console('nosave') }
}

proc _discordBot_lb_levelXP(@args) {
@levelxp = array(0, 100)
array_resize(@levelxp, 200)
@mp = 1
foreach(@i: @lvl in @levelxp) {
	if(@i < 2) { continue() }
	# Define XP needed to reach each level, as a multiplier of level 1 100xp + previous level
	switch(@i) {
	case 2:
		@mp = 2.5
	case 3:
		@mp = 2
	case 4:
		@mp = 1.7
	case 5:
		@mp = 1.5
	case 6:
		@mp = 1.4
	case 7:
		@mp = 1.3
	case 8..11:
		@mp = 1.25
	case 12..15:
		@mp = 1.2
	case 16..22:
		@mp = 1.15
	case 23..32:
		@mp = 1.1
	case 33..39:
		@mp = 1.08
	case 40..49:
		@mp = 1.06
	case 50..69:
		@mp = 1.05
	case 70..79:
		@mp = 1.04
	case 80..89:
		@mp = 1.03
	case 90..109:
		@mp = 1.025
	case 110..134:
		@mp = 1.02
	case 135..159:
		@mp = 1.015
	case 160..169:
		@mp = 1.013
	case 170..200:
		@mp = 1.01
	}
	@levelxp[@i] = integer(@levelxp[(@i - 1)] * @mp)
}
export('DiscordBot.Leaderboard.levelXP', @levelxp)
}

#Handle commands from Discord Users
# discord: userid, username, nickname, channel, message, id, attachments {{url, filename, description}}
proc _discordBot_process_batchfile(@lines, @discord, @dm, @listonly) {
	@config = import('DiscordBot.config.Discord')	
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
		@return = _discordBot_handlecommand(@discord, @senddm, 'batch')
		array_push(@returns, @return)
	}
	return(@returns)
}		
		


proc _discordBot_handlecommand(@discord, @dm, @cmdfrom) {
	@config = import('DiscordBot.config.Discord')
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
	
/*	
	# Find if this is a wish or normal chat.
*/	

#Check User Permissions
	#to  check: does get roles work in a dm
	@userType = 'User'
	@isAdmin = false
	try (
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
		foreach(@role in @userroles) {
			if(array_contains_ic(@config['Role_Admins'], @role)) {
				@userType = 'Admin'
				@isAdmin = true
				break()
			}
		}
	)
#Compute cmd list
	@aliaseslist = array()
	@admincommandlist = array()
# List of Admin Only commands:
	@admincommandlist = import('DiscordBot.Command.List.Admin', array())
	@aliaseslist = import('DiscordBot.Command.List.Alias', array())
	@actions = import('DiscordBot.Command.List', array())
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
			_db_msg_Admins(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Removed "'.@rmargs.'" from '.@discord['username'].'\'s command arguments.')
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
	array_set(@discord, 'admin', @isAdmin)
# make 1 letter aliases

# Execute command action 
	if(array_index_exists(@actions, @command[0])) {
		@return = @actions[@command[0]](@discord, @args);
	} else {
		_send_discord_message('I have no idea what that command was about, try help.', 'command', @discord['SendChannel'], @discord['UseDM'])
		@lastmsgs = get_value('DiscordBot.last.cmd.not.found')
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		@fail = array('time': time(), 'user': @discord['username'], 'command': @command[0], 'args': @args)
		array_insert(@lastmsgs, @fail, 0)
		if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
		store_value('DiscordBot.last.cmd.not.found', @lastmsgs)
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
	@lastmsgs = import('DiscordBot.last.cmd.message')
	if(!is_array(@lastmsgs)) { @lastmsgs = array() }
	array_insert(@lastmsgs, @discord, 0)
	if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
	export('DiscordBot.last.cmd.message', @lastmsgs)

	@lastmsgs = import('DiscordBot.last.cmd.message.return')
	if(!is_array(@lastmsgs)) { @lastmsgs = array() }
	array_insert(@lastmsgs, @return, 0)
	if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
	export('DiscordBot.last.cmd.message.return', @lastmsgs)	
#Send Messages
	if(is_string(@return)) {
		if(@return == 'NoCmd') {
			_send_discord_message('A required command module is not installed.', 'command', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'NotAdmin') {
			_send_discord_message(':no_entry: This command is restricted to use by Admin only.', 'discord', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'NoUserFound') {
			_send_discord_message(':question: User ID given not found on server.', 'discord', @discord['SendChannel'], @discord['UseDM']) 
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


proc _discordBot_cmd_proc_finduserID(@target, @discord) {
	@config = import('DiscordBot.config.Discord')
	@membernames = get_value('DiscordBot.members.names')
	if(!is_array(@membernames)) { @membernames = array() }
	if(is_numeric(@target)) {
		if(@target == @config['Bot_ID']) {
			return('bot')
		}
		if(@target == @discord['userid'] && @discord['UseDM'] != 'dm') {
			return('self')
		}	
		try {
			@memberroles = discord_member_get_roles(@target)
		} catch (NotFoundException @ex) {
			console('[Chat - Discord] User ID given not found on server: '.@target.'!', false)
			return('notfound')
		}
		return(@target)
	} else {
		if(reg_count('^'.@config['Bot_Name'].'[#]?[0-9]{0,4}?$', @target) > 0) {
			return('bot')
		}
		@targetmatches = _array_string_match(array_keys(@membernames), @target)
		if(reg_count('[#][0-9]{4}$', @target) > 0 && !array_index_exists(@targetmatches, 0)) {
			@target = reg_replace('[#][0-9]{4}$', '', @target)
			@targetmatches = _array_string_match(array_keys(@membernames), @target)
		}
		if(equals_ic(@target, @discord['username']) || equals_ic(@target, @discord['nickname'])) {
			return('self')
		}	
		console('[Chat - Discord] finduserID debug: match: '.@targetmatches)
		
		if(!array_index_exists(@targetmatches, 0)) {
			console('[Chat - Discord] Could not find user ID for '.@target.'!', false)
			return('notfound')
		} else if(array_index_exists(@targetmatches, 1)) {
			discord_private_message(@discord['userid'], 'I found multiple users; I\'m not sure which one you meant to apply this command to. Users Matched: \n'.array_implode(@targetmatches, ', '))
			console('[Chat - Discord] finduserID: Found multiple users, Users Matched: \n'.array_implode(@targetmatches, ', '), false)
			return('multiple')
		} else {
			return(@membernames[array_implode(@targetmatches, '')])
		}		
	}
}