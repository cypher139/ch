### Core Startup
if(in_cmdline_mode()) {
	@pf = '/'
	if(get_os() == 'WINDOWS') { @pf = '\\' }
	export('DiscordBot.version', '1.0-tmc-cmd')
	export('DiscordBot.config.dir', file_resolve(pwd().@pf.'Configs'))
	export('DiscordBot.logs.dir', file_resolve(pwd().@pf.'Logs'))
} else {
	@pf = '/'
	if(get_os() == 'WINDOWS') { @pf = '\\' }
	export('DiscordBot.version', '1.0-tmc')
	export('DiscordBot.config.dir', file_resolve(sys_properties()['user.dir'].@pf.'plugins'.@pf.'CommandHelper'.@pf.'LocalPackages'.@pf.'DiscordBot'.@pf.'Configs'))
	export('DiscordBot.logs.dir', file_resolve(sys_properties()['user.dir'].@pf.'plugins'.@pf.'CommandHelper'.@pf.'LocalPackages'.@pf.'DiscordBot'.@pf.'Logs'))
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
	_write_file(import('DiscordBot.logs.dir').'/Log-Admin-Messages.txt', simple_date('MM-dd-yy HH:mm:ss', @time).': '.@consolemsg.'\n', 'Append')
}

proc _db_msg_Console(@message, @guild, string @type = 'prefix') {
	if(@guild == '' || @guild == null || @guild == false) {
		@guild = import('DiscordBot.config.Discord')['Primary_Guild']
		console(color('e').'Nag: No guild given at: '.get_stack_trace());
	}
	@config = array()
	switch(string(@guild)) {
	case 'none':
	case 'bot':
	case 'false': 
		@config = array('Server_Nickname': 'DiscordBot', 'Console_Messages': true, 'Console_Debug': true)
	case 'debug': 
		@config = array('Server_Nickname': 'DiscordBot '.color('e').'<debug>'.color('r'), 'Console_Messages': true, 'Console_Debug': true)
	default:
		@config = import('DiscordBot.config.'.@guild)
	}
	@prefix = ''
	switch(@type) {
	case 'pre':
	case 'prefix':
		@prefix = '['.@config['Server_Nickname'].'] '
	case 'debug':
		@prefix = '['.@config['Server_Nickname'].'] '.color('e').'<debug> '.color('r')
	case 'd':
	case 'bot':
		@prefix = '[DiscordBot] '
	}
	@message = @prefix.@message
	@sendConsole = false
	if(array_index_exists(@config, 'Console_Messages')) {
		if(@config['Console_Messages'] == true) { 
			@sendConsole = true
		}
	}
	if(@guild == 'debug' || @type == 'debug') {
		@sendConsole = false
		if(array_index_exists(@config, 'Console_Debug')) {
			if(@config['Console_Debug'] == true) { 
				@sendConsole = true 
			}
		}
	}
	if(@sendConsole == true) {
		console(@message, false)
	} else {
		_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/Log-Console.txt', '['.simple_date('MM-dd-yy HH:mm:ss', time()).']: '.@message.'\n', 'Append')
	}
}


/*
proc _is_Command(@line) {
	return(string_starts_with(@line, '~'));
}
*/

proc _discordBot_set_activity(@type = '', @message = '', @url = '') {
	@config = import('DiscordBot.config.Discord')	
	if(@type == '' || @type == null) { @type = @config['Activity_Type'] }
	if(@message == '' || @message == null) { @message = @config['Activity_Message'] }
	
	@acttypes8901 = reg_split('of\\s|[,.]\\s(?:or\\s)*', reflect_docs('discord_set_activity', 'description'))[2..]
	foreach(@k: @v in @acttypes8901) {
		if(to_upper(@v) != @v) { array_remove(@acttypes8901, @k) }
	}
	if(array_contains(@acttypes8901, to_upper(@type))) {
		try {
			discord_set_activity(to_upper(@type), string(@message), @url);
		} catch(Exception @ex) {
			_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Bot Activity Message: '.color('r').@ex['message'], color(12).' ('.@ex['classType'].')', true)
		}
	} else {
		_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Selected Bot Activity Type is not supported!')
	}
}

proc _db_load_guilds(array @guilds = array()) {
	if(array_size(@guilds) == 0) { @guilds = discord_get_servers() }
	if(array_size(@guilds) == 0) { return(false) }
	@guildList = array()
	@consoleChats = array()
	foreach(@guild in @guilds) {
		if(!is_numeric(@guild)) { continue() } 
		@return = _db_load_config(@guild)
		if(!is_array(@return)) {
			continue()
		}
		if(@return['Console_Messages_Chat'] == true) {
			if(array_index_exists(@return, 'Server_Nickname')) {
				array_push(@consoleChats, @return['Server_Nickname']);
			} else if(array_index_exists(@return, 'LB_Options', 'Guild_Name')) { 
				array_push(@consoleChats, @return['LB_Options']['Guild_Name']);
			} else {
				array_push(@consoleChats, @guild);
			}
		}
		array_push(@guildList, @guild)
	}
	if(array_size(@guildList) == 0) { return(false) }
	if(array_size(@consoleChats) > 0) { 
		@s = ''
		if(array_size(@consoleChats) > 1) { @s = 's' }
		_db_msg_Console('Console receives Chat from Guild'.@s.': '.array_implode(@consoleChats, ', '), 'bot') 
	}
	export('DiscordBot.Guilds', @guildList)
	return(true)
}

proc _db_load_config(@cfgtype, @prefix = 'DiscordBot') { 
	if(@cfgtype == '' || @cfgtype == null) { @cfgtype = 'Discord' }
	@numtype = ''
	if(is_numeric(@cfgtype)) { @numtype = 'Guilds/' }
	@loadcfg = ''
	@prevcfg = import(@prefix.'.config.'.@cfgtype, array())
# Read config
	try {
		@loadcfg = yml_decode(read(import(@prefix.'.config.dir').'/'.@numtype.@cfgtype.'.yml'))
	} catch(IOException @ex) {
		@msg1 = color(12).@cfgtype.' Config file could not be read. '
		@msg2 = @ex['message']
		@color = 12
		if(@numtype == 'Guilds/') {
			@msg1 = color(9).'No config found for Guild '.@cfgtype
			@msg2 = ' ...'
			@color = 9
		}			
		_db_msg_Admins(color(@color).'['.@prefix.'] '.@msg1, @msg2, true)
		return(false)
	} catch(FormatException @ex) {
		_db_msg_Admins(color(12).'['.@prefix.'] '.@cfgtype.' Config file is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']), true) 
		return(false)
	} catch(Exception @ex) {
		_db_msg_Admins(color(12).'['.@prefix.'] There was an error with the '.@cfgtype.' Config file. ', @ex['message'], true) 
		return(false)
	}
