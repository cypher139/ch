proc _discordBot_cmd_whois(@discord, @args) {
	@serverInfo = import('DiscordBot.Servers.Info.'.@discord['serverid'])
	@showExtraInfo = false
	@userIDs = array()
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard');
	@usercheckargs = array()
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array() }
	@serverMembers = discord_get_members(@discord['serverid'])
	@return = array('content': ':grey_question: Whois:', 'embeds': array())
	#apply all options
	foreach(@arg in @args) {
		switch(@arg) {
		case 'extra':
			@showExtraInfo = true
		case 'all':
			@Placeholder = true
		default:
			if(is_numeric(@arg) && length(@arg) > 12) {
				if(array_contains(@serverMembers, @arg)) {
					@userIDs[] = @arg
				} else {
					@return['content'] = @return['content'].'\n( '.@arg.' not found on server )'
				}
			} else {
				@usercheckargs[] = @arg
			}
		}
	}		
	# Check remaining options for user IDs, add to list of IDs to display
	#Note: Skipped if an ID was already provided
#maybe foreach results to show multiple embeds (limit to 3 results)
	if(array_index_exists(@usercheckargs, 0)) {
		foreach(@arg in @usercheckargs) {
			if(is_numeric(@arg) && length(@arg) < 17) { continue() }
			@checkuser = _discordBot_cmd_proc_finduserID(@arg, @discord)
			# console('arg: '.@arg.'     cu: '.@checkuser)
			switch(string(@checkuser)) {
			case 'bot':
				# @checkuser = @config['Bot_ID']
				continue()
			case 'self':
				@checkuser = @discord['userid']
			case 'notfound':
				continue()
			case 'multiple':
				continue()
			}
			if(!is_numeric(@checkuser)) {
				_db_msg_Console('whois: non-numeric target! '.@checkuser, @discord['serverid'], 'debug')
				@checkuser = @discord['userid']
			}
			@userIDs[] = @checkuser
		}
	}
#No IDs found: view yourself
	if(!array_index_exists(@userIDs, 0)) {
		if(array_index_exists(@usercheckargs, 0)) {
			#no valid users to check
			@return['content'] = @return['content'].'\nNo valid entries to check!'
			return(@return)
		} else {
			#No arguments, or no IDs found: view yourself
			if(@return['content'] == ':grey_question: Whois:') {
				@userIDs[] = @discord['userid']
			}
		}
	}
	foreach(@userID in @userIDs) {
		@newuser = false
		if(!array_contains(@serverMembers, @userID)) {
			@return['content'] = @return['content'].'\n( '.@userID.' not found on server. )'
			continue()
		}
		@userInfo = discord_member_info(@discord['serverid'], @userID);
		@userDisplay = _db_get_user_nick(@discord['serverid'], @userID, @userInfo['username'])
		@embedsExtra = array()
		if(@showExtraInfo == true) {
			@lastUserMsgs = array()
			@embedsExtra[] = array('name': 'Member Index #', 'value': '`Subject to change`\n'.array_index(@serverMembers, @userID), 'inline': true)
			if(array_index_exists(@cacheMsgs, 'user', @userID, 1)) {
				@msgID = 0
				if(@discord['id'] == @cacheMsgs['user'][@userID][0]) { @msgID = 1 }
				@embedsExtra[] = array('name': 'Characters in Last Message', 'value': length(@cacheMsgs['messages'][@cacheMsgs['user'][@userID][@msgID]]['message']), 'inline': true)
			}
			if(is_array(@leaderboard)) {
				if(array_index_exists(@leaderboard, 'members', @userID)) { 
					@lbLM = '`-`'
					if(@leaderboard['members'][@userID]['last_msg'] != 0) { @lbLM = '<t:'.substr(@leaderboard['members'][@userID]['last_msg'], 0, 10).':f>' }
					@embedsExtra[] = array('name': 'Last Message', 'value': @lbLM, 'inline': true)
					if(array_index_exists(@leaderboard, 'members', @userID, 'words')) {
						@embedsExtra[] = array('name': 'Number of Words Said', 'value': @leaderboard['members'][@userID]['words'], 'inline': true)
					}
				}
			}
		}
		@embedsAdmin = array()
		if(@discord['admin'] == true) {
			@newuser = _db_is_newmember(@discord['serverid'], @userID);
			@embedsAdmin[] = array('name': 'Server: Is New User', 'value': @newuser, 'inline': true)
			@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info')
			if(!is_array(@joininfo)) { @joininfo = array() }
			if(!array_index_exists(@joininfo, @userID)) {
				@inv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())	
				if(array_index_exists(@inv, @userID, 'code')) {
					array_set(@joininfo, @userID, array('code': @inv[@userID]['code']))
				}
			}
			if(array_index_exists(@joininfo, @userID, 'code')) {
				@code = @joininfo[@userID]['code']
				if(is_array(@joininfo[@userID]['code'])) { @code = array_implode(@joininfo[@userID]['code'], ', ') }
				if(@code != '') { @embedsAdmin[] = array('name': 'Invite', 'value': @code, 'inline': true) }
			}
			@logJointimes = get_value('DiscordBot.'.@discord['serverid'].'.log.users.Join.Times')
			if(!is_array(@logJointimes)) { @logJointimes = array() }
			if(array_index_exists(@logJointimes, @userID, 1)) {
				@joins = ''
				foreach(@jt in @logJointimes[@userID]) { @joins .= '\n<t:'.substr(@jt, 0, 10).':f>' }
				@embedsAdmin[] = array('name': 'All Server Join Times', 'value': @joins, 'inline': true) 
			}
		}

