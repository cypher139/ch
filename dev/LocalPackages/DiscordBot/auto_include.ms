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
	@prevcfg = import(@prefix.'.config.'.@cfgtype)
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
		if(array_index_exists(@loadcfg, 'VC_Options', '987654321')) {
			_db_msg_Admins(color(14).'[Chat - Discord] Voice Chat Config is still using defaults. Please configure it in order to use the VC Role Ping feature.') 
		}
		if(@loadcfg['Welcome_Text_Channel_Name'] == 'default') {
			_db_msg_Admins(color(14).'[Chat - Discord] Member Config is still using defaults. Please configure it in order to use the Welcome Message feature.') 
		}
		if(@prevcfg != null) {
			_db_setup(@loadcfg);
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
						@msgban = '  Offending player `'.@from['name'].'` was '.@msgbantype.'.'
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

proc _discordBot_send_message(@message, @from, @channel, @type, @option) {
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
	@membersID = import('DiscordBot.members.ID')
	if(@membersID == null) { @membersID = get_value('DiscordBot.members.ID') }
	if(!is_array(@membersID)) { @membersID = discord_get_members() }
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('DiscordBot.members.ID', @membersID)
		export('DiscordBot.members.ID', @membersID)
	}
	@membersnames = import('DiscordBot.members.names')
	if(@membersnames == null) { @membersnames = get_value('DiscordBot.members.names') }
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
		if(import('DiscordBot.Console.receive') != true) {
			if(@args == '' || @args == null) {
				console(@msg, false)
			}
		} else {
			console(@msg, false)
		}
	}
	return(true)
}


proc _db_setup(@config, @args) {
	if(@config == '' || @config == null) {
		@config = import('DiscordBot.config.Discord')
	}
	if(get_value('DiscordBot.Console.receive') == true) {
		export('DiscordBot.Console.receive', true)
		# console('[DiscordBot] Console receives chat from Discord Users.', false)
	} else {
		export('DiscordBot.Console.receive', false)
	}
# Set Bot Activity
	@acttypes8901 = reg_split('of\\s|[,.]\\s(?:or\\s)*', reflect_docs('discord_set_activity', 'description'))[2..]
	foreach(@k: @v in @acttypes8901) {
		if(to_upper(@v) != @v) { array_remove(@acttypes8901, @k) }
	}
	if(array_contains(@acttypes8901, to_upper(@config['Activity_Type']))) {
		try {
			discord_set_activity(to_upper(@config['Activity_Type']), string(@config['Activity_Message']));
		} catch(Exception @ex) {
			_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Bot Activity Message: '.color('r').@ex['message'])
			console(color(4).'['.color(9).'Server'.color(4).'] Bot Activity Message: '.color(12).@ex['classType'].': '.@ex['message'], false)
		}
	} else {
		_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Selected Bot Activity Type is not supported!')
	}
# Setup Leaderboard
	if(@config['LB_Enable'] == true) {
		if(import('DiscordBot.Leaderboard.last.save') == null) {
			export('DiscordBot.Leaderboard.last.save', time());
		}
		if(!is_array(import('DiscordBot.Leaderboard'))) {
			export('DiscordBot.Leaderboard', array('lastedit': time(), 'members': array()))
		}
	}
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
	@userroles = null
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
	if(@config['LB_Enable'] != true) {
		# console('noenable')
		return(false)
	}
	@leaderboard = import('DiscordBot.Leaderboard', array('lastedit': 0));
	@lastsave = import('DiscordBot.Leaderboard.last.save');
	if(@lastsave == null) { @lastsave = time() }
	if(@leaderboard['lastedit'] > @lastsave) {
		# console('[Discord] Saved Leaderboard Database.', false)
		store_value('DiscordBot.Leaderboard', @leaderboard)
		@saveoldroles = import('DiscordBot.debug.roles.Leaderboard.undo')
		if(is_array(@saveoldroles)) {
			store_value('DiscordBot.debug.roles.Leaderboard.undo', @saveoldroles)
		}
		export('DiscordBot.Leaderboard.last.save', time())
		_write_file(import('DiscordBot.logs.dir').'/Leaderboard_'.reg_replace('\\s', '_', @leaderboard['guild']['name']).'.json', json_encode(@leaderboard), 'OVERWRITE')
		return(true)
	}
	# } else { console('nosave') return(false) }
}