# Checks and Startup Init
	if(is_numeric(@cfgtype)) {
		@botconfig = import('DiscordBot.config.Discord')
		array_set(@loadcfg, 'Bot_ID', @botconfig['Bot_ID'])
		array_set(@loadcfg, 'Bot_Name', @botconfig['Bot_Name'])
		if(array_contains(@loadcfg['Channels_Receive'], 'default')) {
			_db_msg_Admins(color(12).'['.@prefix.'] Config file is still using default values. Please configure it in order to use various Discord features.') 
			return(false)
		}
		if(array_index_exists(@loadcfg, 'VC_Options', '987654321')) {
			_db_msg_Admins(color(14).'['.@prefix.'] Voice Chat Config is still using defaults. Please configure it in order to use the VC Role Ping feature.') 
		}
		if(@loadcfg['Welcome_Text_Channel_Name'] == 'default') {
			_db_msg_Admins(color(14).'['.@prefix.'] Member Config is still using defaults. Please configure it in order to use the Welcome Message feature.') 
		}
		if(array_size(@prevcfg) == 0) {
			# Databases Startup
			export('DiscordBot.'.@cfgtype.'.members.ID', get_value('DiscordBot.'.@cfgtype.'.members.ID'))
			export('DiscordBot.'.@cfgtype.'.members.names', get_value('DiscordBot.'.@cfgtype.'.members.names'))
			export('DiscordBot.'.@cfgtype.'.Leaderboard', get_value('DiscordBot.'.@cfgtype.'.Leaderboard'))
			# Setup Leaderboard
			if(@loadcfg['LB_Enable'] == true) {
				if(import('DiscordBot.'.@cfgtype.'.Leaderboard.last.save') == null) {
					export('DiscordBot.'.@cfgtype.'.Leaderboard.last.save', time());
				}
				if(!is_array(import('DiscordBot.'.@cfgtype.'.Leaderboard'))) {
					export('DiscordBot.'.@cfgtype.'.Leaderboard', array('lastedit': time(), 'members': array()))
				}
			}
		}
	} else {
		switch(string(@cfgtype)) {
		case 'Server':
			if(array_index_exists(@loadcfg, 'Not_Configured')) {
				_db_msg_Admins(color(12).'[Chat - Server] Server Config file is still using the default values. Please configure it to your needs!')
				return(false)
			}
		case 'Discord':
			if(!function_exists('discord_connect')) { 
				_db_msg_Console('CHDiscord extension not installed!', 'none')
				return(false)
			}
			if(array_size(@prevcfg) > 0) {
				_discordBot_set_activity();
			}
		case 'Experimental':
		case 'ex':
			@dcfg = import('DiscordBot.config.Discord')
			@loadcfg = array_merge(@loadcfg, @dcfg)
			if(array_contains(@loadcfg['CS_Server_1_Channels'], 'default')) {
				_db_msg_Admins(color(14).'['.@prefix.'] Cross server Config is still using default values. Please configure it in order to use Cross-Server chat features.') 
			}
		default:
			_db_msg_Admins(color(12).'[DiscordBot] Config type given not supported.')
			return(false)
		}
	}
	export(@prefix.'.config.'.@cfgtype, @loadcfg)
	return(@loadcfg)
}

proc _db_message_check_ban_mentions(@message, @from, @option) {
	@config = import('DiscordBot.config.Discord')
	if(@config == '' || @config == null) { _db_load_config('Discord') }
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
						@msgban = '  Offending player `'.@from['name'].'` was '.@msgbantype.'.'
					}
				}
				_db_msg_Admins(@prefix.color(7).'Message from '.@from['display'].' contained a mention of "'.@entry.'".'.@msgban)
			} else {
				if(@config['Message_On_Mention'] == true) { 
					try {
						discord_private_message(@from, '[Chat] Do not mention "'.@entry.'".')
					} catch(Exception @ex) {
						_db_msg_Console(@prefix.'Could not DM user: '. @ex, false)
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

proc _discordBot_send_message(@message, @guild, @from, @channel, @type, @option) {
	if(!function_exists('discord_broadcast') || !function_exists('discord_private_message')) { return(false) }
	@prefixErrorMsg = color(6).'['.color(9).'DiscordBot'.color(6).'] '.color(7).'A message queued to send had a problem: '
	@botconfig = import('DiscordBot.config.Discord')
	if(@guild == '' || @guild == null) {
		#primary guild
		@guild = @botconfig['Primary_Guild']
	}
	@config = import('DiscordBot.config.'.@guild)
	if(!is_array(@config)) {
		_db_msg_Admins(color(7).'Message not sent to Discord: Guild given was not recognized')
		return(false)
	}
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
	_db_msg_Console('msg: array', @guild, 'debug')
		if(array_index_exists(@message, 'content')) {
			_db_msg_Console('msg: content', @guild, 'debug')
			@checkmention = _db_message_check_ban_mentions(@message['content'], @from)
			@sendmsg = @message['content']
		} else if(array_index_exists(@message, 'embeds')) {
			_db_msg_Console('msg: embed only', @guild, 'debug')
				@sendmsg == ''
		} else {
			_db_msg_Console('msg: unsupported array', @guild, 'debug')
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
		@channel = @config['Log_Channel']
	case 'log':
		@channel = @config['Server_Log_Channel']
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
		@channel = @config['Log_Channel']
	case 'console':
		@channel = @config['Log_Channel']
		_db_msg_Console('[Send Message] '.@sendmsg, @guild)
	case 'log':
		@channel = @config['Server_Log_Channel']
	}	
	try {	
		switch(@type){
		case 'admin':
		case 'console':
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
					discord_broadcast(@guild, @channel, @msg)
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
				discord_broadcast(@guild, @channel, @sendmsg)
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
					discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @msg, 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': @option)))))
				}
			} else {
				discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @sendmsg))))
			}
			return(true)	
		case 'join':
			discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': '<:join:1066426544387543080> Joined:', 'description': @sendmsg))))
			return(true)
		case 'leave':
		case 'quit':
			discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': ' <:leave:1066426677481197618> Left: ', 'description': @sendmsg))))
			return(true)
		}
	} catch(InsufficientPermissionException @ex) {
		@msg = @ex['message']
		if(string_ends_with(@ex['message'], 'VIEW_CHANNEL')) {
			@msg = color('c').'Bot cannot view channel: '.@channel
		}
		_db_msg_Admins(@prefixErrorMsg.@msg, '[DiscordBot] ['.@guild.'] '.@msg)
		return(false)
	} catch(NotFoundException @ex) {
		_db_msg_Admins(@prefixErrorMsg.@ex['message'], '[DiscordBot] ['.@guild.'] '.@ex['message'])
		return(false)
	} catch(Exception @ex) {
		_db_msg_Admins(@prefixErrorMsg.@ex['message'], '[DiscordBot] ['.@guild.'] '.color('c').@ex['classType'].' '.color(7).@ex['message'])
		return(false)
	}
}

