# Autosave Keys
@x8db = import('DiscordBot.db.save.keys', array())
@x8db[] = 'antispam.members'
@x8db[] = 'bot.antispam.triggers'
export('DiscordBot.db.save.keys', array_unique(@x8db))

# Anti Spam functions: Check if user is repeating messages, new user chatting on too many channels, etc.
proc _db_as_dm(@discord, @isFirst = false) {
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array() }
	if(array_index_exists(@cacheMsgs, 'messages', @discord['id'], 'deleted')) {
		if(@cacheMsgs['messages'][@discord['id']]['deleted'] == true) {
			_db_msg_Console('[AntiSpam] Message ID '.@discord['id'].' already deleted?!  <first:'.@isFirst.'> [Channel: '.@discord['channel'].']', @discord['serverid'])
			return(false)
		}
	}
	try {
		discord_delete_message(@discord['serverid'], @discord['channelid'], @discord['id']);
		if(array_index_exists(@cacheMsgs, 'messages', @discord['id'])) {
			array_set(@cacheMsgs['messages'][@discord['id']], 'deleted', true)
			export('DiscordBot.'.@discord['serverid'].'.Cache.Messages', @cacheMsgs)
		}
		return(true)
	} catch(Exception @ex) {
		_db_msg_Console('  ['.@discord['serverid'].'] [AntiSpam] Cannot remove message "'.@discord['id'].'" from '.@discord['username'].' <@'.@discord['userid'].'> '.@ex['classType'].@ex['message'], @discord['serverid'])
		return(false)
	}
}

bind('discord_message_received', array('id': 'DiscordBot.antispam.check', 'priority': 'HIGHEST'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die() }
	if(@discord['bot'] == true) { die() }
	@time = time();
	array_set(@discord, 'time', @time);
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@guildInfo = import('DiscordBot.Guilds.Info.'.@discord['serverid'], array('name': @config['Server_Nickname']));
	@codeDesc = array(0: 'Unknown', 1: '*New* user has talked on more than the limit of '.@config['AS_New_User_Channel_Limit'].' different channels.', 2: '*New* user used a global mention: `%word%`', 3: 'Duplicated same message', 4: 'Duplicated same message across 3 or more channels')
	# 0: not selected, 1: New user: channel limit, 2: New user used here/everyone, 3: Dupe messages, 4: dupe messages over 3 channels
	@reasonCode = 0
	@asmembers = import('DiscordBot.'.@discord['serverid'].'.antispam.members');
	if(!is_array(@asmembers)) { 
		@asmembers = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
		if(!is_array(@asmembers)) { @asmembers = array('lastedit': 0) }
		export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	}
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array() }
	@newuser = _db_is_newmember(@discord['serverid'], @discord['userid']);
	@adduser = false
	@lastUserMsgs = array()
	if(array_index_exists(@cacheMsgs, 'user', @discord['userid'])) {
		foreach(@userMsgID in @cacheMsgs['user'][@discord['userid']]) {
			@lastUserMsgs[] = @cacheMsgs['messages'][@userMsgID]
		}
	}
# Record channels user has talked on recently
	@userchannels = import('DiscordBot.'.@discord['serverid'].'.Cache.User.Channels')
	if(!is_array(@userchannels)) { @userchannels = array() }
	if(array_index_exists(@userchannels, @discord['userid'])) {
		if(!array_contains(@userchannels[@discord['userid']], @discord['channelid'])) {
			@userchannels[@discord['userid']][] = @discord['channelid']
			export('DiscordBot.'.@discord['serverid'].'.Cache.User.Channels', @userchannels)
		}		
	} else {		
		array_set(@userchannels, @discord['userid'], array(@discord['channelid']))
		export('DiscordBot.'.@discord['serverid'].'.Cache.User.Channels', @userchannels)
	}
#Checks
# Duplicate messages (More than 3-4 is typically indicative of spam)
	# Do not count if previous data not available, or message is blank
	if(array_index_exists(@lastUserMsgs, 2) && @discord['message'] != '') {
		@dcount = import('DiscordBot.'.@discord['serverid'].'.'.@discord['userid'].'.antispam.dupe', 0)
		# Last message is the same as current:
		if(@lastUserMsgs[0]['message'] == @discord['message']) {
			## Add extra count: Current message is same yet posted on different channel. Can be indicative of spam same message on all available channels.
			if(@lastUserMsgs[0]['channelid'] != @discord['channelid']) { @dcount++ }
			# Last 2 messages is ... also the same as current:
			if(@lastUserMsgs[1]['message'] == @discord['message']) {
				# Previous 2 messages match, highly likely spam event. Increment counter.
				@dcount++
				## Add extra count x2: Current message posted on channel that isn't either of the previous 2 channels. Highly likely spam event! (or someone legitly replying "lol" to everything)
				if(@lastUserMsgs[0]['channelid'] != @discord['channelid'] && @lastUserMsgs[1]['channelid'] != @discord['channelid'] && @lastUserMsgs[0]['channelid'] != @lastUserMsgs[1]['channelid']) {
					@dcount++
					@reasonCode = 4
				}
			}
		}
		if(@dcount > 0) {
			export('DiscordBot.'.@discord['serverid'].'.'.@discord['userid'].'.antispam.dupe', @dcount)
			set_timeout(12345, closure(){
				export('DiscordBot.'.@discord['serverid'].'.'.@discord['userid'].'.antispam.dupe', null)
			});
		}
	### If the counter reaches 5, trigger anti spam
		if(@dcount > 5) {
			@adduser = true
			if(@reasonCode == 0) { @reasonCode = 3 }
		}
	}	
