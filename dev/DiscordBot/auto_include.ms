### Core Startup
@pf = '/'
if(get_os() == 'WINDOWS') { @pf = '\\' }
@path = ''
if(in_cmdline_mode()) {
	export('DiscordBot.version', '1.0.dev-cmd')
	@path = pwd()
} else {
	export('DiscordBot.version', '1.0.dev')
	@path = sys_properties()['user.dir'].@pf.'plugins'.@pf.'CommandHelper'.@pf.'LocalPackages'.@pf.'DiscordBot'
}
export('DiscordBot.config.dir', file_resolve(@path.@pf.'Configs'))
export('DiscordBot.logs.dir', file_resolve(@path.@pf.'Logs'))
##########################################
### Bot Admin Functions
##########################################

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
	_write_file(import('DiscordBot.logs.dir').'/Log-Admin-Messages.txt', simple_date('MM-dd-yy HH:mm:ss', time()).': '.@consolemsg.'\n', 'Append')
}

proc _db_msg_Console(@message, @guild, string @type = 'prefix') {
	if(@guild == '' || @guild == null || @guild == false) {
		@guild = import('DiscordBot.config.Bot')['Primary_Guild']
		console(color(14).'Nag: No guild given at: '.get_stack_trace());
	}
	@config = array()
	switch(string(@guild)) {
	case 'none':
	case 'bot':
	case 'false': 
		@config = array('Server_Nickname': 'DiscordBot', 'Console_Messages': true, 'Console_Debug': true)
	case 'debug': 
		@config = array('Server_Nickname': 'DiscordBot '.color(14).'<debug>'.color('r'), 'Console_Messages': true, 'Console_Debug': true)
	default:
		@config = import('DiscordBot.config.'.@guild)
	}
	@prefix = ''
	switch(@type) {
	case 'pre':
	case 'prefix':
		@prefix = '['.@config['Server_Nickname'].'] '
	case 'debug':
		@prefix = '['.@config['Server_Nickname'].'] '.color(14).'<debug> '.color('r')
	case 'error':
		@prefix = '['.@config['Server_Nickname'].'] '.color(12).'<error> '.color('r')
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
	if(@guild == 'error' || @type == 'error') { @sendConsole = true }
	if(@sendConsole == true) {
		console(@message, false)
	} else {
		_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/Log-Console.txt', '['.simple_date('MM-dd-yy HH:mm:ss', time()).']: '.@message.'\n', 'Append')
	}
}

proc _discordBot_set_activity(@type = '', @message = '', @url = '') {
	@config = import('DiscordBot.config.Bot')
	if(@config['Set_Activity'] == false) { return(false) }
	if(@type == '' || @type == null) { @type = @config['Activity_Type'] }
	if(@message == '' || @message == null) { @message = @config['Activity_Message'] }
	@acttypes8901 = reg_split('of\\s|[,.]\\s(?:or\\s)*', reflect_docs('discord_set_activity', 'description'))[2..]
	foreach(@k: @v in @acttypes8901) {
		if(to_upper(@v) != @v) { array_remove(@acttypes8901, @k) }
	}
	if(array_contains(@acttypes8901, to_upper(@type))) {
		try {
			discord_set_activity(to_upper(@type), string(@message), @url);
		} catch(NotFoundException @ex) {
			_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] '.color(7).'Activity Message not set, connection to Discord server lost.', true)
		} catch(Exception @ex) {
			_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Bot Activity Message: '.color('r').@ex['message'], color(12).' ('.@ex['classType'].')', true)
		}
	} else {
		_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Bot Activity Message: Type "'.@config['Activity_Type'].'" is not supported!')
	}
}