proc _discordBot_dc_add_member(@discord) {
	@membersID = import('DiscordBot.'.@discord['serverid'].'.members.ID')
	if(@membersID == null) { @membersID = get_value('DiscordBot.'.@discord['serverid'].'.members.ID') }
	if(!is_array(@membersID)) { @membersID = discord_get_members(@discord['serverid']) }
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('DiscordBot.'.@discord['serverid'].'.members.ID', @membersID)
		export('DiscordBot.'.@discord['serverid'].'.members.ID', @membersID)
	}
	@membersnames = import('DiscordBot.'.@discord['serverid'].'.members.names')
	if(@membersnames == null) { @membersnames = get_value('DiscordBot.'.@discord['serverid'].'.members.names') }
	if(!is_array(@membersnames)) { @membersnames = array() }
	if(!array_contains(@membersnames, @discord['userid'])) {
		array_set(@membersnames, @discord['username'], @discord['userid'])
		store_value('DiscordBot.'.@discord['serverid'].'.members.names', @membersnames)
		export('DiscordBot.'.@discord['serverid'].'.members.names', @membersnames)
	}
}

proc _db_mc_broadcast(@msg, @args, @cr = false) {
	if(function_exists('broadcast')) {
		if(!is_array(@args) && @args != '' && @args != null) { 
			if(@args == 'players' || @args == 'player') { 
				@args = all_players() 
			} else if(!array_contains(all_players(), @args)) {
				_db_msg_Console('A Message Broadcast to Minecraft players failed: Players given were not found.', 'bot')
				return(false)
			}
		}
		broadcast(@msg, @args)
	} else {
		if(import('DiscordBot.debug.broadcast.Console.msg') != true) {
			_db_msg_Console('Bot Service is not running on a Minecraft server! Messages to broadcast to Minecraft players will be redirected to the console.', 'bot')
			export('DiscordBot.debug.broadcast.Console.msg', true)
		}
		if(@cr != true) {
			if(@args == '' || @args == null) {
				console(@msg, false)
			}
		} else {
			console(@msg, false)
		}
	}
	return(true)
}


#### Command Functions

proc _discordBot_WelcomeRolesFinder(@type, @guild) {
### REWRITE
	@botconfig = import('DiscordBot.config.Discord')
	if(@guild == '' || @guild == null) {
		#primary guild
		@guild = @botconfig['Primary_Guild']
	}
	@config = import('DiscordBot.config.'.@guild, '???')
	if(@config = '???') {
		_db_msg_Admins(@prefix.color(7).'Guild given was not recognized')
		return(false)
	}
@name = 'Discord'
	@return = array('msg': 'Invalid Option', 'amount': '', 'list': array())
	#View Welcome or No roles.
	if(reg_count('^[WwNn0]', @option) > 0) {
		@suffix = ''
		if(reg_count('^[Ww]', @option) > 0) {
			@suffix = 'welcomeroles'
			@return['msg'] = 'members were detected as having only the Welcome Roles.'
		}
		if(reg_count('^[Nn0]', @option) > 0) {	
			@suffix = 'none'
			@return['msg'] = 'members were detected as having 0 roles.'
		}
		@roles = get_value('DiscordBot.'.@guild.'.members.roles.'.@suffix)
		if(is_array(@roles)) {
			@return['amount'] = array_size(@roles)
		} else {
			@return['msg'] = 'Role Data not populated yet, please wait for auto-updates'
			return(@return)
		}
		@membernames = get_value('DiscordBot.'.@guild.'.members.names')
		if(!is_array(@membernames)) { die('plz fill members.names array') }
		foreach(@username: @userid in @membernames) {
			if(array_contains(@roles, @userid)) {
				array_push(@return['list'], @username.' <'.@userid.'>')
			}
		}
		return(@return)
	}
	return(@return)	
}

proc _discordBot_lb_update_database(@args) {
	foreach(@guild in import('DiscordBot.Guilds')) {
	#check for import leaderboard, and import (database lastedittime)
		@config = import('DiscordBot.config.'.@guild)
		if(@config['LB_Enable'] != true) {
			# _db_msg_Console('noenable', @guild, 'debug')
			return(false)
		}
		@leaderboard = import('DiscordBot.'.@guild.'.Leaderboard', array('lastedit': 0));
		@lastsave = import('DiscordBot.'.@guild.'.Leaderboard.last.save');
		if(@lastsave == null) { @lastsave = time() }
		if(@leaderboard['lastedit'] > @lastsave) {
			# _db_msg_Console('Saved Leaderboard Database.', @guild)
			store_value('DiscordBot.'.@guild.'.Leaderboard', @leaderboard)
			@saveoldroles = import('DiscordBot.'.@guild.'.debug.roles.Leaderboard.undo')
			if(is_array(@saveoldroles)) {
				store_value('DiscordBot.'.@guild.'.debug.roles.Leaderboard.undo', @saveoldroles)
			}
			export('DiscordBot.'.@guild.'.Leaderboard.last.save', time())
			_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/Leaderboard_'.reg_replace('\\s', '_', @leaderboard['guild']['name']).'.json', json_encode(@leaderboard), 'OVERWRITE')
			return(true)
		}
	# } else { _db_msg_Console('nosave', @guild, 'debug') return(false) }
	}
}