proc _discordBot_lb_process_message(@discord, boolean @noXP = false) {
	@leaderboard = import('DiscordBot.Leaderboard');
	if(@leaderboard == null) { 
		console('[DiscordBot] Leaderboard data not initialized, exiting') 
		return(false)
	}
	if(!is_array(@discord)) {
		console('[DiscordBot] No data given to Leaderboard system, exiting', false)
		return(false)
	}
	# if(@noXP == '' || @noXP == null) {
		# @noXP = false
	# }
	@mi = ''
	try {
		@mi = discord_member_info(@discord['userid'])
	} catch(NotFoundException @ex) {
		console('[DiscordBot] Member Info not found for user '.@discord['username'].' <@'.@discord['userid'].'>, exiting', false)
		return(false)
	}
	@config = import('DiscordBot.config.Discord')
	@userID = @discord['userid']
	@levelxp = import('DiscordBot.Leaderboard.levelXP')
	if(@levelxp == null) { 
		@levelxp = _discordBot_lb_levelXP();
		array_set(@leaderboard['options'], 'levelXP', @levelxp)
		array_set(@leaderboard, 'Guild_Name', @config['LB_Options']['Guild_Name'])
		}
	# Do not count messages from Command spam channel or Channels marked as no XP earning.
	if(array_contains(@config['LB_Options']['NoXP_Channels'], @discord['channel'])) { @noXP = true }
	if(@discord['channel'] == @config['CMD_Default_Channel']) { @noXP = true }
	@xptimer = import('DiscordBot.Leaderboard.xptimer', array('test': 123))
	if(!array_index_exists(@xptimer, @userID)) {
		array_set(@xptimer, @userID, (time() - 70000))
	}
	
	if(!array_index_exists(@leaderboard, 'members', @userID)) {
		array_set(@leaderboard['members'], @userID, array('last_msg': 0, 'level': 0, 'xp': 0, 'username': @discord['username'], 'msg_count': 0))
	}
	@userRoles = ''
# If user has last chatted in last rolling minute, do not award XP. (continues to count message)
	if((@xptimer[@userID] + 60000) > time()) {
		@noXP = true 
	} else {
# Check if user has a no XP earning role.
		try { 
			@userRoles = discord_member_get_roles(@userID)
		} catch(Exception @ex) {
			return(false)
		}
		foreach(@role in @userRoles) {
			if(array_contains(@config['LB_Options']['NoXP_RoleID'], @role)) {
				@noXP = true
				break()
			}
		}
	}
# Increment Message count and XP
	@leaderboard['members'][@userID]['msg_count'] = @leaderboard['members'][@userID]['msg_count'] + 1
	@leaderboard['members'][@userID]['last_msg'] = time()
	if(@noXP == false) {
		@newxp = rand(@config['LB_Options']['XP_Per_Message'][0], @config['LB_Options']['XP_Per_Message'][1])
		@xptimer[@userID] = time()
		@leaderboard['members'][@userID]['xp'] = @leaderboard['members'][@userID]['xp'] + @newxp
	}
	# noxp true time not counted, so next immediate message (if eligible) would count and update timer

# If current XP is greater than the max for the next level:
#Levelxp: (key: xp to be at this level). to get level up need to check next level
/*
console('max lvlxp for level '.@leaderboard['members'][@userID]['level'].': '.@levelxp[@leaderboard['members'][@userID]['level']])
console('max lvlxp for next level '.(@leaderboard['members'][@userID]['level'] + 1).': '.@levelxp[(@leaderboard['members'][@userID]['level'] + 1)])
console(@levelxp[@leaderboard['members'][@userID]['level'] + 1])
*/

#maxlevel
	if(!array_index_exists(@levelxp, (@leaderboard['members'][@userID]['level'] + 1))) {
		console('[Discord] Level Up: '.@discord['username'].' <@'.@userID.'> is at the maximum level '.@leaderboard['members'][@userID]['level'].'!', false)
		export('DiscordBot.Leaderboard', @leaderboard)
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
		# console(@ranknums)
		@oldroles = array_sort(array_normalize(@userRoles), 'NUMERIC')
	#Find rank
		@rankup = false
		foreach(@i: @rank in @ranknums) {
			@lastrank = 0
		# console(@i)
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
		@saveoldroles = import('DiscordBot.debug.roles.Leaderboard.undo', get_value('DiscordBot.debug.roles.Leaderboard.undo'))
		if(!is_array(@saveoldroles)) { @saveoldroles = array() }
		array_set(@saveoldroles, @discord['userid'], @userRoles)
		export('DiscordBot.debug.roles.Leaderboard.undo', @saveoldroles)
		
	# Remove old role rewards
		if(@config['LB_Options']['Stack_Role_Rewards'] == false) {
			foreach(@role in @config['LB_Options']['Role_Rewards']) {
				array_remove_values(@userRoles, @role['RoleID'])
			}
		}
	# Place and Set new role
		# console(@currentrank)
		if(@currentrank != '') {
			array_push(@userRoles, @currentrank['RoleID'])
			#Set New roles
			try { 
				discord_member_set_roles(@userID, @userRoles, 'Role Rewards: Awarded New Rank '.@currentrank['RoleName'])
			} catch(Exception @ex) {
				return(false)
			}
		}
/*
		console(@currentrank)
		console(@oldroles)
		console(@userRoles)		
*/		

# Message out
		@discordMsg = reg_replace('%UserID%', '<@'.@userID.'>', @config['LB_Options']['Level_Up_Message'])
		if(@newrankname == '') {
			@discordMsg = reg_replace('%Level%', 'Level '.@leaderboard['members'][@userID]['level'].'!', @discordMsg)
		} else {
			@discordMsg = reg_replace('%Level%', @newrankname.'!  ('.@leaderboard['members'][@userID]['level'].')', @discordMsg)
		}
		console('[Discord] Level Up: '.@discord['username'].' <@'.@userID.'> '.color(3).@oldlevel.color('r').' -> '.color(10).@leaderboard['members'][@userID]['level'].' '.color(6).@newrankname, false)
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
			_discordBot_send_message(@discordMsg, 'confirm', @sendchannel, @type)
		}
	}
#Save edits
	@leaderboard['lastedit'] = time()
	export('DiscordBot.Leaderboard', @leaderboard)
	export('DiscordBot.Leaderboard.xptimer', @xptimer)
	return(true)
}