proc _db_load_guilds(array @guilds = array(), @prefix = 'DiscordBot') {
	if(array_size(@guilds) == 0) { @guilds = discord_get_servers() }
	if(array_size(@guilds) == 0) { return(false) }
	@guildList = array()
	@consoleChats = array()
	export('DiscordBot.Guilds.Nicknames', array())
	foreach(@guild in @guilds) {
		if(!is_numeric(@guild)) { continue() } 
		if(function_exists('is_dir')) {
			if(!is_dir(import(@prefix.'.config.dir').'/'.@guild)) {
				create_dir(import(@prefix.'.config.dir').'/'.@guild)
			}
			if(!file_exists(import(@prefix.'.config.dir').'/'.@guild.'/config-'.@guild.'.yml')) {
				http_request('https://raw.githubusercontent.com/cypher139/ch/release/dev/DiscordBot/Configs/123/config-123.yml', array('blocking': true, 'success': closure(@data) {
					if(@data['error'] == true) {
						if(@data['responseCode'] == 404) { console('Default config was not found.')	}
						export('DiscordBot.debug.http.error', @data)
						return(false)
					} else {
						_write_file(import('DiscordBot.config.dir').'/'.@guild.'/config-'.@guild.'.yml', @data['body'], 'CREATE')
						return(true)
					}
				}));
			}
		}
		@return = _db_load_config(@guild, false, @prefix)
		if(!is_array(@return)) {
			continue()
		}
		if(@return['Console_Messages_Chat'] == true) {
			if(array_index_exists(@return, 'Server_Nickname')) {
				@consoleChats[] = @return['Server_Nickname']
			} else if(array_index_exists(@return, 'LB_Options', 'Guild_Name')) { 
				@consoleChats[] = @return['LB_Options']['Guild_Name']
			} else {
				@consoleChats[] = @guild
			}
		}
		@guildList[] = @guild
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

proc _db_load_config(@cfgtype, @init = false, @prefix = 'DiscordBot') { 
	if(@cfgtype == '' || @cfgtype == null) { @cfgtype = 'Bot' }
	@numtype = ''
	if(is_numeric(@cfgtype)) { @numtype = @cfgtype.'/config-' }
	@loadcfg = ''
	@prevcfg = import(@prefix.'.config.'.@cfgtype, array())
# Read config
	try {
		@loadcfg = yml_decode(read(import(@prefix.'.config.dir').'/'.@numtype.@cfgtype.'.yml'))
	} catch(IOException @ex) {
		@msg1 = color(12).@cfgtype.' Config file could not be read. '
		@msg2 = @ex['message']
		@color = 12
		if(@numtype == @cfgtype.'/config-') {
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
		if(!array_index_exists(@loadcfg, 'v')) { _db_msg_Admins(color(12).'['.@prefix.'] Guild Config for "'.@cfgtype.'" is too old, please update.') return('OldConfig') }
		if(@loadcfg['v'] < import('DiscordBot.cfg.version', array(1,1))[1]) {
			_db_msg_Admins(color(12).'['.@prefix.'] Guild Config for "'.@cfgtype.'" is too old, please update.')
			return('OldConfig')
		}
		@botconfig = import('DiscordBot.config.Bot')
		@botInfo = discord_member_info(@cfgtype, @botconfig['Bot_ID'])
		if(@botInfo['nickname'] != '') { array_set(@loadcfg, 'Bot_Name', @botInfo['nickname']) } else { array_set(@loadcfg, 'Bot_Name', @botInfo['displayname']) }
		array_set(@loadcfg, 'Bot_ID', @botconfig['Bot_ID'])
		if(array_contains(@loadcfg['Channels_Receive'], 'default') || array_index_exists(@loadcfg, 'VC_Options', '987654321') || @loadcfg['Welcome_Text_Channel_Name'] == 'default') {
			_db_msg_Admins(color(12).'['.@prefix.'] Guild Config for "'.@cfgtype.'" is still using default values. Configuration is required to use many of the bot\'s features for this Guild.') 
			return('Defaults')
		}
		if(@loadcfg['LB_Options']['Use_Active_User_Role'] == true) {
			try {
				@gmr = discord_get_members_with_role(@cfgtype, @loadcfg['LB_Options']['Active_User_Role'])
			} catch(NotFoundException @ex) {
				array_set(@loadcfg['LB_Options'], 'Active_User_Role_Not_Found', true)
				@loadcfg['LB_Options']['Use_Active_User_Role'] = false
			} catch(Exception @ex) {
				@nc = 1
			}
		}
		if(array_size(@prevcfg) == 0) {
			# Databases Startup
			export('DiscordBot.'.@cfgtype.'.members.ID', get_value('DiscordBot.'.@cfgtype.'.members.ID'))
			export('DiscordBot.'.@cfgtype.'.members.names', get_value('DiscordBot.'.@cfgtype.'.members.names'))
			export('DiscordBot.'.@cfgtype.'.Leaderboard', get_value('DiscordBot.'.@cfgtype.'.Leaderboard'))
			# Setup Leaderboard
			if(@loadcfg['LB_Enable'] == true) {
				if(!is_array(import('DiscordBot.'.@cfgtype.'.Leaderboard'))) {
					export('DiscordBot.'.@cfgtype.'.Leaderboard', array('lastedit': time(), 'members': array()))
				}
			}
			# Setup Server Info
			_discordBot_get_server_info(@cfgtype)
		}
		@guildNick = import('DiscordBot.Guilds.Nicknames', array())
		array_set(@guildNick, @cfgtype, @loadcfg['Server_Nickname'])
		export('DiscordBot.Guilds.Nicknames', @guildNick)
	} else {
		switch(string(@cfgtype)) {
		case 'Server':
			if(array_index_exists(@loadcfg, 'Not_Configured')) {
				_db_msg_Admins(color(12).'[Chat - Server] Server Config file is still using the default values. Please configure it to your needs!')
				return(false)
			}
		case 'Discord':
		case 'Bot':
			if(!array_index_exists(@loadcfg, 'v')) { _db_msg_Admins(color(12).'['.@prefix.'] Bot Config is too old, please update.') return('OldConfig') }
			if(@loadcfg['v'] < import('DiscordBot.cfg.version', array(1,1))[0]) {
				_db_msg_Admins(color(12).'['.@prefix.'] Bot Config is too old, please update.')
				return('OldConfig')
			}
			if(!function_exists('discord_connect')) { 
				_db_msg_Console('CHDiscord extension not installed!', 'none')
				return(false)
			}
			if(array_size(@prevcfg) > 0 && @init == false) {
				_discordBot_set_activity();
			}
		case 'Experimental':
		case 'ex':
			@dcfg = import('DiscordBot.config.Bot')
			@loadcfg = array_merge(@loadcfg, @dcfg)
		default:
			_db_msg_Admins(color(12).'[DiscordBot] Config type given not supported.')
			return(false)
		}
	}
	export(@prefix.'.config.'.@cfgtype, @loadcfg)
	return(@loadcfg)
}

proc _discordBot_get_server_info(@guild) {
	if(@guild == null || @guild == '') { die() }
	if(!is_numeric(@guild)) { die() }
	@time = time()
	@id = rand(123, 465)
	x_new_thread(@id.@time, closure(){
		discord_request('GET', 'guilds/'.@guild.'/preview', null, closure(@data){ 
			# console(@data)
			array_set(@data, 'retrieved', time())
			export('DiscordBot.Guilds.Info.'.@guild, @data)
			store_value('DiscordBot.'.@guild.'.guild.Info', @data)
		}, closure(@data){ 
			_db_msg_Console(color(12).'Cannot retrieve Guild info for guild "'.@guild.'". \n'.color(7).@data, @guild)
		});
	});
	x_thread_join(@id.@time, 7000)
	return(import('DiscordBot.Guilds.Info.'.@guild))
}

proc _db_get_snowflake_time(@snowflake, @epoch = 1420070400000) {
	if(!is_integral(@snowflake)) { throw('ms.lang.CastException', 'Snowflake is not an integer.') }
	return(rshift(@snowflake, 22) + @epoch)
}

proc _db_get_user_nick(@userID, @serverID, @username) {
	@botconfig = import('DiscordBot.config.Bot')
	if(@userID == null || @userID == '') { throw('ms.lang.CastException', 'User ID not given to nick display') }
	if(@username == null || @username == '') { throw('ms.lang.CastException', 'User name not given to nick display') }
	if(@serverID == null || @serverID == '') { @serverID = @botconfig['Primary_Guild'] }
	if(!is_numeric(@userID)) { return(@username) }
	if(!is_numeric(@serverID)) { return(@username) }
	@memberInfo = array()
	try {
		@memberInfo = discord_member_info(@serverID, @userID)
	} catch(NotFoundException @ex) {
		return(@username)
	}
	if(@memberInfo['nickname'] != '') {
		return(@memberInfo['nickname'])
	} else if(@memberInfo['displayname'] != '') {
		return(@memberInfo['displayname']) 
	} else {
		return(@memberInfo['username'])
	}
}

proc _discordBot_db_autosave(string @usekey = '', @option) {
	# _db_msg_Console('Autosaving', 'debug')
	@botconfig = import('DiscordBot.config.Bot')
	@prefix = 'DiscordBot.'
# Get list of keys to check for
	@allKeys = import(@prefix.'db.save.keys', array())
	@time = time()
	@results = array('null': array(), 'na': array(), 'noTS': array(), 'nolb': array(), 'saved': array(), 'nochange': array())
	if(@usekey != '') { @allKeys = array(@usekey) }
	if(array_size(@allKeys) == 0) { return(false) }
	@botSaved = array()
	foreach(@guild in import('DiscordBot.Guilds')) {
		@config = import(@prefix.'config.'.@guild)
		foreach(@e in @allKeys) {
			@gp = @guild.'.'
			if(string_starts_with(@e, 'bot')) { 
				@gp = ''
				if(array_contains(@botSaved, @e)) { continue() } else { @botSaved[] = @e; }
			}
			@saveKey = import(@prefix.@gp.@e)
			#Checks
			if(is_null(@saveKey)) { @results['null'][] = @gp.@e; continue() }
			if(!is_array(@saveKey)) { @results['na'][] = @gp.@e; continue() }
			if(!array_index_exists(@saveKey, 'lastedit')) { @results['noTS'][] = @gp.@e; continue() }
			if(@e == 'Leaderboard' && @config['LB_Enable'] != true) { @results['nolb'][] = @gp.@e; continue() }
			# actions
			if(@saveKey['lastedit'] > (@time - @botconfig['AutoSave_Wait'])) {
				store_value(@prefix.@gp.@e, @saveKey)
				@results['saved'][] = @gp.@e;
				if(@e == 'Leaderboard' && array_index_exists(@saveKey, 'guild')) {
					_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/Leaderboard_'.reg_replace('\\s', '_', @saveKey['guild']['name']).'.json', json_encode(@saveKey), 'OVERWRITE')
				}
			} else {
				@results['nochange'][] = @gp.@e;
			}
		}
	}
	export(@prefix.'db.autosave.time', @time)
	export(@prefix.'db.autosave.results', @results)
	# return(@results)
	return(true)
}

proc _discordBot_clean_cache(@exptime = 0, @guildlist, @option) {
	x_new_thread('DiscordBotCleanCache', closure(){
		@time = time()
		@botconfig = import('DiscordBot.config.Bot')
		if(@exptime < 10000000 || @botconfig['Msg_Cache_Time'] > 2592000000) { @exptime = 2592000000 }
		@exptime = @time - @exptime
		if(!is_array(@guildlist)) { @guildlist = import('DiscordBot.Guilds') }
		# if(!is_array(@cacheMsgs)) { @cacheMsgs = array('messages': array(), 'bot': array(), 'user': array(), 'server': array()) }
		@stats = array()
		@VCstats = array()
		foreach(@guild in @guildlist) {
			@queue = array()
			if(!array_contains(import('DiscordBot.Guilds'), @guild)) { continue() }
			# @config = import(@prefix.'config.'.@guild)
			@cacheMsgs = import('DiscordBot.'.@guild.'.Cache.Messages')
			if(!is_array(@cacheMsgs)) { continue() }
			@guildstats = array('cacheb': array_size(@cacheMsgs['server']), 'cachea': 0, 'queue': 0)
			# 1: Check for messages on server cache above Limit. Always sorted highest first on data insert
			if(array_index_exists(@cacheMsgs['server'], @botconfig['Msg_Cache_Server'])) {
				array_push_all(@queue, @cacheMsgs['server'][cslice(@botconfig['Msg_Cache_Server'], array_size(@cacheMsgs['server']) - 1)])
			}
			#2: Check for messages with an add date from 30 days ago
			foreach(@msg in @cacheMsgs['messages']) {
				if(@msg['time'] < @exptime) {
					@queue[] = @msg['id']
				}
			}
	_db_msg_Console(array_size(@queue).'\n'.@queue, 'debug')
			@queue = array_unique(@queue)
			@guildstats['queue'] = array_size(@queue)
		# For each queue remove message id index in messages & server (Listed first so reaction added messages with no user attached get purged)
			foreach(@id in @queue) {
				array_remove(@cacheMsgs['messages'], @id)
				array_remove_values(@cacheMsgs['server'], @id)
			}
		# For each user's messages check if id is in queue. If so remove ID from user, and queue.
			foreach(@type in array('user', 'bot')) {
				foreach(@userid: @usermsgs in @cacheMsgs[@type]) {
					if(array_size(@queue) == 0) { break(2) }
					foreach(@index: @msgID in @usermsgs) {
						if(array_contains(@queue, @msgID)) {
							array_remove_values(@cacheMsgs[@type][@userid], @msgID)
							array_remove_values(@queue, @msgID)
						}
					}
				}
			}
			if(array_size(@queue) > 0) { _db_msg_Console('Cache queue not empty\n'.@queue, @guild, 'error') }
			export('DiscordBot.'.@guild.'.Cache.Messages', @cacheMsgs)
			@guildstats['cachea'] = array_size(@cacheMsgs['server'])
			array_set(@stats, @guild, @guildstats)
		}
		@displaystats = ''
		foreach(@sid: @stat in @stats) {
			@displaystats = @displaystats.'\n'.color(rand(7,11)).import('DiscordBot.Guilds.Nicknames')[@sid].': '.@stat['cacheb'].' - '.@stat['queue'].' =  '.@stat['cachea']
		}
		_db_msg_Console(color(3).simple_date('MM/dd', @time).' Msg Cache: '.color(10).'<'.(time() - @time).'ms>'.@displaystats, 'debug')
		return(true);
	});
}

##########################################
### Send A Message
##########################################

proc _db_sanitize_message(@message, @caller, @guild, @from, @dm) {
	if(@message == null || @message == '') { return(null); }
	if(@caller == null) { @caller = 'Discord' }
	@caller = to_lower(@caller)
	@botconfig = import('DiscordBot.config.Bot')
	if(@guild == '' || @guild == null || @guild == 'bot') { @guild = @botconfig['Primary_Guild'] }
	@config = import('DiscordBot.config.'.@guild)
	@sanitize = array('Markdown': false, 'User': false, 'Role': false, 'Everyone': false)
	switch(@caller) {
	case 'bot':
		@sanitize['Markdown'] = false
		@sanitize['Role'] = false
		@sanitize['Everyone'] = true
	case 'discord':
		@sanitize['Markdown'] = false
		@sanitize['User'] = true
		@sanitize['Role'] = true
		@sanitize['Everyone'] = true
		try (
			foreach(@rN: @rID in discord_member_get_roles(@guild, @from)) {
				if(array_contains_ic(@config['Role_Admins'], @rN) || array_contains(@config['Role_Admins'], @rID)) {
					@sanitize['Markdown'] = false
					@sanitize['User'] = false
					@sanitize['Role'] = false
					@sanitize['Everyone'] = true
					break()
				}
			}
		)
	case 'minecraft':
		@sanitize['Markdown'] = true
		@sanitize['User'] = true
		@sanitize['Role'] = true
		@sanitize['Everyone'] = true
		if(function_exists('has_permission')) {
			if(player() != '~console') {
				try {
					if(has_permission(@from, 'commandhelper.discord.markdown')) {
						@sanitize['Markdown'] = false
					}
					if(has_permission(@from, 'commandhelper.discord.ping')) {
						@sanitize['Everyone'] = false
					}
					if(has_permission(@from, 'commandhelper.discord.ping.user')) {
						@sanitize['User'] = false
					}
					if(has_permission(@from, 'commandhelper.discord.ping.role')) {
						@sanitize['Role'] = false
					}
				} catch(PlayerOfflineException @ex) {
					@sanitize['Markdown'] = false
					@sanitize['User'] = false
					@sanitize['Role'] = false
				}	
			} else {
				@sanitize['Markdown'] = false
				@sanitize['User'] = false
				@sanitize['Role'] = false
				@sanitize['Everyone'] = false
			}
		}
	case 'server':
	default:
	# Minecraft Player chat
		@message = '`['.@from.']` '.@message
	}

	if(@sanitize['Markdown'] == true && @dm == false) {
		@message = replace(@message, '*', '\\*')
		@message = replace(@message, '~', '\\~')
		@message = replace(@message, '_', '\\_')
		@message = replace(@message, '`', '\\`')
		@message = replace(@message, '>', '\\>')
		@message = replace(@message, '|', '\\|')
    }
	
	if(@sanitize['Everyone'] == true) {
		@message = replace(@message, '@everyone', '')
		@message = replace(@message, '@here', '')
	}
	if(array_index_exists(@config, 'Sanitize_Mentions')) {
		foreach(@mention: @replacement in @config['Sanitize_Mentions']) {
			@message = replace(@message, @mention, @replacement)
		}
	}
	@message = replace(@message, '§', '');
	
	@allowedMentions = array()
	foreach(@k: @v in @sanitize) {
		if(@k == 'Markdown') { continue() }
		if(@v == false) {
			@allowedMentions[] = to_upper(@k)
		}
	}
	@return = array('message': @message)
	@results = array()
	if(array_size(@allowedMentions) == array_size(@botconfig['Allowed_Mentions'])) {
		@sort1 = array_sort(@botconfig['Allowed_Mentions'], 'STRING')
		@sort2 = array_sort(@allowedMentions, 'STRING')
		foreach(@key: @value in @sort1) {
			if(@value == @sort2[@key]) {
				@results[] = true;
			} else {
				@results[] = false;
			}
		}
	} else {
		@results[] = false;
	}
	if(array_contains(@results, false)) {
		if(array_index_exists(@allowedMentions, 0)) {
			array_set(@return, 'allowed_mentions', @allowedMentions)
		}
	}
	return(@return);
}

proc _discordBot_find_emoji(string @findEmoji, @originationGuild, @skipGuild) {
	@botconfig = import('DiscordBot.config.Bot')
	@checkGuilds = array()
	@findEmoji = replace(@findEmoji, ':', '')
	@r2 = false
	# If given, Search origin guild first
	if(is_numeric(@originationGuild) && length(@originationGuild) > 15) {
		@checkGuilds = array(@originationGuild)
	} else if(@originationGuild == null || @originationGuild == '') {
		@checkGuilds = discord_get_servers()
		@r2 = true
	} else { 
		_db_msg_Console('Emoji: guild must be numeric', 'debug')
		die()
	}
	@results = array('NotFound': 'Not Found')
	foreach(@guild in @checkGuilds) {
		if(@guild == @skipGuild) { continue() }
		@serverInfo = import('DiscordBot.Guilds.Info.'.@guild)
		if(@serverInfo == null) { 
			# Loading info if not present in previous config setup, as we can use their emoji even if bot doesn't participate in that guild
			_discordBot_get_server_info(@guild)
			@serverInfo = import('DiscordBot.Guilds.Info.'.@guild, array())
		}
		if(!array_index_exists(@serverInfo, 'emojis')) { continue() }
		foreach(@index: @emoji in @serverInfo['emojis']) {
			# msg(@findEmoji.' -- '.@emoji['name'])
			if(@findEmoji == @emoji['name']) {
				@results = @emoji
				array_set(@results, 'guild', @guild) 
				break()
			}
		}
	}
	#If single guild checked, redo check for all bot guilds
	if(array_index_exists(@results, 'NotFound') && array_size(@checkGuilds) < 2 && @r2 == false) { 
		@return2 = _discordBot_find_emoji(@findEmoji, null, @originationGuild) 
		return(@return2)
	}
	return(@results)
}


proc _discordBot_send_message(@raw, @guild, @from, @channel, @type, @option) {
	if(!function_exists('discord_broadcast') || !function_exists('discord_private_message')) { return(false) }
	@prefixErrorMsg = color(6).'['.color(9).'DiscordBot'.color(6).'] '.color(7).'A message queued to send had a problem: '
	@botconfig = import('DiscordBot.config.Bot')
	if(@guild == '' || @guild == null || @guild == 'bot') {
		#primary guild
		@guild = @botconfig['Primary_Guild']
	}
	@config = import('DiscordBot.config.'.@guild)
	if(!is_array(@config)) {
		_db_msg_Admins(color(7).'Message not sent to Discord: Guild "'.@guild.'" was not recognized')
		return(false)
	}
	@count = 0
	@caller = 'Discord'
	@splitRegEx = '[\\s\\S]{1,1999}(?:\\s|\\S|$)'
	@editMsg = 0
	if(@channel == '') { @channel = @config['Default_Channel'] }
	if(@channel == 'admin') { @channel = @config['Log_Channel'] }
	if(@type == '') { @type = 'broadcast' }
	if(@raw == '') { return(false) }
	if(@from == '' || is_array(@from)) { 
		if(function_exists('player')) { 
			@from = player()
			@caller = 'Minecraft'
		} else {
			@from = 'Discord'
		}
	}
	if(is_closure(@option)) {
		@afterMsg = @option
	} else {
		@afterMsg = closure(@msgID) {
		# console(@msgID)
			@cacheID = import('DiscordBot.'.@guild.'.Cache.Messages.sent.IDs')
			if(!is_array(@cacheID)) { @cacheID = array() }
			@newData = array()
			array_set(@newData, @guild, @msgID)
			array_insert(@cacheID, @newData, 0)
			if(array_index_exists(@cacheID, 100)) { array_remove(@cacheID, 100) }
			export('DiscordBot.'.@guild.'.Cache.Messages.sent.IDs', @cacheID)
			return(true)
		}
	}
	@message = array()
	# Check if message data given is an array of data
	if(is_array(@raw)) {
		# Remove unused array datas & format variables
		@msg3 = 'msg: array: '
		foreach(@k: @v in @raw) {
			if(@k == 'content' || string_starts_with(@k, 'embed') || @k == 'allowed_mentions' || @k == 'reference_id' || @k == 'custom_split' || @k == 'message_id') {
				@msgk = @k
				if(@k == 'embeds') { 
					if(!array_index_exists(@v, 1)) {
						@msgk = reg_replace('s$', '', @msgk)
					}
				}
				if(@k == 'embed') {
					if(!array_index_exists(@v, 1)) {
						@msgk = @msgk.' unsupported'
						@type = 'admin'
						_db_msg_Console('A message queued to Discord used too many embeds for the "embed" array. Use "embeds" for multiple embeds. Message not sent.', @guild, 'debug')
						export('DiscordBot.debug.sm.embed', @raw)
						die()
					}
				}
				if(@k == 'reference_id') {
					if(!is_numeric(@v)) {
						@msgk = color(12).@k.color('r')
						array_remove(@raw, @k)
					}
				}
				if(@k == 'custom_split') {
					@splitRegEx = @v
					console(@splitRegEx)
					array_remove(@raw, @k)
				}
				if(@k == 'message_id') {
					if(is_numeric(@v)) {
						@editMsg = @v
					}
					array_remove(@raw, @k)
				}
				@msg3 = @msg3.@msgk.' '
				continue()
			}
			@msg3 = @msg3.color(8).@k.' '.color('r')
			array_remove(@raw, @k)
		}
		if(array_index_exists(@raw, 'embeds') && array_index_exists(@raw, 'embed')) {
			if(array_index_exists(@raw['embeds'], 0)) {
				@raw['embeds'][] = @raw['embed'][0]
			} else {
				array_remove(@raw, 'embeds')
			}
		}
		if(!array_index_exists(@raw, 'content') && !array_index_exists(@raw, 'embeds')) {
			@msg3 = @msg3.'unsupported'
			@type = 'admin'
			_db_msg_Console(@msg3.' A message queued to Discord did not contain any Content or Embeds; nothing to send.', @guild, 'debug')
			export('DiscordBot.debug.sm.array', @raw)
			die()
		}
		@message = @raw
		_db_msg_Console(@msg3, @guild, 'debug')
	} else { 
		@message = array('content': @raw)
	}
	# Check if a message split is required
	@split = array()
	if(array_index_exists(@message, 'content')) {
		@message['content'] = strip_colors(@message['content'])
		@count = reg_count(@splitRegEx, @message['content'])
	}

# Assign Message Origination:
	switch(to_lower(@from)) {	
	case 'admin':
	case 'announce':
	case 'log':
	case 'ping':
	case 'bot':
	case 'none':
	case 'death':
	case 'command':
	case 'confirm':
		@caller = 'Bot'
	case 'cross':
	case 'discord':
	case 'say':
		@caller = 'Discord'
	case 'server':
	case 'console':
		@caller = 'Minecraft'
	default:
	# Minecraft Player chat
		@caller = 'Minecraft'
	}
	
# Message Formatting: Sanitize mentions, etc.
	if(array_index_exists(@message, 'content')) {
		@dm = false
		switch(@type){
		case 'pm':
		case 'dm':
		case 'message':
		case 'private':
			@dm = true
		}
	# Sanitize Mentions, Check custom mentions, setup allowed mentions
		if(@caller != 'Bot') {
			@sanitize = _db_sanitize_message(@message['content'], @caller, @guild, @from, @dm)
			@message['content'] = @sanitize['message']
			if(array_index_exists(@sanitize, 'allowed_mentions') && !array_index_exists(@message, 'allowed_mentions')) {
				array_set(@message, 'allowed_mentions', array('parse': @sanitize['allowed_mentions']))
			}
		}
	# Emojify
		if(@config['Use_Emojis'] == true) {		
			foreach(@emoji in reg_match_all('[:][^\\s./]+[:]', @message['content'])) {
				#returns: {{0: :match:}}
				@emojiID = _discordBot_find_emoji(@emoji[0], @guild)
				if(array_index_exists(@emojiID, 'NotFound')) { continue() }
				#Check if emoji belongs to this guild and conversion is allowed:
				if(@emojiID['guild'] != @guild && @config['Use_Other_Emojis'] == false) { continue() }
				#Convert emoji :emoji: markdown to bot version:
				@useAnimation = ''
				if(@emojiID['animated'] == true) { @useAnimation = 'a' }
				@message['content'] = replace(@message['content'], @emoji[0], '<'.@useAnimation.':'.@emojiID['name'].':'.@emojiID['id'].'>')
			}
		}	
	# Extra type formats:
		switch(to_lower(@from)) {
		case 'death':
			@message['content'] = ':skull_crossbones: '.@message['content']
		case 'command':
			@message['content'] = ':desktop: '.@message['content']
		case 'confirm':
			@message['content'] = ':white_check_mark: '.@message['content']
		default:
			if(@caller == 'Minecraft') {
			# Minecraft Player chat
				@message['content'] = '`['.@from.']` '.@message['content']
			}
		}
	# Split messages longer than 2000 chars
		if(reg_count(@splitRegEx, @message['content']) > 1) {
			for(@i = 1, @i <= @count, @i++) {
				@match = reg_match(@splitRegEx, @message['content'])[0]
				@split[] = @match
				@message['content'] = @message['content'][cslice(length(@match), (length(@message['content']) - 1))]
			}
		}
	# Send message data to Leaderboard
		@event = array('bot': true, 'serverid': @guild, 'username': @config['Bot_Name'], 'userid': @config['Bot_ID'], 'message': @message['content'], 'channel': @config['Log_Channel'])
		_discordBot_lb_process_message(@event, true)
	}
# Select Channel Presets:
	switch(to_lower(@from)) {
	case 'admin':
		@channel = @config['Log_Channel']
	case 'announce':
		@channel = @config['Announcement_Channel']
	case 'log':
		@channel = @config['Server_Log_Channel']
	case 'debug':
		@channel = @config['Log_Channel']
		@type = 'debug'
	case 'ping':
		if(array_index_exists(@config, 'Ping_Log_Channel')) { @channel = @config['Ping_Log_Channel'] } else { @channel = @config['Log_Channel'] }
	}
	switch(@type){
	case 'admin':
		@channel = @config['Log_Channel']
	case 'announce':
		@channel = @config['Announcement_Channel']
	case 'console':
		@channel = @config['Log_Channel']
		_db_msg_Console('[Send Message] '.@message['content'], @guild)
	case 'log':
		@channel = @config['Server_Log_Channel']
	case 'ping':
		if(array_index_exists(@config, 'Ping_Log_Channel')) { @channel = @config['Ping_Log_Channel'] } else { @channel = @config['Log_Channel'] }
	}
	
# Message Building:
	try {	
		switch(@type){
		case 'debug':
			_db_msg_Console(@message, 'debug')
			return(true);
		case 'admin':
		case 'announce':
		case 'console':
		case 'broadcast':
		case 'b':
		case 'log':
		case 'ping':
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) {
					@splitmsg = array('content': @msg)
					if(@i == (array_size(@split) - 1)) {
						if(array_index_exists(@message, 'embeds')) {
							array_set(@splitmsg, 'embeds', @message['embeds'])
						}
					}
					if(array_index_exists(@message, 'allowed_mentions')) {
						array_set(@splitmsg, 'allowed_mentions', @message['allowed_mentions'])
					}						
					if(array_index_exists(@message, 'reference_id')) {
						array_set(@splitmsg, 'reference_id', @message['reference_id'])
					}					
					discord_broadcast(@guild, @channel, @splitmsg, @afterMsg)
				}
			} else {
				if(@editMsg == 0) {
					discord_broadcast(@guild, @channel, @message, @afterMsg)
				} else {
# console('sm'.@guild.': '.@channel.' '.@editMsg)
					_discordBot_edit_message(@message, 'sm', @guild, @channel, @editMsg)
				}
			}
			return(true);
		case 'pm':
		case 'dm':
		case 'message':
		case 'private':
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) {
					if(@i == (array_size(@split) - 1)) {
						if(array_index_exists(@message, 'embeds')) {
							@msg = array('content': @msg, 'embeds': @message['embeds'])
						}
					}						
					discord_private_message(@channel, @msg)
				}
			} else {
				if(array_index_exists(@message, 'allowed_mentions')) { array_remove(@message, 'allowed_mentions') }
				if(array_index_exists(@message, 'reference_id')) { array_remove(@message, 'reference_id') }
				discord_private_message(@channel, @message)
			}
			return(true)
		case 'broadcast_embed':
		case 'embed':
			if(@option == '') { @option = 'the cool bot' }
			@sayicons = array('https://cdn.discordapp.com/emojis/511919341093257266.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919341118160912.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919341281738773.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919340740673536.webp?size=48&quality=lossless', 'https://cdn.discordapp.com/emojis/511919340837404672.webp?size=48&quality=lossless') 
			if(array_index_exists(@split, 0)) {
				foreach(@i: @msg in @split) { 
					@option = @option.' (Message '.(@i + 1).' of '.array_size(@split).')'
					discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @msg, 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': @option)))), @afterMsg)
				}
			} else {
				discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': @message['content']))), @afterMsg)
			}
			return(true)	
		case 'join':
			discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': '<:join:1066426544387543080> Joined:', 'description': @message['content']))), @afterMsg)
			return(true)
		case 'leave':
		case 'quit':
			discord_broadcast(@guild, @channel, array('embeds': array(array('thumbnail': 'https://cdn.discordapp.com/emojis/562416478230675456.webp?size=32&quality=lossless', 'title': '<:leave:1066426677481197618> Left: ', 'description': @message['content']))), @afterMsg)
			return(true)
		}
	} catch(InsufficientPermissionException @ex) {
		@msg = @ex['message']
		if(string_ends_with(@ex['message'], 'VIEW_CHANNEL')) {
			@msg = color(12).'Bot cannot view channel: '.@channel
		}
		_db_msg_Admins(@prefixErrorMsg.@msg, '[DiscordBot] ['.@guild.'] '.@msg)
		return(false)
	} catch(NotFoundException @ex) {
		_db_msg_Admins(@prefixErrorMsg.@ex['message'], '[DiscordBot] ['.@guild.'] '.@ex['message'])
		return(false)
	} catch(Exception @ex) {
		@traceDisplay = ''
		foreach(@st in @ex['stackTrace']) {
			@traceDisplay = @traceDisplay.'\n'.@st['id'].'  '.@st['line'].'.'.@st['col']
		}
		_db_msg_Admins(@prefixErrorMsg.@ex['message'], '[DiscordBot] ['.@guild.'] '.color(12).@ex['classType'].' '.color(7).@ex['message'].@traceDisplay)
		return(false)
	}
}