proc _discordBot_lb_process_message(@discord, boolean @noXP = false) {
	@config = import('DiscordBot.config.'.@discord['serverid'])
	if(@config['LB_Enable'] != true) { return(false) }
	@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard');
	if(@leaderboard == null) { 
		_db_msg_Console('Leaderboard data not initialized, exiting', @discord['serverid']) 
		return(false)
	}
	if(!is_array(@discord)) {
		_db_msg_Console('No data given to Leaderboard system, exiting', @discord['serverid'])
		return(false)
	}
	@userID = @discord['userid']
	@xpType = 2
	# Event consumed
	if(@noXP == true) { @xpType = 0 }
	@levelxp = import('DiscordBot.'.@discord['serverid'].'.Leaderboard.levelXP')
	if(@levelxp == null) { 
		@levelxp = _discordBot_lb_levelXP(@discord['serverid'], @config['LB_Options']['XP_Type']);
		array_set(@leaderboard['options'], 'levelXP', @levelxp)
		array_set(@leaderboard, 'Guild_Name', @config['LB_Options']['Guild_Name'])
		}
	# Do not count messages from Command spam channel or Channels marked as no XP earning.
	if(array_contains(@config['LB_Options']['NoXP_Channels'], @discord['channel'])) { @noXP = true @xpType = 0 }
	if(@discord['channel'] == @config['CMD_Default_Channel']) { @noXP = true @xpType = 0 }
	@xptimer = import('DiscordBot.'.@discord['serverid'].'.Leaderboard.xptimer', array('test': 123))
	if(!array_index_exists(@xptimer, @userID)) {
		array_set(@xptimer, @userID, (time() - 70000))
	}
	
	if(!array_index_exists(@leaderboard, 'members', @userID)) {
	#all_xp: {xp from bot spams, xp from messages in same minute, total XP}
		array_set(@leaderboard['members'], @userID, array('all_xp': array(0, 0, 0), 'last_msg': 0, 'level': 0, 'xp': 0, 'username': @discord['username'], 'msg_count': 0))
	}
	if(!array_index_exists(@leaderboard, 'members', @userID, 'all_xp', 2)) { array_set(@leaderboard['members'][@userID], 'all_xp', array(0, 0, @leaderboard['members'][@userID]['xp'])) }
	@userRoles = ''
# If user has last chatted in last rolling minute, do not award XP. (continues to count message)
	if((@xptimer[@userID] + 60000) > time()) {
		#If already true, presume botspam
		if(@noXP == false) {
			@noXP = true
			@xpType = 1
		}
	} else {
# Check if user has a no XP earning role.
		try { 
			@userRoles = discord_member_get_roles(@discord['serverid'], @userID)
		} catch(Exception @ex) {
			return(false)
		}
		foreach(@role in @userRoles) {
			if(array_contains(@config['LB_Options']['NoXP_RoleID'], @role)) {
				@noXP = true
				@xpType = 0
				break()
			}
		}
	}
# Increment Message count and XP
	@leaderboard['members'][@userID]['msg_count'] = @leaderboard['members'][@userID]['msg_count'] + 1
	@leaderboard['members'][@userID]['last_msg'] = time()
	@newxp = rand(@config['LB_Options']['XP_Per_Message'][0], @config['LB_Options']['XP_Per_Message'][1])
	#All XP:
	# 0: #botspam. Either user talked in ignored channels, has a ignored role, executed a bot command, or is a bot. Also occurs if message event was consumed (ex. showcase check).
	# 1: Another message was already counted in timeout period
	# 2: Normal message
	@leaderboard['members'][@userID]['all_xp'][@xpType] = @leaderboard['members'][@userID]['all_xp'][@xpType] + @newxp

	if(@xpType == 2) {
		@xptimer[@userID] = time()
		@leaderboard['members'][@userID]['xp'] = @leaderboard['members'][@userID]['xp'] + @newxp
	}
	# noxp true time not counted, so next immediate message (if eligible) would count and update timer

# If current XP is greater than the max for the next level:
#Levelxp: (key: xp to be at this level). to get level up need to check next level
/*
_db_msg_Console('max lvlxp for level '.@leaderboard['members'][@userID]['level'].': '.@levelxp[@leaderboard['members'][@userID]['level']], @discord['serverid'], 'debug')
_db_msg_Console('max lvlxp for next level '.(@leaderboard['members'][@userID]['level'] + 1).': '.@levelxp[(@leaderboard['members'][@userID]['level'] + 1)], @discord['serverid'], 'debug')
_db_msg_Console(@levelxp[@leaderboard['members'][@userID]['level'] + 1], @discord['serverid'], 'debug')
*/

#maxlevel
	if(!array_index_exists(@levelxp, (@leaderboard['members'][@userID]['level'] + 1))) {
		_db_msg_Console('Level Up: '.@discord['username'].' <@'.@userID.'> is at the maximum level '.@leaderboard['members'][@userID]['level'].'!', @discord['serverid'])
		export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
		return(false)
	}
#Level UP
	if(@leaderboard['members'][@userID]['xp'] > @levelxp[@leaderboard['members'][@userID]['level'] + 1] && @noXP == false) {
		@newrankname = ''
		@currentrank = ''
		@oldlevel = @leaderboard['members'][@userID]['level']
		@newlevel = @leaderboard['members'][@userID]['level'] + 1
		if(@leaderboard['members'][@userID]['xp'] > @levelxp[@newlevel + 1]) {
			#multiple level up, skip to last	
			foreach(@i: @lvl in @levelxp) {
				if(@leaderboard['members'][@userID]['xp'] < @lvl) {
					@newlevel = @i - 1
					@oldlevel = '    '.@oldlevel
					break()
				}
			}
		}				
		@leaderboard['members'][@userID]['level'] = @newlevel
		@ranknums = array_sort(array_keys(@config['LB_Options']['Role_Rewards']), 'NUMERIC')
		# _db_msg_Console(@ranknums, @discord['serverid'], 'debug')
		@oldroles = array_sort(array_normalize(@userRoles), 'NUMERIC')
	#Find rank
		@rankup = false
		foreach(@i: @rank in @ranknums) {
			@lastrank = 0
			if(@i == 0) {
				@lastrank = 0
			} else {
				@lastrank = @ranknums[(@i - 1)]
			}
			if(@newlevel == @rank) {
				@currentrank = @config['LB_Options']['Role_Rewards'][@rank]
				@newrankname = @config['LB_Options']['Role_Rewards'][@rank]['RoleName']
				@rankup = true
				break()
			}
			#In Between two ranks
			if(@newlevel < @rank && @newlevel > @lastrank) {
				#No level ups yet
				if(@lastrank == 0) { 
					break()
				} else {
					@currentrank = @config['LB_Options']['Role_Rewards'][@lastrank]
					break()
				}
			}
			#Has highest rank
			if(array_size(@ranknums) - 1 == @i && @newlevel > @rank) {
				@currentrank = @config['LB_Options']['Role_Rewards'][@rank]
				break()
			}
		}
		@userRoles = array_normalize(@userRoles)
		@saveoldroles = import('DiscordBot.'.@discord['serverid'].'.debug.roles.Leaderboard.undo')
		if(!is_array(@saveoldroles)) { @saveoldroles = get_value('DiscordBot.'.@discord['serverid'].'.debug.roles.Leaderboard.undo') }
		if(!is_array(@saveoldroles)) { @saveoldroles = array() }
		array_set(@saveoldroles, @discord['userid'], @userRoles)
		export('DiscordBot.'.@discord['serverid'].'.debug.roles.Leaderboard.undo', @saveoldroles)
		
	# Remove old role rewards
		if(@config['LB_Options']['Stack_Role_Rewards'] == false) {
			foreach(@role in @config['LB_Options']['Role_Rewards']) {
				array_remove_values(@userRoles, @role['RoleID'])
			}
		}
	# Place and Set new role
		# _db_msg_Console(@currentrank, @discord['serverid'], 'debug')
		if(@currentrank != '') {
			array_push(@userRoles, @currentrank['RoleID'])
			#Set New roles
			try { 
				discord_member_set_roles(@discord['serverid'], @userID, @userRoles, 'Role Rewards: Awarded New Rank '.@currentrank['RoleName'])
			} catch(Exception @ex) {
				return(false)
			}
		}
/*
		_db_msg_Console(@currentrank, @discord['serverid'], 'debug')
		_db_msg_Console(@oldroles, @discord['serverid'], 'debug')
		_db_msg_Console(@userRoles, @discord['serverid'], 'debug')		
*/		
# Message out
		@discordMsg = reg_replace('%UserID%', '<@'.@userID.'>', @config['LB_Options']['Level_Up_Message'])
		if(@newrankname == '') {
			@discordMsg = reg_replace('%Level%', 'Level '.@leaderboard['members'][@userID]['level'].'!', @discordMsg)
		} else {
			@discordMsg = reg_replace('%Level%', @newrankname.'!  ('.@leaderboard['members'][@userID]['level'].')', @discordMsg)
		}
		_db_msg_Console('Level Up: '.@discord['username'].' <@'.@userID.'> '.color(3).@oldlevel.color('r').' -> '.color(10).@leaderboard['members'][@userID]['level'].' '.color(6).@newrankname, @discord['serverid'])
		@sendMsg = true
		@sendMsgtoLog = false
		if(@config['LB_Options']['Level_Up_Announce_OnlyReward'] == true) {
			if(@rankup != true) {
				@sendMsg = false
			}
		} 
		if(@newlevel < @config['LB_Options']['Level_Up_Announce_Start'] || @newlevel > @config['LB_Options']['Level_Up_Announce_End']) {
			@sendMsgtoLog = true
		}
		if(@config['LB_Options']['Level_Up_Announce'] == false) {
			@sendMsg = false
		}
		if(@sendMsg == true) {
			@type = 'broadcast'
			@sendchannel = @discord['channel']
			switch(string(@config['LB_Options']['Level_Up_Announce'])) {
			case 'log':
				@sendchannel = @config['Log_Channel'] 
			case 'dm':
				@type = 'dm'
				@sendchannel = @discord['userid']
			}
			if(@sendMsgtoLog == true) { @sendchannel = @config['Log_Channel'] @type = 'broadcast' }
			_discordBot_send_message(@discordMsg, @discord['serverid'], 'confirm', @sendchannel, @type)
		}
	}
#Save edits
	@leaderboard['lastedit'] = time()
	export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
	export('DiscordBot.'.@discord['serverid'].'.Leaderboard.xptimer', @xptimer)
	return(true)
}