proc _discordBot_backup_members(@args) {
	@config = import('DiscordBot.config.Discord')
	@data = array(
	'membersID': get_value('DiscordBot.members.ID'),
	'membersNames': get_value('DiscordBot.members.names'),
	'membersRoles': get_value('DiscordBot.members.roles'),
	'membersInfo': get_value('DiscordBot.members.info'),
	'membersWR': get_value('DiscordBot.members.roles.welcomeroles'),
	'membersNoRoles': get_value('DiscordBot.members.roles.none'),
	'rolesTotal': get_value('DiscordBot.roles.total'),
	'rolesMembers': get_value('DiscordBot.roles.members'),
	'Leaderboard': import('DiscordBot.Leaderboard')
	)
	@time = time();
	foreach(@k: @v in @data) {
		if(@v == '' || @v == null) { continue() }
		_write_file(import('DiscordBot.logs.dir').'/Backup/'.simple_date('MM-dd-yy_HHmm_', @time).@k.'.json', json_encode(@v), 'CREATE')
	}
}

proc _discordBot_update_members(@args) {
	@debugstats = array('size': array(), 'nf': 0, 'total': 0, 'af': 0, 'norole': 0, 'wr': 0, 'fails': 0)
	@membersID = discord_get_members()
	@membersNames = array()
	@membersRoles = array()
	@membersInfo = array()
	@membersWR = array()
	@membersNoRoles = array()
	@totalroles = array()
	@rolesMembers = array()
	@config = import('DiscordBot.config.Discord')
	@leaderboard = import('DiscordBot.Leaderboard')
	@sortWR = array_sort(@config['Welcome_Roles'], 'NUMERIC')

	foreach(@index: @id in @membersID) {
		@idInfo = ''
		try {
			@idInfo = discord_member_info(@id)
		} catch(NotFoundException @ex) {
			console('[DiscordBot] Update Roles: Not found: '.@id)
			@debugstats['nf']++
			continue()		
		} catch(Exception @ex) {
			console('[DiscordBot] error on id: '.@id.'\n'.@ex['message'])		
			@debugstats['fails']++
			continue()
		}
		@idRoles = discord_member_get_roles(@id);
		if(!is_array(@idRoles)) {
			@debugstats['af']++
			continue()
		}
		# if(@idInfo['color'] == null) { console(@id.' i '.@idInfo, false) }
		if(array_size(@idRoles) == 0) {
			array_push(@membersNoRoles, @id)
			continue()
		}
		
		array_set(@membersRoles, @id, @idRoles)
		array_set(@membersInfo, @id, @idInfo)
		array_set(@membersNames, @idInfo['username'], @id)

		#Leaderboard: Avatars, usernames, color
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
		
		# Total roles ( id: name )
		foreach(@k: @v in @idRoles) {
			if(!array_contains(array_keys(@totalroles), @v)) {
				array_set(@totalroles, @v, @k)
			}
		}

	# Just welcome roles		
		if(array_size(@idRoles) == array_size(@sortWR)) {
			@results = array()
			#sort arrays so roles are in same key order
			@sortUR = array_sort(array_normalize(@idRoles), 'NUMERIC')

			foreach(@key: @roleid in @sortWR) {
				if(@roleid == @sortUR[@key]) {
					array_push(@results, true)
				} else {
					array_push(@results, false)
				}
			}
			if(array_every(@results, closure(@value) { return(@value) }) == true) {
				array_push(@membersWR, @id)
			}
			@results = array()
		}
	}
	@rolesMembers = array()
	foreach(@roleid: @rolename in @totalroles) {
		array_set(@rolesMembers, @roleid, array())
	}
# Load roles members
	foreach(@memberid: @mr in @membersRoles) {
	# server member roles array: {memberid: {role: 123, role2: 4235}, memberid: {role: 234}, }
		foreach(@k: @v in @mr) { 
		#this foreach value sees: @k = role, @v = 123
		#loop through each role present, push memberid to main list
			array_push(@rolesMembers[@v], @memberid)
		}
	}

	#save data
	if(@config['LB_Enable'] == true && is_array(@leaderboard)) {
		export('DiscordBot.Leaderboard', @leaderboard)
	}
	store_value('DiscordBot.members.ID', @membersID)
	export('DiscordBot.members.ID', @membersID)
	array_set(@debugstats['size'], 'ID', array_size(@membersID))
	store_value('DiscordBot.members.roles', @membersRoles)
	array_set(@debugstats['size'], 'mr', array_size(@membersRoles))
	store_value('DiscordBot.roles.members', @rolesMembers)
	array_set(@debugstats['size'], 'rm', array_size(@rolesMembers))
	store_value('DiscordBot.roles.total', @totalroles)
	array_set(@debugstats['size'], 'rt', array_size(@totalroles))
	store_value('DiscordBot.members.names', @membersNames)
	array_set(@debugstats['size'], 'mn', array_size(@membersNames))
	store_value('DiscordBot.members.roles.welcomeroles', @membersWR)
	array_set(@debugstats['size'], 'wr', array_size(@membersWR))
	store_value('DiscordBot.members.roles.none', @membersNoRoles)
	array_set(@debugstats['size'], 'norole', array_size(@membersNoRoles))
	export('DiscordBot.members.names', @membersNames)
	store_value('DiscordBot.members.info', @membersInfo)
	export('DiscordBot.members.info', @membersInfo)
	array_set(@debugstats['size'], 'mi', array_size(@membersInfo))
	export('DiscordBot.debug.stats.last.updatemembers', @debugstats)
	return(true)
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
	_write_file(import('DiscordBot.logs.dir').'/Leaderboard_LevelXP.json', json_encode(@levelxp), 'CREATE')
	return(@levelxp)
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
			console('[Discord] Required data array not given to Command Handler!', false)
			return(false)
		}
	} else {
		console('[Discord] Required data array not given to Command Handler!', false)
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
			console('[Discord] Required data array not given to Command Handler!', false)
			return(false)
		} else {
			if(!array_index_exists(@discord, 'time')) {
				array_set(@discord, 'time', time())
			}
		}
	} else {
		console('[Discord] Required data array not given to Command Handler!', false)
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
		_discordBot_send_message(array('embeds': array(array('description': 'Ooooh! I can\'t wait to see what command you enter next!', 'footer': array('text': '...or not'), 'image': 'https://media.tenor.com/hrg1biY9FbsAAAAC/awesome-minions.gif'))), 'none', @discord['SendChannel'], @discord['UseDM'])	
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
			if(_array_string_contains(@config['Banned_Mentions'], @entry)) {
				array_push(@rmargs, @entry)
				array_remove(@args, @i)
			}
		}
		if(array_index_exists(@rmargs, 0)) {
			@rmargs = array_implode(array_unique(@rmargs), ', ')
			_db_msg_Admins(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Removed "'.@rmargs.'" from '.@discord['username'].'\'s command arguments.')
			discord_broadcast(@config['Log_Channel'], 'Removed `'.@rmargs.'` from '.@discord['username'].'\'s command arguments.')	
			if(@config['Message_On_Mention'] == true) { discord_private_message(@discord['userid'], 'Mention(s) `'.@rmargs.'` are not allowed on the server.') }
		}
		@commanddismc = 'Args: '.color(9).array_implode(@args, ', ')
		@commanddisdc = 'Args: `'.array_implode(@args, '`  `').'`' 
		if(!array_index_exists(@args, 0)) { @commanddisdc = '' }	
	}
	