proc _discordBot_edit_message(@raw, @from, @guild, @channel, @msgID, @type, @option) {
	@botconfig = import('DiscordBot.config.Bot')
	if(!is_numeric(@channel)) { _db_msg_Console('Edit: Channel ID is not numeric!', @guild, 'error') return(false) }
	if(!is_numeric(@msgID)) { _db_msg_Console('Edit: Message ID is not numeric!', @guild, 'error') return(false) }
	@config = import('DiscordBot.config.'.@guild)
	if(!is_array(@config)) { return(false) }
	@count = 0
	@caller = 'Discord'
	@editMsg = 0
	if(@raw == '') { return(false) }
	if(@from == '' || is_array(@from)) { 
		if(function_exists('player')) { 
			@from = player()
			@caller = 'Minecraft'
		} else {
			@from = 'Discord'
		}
	}
	@message = array()
	if(is_array(@raw)) { @message = @raw } else { @message = array('content': @raw) }
# Assign Message Origination:
	switch(to_lower(@from)) {	
	case 'admin':
	case 'log':
	case 'bot':
	case 'none':
	case 'death':
	case 'command':
	case 'confirm':
		@caller = 'Bot'
	case 'cross':
	case 'discord':
	case 'say':
		@caller = 'Discord'
	case 'server':
	case 'console':
		@caller = 'Minecraft'
	case 'sm':
		@caller = 'sm'
	default:
	# Minecraft Player chat
		@caller = 'Minecraft'
	}
# Message Formatting: Sanitize mentions, etc.
	if(array_index_exists(@message, 'content') && @caller != 'sm') {
	# Sanitize Mentions, Check custom mentions, setup allowed mentions
		if(@caller != 'Bot') {
			@sanitize = _db_sanitize_message(@message['content'], @caller, @guild, @from, false)
			@message['content'] = @sanitize['message']
			if(array_index_exists(@sanitize, 'allowed_mentions') && !array_index_exists(@message, 'allowed_mentions')) {
				array_set(@message, 'allowed_mentions', array('parse': @sanitize['allowed_mentions']))
			}
		}
	# Emojify
		if(@config['Use_Emojis'] == true) {		
			foreach(@emoji in reg_match_all('[:][^\\s./]+[:]', @message['content'])) {
				#returns: {{0: :match:}}
				@emojiID = _discordBot_find_emoji(@emoji[0], @guild)
				if(array_index_exists(@emojiID, 'NotFound')) { continue() }
				#Check if emoji belongs to this guild and conversion is allowed:
				if(@emojiID['guild'] != @guild && @config['Use_Other_Emojis'] == false) { continue() }
				#Convert emoji :emoji: markdown to bot version:
				@useAnimation = ''
				if(@emojiID['animated'] == true) { @useAnimation = 'a' }
				@message['content'] = replace(@message['content'], @emoji[0], '<'.@useAnimation.':'.@emojiID['name'].':'.@emojiID['id'].'>')
			}
		}	
	# Extra type formats:
		switch(to_lower(@from)) {
		case 'death':
			@message['content'] = ':skull_crossbones: '.@message['content']
		case 'command':
			@message['content'] = ':desktop: '.@message['content']
		case 'confirm':
			@message['content'] = ':white_check_mark: '.@message['content']
		default:
			if(@caller == 'Minecraft') {
			# Minecraft Player chat
				@message['content'] = '`['.@from.']` '.@message['content']
			}
		}
	# refuse messages longer than 2000 chars
		if(length(@message['content']) > 1999) { _db_msg_Console(@prefixErrorMsg.'Message is longer than 2000 characters!', @guild, 'error') return(false) }
	}
	#Final edit setup
	if(!array_index_exists(@message, 'embeds') && array_index_exists(@message, 'embed')) {
		array_set(@message, 'embeds', array())
		@message['embeds'][] = @message['embed']
	}
	if(array_index_exists(@message, 'embeds')) {
		if(array_index_exists(@message, 'embed')) { array_remove(@message, 'embed') }
		foreach(@i: @embed in @message['embeds']) {
			if(array_index_exists(@embed, 'thumbnail')) {
				@message['embeds'][@i]['thumbnail'] = array('url': @embed['thumbnail'])
			}
			if(array_index_exists(@embed, 'color', 'r')) {
				@message['embeds'][@i]['color'] = 65536 * @embed['color']['r'] + 256 * @embed['color']['g'] + @embed['color']['b']
			}
			if(array_index_exists(@embed, 'timestamp')) {
				@message['embeds'][@i]['timestamp'] = simple_date('yyyy-MM-dd\'T\'HH:mm:ssZ', @embed['timestamp'])
			}
		}
	}
	discord_request('PATCH', 'channels/'.@channel.'/messages/'.@msgID, @message, closure(@result){ _db_msg_Console(color(10).'Edited Message ID '.color(7).@msgID, @guild) }, closure(@result){ _db_msg_Console(color(12).'Failed to Edit Message ID '.color(7).@msgID.'\n'.color('r').@result)}) 
	return(true)
}
	