proc _discordBot_backup_members(@args) {
	@config = import('DiscordBot.config.Discord')
	@guilds = import('DiscordBot.Guilds', array())
	if(array_size(@guilds) == 0) { return(false) }
	foreach(@guild in @guilds) {
		@data = array(
		'membersID': get_value('DiscordBot.'.@guild.'.members.ID'),
		'membersNames': get_value('DiscordBot.'.@guild.'.members.names'),
		'membersRoles': get_value('DiscordBot.'.@guild.'.members.roles'),
		'membersInfo': get_value('DiscordBot.'.@guild.'.members.info'),
		'membersWR': get_value('DiscordBot.'.@guild.'.members.roles.welcomeroles'),
		'membersNoRoles': get_value('DiscordBot.'.@guild.'.members.roles.none'),
		'rolesTotal': get_value('DiscordBot.'.@guild.'.roles.total'),
		'rolesMembers': get_value('DiscordBot.'.@guild.'.roles.members'),
		'Leaderboard': import('DiscordBot.'.@guild.'.Leaderboard'),
		'Invites': get_value('DiscordBot.'.@guild.'.Invites')
		)
		@time = time();
		foreach(@k: @v in @data) {
			if(@v == '' || @v == null) { continue() }
			if(is_array(@v) && array_size(@v) == 0) { continue() }
			_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/'.@guild.'_'.simple_date('MM-dd-yy_HHmm_', @time).@k.'.json', json_encode(@v), 'CREATE')
		}
	}
}