# whois role rank - check roles if id matches configrewards state that role
		@userinfo = array()
		try {
			@userinfo = discord_member_info(@discord['serverid'], @userID);
		} catch(NotFoundException @ex) {
			export('DiscordBot.debug.user.not.found.'.@userID, @discord['serverid'])
		} 
		if(!array_index_exists(@userinfo, 'userid')) { continue() }
		@userRoles = array()
		try {
			@userRoles = discord_member_get_roles(@discord['serverid'], @userID)
		} catch(NotFoundException @ex) {
			export('DiscordBot.debug.user.not.found.'.@userID, @discord['serverid'])
		} 
		@displayUR = 'None'
		if(array_size(@userRoles) > 0) { @displayUR = '<@&'.array_implode(@userRoles, '> <@&').'>' }
	#Get Avatar and embed color info
		if(!array_index_exists(@userinfo, 'avatar')) { array_set(@userinfo, 'avatar', 'https://cdn.discordapp.com/embed/avatars/0.png') }
		@embed = array(
		'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @userinfo['username'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @userinfo['username'])),
		'color': array('r': 109, 'g': 109, 'b': 109),
		'thumbnail': @userinfo['avatar'].'?size=60',
		'fields': array(
			array('name': 'Join: Server', 'value': '<t:'.substr(@userinfo['joined_at'], 0, 10).':f>', 'inline': true),
			array('name': 'Join: Discord', 'value': '<t:'.substr(rshift(@userID, 22) + 1420070400000, 0, 10).':f>', 'inline': true)
		),
		'footer': array('text': 'ID: '.@userID),
		'timestamp': time()
		)
		if(array_index_exists(@userinfo, 'color')) {
			if(@userinfo['color'] != null) {
				array_set(@embed, 'color', @userinfo['color'])
			}
		}
		if(is_array(@leaderboard)) {
			if(array_index_exists(@leaderboard, 'members', @userID)) { 
				if(@leaderboard['members'][@userID]['level'] > 0) {
					@embed['fields'][] = array('name': 'Leaderboard Level', 'value': @leaderboard['members'][@userID]['level'], 'inline': true)
					@embed['fields'][] = array('name': 'Messages', 'value': @leaderboard['members'][@userID]['msg_count'], 'inline': true)
				}	
			}
		}
	# Format embed setup, send to return
		array_push_all(@embed['fields'], @embedsExtra)
		array_push_all(@embed['fields'], @embedsAdmin)
		# array_sort(@embed['fields'], closure(@left, @right){
			# return(@left['name'] > @right['name']);
		# });
		@embed['fields'][] = array('name': 'Roles ['.array_size(@userRoles).']', 'value': @displayUR, 'inline': false)
		@return['embeds'][] = @embed
	}
	if(!array_index_exists(@return, 'embeds', 0)) { array_remove(@return, 'embeds') }
	return(@return)
}