# Deny Admin commands	
	if(array_contains_ic(@admincommandlist, @command[0]) && @userType != 'Admin') {
		console('[Discord] '.@discord['username'].' tried to use an admin command'.@cmdfrom.': '.color(3).@command[0].'  '.color('r').@commanddismc, false)
		_discordBot_send_message(@discord['username'].' tried to use admin command'.@cmdfrom.': `'.@command[0].'`  '.strip_colors(@commanddisdc), 'admin', '')
		return('NotAdmin')
	}
	array_set(@discord, 'admin', @isAdmin)
# make 1 letter aliases

# Execute command action 
	if(array_index_exists(@actions, @command[0])) {
		@return = @actions[@command[0]](@discord, @args);
	} else {
		_discordBot_send_message('I have no idea what that command was about, try help.', 'command', @discord['SendChannel'], @discord['UseDM'])
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
ex.:	_discordBot_send_message(return, 'discord', @discord['SendChannel'], @discord['UseDM'])
return may be an array or string too
nocmd return: 		_discordBot_send_message('A required command module is not installed.', 'command', @discord['SendChannel'], @discord['UseDM']) returnfalse
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
			_discordBot_send_message('A required command module is not installed.', 'command', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'NotAdmin') {
			_discordBot_send_message(':no_entry: This command is restricted to use by Admin only.', 'discord', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'NoUserFound') {
			_discordBot_send_message(':question: User ID given not found on server.', 'discord', @discord['SendChannel'], @discord['UseDM']) 
			@return = false
		} else if(@return == 'pong') {
			@timeElapsed = (time() - @discord['time'])
			_discordBot_send_message('Pong! ('.(@timeElapsed / 1000).')', 'command', @discord['SendChannel'], @discord['UseDM']) 
			@return = true
		} else {
			_discordBot_send_message(@return, 'discord', @discord['SendChannel'], @discord['UseDM'])
			@return = true
		}
	} else if(is_array(@return)) {
		if(array_index_exists(@return, 'content') || array_index_exists(@return, 'embeds')) {
			_discordBot_send_message(@return, 'discord', @discord['SendChannel'], @discord['UseDM'])
			@return = true
		} else {
			_discordBot_send_message(@discord['username'].'\'s command `'.@command[0]'` failed: '.@return, 'admin', '')
			@return = false
		}
	}
# Send Log Messages and End.
	@colorret = ''
	@retdisplay = ''
	if(@return == true) { @colorret = 3 @retdisplay = '' } else { @colorret = 'c' @retdisplay = ' (Failed)' }
	console('[Discord] '.@discord['username'].' used command'.@cmdfrom.': '.color(@colorret).@command[0].'  '.color('r').@commanddismc.color('r').@retdisplay, false)
	_discordBot_send_message(@discord['username'].' used command'.@cmdfrom.' `'.@command[0].'`  '.strip_colors(@commanddisdc).@retdisplay, 'admin', '')
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