proc _discordBot_update_members(@args) {
	@guilds = import('DiscordBot.Guilds', array());
	@startTime = time();
	if(array_size(@guilds) == 0) { return(false) }
	foreach(@guild in @guilds) {
		@debugstats = array('size': array(), 'nf': 0, 'af': 0, 'fails': 0);
		@membersID = array();
		try {
			@membersID = discord_get_members(@guild);
		} catch(NotFoundException @ex) {
			array_remove_values(@guilds, @guild);
			_db_msg_Admins('[DiscordBot] Bot is not a member of guild "'.@guild.'"! Removed from active guild list.')
			continue();
		}
		@membersNames = array();
		@membersRoles = array();
		@membersInfo = array();
		@membersWR = array();
		@membersNoRoles = array();
		@totalroles = array();
		@rolesMembers = array();
		@config = import('DiscordBot.config.'.@guild);
		@leaderboard = import('DiscordBot.'.@guild.'.Leaderboard');
		@invites = get_value('DiscordBot.'.@guild.'.Invites');
		@rrUpdates = 0
		@sortWR = array(123,456);
		if(@config['Welcome_Roles_Award'] == true) {
			@sortWR = array_sort(@config['Welcome_Roles'], 'NUMERIC');
		}
	#Invites: only update if it does not already exist, else let member join handle updates
		if(!is_array(@invites) && @config['Log_Invites'] == true) {
			try {
				discord_retrieve_invites(@guild, closure(@raw) { 
					@inv = array()
					foreach(@i: @invite in @raw) {
						array_set(@inv, @invite['code'], @invite)
					}
					store_value('DiscordBot.'.@guild.'.Invites', @inv)
					_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/Invites.yml', yml_encode(@inv, true), 'overwrite')
				});
			} catch(InsufficientPermissionException @ex) {
				if(string_ends_with(@ex['message'], 'MANAGE_SERVER')) {
					array_set(@config, 'NoInvites', true)
					_db_msg_Console(color('c').'Invite Logging is Enabled, but bot does not have permission to view invites!', @guild)
				} else {
					_db_msg_Console(@ex['message'], @guild)
				}
			} catch(Exception @ex) {
				_db_msg_Console(@ex['message'], @guild)
			}
		}
		@rankstats = get_value('DiscordBot.debug.'.@guild.'.rank.stats')	
		if(!is_array(@rankstats)) { @rankstats = array() }
# Process each User ID
		foreach(@index: @id in @membersID) {
	# Member Info (avatar, isBot, Username, etc)
			@idInfo = ''
			try {
				@idInfo = discord_member_info(@guild, @id)
			} catch(NotFoundException @ex) {
				_db_msg_Console('Update Roles: Not found: '.@id, @guild)
				@debugstats['nf']++
				continue()		
			} catch(Exception @ex) {
				_db_msg_Console('error on id: '.@id.'\n'.@ex['message'], @guild)		
				@debugstats['fails']++
				continue()
			}
			array_set(@membersInfo, @id, @idInfo)
			array_set(@membersNames, @idInfo['username'], @id)
		# Leaderboard: Avatars, usernames, role color
			if(@config['LB_Enable'] == true && is_array(@leaderboard) && @idInfo['bot'] == false) {
				if(array_index_exists(@leaderboard, 'members', @id)) {
					@newavatar = reg_match('([^/]+)[.][A-Za-z]{2,}$', @idInfo['avatar'])
					@newcolor = 'fff'
					if(@idInfo['color'] != null) { @newcolor = _rgb_to_hex(@idInfo['color']) }
					if(array_index_exists(@newavatar, 1)) { array_set(@leaderboard['members'][@id], 'avatar', @newavatar[1]) }
					array_set(@leaderboard['members'][@id], 'color', @newcolor)
					array_set(@leaderboard['members'][@id], 'username', @idInfo['username'])
				}
			}
		# Roles: Check for No Roles
			@idRoles = discord_member_get_roles(@guild, @id);
			if(!is_array(@idRoles)) {
				@debugstats['af']++
				continue()
			}
			# if(@idInfo['color'] == null) { _db_msg_Console(@id.' i '.@idInfo, @guild, 'debug') }
			if(array_size(@idRoles) == 0) {
				array_push(@membersNoRoles, @id)
				continue()
			}	
			array_set(@membersRoles, @id, @idRoles)	
		# Add discovered roles to Total roles ( id: name )
			foreach(@k: @v in @idRoles) {
				if(!array_contains(array_keys(@totalroles), @v)) {
					array_set(@totalroles, @v, @k)
				}
			}
		# If Just welcome roles, add member to WR
			if(array_size(@idRoles) == array_size(@sortWR)) {
				@results = array()
				#sort arrays so roles are in same key order
				@sortUR = array_sort(array_normalize(@idRoles), 'NUMERIC')
				foreach(@key: @roleid in @sortWR) {
					if(@roleid == @sortUR[@key]) {
						@results[] = true;
					} else {
						@results[] = false;
					}
				}
				if(!array_contains(@results, false)) {
					@membersWR[] = @id;
					continue()
				}
				@results = array()
			}
		# Check Roles Ranks
			if(@config['Use_Role_Ranks'] == true) {
				@rrStats = _discordBot_process_role_ranks(array('serverid': @guild, 'userid': @id, 'username': @idInfo['username']), @idRoles, true)
				if(is_array(@rrStats)) {
					if(@rrStats['setRoles'] == true) { 
						@rrUpdates++
						_db_msg_Console('('.@index.')['.@idInfo['username'].'] '.@rrStats['rrMsg'], @guild);
					}
				} else {
					_db_msg_Console('('.@index.')['.@idInfo['username'].'] '.@rrStats, @guild);
				}
				array_set(@rankstats, @idInfo['username'], @rrStats)
			}
		}
	# Roles Members
		foreach(@roleid: @rolename in @totalroles) {
			array_set(@rolesMembers, @roleid, array())
		}
		foreach(@memberid: @mr in @membersRoles) {
		# server member roles array: id: {role: 123, role2: 4235}
			foreach(@roleName: @roleID in @mr) { 
				array_push(@rolesMembers[@roleID], @memberid)
			}
		}
	# Save data
		@alldebugstats = import('DiscordBot.debug.stats.last.updatemembers', array())
		if(@config['LB_Enable'] == true && is_array(@leaderboard)) {
			export('DiscordBot.'.@guild.'.Leaderboard', @leaderboard)
		}
		array_set(@debugstats['size'], 'rrUp', @rrUpdates)
		store_value('DiscordBot.'.@guild.'.members.ID', @membersID)
		export('DiscordBot.'.@guild.'.members.ID', @membersID)
		array_set(@debugstats['size'], 'ID', array_size(@membersID))
		store_value('DiscordBot.'.@guild.'.members.roles', @membersRoles)
		array_set(@debugstats['size'], 'mr', array_size(@membersRoles))
		store_value('DiscordBot.'.@guild.'.roles.members', @rolesMembers)
		array_set(@debugstats['size'], 'rm', array_size(@rolesMembers))
		store_value('DiscordBot.'.@guild.'.roles.total', @totalroles)
		array_set(@debugstats['size'], 'rt', array_size(@totalroles))
		store_value('DiscordBot.'.@guild.'.members.names', @membersNames)
		array_set(@debugstats['size'], 'mn', array_size(@membersNames))
		store_value('DiscordBot.'.@guild.'.members.roles.welcomeroles', @membersWR)
		array_set(@debugstats['size'], 'wr', array_size(@membersWR))
		store_value('DiscordBot.'.@guild.'.members.roles.none', @membersNoRoles)
		array_set(@debugstats['size'], 'norole', array_size(@membersNoRoles))
		export('DiscordBot.'.@guild.'.members.names', @membersNames)
		store_value('DiscordBot.'.@guild.'.members.info', @membersInfo)
		export('DiscordBot.'.@guild.'.members.info', @membersInfo)
		array_set(@debugstats['size'], 'mi', array_size(@membersInfo))
		array_set(@debugstats['size'], 'inv', array_size(@membersInfo))
		array_set(@alldebugstats, @guild, @debugstats)
		export('DiscordBot.debug.stats.last.updatemembers', @alldebugstats)
		store_value('DiscordBot.debug.'.@guild.'.rank.stats', @rankstats)
	}
	@timeElapsed = time() - @startTime;
	_db_msg_Console('Update: 'color(3).@timeElapsed.'ms', 'none', 'bot')
	return(true);
}

proc _discordBot_lb_levelXP(@guild = 'default', @args = 1) {
	@levelxp = array(0, 100)
	array_resize(@levelxp, 200)
	@mp = 1
# Mee6 XP formula:
	# https://github.com/randomairborne/experienced/blob/main/mee6/src/lib.rs
	# https://github.com/Mee6/Mee6-documentation/blob/master/docs/levels.md
	# The operation used to calculate how many XP a given level is is (5 / 6) * level * (2 * level * level + 27 * level + 91)
	if(@args == 0) {
		foreach(@i: @lvl in @levelxp) {
			if(@i < 2) { continue() }
			@levelxp[@i] = integer((5 / 6) * @i * (2 * @i * @i + 27 * @i + 91))
		}
	}
# cypher139's XP reimplementation via estimates. Allows to reach new levels much easier.
	if(@args == 1) {
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
	}
	export('DiscordBot.'.@guild.'.Leaderboard.levelXP', @levelxp)
	_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/Leaderboard_LevelXP.json', json_encode(@levelxp), 'CREATE')
	return(@levelxp)
}