proc _discordBot_cmd_wrf(@discord, @args) {
		if(!array_index_exists(@args, 0)) { @args = array('welcome') }
		@type = 'd'
		@sorttype = 'name'
		if(array_index_exists(@args, 1)) { @sorttype = @args[1] }
		if(@args[-1] == 'mc') { @type = 'mc' }
		@msg = ''
		@amount = 0
		@config = import('DiscordBot.config.'.@discord['serverid'])
		@guildInfo = import('DiscordBot.Servers.Info.'.@discord['serverid'])
		@guildIconType = 'png'
		if(string_starts_with(@guildInfo['icon'], 'a_')) { @guildIconType = 'gif' }
		@suffix = ''
		switch(to_lower(substr(@args[0], 0, 1))) {
		case 'w':
			@suffix = 'welcomeroles'
			@msg = 'Members with only the Welcome Roles:'
		case 'n':
		case '0':		
			@suffix = 'none'
			@msg = 'Members with 0 roles:'
		default:
			return('Specify the type you want: WelcomeRoles for members with just welcome roles, None for those with no roles.')
		}
		@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles.'.@suffix)
		if(is_array(@roles)) {
			@amount = array_size(@roles)
		} else {
			_discordBot_update_members(@discord['serverid'])
			return('Role Data not populated yet, try again later.')
		}
		@cSplit = '>'
		#DM list of IDs:
		@list = array()
		@mclist = array()
		if(@amount > 0 && @discord['admin'] == true) {
			@membernames = get_value('DiscordBot.'.@discord['serverid'].'.members.names')
			foreach(@username: @userid in @membernames) {
				if(array_contains(@roles, @userid)) {
					@list[] = array('username': @username, 'id': @userid)
				}
			}
			switch(@sorttype) {
			case 'id':
				array_sort(@list, closure(@left, @right){
					return(@left['id'] > @right['id']);
				});
			}		
			#make List
			foreach(@i: @entry in @list) {
				@idmsg = ' <'.@entry['id'].'>'
				if(array_contains(@args, 'hideid')) { @idmsg = '' @cSplit = '(?<!^)`' }
				@list[@i] = '`'.@entry['username'].'`'.@idmsg
				@mclist[] = @entry['username'].@idmsg
			}
			if(@type == 'd') {
			# send to console to check split
				_discordBot_broadcast('bot', @discord['userid'], array('dm': true, 'content': '```List of IDs:```\n'.array_implode(@list, '\n'), 'custom_split': '[\\s\\S]{1,1970}(?:'.@cSplit.'|$)'), 'bot')
			}
		}
		#Return
		return(array('MCCmd': array('list': @mclist, 'msg': @msg.' '.color(9).@amount), 'embeds': array(array('author': array('icon_url': 'https://cdn.discordapp.com/icons/'.@discord['serverid'].'/'.@guildInfo['icon'].'.'.@guildIconType, 'name': @guildInfo['name']),
'title': 'Welcome Roles Finder', 'description': @msg.' `'.@amount.'`', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'])))))
}

proc _discordBot_cmd_asremove(@discord, @args) {
	# Remove user from triggered state
	if(!array_index_exists(@args, 0)) { return(color(12).'Specify the Discord user ID to remove anti spam restrictions!') }
	if(!is_numeric(@args[0])) {
		return(color(12).'Discord Usernames are not supported in this command.')
	}
	@userid = @args[0]
	@asmembers = import('DiscordBot.'.@discord['serverid'].'.antispam.members');
	if(!is_array(@asmembers)) { 
		@asmembers = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
	}
	@count = import('DiscordBot.bot.antispam.triggers')
	if(!is_array(@count)) { 
		@count = get_value('DiscordBot.bot.antispam.triggers')
		if(!is_array(@count)) { @count = array('lastedit': 0, 'total': 0) }
		if(!array_index_exists(@count, 'msgs')) { array_set(@count, 'msgs', array()) }
	}
	if(!is_array(@asmembers)) { return(color(12).'No Antispam user data found for this server.') }
	if(!array_index_exists(@asmembers, @userid)) { return(color(12).'Invalid User ID or User Not Found.') }
	@asmembersR = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
	if(!is_array(@asmembersR)) { @asmembersR = array() }
	@username = @asmembers[@userid]['username']
	array_set(@asmembers[@userid], 'removed', time())
	array_set(@asmembers[@userid], 'removeuser', @discord['username'])
	array_set(@asmembersR, @userid, @asmembers[@userid])
	array_remove(@asmembers, @userid)
	if(array_index_exists(@count, 'active', @discord['userid'])) { array_remove(@count['active'], @discord['userid']) }
	store_value('DiscordBot.'.@discord['serverid'].'.antispam.members.removed', @asmembersR)
	store_value('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	export('DiscordBot.bot.antispam.triggers', @count)
	return('Removed '.@userid.' ('.@username.') from Anti-Spam restrictions.')
}

# Lookup ASN number, ISP, and country of any IP address, using the GeoIP shell command lookup feature.
proc _discordBot_cmd_geoiplookup(@discord, @args) {
	# Requires Chat script and working shell command.
	if(!is_proc('_chat_lookup_ip_db')) { return('NoCmd') }
	@blacklistIP = import('Chat.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
	@raw = false
	if(array_contains(@args, 'raw')) { 
		@raw = true
		array_remove_values(@args, 'raw')
	}
	@ipdb = array()
	@rawIPData = array()
	@msgIPData = array('ISP Database Lookup Results:')
	foreach(@i: @ip in @args) {
		if(@ip == 'raw') { continue() }
		if(@i > 5) { @msgIPData[] = 'Sorry, this command only supports a few IP addresses at a time.' break() }
		@noip = false
		#contains both or neither octet dividers.
		if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) { @noip = true }
		#v4:
		if(string_contains(@ip, '.') && !string_contains(@ip, ':')) {
			if(!is_numeric(replace(@ip, '.', ''))) { @noip = true }
		} 
		#v6:
		if(!string_contains(@ip, '.') && string_contains(@ip, ':')) {
			if(reg_count('[G-Zg-z]+', @ip) > 0) { console(reg_match_all('[G-Zg-z]+', @ip)) @noip = true }
			@ip = reg_replace('[%][0]$', '', @ip)
		}
		if(@noip == true) {
			@userCheck = 'string'
			@userCheck = _discordBot_cmd_proc_finduserID(@ip, @discord, true);
			if(is_numeric(@userCheck) || @userCheck == 'bot' || @userCheck == 'self') { 
				_db_msg_Console(color(8).'Geo IP lookup: '.color(4).@discord['username'].' tried to doxx fellow Discord user '.@ip.'.', @discord['serverid'], 'warning')
				@say = array('https://media.tenor.com/uvxv8BBNFNYAAAAC/kid-child.gif', 'https://imgs.xkcd.com/comics/wisdom_of_the_ancients.png', 'https://imgs.xkcd.com/comics/second.png', 'https://imgs.xkcd.com/comics/security.png')
				@footer = 'You thought you had me on that one, didn\'t you? no. XD'
				if(@userCheck == 'bot') { @footer = 'Haha, I don\'t give up that easily.' }
				if(@userCheck == 'self') { @footer = 'You were really going to go that far, huh?' }
				return(array('MC': '[Server] Discordian "'.@discord['username'].'" tried to trick me! It was not effective.', 'embed': array('footer': array('text': @footer), 'image': array_get_rand(@say))))
			}
			_db_msg_Console(color(12).'Geo IP lookup: Invalid IP given: '.@ip, @discord['serverid'], 'warning')
			continue()
		}
		@listIPData = '`'.@ip.'` '
		@ipdb = _chat_lookup_ip_db(@ip, @raw);
		if(array_index_exists(@blacklistIP, 'IP_Blacklist')) {
			if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
				@listIPData .= ' <<IP present on blacklist>>'
			}
		}
		if(!is_array(@ipdb)) { return('Error') }
		if(@raw == true) {
			@listIPData .= @ipdb['raw']
		}
		if(@raw == true) { @rawIPData[] = @ip.@ipdb['raw'] }
		if(@ipdb['c'] != '') { @listIPData .= ' Country: '.@ipdb['c'] }
		if(@ipdb['cn'] != '') { @listIPData .= ' :flag_'.to_lower(@ipdb['cn']).':' }
		if(@ipdb['rc'] != '') { @listIPData .= ' Registered Country: '.@ipdb['rc'] }
		if(@ipdb['rcn'] != '') { @listIPData .= ' (:flag_'.to_lower(@ipdb['rcn']).':)' }
		# if(@ipdb['asn'] != '') { @listIPData .= ' '.'ASN: '.@ipdb['asn'] }
		if(@ipdb['asn'] != '') { 
			@listIPData .= ' ASN: '.@ipdb['asn']
			if(array_index_exists(@blacklistIP, 'Discovered_ASNs')) {
				if(array_contains(@blacklistIP['Discovered_ASNs'], @ipdb['asn'])) {
					@listIPData .= ' <ASN present on blacklist>'
				}
			}
		}
		if(@ipdb['aso'] != '') { @listIPData .= ' ISP: '.to_lower(@ipdb['aso']) }
		if(@listIPData != '`'.@ip.'` ') {
			@msgIPData[] = @listIPData
		}
	}
	if(@raw == true) {
		_discordBot_broadcast(@discord['serverid'], @discord['userid'], array('dm': true, 'content': array_implode(@rawIPData, '\n')), 'bot')
	}
	if(array_size(@msgIPData) < 2) { @msgIPData[] = '`None Found`' }
	return(array_implode(@msgIPData, '\n'))
}

proc _discordBot_cmd_getperms(@discord, @args) {
	@serverID = @discord['serverid']
	foreach(@arg in @args) {
		if(array_contains(import('DiscordBot.Servers'), @arg)) {
			@serverID = @arg
			array_remove_values(@args, @arg);
			break();
		}
	}
	@perms = discord_get_permissions(@serverID);
	@requiredPerms = array(
	# basics:
	'MESSAGE_SEND': 'I Cannot post *any* messages! How will users interact with me?',
	'MESSAGE_SEND_IN_THREADS': 'I can\'t post messages in threads, users will need to use regular channels then.',
	'MESSAGE_HISTORY': 'Any messages I send may not be able to reference another message.',
	'VIEW_CHANNEL': 'If I can\'t see messages how am I supposed to interact with it?',
	'MESSAGE_EXT_EMOJI': 'This grants the ability for Cross-Server Chat to use emojis from their servers.',
	'MESSAGE_ADD_REACTION': 'This grants the ability for the bot to add confirmation reactions to certain messages.',
	#advanced
	'MANAGE_SERVER': 'Required for Invite logging. This grants the ability to retrive your server\'s invites.',
	'MESSAGE_MANAGE': 'Required to delete others messages. Used for: <Anti Spam: remove spam messages> <Showcase: remove chat messages>',
	'MODERATE_MEMBERS': 'Required to issue a timeout to a user upon their triggering Anti Spam protections.',
	'MANAGE_WEBHOOKS': 'Required to retrive data about webhooks. Used in various embeds to show the webhook\'s avatar, if a webhook updates a message.',
	'VOICE_MOVE_OTHERS': '\"MOVE_MEMBERS\" grants the ability for Voice Chat features to disconnect any bots still in voice channel when all users leave.',
	'NICKNAME_MANAGE': '\"MANAGE_NICKNAMES\" grants the ability for Anti Spam to add \"spammer\" to those who trigger Anti Spam protections.',
	'MANAGE_ROLES': 'Setting roles grants the ability for various role related functions to operate: <Leaderboards: Active User, Role Ranks> <Commands: Fakeadmin, transferroles> <Restore previous roles upon user rejoin> <Welcome roles on user join>'
	)
	@results = array('true': array(), 'false': '', 'notreq': array())
	@return = array()
	if(array_contains(@perms, 'ADMINISTRATOR')) {
		@return[] = color(10).'Administrator permissions detected, therefore the bot has the permissions it needs!'
	} else {
		foreach(@p: @desc in @requiredPerms) {
			if(array_contains(@perms, @p)) {
				@results['true'][] = @p
			} else {
				@results['false'] = @results['false'].'\n'.color(12).@p.': '.color(7).@desc
			}
		}
		@return[] = color(10).'Required and Granted Permissions: '.color(9).array_implode(@results['true'], '  ')
		if(@results['false'] != '') { @return[] = color(4).'Permissions **Not** Found:'.@results['false'] }
	}
	return(array('console': array_implode(@return, '\n'), 'csid': @serverID, 'content': strip_colors(array_implode(@return, '\n')), 'dm': true));
}

proc _discordBot_cmd_error(@discord, @args) {
	return('Error')
}

#Add Commands to list
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'whois': array('alias': array('who', 'is'), 'admin': false, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_whois(@discord, @args)); }),
	'welcomerolesfinder': array('alias': array('wrf'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_wrf(@discord, @args)); }),
	'asremove': array('alias': array('as'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_asremove(@discord, @args)); }),
	'geoiplookup': array('alias': array('geoip'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_geoiplookup(@discord, @args)); }),
	'getperms': array('alias': array('checkpermissions'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_getperms(@discord, @args)); }),
	'errdebug': array('alias': array('error'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_error(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)