proc _db_mc_broadcast(@msg, @args, @cr = false, @checkPermission = null) {
	if(function_exists('broadcast')) {
		if(!is_array(@args) && @args != '' && @args != null) { 
			if(@args == 'players' || @args == 'player') {
				@args = all_players() 
			} else if(!array_contains(all_players(), @args)) {
				_db_msg_Console('A Message Broadcast to Minecraft players failed: Players given were not found.', 'bot')
				return(false)
			}
		}
		if(is_array(@args) && @checkPermission != null && @checkPermission != '') {
			foreach(@i: @user in @args) {
				if(!has_permission(@user, @checkPermission)) {
					array_remove(@args, @i)
				}
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

proc _discordBot_send_mc_chat(@message, @player, @overrideChannel = null, @type = 'b') {
	if(@message == '' || @message == null) { return(false) }
	if(@player == '' || @player == null) {
		if(function_exists('player')) { 
			@player = player()
		} else {
			return(false)
		}
	}
	@botconfig = import('DiscordBot.config.Bot')
	@guilds = import('DiscordBot.Guilds', array());
	if(array_size(@guilds) == 0) { return(false) }
	foreach(@guild in @guilds) {
		@config = import('DiscordBot.config.'.@guild);
# Send message to guild's MC channel, if configured
		if(@config['Minecraft_Messages'] == false) { continue() }
		@channel = @config['Minecraft_Channel']
		# Primary Guild only: Accept channel overrides, if channel is in approved list
		if(@guild == @botconfig['Primary_Guild']) {
			if(@overrideChannel == '' || @overrideChannel == null) { @nc = 1 } else {
				if(array_contains(@config['Channels_Send'], @overrideChannel)) { 
					@channel = @overrideChannel
				}
			}
		}
		#Admin channel override
		if(@overrideChannel == 'admin') { @channel = @overrideChannel }
		_discordBot_send_message(@message, @guild, @player, @channel, @type)
	}
	return(true);
}

proc _discordBot_send_cs_chat(@discord, @option) {
	if(!is_array(@discord)) { return(false) }
	@botconfig = import('DiscordBot.config.Bot')
	@guilds = import('DiscordBot.Guilds', array());
	if(array_size(@guilds) == 0) { return(false) }
	#Message Formatting & File links
	@urls = array()
	@suffix = ''
	if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
		if(@discord['message'] == '') {
			@suffix = '<Sent a file> '
		} else {
			@suffix = @suffix.'\n <Also attached file:> '
		}
		foreach(@num: @attach in @discord['attachments']) {
			@urls[] = array('name': 'URL #'.(@num + 1), 'value': @attach['url'], 'inline': false)
			@filenum = 'File: '
			if(@num != 0) { @filenum = '  File #'.(@num + 1).': ' }
			@suffix = @suffix.@filenum.@attach['filename']
		}
	}
	#user avatar
	@userInfo = discord_member_info(@discord['serverid'], @discord['userid'])
	@userName = @userInfo['displayname']
	if(@userName == '' || @userName == null) { @userName = @userInfo['username'] }
	foreach(@guild in @guilds) {
		if(@discord['serverid'] == @guild) { continue() }
		@config = import('DiscordBot.config.'.@guild);
		if(@config['Cross_Server_Messages'] == false) { continue() }
		if(!array_index_exists(@config, 'Minecraft_Channel')) { continue() }
		@channel = @config['Minecraft_Channel']
		if(array_index_exists(@config, 'CS_Channel')) { @channel = @config['CS_Channel'] }
		@message = array('content': @discord['message'], 'embeds': array(array()))
		#Message Formatting
		if(reg_count('^.+\\/\\/tenor\\.com\\/view', @message['content']) > 0 && @config['CS_URL_Broadcast'] == false) {
			@message['content'] = '<Sent a GIF>'
		}
		@userPrefix = ''
		@userRefPrefix = '...'
		@prefixEscape = array('`', '[', ']')
	# Prefix user to the beginning of message
		if(@config['CS_Prefix_User'] == true) {
			# Limit user mention to if is a server member
			if(array_contains(discord_get_members(@guild), @discord['userid'])) {
				@userPrefix = @discord['userid']
				@prefixEscape = array('', '<@', '>')
			} else {
				@userPrefix = @userName
			}
			if(array_index_exists(@discord, 'reference', 'id')) {
				if(array_contains(discord_get_members(@guild), @discord['reference']['userid'])) {
					@userRefPrefix = '<@'.@discord['reference']['userid'].'>'
				} else {
					@userRefPrefix = @discord['reference']['username']
				}
			}
			# Limit prefix to 1 letter
			if(@config['CS_Prefix_Limit'] == true) {
				@prefixEscape = array('`', '[', '...]')
				@uP1 = reg_match('(?<a>[A-Za-z0-9])', @userName)
				if(array_index_exists(@uP1, 'a')) { @userPrefix = @uP1['a'] } else { @userPrefix = @userName[0] }
				if(array_index_exists(@discord, 'reference', 'id')) {
					@uP2 = reg_match('(?<a>[A-Za-z0-9])', @discord['reference']['username'])
					if(array_index_exists(@uP2, 'a')) { @userRefPrefix = @uP2['a'] } else { @userPrefix = @discord['reference']['username'][0] }
				}
			}
		} else {
			@userPrefix = @config['Server_Nickname']
		}
		@userPrefixEnd = ': '
		if(@discord['bot'] == true) { @userPrefixEnd = ' (Bot): ' }
		@userPrefix = @prefixEscape[0].@prefixEscape[1].@userPrefix.@prefixEscape[2].@prefixEscape[0].@userPrefixEnd
		if(array_index_exists(@discord, 'reference', 'id')) { @userRefPrefix = @prefixEscape[0].@prefixEscape[1].@userRefPrefix.@prefixEscape[2].@prefixEscape[0].':' }

# Option-add footer of chat from xyz server, thumbnail of user / author

	# Allow mention of username?
		@au = array()
		if(@config['CS_Mention_User'] == true) { @au[] = 'USER' }
		array_set(@message, 'allowed_mentions', array('parse': @au))
	# If the message provides a referenced message, show referenced message in an embed?
		if(@config['CS_Show_Reference'] == true) {
			if(array_index_exists(@discord, 'reference', 'message')) {
				@msgLength = length(@discord['reference']['message']) - 1
				@msgl2 = ''
				if(@msgLength > 240) { @msgLength = 240 @msgl2 = ' ...' }
				array_set(@message['embeds'][0], 'fields', array(array('name': 'Referenced Message', 'value': @userRefPrefix.'\n'.@discord['reference']['message'][cslice(0, @msgLength)].@msgl2, 'inline': false)))
			}
		}
	# Show URL links to attached files?
		if(array_index_exists(@urls, 0) && @config['CS_URL_Broadcast'] == true) {
			if(array_index_exists(@message, 'embeds', 0, 'fields')) {
				array_push_all(@message['embeds'][0]['fields'], @urls)
			} else {
				array_set(@message['embeds'][0], 'fields', @urls)
			}
		}
		if(array_size(@message['embeds'][0]) == 0) { array_remove(@message, 'embeds') }
		@message['content'] = @userPrefix.@message['content'].@suffix
		_discordBot_send_message(@message, @guild, 'cross', @channel)
	}
	return(true);
}


##########################################
### Backend Functions
##########################################

#### Cache & User Management

proc _discordBot_dc_add_member(@discord) {
	@membersID = import('DiscordBot.'.@discord['serverid'].'.members.ID')
	if(@membersID == null) { @membersID = get_value('DiscordBot.'.@discord['serverid'].'.members.ID') }
	if(!is_array(@membersID)) { @membersID = discord_get_members(@discord['serverid']) }
	if(!array_contains(@membersID, @discord['userid'])) {
		@membersID[] = @discord['userid']
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

proc _discordBot_backup_guild_data(@args) {
	@botconfig = import('DiscordBot.config.Bot')
	@guilds = import('DiscordBot.Guilds', array())
	if(array_size(@guilds) == 0) { return(false) }
	@writes = 0
	@lastUpdateTime = get_value('DiscordBot.last.CacheUpdate')
	if(!is_array(@lastUpdateTime)) { @lastUpdateTime = array() }
	@lastBackupTime = get_value('DiscordBot.last.Backup')
	if(!is_array(@lastBackupTime)) { @lastBackupTime = array() }
	foreach(@guild in @guilds) {
		#Update check
		if(array_index_exists(@lastBackupTime, @guild) && array_index_exists(@lastUpdateTime, @guild)) {
			if(@lastBackupTime[@guild] > @lastUpdateTime[@guild]) { continue() }
		}
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
		'Invites': get_value('DiscordBot.'.@guild.'.Invites'),
		'GuildInfo': get_value('DiscordBot.'.@guild.'.guild.Info'),
		'JoinInfo': get_value('DiscordBot.'.@guild.'.Join.info'),
		'LogJoinTimes': get_value('DiscordBot.'.@guild.'.log.users.Join.Times')
		)
		@time = time();
		foreach(@k: @v in @data) {
			if(@v == '' || @v == null) { continue() }
			if(is_array(@v) && array_size(@v) == 0) { continue() }
			_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/'.simple_date('MMyy', @time).'/'.@guild.'_'.simple_date('MM-dd-yy_HHmm_', @time).@k.'.json', json_encode(@v), 'CREATE')
			@writes++
		}
		array_set(@lastBackupTime, @guild, @time)
	}
	store_value('DiscordBot.last.Backup', @lastBackupTime)
	return(@writes)
}

proc _discordBot_update_members(@useguild = 0) {
	x_new_thread('DiscordBotUpdate', closure(){
		@startTime = time();
		@guilds = import('DiscordBot.Guilds', array());
		if(@useguild != 0 && is_numeric(@useguild)) {
			@guilds = array(@useguild)
		}
		if(array_size(@guilds) == 0) { return(false) }
		@lastUpdateTime = get_value('DiscordBot.last.CacheUpdate')
		if(!is_array(@lastUpdateTime)) { @lastUpdateTime = array() }
		foreach(@guild in @guilds) {
			@debugstats = array('size': array(), 'nf': 0, 'af': 0, 'fails': 0);
		#Guild Infos
			x_new_thread('DiscordBotUpdateGuildInfo'.rand(1153,5407), closure(){
				_discordBot_get_server_info(@guild);
			});
			if(array_index_exists(@lastUpdateTime, @guild)) {
				if(import('DiscordBot.'.@guild.'.CacheUpdate') != true) { continue() }
			} else { 
				array_set(@lastUpdateTime, @guild, @startTime)
			}
			@guildInfo = import('DiscordBot.Guilds.Info.'.@guild)
		#Members Cache and Activity Updates
			@membersID = array();
			try {
				@membersID = discord_get_members(@guild);
			} catch(NotFoundException @ex) {
				array_remove_values(@guilds, @guild);
				_db_msg_Admins('[DiscordBot] Bot is not a member of guild "'.@guild.'"! Removed from active guild list.')
				continue();
			}
			@membersNames = array();
			@membersNamesDisplay = array();
			@membersRoles = array();
			@membersInfo = array();
			@membersWR = array();
			@membersNoRoles = array();
			@totalroles = array();
			@rolesMembers = array();
			@activeUsers = array();
			@config = import('DiscordBot.config.'.@guild);
			@leaderboard = import('DiscordBot.'.@guild.'.Leaderboard');
			@invites = get_value('DiscordBot.'.@guild.'.Invites');
			@logJointimes = get_value('DiscordBot.'.@guild.'.log.users.Join.Times')
			if(!is_array(@logJointimes)) { @logJointimes = array() }
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
						_db_msg_Console(color(12).'Invite Logging is Enabled, but bot does not have permission to view invites!', @guild)
					} else {
						_db_msg_Console(@ex['message'], @guild)
					}
				} catch(Exception @ex) {
					_db_msg_Console(@ex['message'], @guild)
				}
			}
			# @rankstats = get_value('DiscordBot.debug.'.@guild.'.rank.stats')
			# @activeuserstats = get_value('DiscordBot.debug.'.@guild.'.activeuser.stats')
			# if(!is_array(@rankstats)) { @rankstats = array() }
			# if(!is_array(@activeuserstats)) { @activeuserstats = array() }	
			@rankstats = array()
			@activeuserstats = array()
	# Process each User ID
			foreach(@index: @id in @membersID) {
		# Member Info (avatar, isBot, Username, etc)
				@idInfo = ''
				@idLastMsg = 0
				@idLevel = 0
				@consoleMsg = ''
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
				if(@idInfo['displayname'] != null && @idInfo['displayname'] != @idInfo['username']) {
					array_set(@membersNamesDisplay, @idInfo['displayname'], @id)
				}
			# Config Updates if bot User
				if(@id == @config['Bot_ID']) {
					if(@idInfo['nickname'] != '') { @config['Bot_Name'] = @idInfo['nickname'] } else { @config['Bot_Name'] = @idInfo['nickname'] }
					export('DiscordBot.config.'.@guild, @config);
				}
			# Add User Join time to logs, if not present
				if(!array_index_exists(@logJointimes, @id)) { array_set(@logJointimes, @id, array()) }
				if(!array_index_exists(@logJointimes, @id, 0)) {
					array_insert(@logJointimes[@id], @idInfo['joined_at'], 0)
				}
			# pseudo array for functions that expect event array
				@discord = array('bot': @idInfo['bot'], 'serverid': @guild, 'userid': @id, 'username': @idInfo['username'])
			# Leaderboard: Avatars, usernames, role color
				if(@config['LB_Enable'] == true && is_array(@leaderboard) && @idInfo['bot'] == false) {
					if(array_index_exists(@leaderboard, 'members', @id)) {
						@newavatar = reg_match('([^/]+)[.][A-Za-z]{2,}$', @idInfo['avatar'])
						@newcolor = 'fff'
						if(@idInfo['color'] != null) { @newcolor = _rgb_to_hex(@idInfo['color']) }
						if(array_index_exists(@newavatar, 1)) { array_set(@leaderboard['members'][@id], 'avatar', @newavatar[1]) }
						array_set(@leaderboard['members'][@id], 'color', @newcolor)
						array_set(@leaderboard['members'][@id], 'username', @idInfo['username'])
						if(array_index_exists(@leaderboard, 'members', @id, 'last_msg')) {	
							@idLastMsg = @leaderboard['members'][@id]['last_msg']
							@idLevel = @leaderboard['members'][@id]['level']
						}
					}
				}
			# Roles: Check for No Roles
				@idRoles = discord_member_get_roles(@guild, @id);
				if(!is_array(@idRoles)) {
					@debugstats['af']++
					continue()
				}
				if(array_size(@idRoles) == 0) {
					@membersNoRoles[] = @id;
					continue()
				}
				@idRoles2 = array_normalize(@idRoles)			
			# Add/Remove user to Active role (bots excluded)
				if(@config['LB_Enable'] == true && is_array(@leaderboard) && @idInfo['bot'] == false) {
					if(@config['LB_Options']['Use_Active_User_Role'] == true) {
						@auType = ''
						# if last message was less than 60 days ago, add to active
						if(@idLastMsg > (@startTime - 5184000000)) {
							@auType = 'add'
							@activeUsers[] = @id
						} else {
							@auType = 'remove'
						}
						@auStats = _discordBot_process_activeuserrole(@discord, @auType, @idRoles, false, @idLevel);	
						if(@auStats == 'Added') { @consoleMsg = @consoleMsg.color(10).'<active>'.color('r') }
						if(@auStats == 'Removed') { @consoleMsg = @consoleMsg.color(14).'<inactive>'.color('r') }
						if(@auStats != 'No Change') { array_set(@activeuserstats, @idInfo['username'], @auStats); }
					}
				}
			# Add discovered roles to Total roles ( id: name )
				foreach(@k: @v in @idRoles) {
					if(!array_contains(array_keys(@totalroles), @v)) {
						array_set(@totalroles, @v, @k)
					}
				}
			# Save User's roles to main cache
				array_set(@membersRoles, @id, @idRoles)
				
			# --- Next few items don't count if just Active user role
				if(array_contains(@idRoles2, @config['LB_Options']['Active_User_Role'])) { array_remove_values(@idRoles2, @config['LB_Options']['Active_User_Role']) }	
				# if(@idInfo['color'] == null) { _db_msg_Console(@id.' i '.@idInfo, @guild, 'debug') }
			# Check no roles again, count users who just have active role
				if(array_size(@idRoles2) == 0) {
					@membersNoRoles[] = @id;
					continue()
				}	
			# If Just welcome roles, add member to WR
				if(array_size(@idRoles2) == array_size(@sortWR)) {
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
					@rrStats = _discordBot_process_role_ranks(@discord, @idRoles, true)
					if(is_array(@rrStats)) {
						if(@rrStats['setRoles'] == true) { 
							@rrUpdates++
							@consoleMsg = @consoleMsg.@rrStats['rrMsg'].color('r')
						}
					} else {
						@consoleMsg = @consoleMsg.color(8).'(RR) '.@rrStats.color('r')
					}
					array_set(@rankstats, @idInfo['username'], @rrStats)
				}
			# Console Messages
				if(@consoleMsg != '') {
					_db_msg_Console(color(9).'('.@index.')'.color('r').'['.@idInfo['username'].'] '.@consoleMsg, @guild);
				}
			}
		# Roles Members
			foreach(@roleid: @rolename in @totalroles) {
				array_set(@rolesMembers, @roleid, array())
			}
			foreach(@memberid: @mr in @membersRoles) {
			# server member roles array: id: {role: 123, role2: 4235}
				foreach(@roleName: @roleID in @mr) { 
					@rolesMembers[@roleID][] = @memberid
				}
			}
		# Save data
			array_set(@lastUpdateTime, @guild, @startTime)
			@alldebugstats = import('DiscordBot.debug.stats.last.updatemembers', array())
			if(@config['LB_Enable'] == true && is_array(@leaderboard)) { export('DiscordBot.'.@guild.'.Leaderboard', @leaderboard) }
			array_set(@debugstats['size'], 'rrUp', @rrUpdates)
			export('DiscordBot.'.@guild.'.user.update.time.rr', null)
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
			store_value('DiscordBot.'.@guild.'.members.names.display', @membersNamesDisplay)
			array_set(@debugstats['size'], 'mn-d', array_size(@membersNamesDisplay))
			store_value('DiscordBot.'.@guild.'.members.roles.welcomeroles', @membersWR)
			array_set(@debugstats['size'], 'wr', array_size(@membersWR))
			store_value('DiscordBot.'.@guild.'.members.roles.none', @membersNoRoles)
			array_set(@debugstats['size'], 'norole', array_size(@membersNoRoles))
			export('DiscordBot.'.@guild.'.members.names', @membersNames)
			store_value('DiscordBot.'.@guild.'.members.info', @membersInfo)
			export('DiscordBot.'.@guild.'.members.info', @membersInfo)
			array_set(@debugstats['size'], 'mi', array_size(@membersInfo))
			if(is_array(@invites)) { array_set(@debugstats['size'], 'inv', array_size(@invites)) }
			array_set(@debugstats['size'], 'au', array_size(@activeUsers))
			store_value('DiscordBot.'.@guild.'.log.users.Join.Times', @logJointimes)
			export('DiscordBot.'.@guild.'.CacheUpdate', null)
			export('DiscordBot.'.@guild.'.returning.users', null)
			array_set(@alldebugstats, @guild, @debugstats)
			export('DiscordBot.debug.stats.last.updatemembers', @alldebugstats)
			store_value('DiscordBot.debug.'.@guild.'.rank.stats', @rankstats)
			store_value('DiscordBot.debug.'.@guild.'.activeuser.stats', @activeuserstats)
/* 			foreach(@k: @v in @activeuserstats) {
				if(@v == 'No Change') { continue() }
				_db_msg_Console('['.@k.'] active: '.@v, @guild)
			} */
		}
		store_value('DiscordBot.last.CacheUpdate', @lastUpdateTime)
		@timeElapsed = time() - @startTime;
		_db_msg_Console('Update:  '.color(3).@timeElapsed.'ms', 'none', 'bot')
		return(true);
	});
}

proc _discordBot_process_role_ranks(@discord, array @userRoles = array(), @isloop = false) {
#SINGLE user only, call via a foreach if all is desired
	if(!is_array(@discord)) { return('No data') }
	if(!array_index_exists(@discord, 'userid')) { return('No user') }
	if(!array_index_exists(@discord, 'serverid')) { return('server?') }
	@config = import('DiscordBot.config.'.@discord['serverid'])
	if(!is_array(@config['Role_Ranks'])) { return('no rank data') }
	@ranknums = array_sort(array_keys(@config['Role_Ranks']), 'NUMERIC')
	if(@config['Role_Ranks_IgnoreAdmin'] == true) {
		foreach(@irole in @config['Role_Admins']) {
			if(array_contains(@userRoles, @irole) || array_index_exists(@userRoles, @irole)) {
				return('ignored Admin');
			}
		}
	}
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
# Count role separators
	@sRoles = 0
	foreach(@role in @config['Role_Ranks_Separators']) {
		if(array_contains(@userRoles, @role)) {
			@sRoles++
		}
	}
# Count which Bonus Roles are present: If an associated role is not present from above list, then check these additional Roles:
	if(array_index_exists(@config, 'Role_Ranks_QR_Bonus')) {
		foreach(@roleNotPresent: @BonusRole in @config['Role_Ranks_QR_Bonus']) {
			if(!array_contains(@userRoles, @roleNotPresent) && array_contains(@userRoles, @BonusRole)) {
				@qRoles++
			}
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
# Set up Role Separators
	@rsMsg = ''
	@rsType = ''
	if(@config['Use_Role_Ranks_Separators'] == true) {
		foreach(@roledata in @config['Role_Ranks_Separators']) {
			if(@newRank > 0) {
				if(!array_contains(@newRoles, @roledata)) {
					@newRoles[] = @roledata
					@rsMsg = ', Added Separator roles'
					@rsType = '[A]'
				}
			} else if(array_contains(@newRoles, @roledata)) {
				array_remove_values(@newRoles, @roledata)
				@rsMsg = ', Removed Separator roles'
				@rsType = '[R]'
			}
		}
	}
# Setup Messages
	@logmsg = 'Role Ranks: 0 roles'.@rsMsg
	if(@newRank != 0) {
		@newRoles[] = @config['Role_Ranks'][@newRank]['RoleID'];
		@logmsg = 'Awarded Role Rank "'.@config['Role_Ranks'][@newRank]['RoleName'].'"'.@rsMsg
	}
	if(@newRank < @currentRank) {
		@logmsg = 'Role Ranks: Derank! ('.@newRank.' < '.@currentRank.')'.@rsMsg
		array_set(@stats, 'derank', true)
	}
	if(@newRank == @currentRank && @rRoles > 1) {
		@logmsg = 'Role Ranks: Removing '.(@rRoles - 1).' of Multiple Rank Roles'.@rsMsg
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
		@rrMsgPrefix = '['.@discord['username'].'] '
		if(@isloop == true) { @rrMsgPrefix = '' }
		@rrMsgType = color(7).'='
		if(array_index_exists(@stats, 'derank')) { @rrMsgType = color(14).'>' }
		if(@currentRank < @newRank) { @rrMsgType = color(10).'<' }
		@rrMsg = @currentRank.' '.@rrMsgType.' '.color('r').@newRank.color(8).' ('.@qRoles.')'.@rsType
		if(@currentRank == @newRank && @rRoles > 1) {
			@rrMsg = @rrMsgPrefix.color(11).'Multiple Rank Roles: '.@rRoles.@rsType
		}
		if(@isloop == false) {
			_db_msg_Console(@rrMsgPrefix.@rrMsg, @discord['serverid'])
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


#### Leaderboard Management

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
	@userRoles = array()
	@newWords = array_size(parse_args(@discord['message']))
# New Joiner Timeout, default is 10 seconds before MemberJoin handles these arrays. During this time typically Discord's default join message occurs, *which is sent under the user's userid* and not as system.
	@checkwm = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', array())
	@checkinv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())
	if(array_index_exists(@checkinv, @discord['userid']) || array_index_exists(@checkwm, @discord['userid'])) { return(false) }
# Setup No XP earning	
	@xpType = 2
	if(@noXP == true) {
	# Event consumed
		@xpType = 0
		# If new user: Presuming antispam action
		@newuser = _db_is_newmember(@discord['serverid'], @discord['userid']);
		if(@newuser == true) { return(false) }
	}
	# Do not count XP on messages from 1) Channels marked as no XP earning 2) Command spam channel
	if(array_contains(@config['LB_Options']['NoXP_Channels'], @discord['channel']) || @discord['channel'] == @config['CMD_Default_Channel']) {
		@noXP = true 
		@xpType = 0 
	}
# Setup Level XP
	@levelxp = import('DiscordBot.'.@discord['serverid'].'.Leaderboard.levelXP')
	if(@levelxp == null) {
		@levelxp = _discordBot_lb_levelXP(@discord['serverid'], @config['LB_Options']['XP_Type']);
		array_set(@leaderboard['options'], 'levelXP', @levelxp)
		if(array_index_exists(@config, 'LB_Options', 'Custom_Name')) {
			array_set(@leaderboard, 'Guild_Name', @config['LB_Options']['Custom_Name'])
		} else {
			@serverInfo = import('DiscordBot.Guilds.Info.'.@discord['serverid'], array('name': null))
			if(@serverInfo['name'] != null) {
				array_set(@leaderboard, 'Guild_Name', @serverInfo['name'])
			}
		}
		if(!array_index_exists(@leaderboard, 'averages')) {
			array_set(@leaderboard, 'averages', array('words': array('msgs': 0, 'count': 0)))
		}
	}
# Setup Array entries
	if(!array_index_exists(@leaderboard, 'members', @userID)) {
		array_set(@leaderboard['members'], @userID, array('all_xp': array(0, 0, 0), 'last_msg': 0, 'level': 0, 'xp': 0, 'username': @discord['username'], 'msg_count': 0, 'words': 0))
	}
	if(!array_index_exists(@leaderboard, 'members', @userID, 'all_xp', 2)) { array_set(@leaderboard['members'][@userID], 'all_xp', array(0, 0, @leaderboard['members'][@userID]['xp'])) }
	if(!array_index_exists(@leaderboard, 'members', @userID, 'words')) { array_set(@leaderboard['members'][@userID], 'words', 0) }
	@xptimer = import('DiscordBot.'.@discord['serverid'].'.Leaderboard.xptimer', array('123': 456))
	if(!array_index_exists(@xptimer, @userID)) {
		array_set(@xptimer, @userID, (time() - 70000))
	}
# If user has last chatted in last rolling minute, do not award XP. (continues to count message)
	if((@xptimer[@userID] + 60000) > time()) {
		#If already true, presume botspam
		if(@noXP == false) {
			@noXP = true
			@xpType = 1
		}
	} else {
# Check if user has a no XP earning role.
		# Adds user to Active User role, Gets new saved roles from check, if available
		@userRoles = _discordBot_process_activeuserrole(@discord, 'add', array(), true, @leaderboard['members'][@userID]['level']);
		if(!is_array(@userRoles)) {	
			try {
				@userRoles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
			} catch(Exception @ex) {
				if(@discord['bot'] == false) {
					return(false)
				}
			}
		}
		if(@discord['bot'] == true) {
			array_set(@leaderboard['members'][@userID], 'bot', true)
			@xpType = 0
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
	@leaderboard['members'][@userID]['words'] = @leaderboard['members'][@userID]['words'] + @newWords
	@leaderboard['averages']['words']['msgs']++
	@leaderboard['averages']['words']['count'] = @leaderboard['averages']['words']['count'] + @newWords
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
###############################################################################################################################
# Max level
	if(!array_index_exists(@levelxp, (@leaderboard['members'][@userID]['level'] + 1))) {
		_db_msg_Console('Level Up: '.@discord['username'].' <@'.@userID.'> is at the maximum level '.@leaderboard['members'][@userID]['level'].'!', @discord['serverid'])
		export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
		return(false)
	}
# Level UP
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
		array_set(@saveoldroles, 'lastedit', time())
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
			@userRoles[] = @currentrank['RoleID']
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
		@discordMsg = replace(@config['LB_Options']['Level_Up_Message'], '%UserID%', '<@'.@userID.'>')
		@discordMsg = replace(@discordMsg, '%Level%', @leaderboard['members'][@userID]['level'])
		@discordMsg = replace(@discordMsg, '%MsgCount%', @leaderboard['members'][@userID]['msg_count'])
		if(@newrankname == '') {
			@discordMsg = replace(@discordMsg, '%LevelDisplay%', 'Level '.@leaderboard['members'][@userID]['level'].'!')
		} else {
			@discordMsg = replace(@discordMsg, '%LevelDisplay%', @newrankname.'!  ('.@leaderboard['members'][@userID]['level'].')')
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
			@outMsg = array('content': @discordMsg)
			if(@config['LB_Options']['Level_Up_Announce_Reference'] == true) { array_set(@outMsg, 'reference_id', @discord['id']) }
			_discordBot_send_message(@outMsg, @discord['serverid'], 'confirm', @sendchannel, @type)
		}
	}
# Save Edits
	@leaderboard['lastedit'] = time()
	export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
	export('DiscordBot.'.@discord['serverid'].'.Leaderboard.xptimer', @xptimer)
	return(true)
}

proc _discordBot_process_activeuserrole(@discord, @type, @userRoles = array(), @retRoles = false, @lbLevel = 0) {
	if(!is_array(@discord)) { return('No data') }
	if(!array_index_exists(@discord, 'userid')) { return('No user') }
	if(!array_index_exists(@discord, 'serverid')) { return('server?') }
	if(@discord['bot'] == true) { return('bot') }
	@config = import('DiscordBot.config.'.@discord['serverid']);
	if(array_index_exists(@config, 'LB_Options', 'Active_User_Role_Not_Found')) { 
		if(import('DiscordBot.debug.au.roleexist.msg') != true) {
			_db_msg_Console('['.@discord['serverid'].'] Active user role '.@config['LB_Options']['Active_User_Role'].' does not exist!', @discord['serverid'], 'debug')
			export('DiscordBot.debug.au.roleexist.msg', true)
		}
		@config['LB_Options']['Use_Active_User_Role'] = false
	}
	if(array_size(@userRoles) == 0) {
		try { 
			@userRoles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
		} catch(Exception @ex) {
			return('Not a member')
		}
	}
	if(@config['LB_Options']['Use_Active_User_Role'] != true) {
		if(@retRoles == true) {
			return(@userRoles)
		} else {
			return('disabled')
		}
	}
	#check min level
	if(@config['LB_Options']['Active_User_Role_Min_Level'] > @lbLevel) { @type = 'remove' }

# Check if user has the Active User role.
	@hasActiveRole = false
	@roleMsg = ''
	@index = ''
	@ret = 'No Change'
	if(array_contains_ic(array_keys(@userRoles), @config['LB_Options']['Active_User_Role']) || array_contains(@userRoles, @config['LB_Options']['Active_User_Role'])) {
		@hasActiveRole = true
		if(is_numeric(@config['LB_Options']['Active_User_Role'])) {
			@index = array_index(@userRoles, @config['LB_Options']['Active_User_Role'])
		} else {
			@index = @config['LB_Options']['Active_User_Role']
		}
	}
# Add / Remove role
	switch(string(@type)) {
	case '+':
	case 'add':
	case 'true':
	# Add user to Active role
		if(@hasActiveRole == false) {
			@userRoles[] = @config['LB_Options']['Active_User_Role']
			@roleMsg = 'Awarded Active User role'
			@ret = 'Added'
		}
	case '-':
	case 'remove':
	case 'false':
		if(@hasActiveRole == true) {
			array_remove(@userRoles, @index)
			@roleMsg = 'Inactivity: Removed Active User role'
			@ret = 'Removed'
		}
	default:
		@ret = 'Neutral'
	}	
# Set New roles
	if(@roleMsg != '') {	
		try { 
			discord_member_set_roles(@discord['serverid'], @discord['userid'], @userRoles, @roleMsg)
		} catch(Exception @ex) {
			_db_msg_Console('['.@discord['username'].'] Active user role: '.@ex['classType'].' '.@ex['message'], @discord['serverid'], 'debug')
			@ret = 'Failed'
		}
	}
# Return Role array if requested, else return status
	if(@retRoles == true) { return(@userRoles) }
	return(@ret)
}

proc _discordBot_lb_levelXP(@guild = 'default', @preset = 1) {
	@levelxp = array(0, 100, 250, 450)
	array_resize(@levelxp, 200)
	@d1 = 10
	@d2 = 12
	switch(@preset) {
	case 0:
	# mee6's XP
		@d1 = 5
		@d2 = 6
	case 'hard':
		@d1 = 6
		@d2 = 4
	case 'easy':
		@d1 = 4
		@d2 = 8
	case 1:
	default:
	# cypher139's XP version - Allows to reach new levels easier.
		@d1 = 4
		@d2 = 5
	}
	foreach(@i: @lvl in @levelxp) {
		if(@i < 4) { continue() }
		# Mee6 XP formula:
		# https://github.com/randomairborne/experienced/blob/main/mee6/src/lib.rs
		# https://github.com/Mee6/Mee6-documentation/blob/master/docs/levels.md
		# The operation used to calculate how many XP a given level is is (5 / 6) * level * (2 * level * level + 27 * level + 91)
		@levelxp[@i] = integer((@d1 / @d2) * @i * (2 * @i * @i + 27 * @i + 91))
	}
	export('DiscordBot.'.@guild.'.Leaderboard.levelXP', @levelxp)
	_write_file(import('DiscordBot.logs.dir').'/'.@guild.'/Leaderboard_LevelXP.json', json_encode(@levelxp), 'CREATE')
	return(@levelxp)
}


#### Bot Command Functions

proc _db_is_newmember(@guild, @userid) {
	if(!is_numeric(@guild)) { return(0) }
	if(!is_numeric(@userid)) { return(0) }
	@config = import('DiscordBot.config.'.@guild);
	@newuser = false
	@userJoinTime = 0
	try {
		@userJoinTime = discord_member_info(@guild, @userid)['joined_at']
	} catch(NotFoundException @ex) {
		export('DiscordBot.'.@guild.'.debug.user.not.found.'.@userid, 1)
	}
	if((@userJoinTime + @config['AS_New_User_Time']) > time()) { @newuser = true }
	if(@newuser == true) {
		# Returning users: Bypass new user checks
		@newreturn = import('DiscordBot.'.@guild.'.returning.users')
		if(!is_array(@newreturn)) { @newreturn = array() }
		if(array_index_exists(@newreturn, @userid)) {
			if(@newreturn[@userid] == true) { @newuser = false }
		} else {
			@joininfo = get_value('DiscordBot.'.@guild.'.Join.info')
			if(!is_array(@joininfo)) { @joininfo = array() } 
			if(array_index_exists(@joininfo, @userid, 'return')) {
				array_set(@newreturn, @userid, @joininfo[@userid]['return'])
				if(@joininfo[@userid]['return'] == true) { @newuser = false } 
			} else {
				array_set(@newreturn, @userid, false)
			}
			export('DiscordBot.'.@guild.'.returning.users', @newreturn)
		}
	}
	return(@newuser)
}

proc _discordBot_ismention(@discord, @regexPrefix = '^') {
	@botconfig = import('DiscordBot.config.Bot')
	@botinfo = import('DiscordBot.Bot.Info')
	@isMention = false
	if(is_array(@discord)) {
		if(!array_index_exists(@discord, 'serverid') || !array_index_exists(@discord, 'message')) {
			_db_msg_Console('User message not given to ismention!', @discord['serverid'], 'debug')
			return(false)
		}
	} else {
		_db_msg_Console('Required Discord data not given to ismention!', 'debug')
		return(false)
	}
	# Mentions:
	if(reg_count(@regexPrefix.'[@]'.@botconfig['Bot_Name'].'\\s', @discord['message']) > 0) {
		@isMention = true
	}
	if(reg_count(@regexPrefix.'[@]'.@botinfo['displayname'].'\\s', @discord['message']) > 0) {
		@isMention = true
	}
	return(@isMention)
}

#Handle commands from Discord Users
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
		@returns[] = @return
	}
	return(@returns)
}		

proc _discordBot_iscommand(@discord, @returnType = 'a', @regexPrefix = '^') {
	@botconfig = import('DiscordBot.config.Bot')
	@botinfo = import('DiscordBot.Bot.Info')
	@isCmd = false
	@userserver = 0
	if(is_array(@discord)) {
		if(!array_index_exists(@discord, 'message')) {
			_db_msg_Console('User message not given to isCommand!', 'debug')
			return(false)
		}
	} else {
		_db_msg_Console('Required Discord data not given to isCommand!', 'debug')
		return(false)
	}
	if(!array_index_exists(@discord, 'UseDM')) { array_set(@discord, 'UseDM', '') }	
	if(@discord['UseDM'] != 'dm') {
		@config = import('DiscordBot.config.'.@discord['serverid'])
		# Prefix:
		if(reg_count(@config['CMD_Command_Prefix'], @discord['message']) > 0) { @isCmd = true }
		# Mentions:
		if(reg_count(@regexPrefix.'[@]'.@botconfig['Bot_Name'].'\\s', @discord['message']) > 0) { @isCmd = true }
		if(reg_count(@regexPrefix.'[@]'.@botinfo['displayname'].'\\s', @discord['message']) > 0) { @isCmd = true }
	} else {
		# from DM
		# Check for each server's Command prefix
		foreach(@guild in import('DiscordBot.Guilds')) {
			@cfg = import('DiscordBot.config.'.@guild)
			if(array_contains(discord_get_members(@guild), @discord['userid']) && reg_count(@cfg['CMD_Command_Prefix'], @discord['message']) > 0) {
				@isCmd = true
				@userserver = @guild
				break()
			}
		}
		if(@isCmd == true && @returnType == 'id') {
			return(@userserver)
		} else {
		# Prefix not found, check for first word matches a command name
			@cmdList = import('DiscordBot.Command.List.Name')
			@check = parse_args(@discord['message'])
			if(is_array(@cmdList) && array_size(@check) > 0) {
				if(array_index_exists(@cmdList, to_lower(@check[0]))) {
					@isCmd = true
				}
			}
		}
	}	
	return(@isCmd)
}

proc _discordBot_handlecommand(@discord, @dm, @cmdfrom) {
	@StartTime = time()
	@sendLogMsg = true
	@botconfig = import('DiscordBot.config.Bot')
	@botinfo = import('DiscordBot.Bot.Info')
	@cmdfromdis = ''
	@editMsg = 0
	@returnMsg = array('content': 'Debug')
	if(is_array(@discord)) {
		if(!array_index_exists(@discord, 'time')) {
			array_set(@discord, 'time', time())
		}
		if(!array_index_exists(@discord, 'serverid')) {
			array_set(@discord, 'serverid', 0)
		}
		if(!array_index_exists(@discord, 'userid')) {
			_db_msg_Console('User Data not given to Command Handler!', @discord['serverid'], 'debug')
			return(false)
		}
	} else {
		_db_msg_Console('Required Discord data not given to Command Handler!', 'debug')
		return(false)
	}
	#Check for specified server, if not given already. User must be a member of that server!
	if(@discord['serverid'] == 0 || @cmdfrom == 'dm') {
		@guilds = import('DiscordBot.Guilds')
		foreach(@i: @v in parse_args(@discord['message'])) {
			if(is_numeric(@v) && length(@v) > 15 && array_contains(@guilds, @v)) {
				@discord['serverid'] = @v
				@discord['message'] = replace(@discord['message'], @v, '')
			}
		}
	}
	if(@discord['serverid'] == 0) {
		console('I\'m unsure of which guild you want me to use this command on! trying Primary Guild')
		@discord['serverid'] = @botconfig['Primary_Guild']
	}
	if(!array_contains(discord_get_members(@discord['serverid']), @discord['userid'])) {
		console('User not a member!')
		return('UserNotServerMember')
	}
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@return = false
	@CmdReturn = ''
	# Setup And Load Command Actions
	if(is_proc('_discordBot_cmd_help') != true) {
		include_dir('command.library')
		_discordBot_init_cmd_list()
	}
	@actions = import('DiscordBot.Command.List', array())
	@commandList = import('DiscordBot.Command.List.Name', array())
	switch(@dm) {
	case 'dm':
	case 'pm':
	case 'message':
		@dm = 'dm'
		array_set(@discord, 'SendChannel', @discord['userid'])
		@cmdfromdis = ' in DM'
	case 'edit':
		@commandReplyIDs = import('DiscordBot.'.@discord['serverid'].'.Cache.Cmd.Messages.sent.IDs')
		if(!is_array(@commandReplyIDs)) { @commandReplyIDs = array() }
		if(array_index_exists(@commandReplyIDs, @discord['id']) && to_lower(@config['CMD_Message_Action']) != 'delete') {
			if(@commandReplyIDs[@discord['id']]['time'] > (time() - 86400000)) { 
				@editMsg = @commandReplyIDs[@discord['id']]['id'] 
				@cmdfromdis = ' (via message edit)'
			}
		}
		@dm = 'broadcast'
		array_set(@discord, 'SendChannel', @discord['channelid'])
	case '':
	default:
		@dm = 'broadcast'
		array_set(@discord, 'SendChannel', @discord['channelid'])
	}
	switch(@cmdfrom) {
	case 'batch':
		@cmdfromdis = ' (via Batch file)'
	default:
		if(@dm == 'dm') { @cmdfromdis = ' in DM' }
	}
	array_set(@discord, 'UseDM', @dm)

	if(@editMsg > 0 && to_lower(@config['CMD_Message_Action']) != 'delete') {
		array_set(@returnMsg, 'message_id', @editMsg)
	}
	@afterMsg = closure(@msgID) {
		@cacheID = import('DiscordBot.'.@discord['serverid'].'.Cache.Cmd.Messages.sent.IDs')
		if(!is_array(@cacheID)) { @cacheID = array() }
		array_set(@cacheID, @discord['id'], array('id': @msgID, 'time': time()))
		if(array_index_exists(@cacheID, @botconfig['Msg_Cache_Cmd'])) { array_remove(@cacheID, @botconfig['Msg_Cache_Cmd']) }
		export('DiscordBot.'.@discord['serverid'].'.Cache.Cmd.Messages.sent.IDs', @cacheID)
		return(true)
	}
#Check User Permissions
	#to  check: does get roles work in a dm
	@userType = 'User'
	@isAdmin = false
	try {
		foreach(@rN: @rID in discord_member_get_roles(@discord['serverid'], @discord['username'])) {
			if(array_contains_ic(@config['Role_Admins'], @rN) || array_contains(@config['Role_Admins'], @rID)) {
				@userType = 'Admin'
				@isAdmin = true
				break()
			}
		}
	} catch(Exception @ex) {
		_db_msg_Console('Cmd isAdmin check: '.@ex, @discord['serverid'], 'error')
		return('NotAdmin')
	}
###############
	# _db_msg_Console(@actions, @discord['serverid'], 'debug')
	# _db_msg_Console(@commandList, @discord['serverid'], 'debug')
###############
# Extract Command
	@msgcheck = reg_replace(@config['CMD_Command_Prefix'], '', @discord['message'])
	if(@dm == 'dm' || @cmdfrom == 'mention') {
		@msgcheck = reg_replace('^[@]'.@botconfig['Bot_Name'].'\\s', '', @msgcheck)
		@msgcheck = reg_replace('^[@]'.@config['Bot_Name'].'\\s', '', @msgcheck)
	}
	@command = parse_args(@msgcheck)
	# No Command Given
	if(!array_index_exists(@command, 0)) {
		_discordBot_send_message(array('embeds': array(array('description': 'Ooooh! I can\'t wait to see what command you enter next!', 'footer': array('text': '...or not'), 'image': 'https://media.tenor.com/hrg1biY9FbsAAAAC/awesome-minions.gif'))), @discord['serverid'], 'none', @discord['SendChannel'], @discord['UseDM'])	
		return('NoCmdGiven')
	}
	# No mentions
	@command[0] = reg_replace('@', '', @command[0])
#Command Blacklist
	if(array_contains(@botconfig['CMD_Blacklist_Commands'], @command[0])) {
		_db_msg_Console(color(8).'Commands: Ignored '.color(9).@command[0], @discord['serverid'], 'debug')
		return('Blacklist')
	}
# Setup Arguments
	@args = array()
	if(array_index_exists(@command, 1)) {
		@args = @command[cslice(1, array_size(@command) - 1)]
	}

	if(is_string(@command[0])) { @command[0] = to_lower(@command[0]) }
	@commanddismc = ''
	@commanddisdc = ''
	if(array_index_exists(@args, 0)) {
# Remove mention in arguments
		if(array_index_exists(@config, 'Sanitize_CMD_Arguments')) {
			foreach(@mention: @replacement in @config['Sanitize_CMD_Arguments']) {
				foreach(@k: @arg in @args) {
					@args[@k] = replace(@args[@k], @mention, @replacement)
				}
			}
		}
		@arglimit = array_size(@args)
		@argcontinues = ''
		if(@arglimit >= @config['CMD_Args_Display_Limit']) { @arglimit = @config['CMD_Args_Display_Limit'] @argcontinues = ' ...' }
		@commanddismc = 'Args: '.color(9).array_implode(@args[cslice(0, @arglimit - 1)], ', ').@argcontinues
		@commanddisdc = 'Args: `'.array_implode(@args[cslice(0, @arglimit - 1)], '`  `').'`'.@argcontinues 
		if(!array_index_exists(@args, 0)) { @commanddisdc = '' }
	}
	
# Deny Admin commands
	if(array_index_exists(@commandList, @command[0])) {
		if(@actions[@commandList[@command[0]]]['admin'] == true && @userType != 'Admin') {
			_db_msg_Console(@discord['username'].' tried to use an admin command'.@cmdfromdis.': '.color(3).@command[0].'  '.color('r').@commanddismc, @discord['serverid'])
			_discordBot_send_message(@discord['username'].' tried to use admin command'.@cmdfromdis.': `'.@command[0].'`  '.strip_colors(@commanddisdc), @discord['serverid'], 'admin')
			return('NotAdmin')
		}
	}
	array_set(@discord, 'admin', @isAdmin)

# Execute command action
	if(array_index_exists(@commandList, @command[0])) {
		@CmdReturn = @actions[@commandList[@command[0]]]['cmd'](@discord, @args);
	} else {
	#Debug: Save unrecognized commands for review
		@saveData = array('time': time(), 'user': @discord['username'], 'command': @command[0], 'args': @args)
		@nocmdData = get_value('DiscordBot.debug.cmd.not.found')
		if(!is_array(@nocmdData)) { @nocmdData = array() }
		if(!array_index_exists(@nocmdData, 'cmds')) { array_set(@nocmdData, 'cmds', array()) }
		array_insert(@nocmdData['cmds'], @command[0], 0)
		if(!array_index_exists(@nocmdData, @discord['userid'])) { array_set(@nocmdData, @discord['userid'], array()) }
		array_insert(@nocmdData[@discord['userid']], @saveData, 0)
		if(array_index_exists(@nocmdData[@discord['userid']], 20)) { array_remove(@nocmdData[@discord['userid']], 20) }
		store_value('DiscordBot.debug.cmd.not.found', @nocmdData)
		#Send Not Found messages
		_db_msg_Console(@discord['username'].' tried to use non-existent command'.@cmdfromdis.': '.color(14).@command[0].'  '.color('r').@commanddismc, @discord['serverid'])
		#Send User Message
		@sendUserMessage = true
		if(@cmdfrom == 'mention') { @sendUserMessage = false }
		# Only message user on repeated not found command?
		if(to_lower(@config['CMD_Not_Found_Message_Action']) == 'repeat') {
			if(array_index_exists(@nocmdData[@discord['userid']], 1)) { 
				if(@nocmdData[@discord['userid']][1]['command'] != @command[0]) { @sendUserMessage = false }
			} else { 
				@sendUserMessage = false
			}
		}
		if(@config['CMD_Not_Found_Message_Action'] == false) { @sendUserMessage = false }
		if(@sendUserMessage == true) {
			@returnMsg['content'] = 'I have no idea what that command is, try ?help'
			array_set(@returnMsg, 'reference_id', @discord['id'])
			_discordBot_send_message(@returnMsg, @discord['serverid'], 'command', @discord['SendChannel'], @discord['UseDM'])
		}		
		return('NotACmd')
	}
# _db_msg_Console('ret: '.@CmdReturn, @discord['serverid'], 'debug')
# _db_msg_Console('retis: '.is_string(@CmdReturn), @discord['serverid'], 'debug')
#Save Recent Messages and Returns for reference	
	array_set(@discord, 'return', @CmdReturn)
	@cacheCmd = import('DiscordBot.Cache.Cmd.Messages')
	if(!is_array(@cacheCmd)) { @cacheCmd = array() }
	array_insert(@cacheCmd, @discord, 0)
	if(array_index_exists(@cacheCmd, @botconfig['Msg_Cache_Cmd'])) { array_remove(@cacheCmd, @botconfig['Msg_Cache_Cmd']) }
	export('DiscordBot.Cache.Cmd.Messages', @cacheCmd)

	@cacheCmd = import('DiscordBot.Cache.Cmd.Messages.return')
	if(!is_array(@cacheCmd)) { @cacheCmd = array() }
	array_insert(@cacheCmd, @CmdReturn, 0)
	if(array_index_exists(@cacheCmd, @botconfig['Msg_Cache_Cmd'])) { array_remove(@cacheCmd, @botconfig['Msg_Cache_Cmd']) }
	export('DiscordBot.Cache.Cmd.Messages.return', @cacheCmd)	
#Send Messages
#return messages final message, unless true/false. multiple messages need to be handled by action
	if(to_lower(@config['CMD_Message_Action']) == 'reply') {
		array_set(@returnMsg, 'reference_id', @discord['id'])
	}
	@messageType = 'command'
	if(is_string(@CmdReturn)) {
		switch(@CmdReturn) {
		case 'NoCmd':
			@returnMsg['content'] = 'A required command module is not installed.'
			@return = false
		case 'NotAdmin':
			@returnMsg['content'] = ':no_entry: This command is restricted to use by Admin only.'
			@messageType = 'discord'
			@return = false
		case 'NoUserFound':
			@returnMsg['content'] = ':question: User ID given not found on server.'
			@messageType = 'discord'
			@return = false
		case 'NoPerms':
			@returnMsg['content'] = ':question: I did not have permission to finish this command!'
			@messageType = 'discord'
			@discord['SendChannel'] = 'admin'
			@return = false
		case 'NotEnabled':
			@returnMsg['content'] = ':x: This feature is not enabled on this server.' 
			@return = false
		case 'Error':
			@returnMsg['content'] = ':x: An error occured in the command, see logs.'
			@return = false
		case 'pong':
			@timeElapsed = (time() - @discord['time'])
			@returnMsg['content'] = 'Pong! ('.(@timeElapsed / 1000).')'
			@return = true
		default:
			@returnMsg['content'] = @CmdReturn
			@messageType = 'discord'
			@return = true
		}
		_discordBot_send_message(@returnMsg, @discord['serverid'], @messageType, @discord['SendChannel'], @discord['UseDM'], @afterMsg)
	} else if(is_array(@CmdReturn)) {
		if(array_index_exists(@CmdReturn, 'content') || array_index_exists(@CmdReturn, 'embeds')) {
			if(array_index_exists(@CmdReturn, 'dm')) {
				switch(string(@CmdReturn['dm'])) {
				case 'true':
				case 'dm':
					@discord['UseDM'] = 'dm'
					@cmdfromdis = @cmdfromdis.' (DM reply)'
					@discord['SendChannel'] = @discord['userid']
				case 'false':
				case 'broadcast':
					@discord['UseDM'] = 'broadcast'
					@discord['SendChannel'] = @discord['channelid']
				}
				array_remove(@CmdReturn, 'dm')
			}
			if(array_index_exists(@CmdReturn, 'console')) {
				_db_msg_Console(@CmdReturn['console'], @discord['serverid'])
				array_remove(@CmdReturn, 'console')
			}
			if(array_index_exists(@CmdReturn, 'MCCmd')) {
				array_remove(@CmdReturn, 'MCCmd')
			}
			if(array_index_exists(@CmdReturn, 'MC')) {
				_db_mc_broadcast(@CmdReturn['MC'], @CmdReturn['players'])
				array_remove(@CmdReturn, 'MC')
				array_remove(@CmdReturn, 'players')
			}
			if(array_index_exists(@config, 'CMD_Message_Action')) {
				if(to_lower(@config['CMD_Message_Action']) == 'reply') {
					array_set(@CmdReturn, 'reference_id', @discord['id'])
				}
				if(@editMsg > 0 && to_lower(@config['CMD_Message_Action']) != 'delete') {
					array_set(@CmdReturn, 'message_id', @editMsg)
				}
			}
			_discordBot_send_message(@CmdReturn, @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'], @afterMsg)
			@return = true
		} else {
			_discordBot_send_message(@discord['username'].'\'s command `'.@command[0]'` failed: '.@CmdReturn, @discord['serverid'], 'admin')
			@return = false
		}
	} else if(is_boolean(@CmdReturn)) {
		@return = @CmdReturn
	}
# Send Log Messages and End.
	@colorret = 3
	@retdisplay = ''
	if(@return == false) { @colorret = 12 @retdisplay = ' (Failed)' }
	if(array_index_exists(@config, 'CMD_Message_Action')) {
		if(to_lower(@config['CMD_Message_Action']) == 'delete' && string(@CmdReturn) != 'NotACmd' && @discord['UseDM'] != 'dm') {
			try {
				discord_delete_message(@discord['serverid'], @discord['channel'], @discord['id'])
			} catch(Exception @ex) {
				_db_msg_Console('Could not delete command message, Another bot running?', @discord['serverid'])
			}
		}
	}
	_db_msg_Console('<'.(time() - @StartTime).'ms> '.@discord['username'].' used command'.@cmdfromdis.': '.color(@colorret).@command[0].'  '.color('r').@commanddismc.color('r').@retdisplay, @discord['serverid'])
		if(array_index_exists(@config, 'CMD_Log_Ignore_Users')) {
		if(array_contains(@config['CMD_Log_Ignore_Users'], @discord['username']) || array_contains(@config['CMD_Log_Ignore_Users'], @discord['userid'])) { @sendLogMsg = false }
	}
	if(@sendLogMsg == true) {
		_discordBot_send_message(@discord['username'].' used command'.@cmdfromdis.' `'.@command[0].'`  '.strip_colors(@commanddisdc).@retdisplay, @discord['serverid'], 'admin')
	}
	return(@return)
}


proc _discordBot_init_cmd_list(@test) {
	@commandList = import('DiscordBot.Command.List')
	if(!is_array(@commandList)) { _db_msg_Console('Command list not initialized', 'debug') return(false) }
	@cmdListName = array()
	@cmdListAlias = array()
	@cmdListCat = array()
	foreach(@cmd: @data in @commandList) {
		@lCmd = to_lower(@cmd)
		array_set(@cmdListName, @lCmd, @cmd)
		if(is_array(@data['alias'])) {
			foreach(@alias in @data['alias']) {
				array_set(@cmdListName, to_lower(@alias), @cmd)
				@cmdListAlias[] = @alias
			}
		}
		if(!array_index_exists(@cmdListCat, @data['category'])) { array_set(@cmdListCat, @data['category'], array()) }
		@cmdListCat[@data['category']][] = @lCmd
	}
	export('DiscordBot.Command.List.Name', @cmdListName)
	export('DiscordBot.Command.List.Alias', @cmdListAlias)
	export('DiscordBot.Command.List.Categories', @cmdListCat)
}


proc _discordBot_cmd_proc_finduserID(@target, @discord) {
	@botconfig = import('DiscordBot.config.Bot')
	if(!array_index_exists(@discord, 'serverid')) { array_set(@discord, 'serverid', @botconfig['Primary_Guild']) }
	if(!array_index_exists(@discord, 'userid')) { array_set(@discord, 'userid', null) }
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@membernames = get_value('DiscordBot.'.@discord['serverid'].'.members.names')
	@membernamesDisplay = get_value('DiscordBot.'.@discord['serverid'].'.members.names.display')
	@useDisplay = false
	if(!array_index_exists(@discord, 'UseDM')) { array_set(@discord, 'UseDM', 'broadcast') }
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
		if(@target == '' || @target == null) { return('notfound') }
		@target = replace(@target, '@', '')
		if(reg_count('^[@]?'.@config['Bot_Name'].'[#]?[0-9]{0,4}?$', @target) > 0) {
			return('bot')
		}
		if(equals_ic(@botconfig['Bot_Name'], @target)) { return('bot') }
		if(equals_ic(@config['Bot_Name'], @target)) { return('bot') }
		@targetmatches = _array_string_contains(array_keys(@membernames), @target, '', 'array')
		#Recheck with tag, if exists
		if(reg_count('[#][0-9]{4}$', @target) > 0 && !array_index_exists(@targetmatches, 0)) {
			@target = reg_replace('[#][0-9]{4}$', '', @target)
			@targetmatches = _array_string_contains(array_keys(@membernames), @target, '', 'array')
		}
		#Check Display names if not found in username
		if(!array_index_exists(@targetmatches, 0)) {
			@targetmatches = _array_string_contains(array_keys(@membernamesDisplay), @target, '', 'array')
			@useDisplay = true
		}
		if(array_index_exists(@discord, 'username') && array_index_exists(@discord, 'nickname')) {
			if(equals_ic(@target, @discord['username']) || equals_ic(@target, @discord['nickname'])) {
				return('self')
			}
		}
		_db_msg_Console('finduserID: matches: '.@targetmatches, @discord['serverid'], 'debug')
		
		if(!array_index_exists(@targetmatches, 0)) {
			_db_msg_Console('Could not find user ID for '.@target.'!', @discord['serverid'])
			return('notfound')
		} else if(array_index_exists(@targetmatches, 1)) {
			if(@discord['userid'] != null) {
				discord_private_message(@discord['userid'], 'I found multiple users; I\'m not sure which one you meant to apply this command to. Users Matched: \n'.array_implode(@targetmatches, ', '))
			}
			_db_msg_Console('finduserID: Found multiple users, Users Matched: \n'.array_implode(@targetmatches, ', '), @discord['serverid'])
			return('multiple')
		} else if(@useDisplay == true) {
			return(@membernamesDisplay[array_implode(@targetmatches, '')])
		} else {
			return(@membernames[array_implode(@targetmatches, '')])
		}
	}
}



#### Bot Command Logic

/*
proc _discordBot_link_mc_account(@from = '', @type = 'create', @user = '', @id = '', @code = '', @options) {
	if(@from == '') { die() }
	if(@user == '') { die() }
	if(@id == '') { die() }
	if(@code == '') { die() }
	if(@from == '') { die() }
	
	
*/