proc _discordBot_process_role_ranks(@discord, array @userRoles = array(), @isloop = false) {
#SINGLE user only, call via a foreach if all is desired
	if(!is_array(@discord)) { return('No data') }
	if(!array_index_exists(@discord, 'userid')) { return('No user') }
	if(!array_index_exists(@discord, 'serverid')) { return('server?') }
	@config = import('DiscordBot.config.'.@discord['serverid'])
	if(!is_array(@config['Role_Ranks'])) { return('no rank data') }
	@ranknums = array_sort(array_keys(@config['Role_Ranks']), 'NUMERIC')
	if(is_array(@config['Role_Ranks_IgnoreUser'])) {
		if(array_contains(@config['Role_Ranks_IgnoreUser'], @discord['userid'])) {
			return('ignored User');
		}
	}
# Get current rank
	if(array_size(@userRoles) == 0) { @userRoles = discord_member_get_roles(@discord['serverid'], @discord['userid']) }
	@userRoles = array_sort(array_normalize(@userRoles), 'NUMERIC')
	if(is_array(@config['Role_Ranks_IgnoreRole'])) {
		foreach(@irole in @config['Role_Ranks_IgnoreRole']) {
			if(array_contains(@userRoles, @irole)) {
				return('ignored Role');
			}
		}
	}
	@currentRank = 0
	@rRoles = 0
	foreach(@rank: @data in @config['Role_Ranks']) {
		if(array_contains(@userRoles, @data['RoleID'])) {
			@currentRank = @rank
			@rRoles++
		}
	}
# Count qualifying roles
	@qRoles = 0
	foreach(@role in @config['Role_Ranks_Qualifying_Roles']) {
		if(array_contains(@userRoles, @role)) {
			@qRoles++
		}
	}
# Find which rank matches counted roles
	@newRank = 0
	@newRankMsg = 'level 0'
	foreach(@i: @rank in @ranknums) {
		@lastrank = 0
		if(@i != 0) {
			@lastrank = @ranknums[(@i - 1)]
		}
		if(@qRoles == @rank) {
			@newRank = @rank
			@newRankMsg = @qRoles.' = '.@newRank
			break()
		}
		#In Between two ranks
		if(@qRoles < @rank && @qRoles > @lastrank) {
			#No level ups yet
			if(@lastrank == 0) { 
				@newRankMsg = '   0'
				break()
			} else {
				@newRank = @lastrank
				@newRankMsg = @qRoles.' not at '.@rank.' yet'
				break()
			}
		}
		#Has highest rank
		if(array_size(@ranknums) - 1 == @i && @qRoles > @rank) {
			@newRank = @rank
			@newRankMsg = @qRoles.' > max: '.@newRank
			break()
		}
	}
# New roles setup	
	@stats = array('status': @newRankMsg, 'setRoles': false, 'qR': @qRoles, 'rR': @rRoles, 'currentrank': @currentRank, 'newrank': @newRank)
	@newRoles = array_deep_clone(@userRoles)
	foreach(@roledata in @config['Role_Ranks']) {
		array_remove_values(@newRoles, @roledata['RoleID'])
	}
# Setup Messages
	@logmsg = 'Role Ranks: 0 roles'
	if(@newRank != 0) {
		@newRoles[] = @config['Role_Ranks'][@newRank]['RoleID'];
		@logmsg = 'Awarded Role Rank "'.@config['Role_Ranks'][@newRank]['RoleName'].'"'
	}
	if(@newRank < @currentRank) {
		@logmsg = 'Role Ranks: Derank! ('.@newRank.' < '.@currentRank.')'
		array_set(@stats, 'derank', true)
	}
	if(@newRank == @currentRank && @rRoles > 1) {
		@logmsg = 'Role Ranks: Removing multiple roles ('.@rRoles.')'
	}
	array_set(@stats, 'logmsg', @logmsg)
# Array compare. sort both role arrays	
	array_sort(@newRoles, 'NUMERIC')
	@results = array()
	#check both old and new role arrays that each key's values matches. if not, save roles
	if(array_size(@userRoles) == array_size(@newRoles)) {
		foreach(@k: @v in @newRoles) {
			if(@v == @userRoles[@k]) {
				@results[] = true;
			} else {
				@results[] = false;
			}
		}
	} else {
		@results[] = false;
	}
# If a role change detected, set roles
	if(array_contains(@results, false)) {
		@saveoldroles = get_value('DiscordBot.'.@discord['serverid'].'.debug.roles.rank.undo')	
		if(!is_array(@saveoldroles)) { @saveoldroles = array() }
		array_set(@saveoldroles, @discord['userid'], @userRoles)
		store_value('DiscordBot.'.@discord['serverid'].'.debug.roles.rank.undo', @saveoldroles)
		try { 
			@stats['setRoles'] = true;
			discord_member_set_roles(@discord['serverid'], @discord['userid'], @newRoles, @logmsg)
		} catch(Exception @ex) {
			_db_msg_Console(@ex, @discord['serverid'], 'debug')
			@stats['setRoles'] = @ex['classType'];
		}
	} else {
		array_remove(@stats, 'logmsg')
	}
	@rrMsg = ''
	if(@stats['setRoles'] == true) {
		# _db_msg_Console('['.@discord['username'].'] '.@stats, @discord['serverid'], 'debug')
		@rrMsgPrefix = '['.@config['Server_Nickname'].'] ['.@discord['username'].'] '
		if(@isloop == true) { @rrMsgPrefix = '' }
		@rrMsgType = color(10).' < '
		if(array_index_exists(@stats, 'derank')) { @rrMsgType = color(14).' > ' }
		@rrMsg = @rrMsgPrefix.@currentRank.@rrMsgType.color('r').@newRank.color(8).' ('.@qRoles.')'
		if(@currentRank == @newRank && @rRoles > 1) {
			@rrMsg = @rrMsgPrefix.color(11).'Multiple Rank Roles: '.@rRoles
		}
		if(@isloop == false) {
			_db_msg_Console(@rrMsg, @discord['serverid'])
		}
	}
	if(@isloop == false) {
		@allstats = get_value('DiscordBot.debug.'.@discord['serverid'].'.rank.stats')	
		if(!is_array(@allstats)) { @allstats = array() }
		array_set(@allstats, @discord['username'], @stats)
		store_value('DiscordBot.debug.'.@discord['serverid'].'.rank.stats', @allstats)
	}
	if(@stats['setRoles'] == true && @isloop == true) {	array_set(@stats, 'rrMsg', @rrMsg) }
	return(@stats);
}


#Handle commands from Discord Users
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
		array_push(@returns, @return)
	}
	return(@returns)
}		