# Checks for New Users:
	if(@newuser == true) {
	# New user has talked on most channels - unlikely unless spamming. **Set limit to around number of channels @everyone can talk on.**
		if(array_size(@userchannels[@discord['userid']]) >= @config['AS_New_User_Channel_Limit']) {
			@adduser = true
			@reasonCode = 1
		}
	# New user pinged here or everyone
		@checkmsg = parse_args(@discord['message'])
		foreach(@word in @checkmsg) {
			if(to_lower(@word) == '@here' || to_lower(@word) == '@everyone') {
				@adduser = true
				@reasonCode = 2
				@codeDesc[@reasonCode] = replace(@codeDesc[@reasonCode], '%word%', @word)
			}
		}
	}

# Add user to Triggered state:
	if(@adduser == true) {
		if(!array_index_exists(@asmembers, @discord['userid'])) {
			# Returning users: Bypass new user checks
			if(@reasonCode < 3) {
				@newreturn = import('DiscordBot.'.@guild.'.returning.users')
				if(!is_array(@newreturn)) { @newreturn = array() }
				if(array_index_exists(@newreturn, @discord['userid'])) {
					if(@newreturn[@discord['userid']] == true) { die() }
				}
			}
			array_set(@asmembers, @discord['userid'], array('rt': @reasonCode, 'log': false, 'rtime': @time, 'time': @time, 'username': @discord['username'], 'notes': '', 'triggercount': 0))
		}
	}
	
