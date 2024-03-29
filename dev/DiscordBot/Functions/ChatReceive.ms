# Autosave Keys
@x8db = import('DiscordBot.db.save.keys', array())
@x8db[] = 'Leaderboard'
@x8db[] = 'debug.roles.Leaderboard.undo'
export('DiscordBot.db.save.keys', array_unique(@x8db))

# Receive messages from Discord users, pass data to Leaderboard and Minecraft server, save message for future reference.
bind('discord_message_received', array('id': 'DiscordBot.Message.Receive', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die() }
	@time = time()
	array_set(@discord, 'time', @time);
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@noXP = false
	if(@discord['bot'] == true || is_consumed() == true) { @noXP = true }
	@userDisplay = _db_get_user_nick(@discord['userid'], @discord['serverid'], @discord['username'])
	@sendtoMC = false
	@sendtoCS = false
	if(@discord['channel'] == @config['Minecraft_Channel'] || @discord['channelid'] == @config['Minecraft_Channel']) { @sendtoMC = true @sendtoCS = true }
	if(array_index_exists(@config, 'CS_Channel')) {
		@sendtoCS = false
		if(@discord['channel'] == @config['CS_Channel'] || @discord['channelid'] == @config['CS_Channel']) { @sendtoCS = true }
	}

# Console: List bot reference mention
	if(array_index_exists(@discord, 'reference', 'userid')) {
		if(@discord['reference']['userid'] == @botconfig['Bot_ID']) {
			_db_msg_Console(color(11).@userDisplay.'\'s '.color(9).'message referenced me! Their message:\n'.color('r').@discord['message'], @discord['serverid'])
		}
	}

#Send data to leaderboard
	_discordBot_lb_process_message(@discord, @noXP);
	
#Send data to cross-server chat
	if(@config['Cross_Server_Messages'] == true && @sendtoCS == true && is_consumed() == false) {
		_discordBot_send_cs_chat(@discord);
	}
	
# Remaining items to only occur if event is not consumed
	if(is_consumed() == false) {
		export('DiscordBot.'.@discord['serverid'].'.CacheUpdate', true)
		@newuser = _db_is_newmember(@discord['serverid'], @discord['userid']);
	#Message Formatting
		if(reg_count('^.+\\/\\/tenor\\.com\\/view', @discord['message']) > 0 && @config['URL_Broadcast'] == false) {
			@discord['message'] = '<Sent a GIF>'
		}
		if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
			if(@discord['message'] == '') {	
				@discord['message'] = '<Sent a file> '
			} else {
				@discord['message'] = @discord['message'].'\n <Also attached file:> '
			}
			foreach(@num: @attach in @discord['attachments']) {
				@filenum = 'File: '
				if(@num != 0) { @filenum = '  File #'.(@num + 1).': ' }
				@discord['message'] = @discord['message'].@filenum.@attach['filename']
			}
		}
	#Save Recent Messages for reference
		@userType = 'user'
		if(@discord['bot'] == true) { @userType = 'bot' }
		if(array_index_exists(@discord, 'channeltype')) {
			if(@discord['channeltype'] == 'TEXT') {
				array_remove(@discord, 'channeltype')
			}
		}
		@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
		if(!is_array(@cacheMsgs)) { @cacheMsgs = array('messages': array(), 'bot': array(), 'user': array(), 'server': array()) }
		array_set(@cacheMsgs['messages'], @discord['id'], @discord)
		if(!array_index_exists(@cacheMsgs, @userType, @discord['userid'])) { array_set(@cacheMsgs[@userType], @discord['userid'], array()) }
		array_insert(@cacheMsgs[@userType][@discord['userid']], @discord['id'], 0)
		array_insert(@cacheMsgs['server'], @discord['id'], 0)
		if(array_size(@cacheMsgs['messages']) > @botconfig['Msg_Cache_Server'] + 100) {
			array_remove(@cacheMsgs['messages'], array_sort(array_keys(@cacheMsgs['messages']), 'NUMERIC')[0])
		}
		if(array_index_exists(@cacheMsgs, @userType, @discord['userid'], @botconfig['Msg_Cache_User']) && @newuser == false) { array_remove(@cacheMsgs[@userType][@discord['userid']], @botconfig['Msg_Cache_User']) }
		if(array_index_exists(@cacheMsgs, 'server', @botconfig['Msg_Cache_Server'])) { array_remove(@cacheMsgs['server'], @botconfig['Msg_Cache_Server']) }
		export('DiscordBot.'.@discord['serverid'].'.Cache.Messages', @cacheMsgs)
	#Check User Role Ranks
		if(@config['Use_Role_Ranks'] == true && @discord['bot'] == false) {
			@rrupdates = import('DiscordBot.'.@discord['serverid'].'.user.update.time.rr')
			if(@rrupdates == null) { @rrupdates = array() }
			if(!array_index_exists(@rrupdates, @discord['userid'])) {
				array_set(@rrupdates, @discord['userid'], time())
				export('DiscordBot.'.@discord['serverid'].'.user.update.time.rr', @rrupdates)
			}
			if(time() > (@rrupdates[@discord['userid']] + 86400000)) {
				_discordBot_process_role_ranks(@discord);
				@rrupdates[@discord['userid']] = time()
				export('DiscordBot.'.@discord['serverid'].'.user.update.time.rr', @rrupdates)
			}
		}
	#Send message to Minecraft players and/or console
		@checkPermission = null
		#Primary Guild: accept multiple channels
		if(@discord['serverid'] == @botconfig['Primary_Guild']) {
			if(array_contains(@config['Channels_Receive'], @discord['channel']) || array_contains(@config['Channels_Receive'], @discord['channelid'])) { 
				@sendtoMC = true
				@checkPermission = 'DiscordBot.chat.channel.'.@discord['channel']
			}
		}
		if(@sendtoMC == true && is_consumed() == false && @config['Minecraft_Messages'] == true) {
			@userRoles = discord_member_get_roles(@discord['serverid'], @discord['username'])
		#Set username color based on data previously set from Discord colors
		# keys system gives roles alphabetically, not server's order
			@usernamecolor = 'ad0'
			@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard', array())
			if(array_index_exists(@leaderboard, 'members', @discord['userid'], 'color')) { @usernamecolor = @leaderboard['members'][@discord['userid']]['color'] }
			@isAdmin = false
			foreach(@rN: @rID in @userRoles) {
				if(array_contains_ic(@config['Role_Admins'], @rN) || array_contains(@config['Role_Admins'], @rID)) {
					@isAdmin = true
					break()
				}
			}
			foreach(@rN: @rID in @userRoles) {
				@role = 0
				if(array_contains_ic(array_keys(@config['Role_Colors']), @rN)) { @role = @rN }
				if(array_contains_ic(array_keys(@config['Role_Colors']), @rID)) { @role = @rID }
				if(@role != 0) {	
					#Try to ensure an admin role gets picked for color
					if(@isAdmin == true && !array_contains_ic(@config['Role_Admins'], @role)) { continue() }
					@usernamecolor = @config['Role_Colors'][@role]
	#dev				_db_msg_Console('chose role color: '.@role, @discord['serverid'], 'debug')
					#Only go with first role found
					break()
				}
			}
		#Send
			@sendmsg = color('#'.@usernamecolor).'['.@userDisplay.'] '.color(7).@discord['message']
			if(@discord['bot'] == true) {
				@sendmsg = color(@usernamecolor).'[Bot]'.@sendmsg
			}
			@sendto = 'players'
			if(@config['Console_Messages_Chat'] == true) { @sendto = '' }
			_db_mc_broadcast(@sendmsg, @sendto, @config['Console_Messages_Chat'], @checkPermission)
			if(array_index_exists(@discord, 'attachments', 0, 'filename') && @config['URL_Broadcast'] == true) {
				foreach(@num: @attach in @discord['attachments']) {
					_db_mc_broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], @sendto, @config['Console_Messages_Chat'], @checkPermission)
				}
			}
		}
	}
}