proc _discordBot_handlecommand(@discord, @dm, @cmdfrom) {
	@botconfig = import('DiscordBot.config.Discord')
	if(is_array(@discord)) {
		if(!array_index_exists(@discord, 'userid')) {
			_db_msg_Console('Required data array not given to Command Handler!', @discord['serverid'], 'debug')
			return(false)
		} else {
			if(!array_index_exists(@discord, 'time')) {
				array_set(@discord, 'time', time())
			}
			if(!array_index_exists(@discord, 'serverid')) {
				array_set(@discord, 'serverid', @botconfig['Primary_Guild'])
			}
		}
	} else {
		_db_msg_Console('Required data array not given to Command Handler!', @discord['serverid'], 'debug')
		return(false)
	}
	@config = import('DiscordBot.config.'.@discord['serverid'])
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
		@userroles = array_keys(discord_member_get_roles(@discord['serverid'], @discord['username']))
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
	_db_msg_Console(@admincommandlist, @discord['serverid'], 'debug')
	_db_msg_Console(@aliaseslist, @discord['serverid'], 'debug')
	_db_msg_Console(@commandlist, @discord['serverid'], 'debug')
*/
# Extract Command
	@command = parse_args(reg_replace(@config['CMD_Command_Prefix'], '', @discord['message']))
# No Command Given
	if(!array_index_exists(@command, 0)) {
		_discordBot_send_message(array('embeds': array(array('description': 'Ooooh! I can\'t wait to see what command you enter next!', 'footer': array('text': '...or not'), 'image': 'https://media.tenor.com/hrg1biY9FbsAAAAC/awesome-minions.gif'))), @discord['serverid'], 'none', @discord['SendChannel'], @discord['UseDM'])	
		return('NoCmdGiven')
	}
#No mentions
	@command[0] = reg_replace('@', '', @command[0])
# Setup Arguments
	@args = array()
	if(array_index_exists(@command, 1)) {
		@args = @command[cslice(1, array_size(@command) - 1)]
	}
#check ************ : @here cmd @here does it remove "@here cmd" due to index shift

	if(is_string(@command[0])) { @command[0] = to_lower(@command[0]) }
	@commanddismc = ''
	@commanddisdc = ''
	if(array_index_exists(@args, 0)) { 
# Remove mention in arguments 
		@rmargs = array()
		foreach(@i: @entry in @args) {
			if(_array_string_contains(@botconfig['Banned_Mentions'], @entry)) {
				array_push(@rmargs, @entry)
				array_remove(@args, @i)
			}
		}
		if(array_index_exists(@rmargs, 0)) {
			@rmargs = array_implode(array_unique(@rmargs), ', ')
			_db_msg_Admins(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Removed "'.@rmargs.'" from '.@discord['username'].'\'s command arguments.')
			discord_broadcast(@discord['serverid'], @config['Log_Channel'], 'Removed `'.@rmargs.'` from '.@discord['username'].'\'s command arguments.')	
			if(@config['Message_On_Mention'] == true) { discord_private_message(@discord['userid'], 'Mention(s) `'.@rmargs.'` are not allowed on the server.') }
		}
		@commanddismc = 'Args: '.color(9).array_implode(@args, ', ')
		@commanddisdc = 'Args: `'.array_implode(@args, '`  `').'`' 
		if(!array_index_exists(@args, 0)) { @commanddisdc = '' }	
	}
	
# Deny Admin commands	
	if(array_contains_ic(@admincommandlist, @command[0]) && @userType != 'Admin') {
		_db_msg_Console(@discord['username'].' tried to use an admin command'.@cmdfrom.': '.color(3).@command[0].'  '.color('r').@commanddismc, @discord['serverid'])
		_discordBot_send_message(@discord['username'].' tried to use admin command'.@cmdfrom.': `'.@command[0].'`  '.strip_colors(@commanddisdc), @discord['serverid'], 'admin')
		return('NotAdmin')
	}
	array_set(@discord, 'admin', @isAdmin)
# make 1 letter aliases

# Execute command action 
	if(array_index_exists(@actions, @command[0])) {
		@return = @actions[@command[0]](@discord, @args);
	} else {
		_discordBot_send_message('I have no idea what that command was about, try help.', @discord['serverid'], 'command', @discord['SendChannel'], @discord['UseDM'])
		@lastmsgs = get_value('DiscordBot.last.cmd.not.found')
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		@fail = array('time': time(), 'user': @discord['username'], 'command': @command[0], 'args': @args)
		array_insert(@lastmsgs, @fail, 0)
		if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
		store_value('DiscordBot.last.cmd.not.found', @lastmsgs)
		_db_msg_Console(@discord['username'].' tried to use non-existent command'.@cmdfrom.': '.color('e').@command[0].'  '.color('r').@commanddismc, @discord['serverid'])
		return('NotACmd')
	}

/*
should get array closure return. chat procs need to return to closure
auto includes messages final message, unless true/false. multiple messages need to be handled by action
ex.:	_discordBot_send_message(return, @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
return may be an array or string too
nocmd return: 		_discordBot_send_message('A required command module is not installed.', @discord['serverid'], 'command', @discord['SendChannel'], @discord['UseDM']) returnfalse
*/
_db_msg_Console('ret: '.@return, @discord['serverid'], 'debug')
_db_msg_Console('retis: '.is_string(@return), @discord['serverid'], 'debug')
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
			_discordBot_send_message('A required command module is not installed.', @discord['serverid'], 'command', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'NotAdmin') {
			_discordBot_send_message(':no_entry: This command is restricted to use by Admin only.', @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'NoUserFound') {
			_discordBot_send_message(':question: User ID given not found on server.', @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'pong') {
			@timeElapsed = (time() - @discord['time'])
			_discordBot_send_message('Pong! ('.(@timeElapsed / 1000).')', @discord['serverid'], 'command', @discord['SendChannel'], @discord['UseDM']) 
			@return = true
		} else {
			_discordBot_send_message(@return, @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
			@return = true
		}
	} else if(is_array(@return)) {
		if(array_index_exists(@return, 'content') || array_index_exists(@return, 'embeds')) {
			_discordBot_send_message(@return, @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
			@return = true
		} else {
			_discordBot_send_message(@discord['username'].'\'s command `'.@command[0]'` failed: '.@return, @discord['serverid'], 'admin')
			@return = false
		}
	}
# Send Log Messages and End.
	@colorret = ''
	@retdisplay = ''
	if(@return == true) { @colorret = 3 @retdisplay = '' } else { @colorret = 'c' @retdisplay = ' (Failed)' }
	_db_msg_Console(@discord['username'].' used command'.@cmdfrom.': '.color(@colorret).@command[0].'  '.color('r').@commanddismc.color('r').@retdisplay, @discord['serverid'])
	_discordBot_send_message(@discord['username'].' used command'.@cmdfrom.' `'.@command[0].'`  '.strip_colors(@commanddisdc).@retdisplay, @discord['serverid'], 'admin')
	return(@return)
}


proc _discordBot_cmd_proc_finduserID(@target, @discord) {
	@botconfig = import('DiscordBot.config.Discord')
	if(!array_index_exists(@discord, 'serverid')) { array_set(@discord, 'serverid', @botconfig['Primary_Guild']) }
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@membernames = get_value('DiscordBot.'.@discord['serverid']'.members.names')
	if(!is_array(@membernames)) { @membernames = array() }
	if(is_numeric(@target)) {
		if(@target == @config['Bot_ID']) {
			return('bot')
		}
		if(@target == @discord['userid'] && @discord['UseDM'] != 'dm') {
			return('self')
		}	
		try {
			@memberroles = discord_member_get_roles(@discord['serverid'], @target)
		} catch (NotFoundException @ex) {
			_db_msg_Console('User ID given not found on server: '.@target.'!', @discord['serverid'])
			return('notfound')
		}
		return(@target)
	} else {
		if(reg_count('^[@]?'.@config['Bot_Name'].'[#]?[0-9]{0,4}?$', @target) > 0) {
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
		_db_msg_Console('finduserID debug: match: '.@targetmatches, @discord['serverid'])
		
		if(!array_index_exists(@targetmatches, 0)) {
			_db_msg_Console('Could not find user ID for '.@target.'!', @discord['serverid'])
			return('notfound')
		} else if(array_index_exists(@targetmatches, 1)) {
			discord_private_message(@discord['userid'], 'I found multiple users; I\'m not sure which one you meant to apply this command to. Users Matched: \n'.array_implode(@targetmatches, ', '))
			_db_msg_Console('finduserID: Found multiple users, Users Matched: \n'.array_implode(@targetmatches, ', '), @discord['serverid'])
			return('multiple')
		} else {
			return(@membernames[array_implode(@targetmatches, '')])
		}		
	}
}