# !!! User is in Triggered state: !!!
	if(array_index_exists(@asmembers, @discord['userid'])) {
		consume();
		@actiontaken = '\n- *Actions taken:*'
	# Record total server triggers
		@count = import('DiscordBot.bot.antispam.triggers')
		if(!is_array(@count)) { 
			@count = get_value('DiscordBot.bot.antispam.triggers')
			if(!is_array(@count)) { @count = array('lastedit': 0, 'total': 0) }
			if(!array_index_exists(@count, 'msgs')) { array_set(@count, 'msgs', array()) }
			if(!array_index_exists(@count, 'active')) { array_set(@count, 'active', array()) }
		}
		if(!array_index_exists(@count, @discord['serverid'])) { array_set(@count, @discord['serverid'], 0) }
		@count[@discord['serverid']]++
		@count['total']++
	# Record User message hash (for DMs to verify if same spam was DM'ed to bot)
		if(!array_index_exists(@count, 'msgs', @discord['userid'])) { array_set(@count['msgs'], @discord['userid'], array()) }
		if(!array_contains(@count['msgs'][@discord['userid']], sha1(@discord['message']))) {
			@count['msgs'][@discord['userid']][] = sha1(@discord['message'])
		}
	# Record user is active under Anti Spam
		if(!array_index_exists(@count, 'active', @discord['userid'])) {
			array_set(@count['active'], @discord['userid'], @discord['serverid'])
		}
		@count['lastedit'] = @time
		export('DiscordBot.bot.antispam.triggers', @count)
	# If user's first trigger:
		if(@asmembers[@discord['userid']]['triggercount'] < 2) {
			@msgcount = 0
		# Delete all messages recorded in the user's last message storage
			if(@config['AS_Delete_Messages'] == true) {
				foreach(@message in @lastUserMsgs) {
					# Action upon only today's messages
					if(@message['time'] > (@time - 43200000)) {
						@return = _db_as_dm(@message, true);
						if(@return == true) { @msgcount++ }
					}
				}
			}
			if(@msgcount > 0) {
				@actiontaken = @actiontaken.' Deleted '.@msgcount.' of user\'s recent messages'
			}
		# Message Admins, and DM user.
			if(@actiontaken == '\n- *Actions taken:*') { @actiontaken = '' }
			@logMsg = array('content': '__**Anti Spam alert**__\nUser <@'.@discord['userid'].'> [`'.@discord['username'].'`  `'.@discord['userid'].'`] triggered Anti Spam protection!\n- *Protection Reason:* '.@codeDesc[@reasonCode].@actiontaken)
			@userinfo = array()
			try {
				@userinfo = discord_member_info(@discord['serverid'], @discord['userid']);
			} catch(NotFoundException @ex) {
				export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid'])
			}
			if(@config['AS_Log_ShowUserInfo'] == true && array_index_exists(@userinfo, 'userid')) {
				@userRoles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
				@displayUR = 'None'
				if(array_size(@userRoles) > 0) { @displayUR = '<@&'.array_implode(@userRoles, '> <@&').'>' }
				array_set(@logMsg, 'embeds', array())
			#Get Avatar and embed color info
				if(!array_index_exists(@userinfo, 'avatar')) { array_set(@userinfo, 'avatar', 'https://cdn.discordapp.com/embed/avatars/0.png') }
				@logMsg['embeds'][] = array(
				'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @discord['username'])),
				'color': array('r': 109, 'g': 109, 'b': 109),
				'thumbnail': @userinfo['avatar'].'?size=48',
				'fields': array(
					array('name': 'Join: Server', 'value': '<t:'.substr(@userinfo['joined_at'], 0, 10).':f>', 'inline': true),
					array('name': 'Server: Is New User', 'value': @newuser, 'inline': true),
					array('name': 'Join: Discord', 'value': '<t:'.substr(rshift(@discord['userid'], 22) + 1420070400000, 0, 10).':f>', 'inline': true)
				),
				'footer': array('text': 'ID: '.@discord['userid']),
				'timestamp': time()
				)
				if(array_index_exists(@userinfo, 'color')) {
					if(@userinfo['color'] != null) {
						array_set(@logMsg['embeds'][0], 'color', @userinfo['color'])
					}
				}
				@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard')
				if(is_array(@leaderboard)) {
					if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { 
						if(@leaderboard['members'][@discord['userid']]['level'] > 0) {
							@logMsg['embeds'][0]['fields'][] = array('name': 'Leaderboard Level', 'value': @leaderboard['members'][@discord['userid']]['level'], 'inline': true)
						}	
					}
				}
				@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info')
				if(!is_array(@joininfo)) { @joininfo = array() }
				if(!array_index_exists(@joininfo, @discord['userid'])) {
					@inv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())	
					if(array_index_exists(@inv, @discord['userid'], 'code')) {
						array_set(@joininfo, @discord['userid'], array('code': @inv[@discord['userid']]['code']))
					}
				}
				if(array_index_exists(@joininfo, @discord['userid'], 'code')) {
					@code = @joininfo[@discord['userid']]['code']
					if(is_array(@joininfo[@discord['userid']]['code'])) { @code = array_implode(@joininfo[@discord['userid']]['code'], ', ') }
					if(@code != '') { @logMsg['embeds'][0]['fields'][] = array('name': 'Invite', 'value': @code, 'inline': true) }
				}
				@logMsg['embeds'][0]['fields'][] = array('name': 'Roles ['.array_size(@userRoles).']', 'value': @displayUR, 'inline': false)
			}
			if(@asmembers[@discord['userid']]['log'] == false) {
				_db_msg_Console(color(14).@discord['username'].color(8).' <@'.@discord['userid'].'>'.color(7).' triggered Anti Spam protection. Reason #'.@reasonCode.color(9).'\n'.@codeDesc[@reasonCode], @discord['serverid'])
				_discordBot_send_message(@logMsg, @discord['serverid'], 'admin');
				@announceMsg = ''
				if(array_index_exists(@config, 'AS_Announcement_'.@reasonCode)) {
					@announceMsg = replace(@config['AS_Announcement_'.@reasonCode], '%UserID%', '<@'.@discord['userid'].'>')
				} else if(array_index_exists(@config, 'AS_General_Announcement')) {
					@announceMsg = @config['AS_General_Announcement']
				}
				if(@announceMsg != '') { _discordBot_send_message(@announceMsg, @discord['serverid'], 'announce'); }
				@subMsg = ''
				if(@reasonCode < 3) {
					@logJointimes = get_value('DiscordBot.'.@discord['serverid'].'.log.users.Join.Times')
					if(!is_array(@logJointimes)) { @logJointimes = array() }
					if(!array_index_exists(@logJointimes, @discord['userid'], 1)) { @subMsg = '\n\nIf you have recently rejoined the server with a new account, ask the moderators to use my `transferroles` command to bypass this AntiSpam protection.' }
				}
				_discordBot_send_message('Your recent activity at the server "'.@guildInfo['name'].'" has triggered their Anti Spam protection. You will need to message the moderators to reinstate access.'.@subMsg, @discord['serverid'], 'death', @discord['userid'], 'dm')
				@asmembers[@discord['userid']]['log'] = true
			}
		}
	#Actions for each trigger:
		if(@config['AS_Delete_Messages'] == true) {
			_db_as_dm(@discord);
		}
		@asmembers['lastedit'] = @time
		array_set(@asmembers[@discord['userid']], 'rtime', @time)
		@asmembers[@discord['userid']]['triggercount']++
		export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	}
	# } else {
	#User OK 
}