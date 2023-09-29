#version 1.3-tmc

# Every 10 minutes store changes to leaderboard in RAM to the database
# Also publishes json to logs. A webserver can pull from this for a online leaderboard display. (sold separately sry)
set_interval(600000, 100000, closure(){ _discordBot_lb_update_database() });

bind('discord_message_received', array('id': 'DiscordBot.Message.Receive', 'priority': 'MONITOR'), null, @discord) {
	array_set(@discord, 'time', time());
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@noXP = false
	if(@discord['bot'] == true || is_consumed() == true) { @noXP = true }
	@userDisplay = @discord['username']
	if(nequals_ic(@discord['username'], @discord['nickname'])) {
		@userDisplay = @discord['nickname']
	}
	
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
	if(is_consumed() == false) {
		@loadBot = ''
		if(array_index_exists(@discord, 'channeltype')) {
			if(@discord['channeltype'] == 'TEXT') {
				array_remove(@discord, 'channeltype')
			}
		}
		# Server's last 50 messages
		if(@discord['bot'] == true) { @loadBot = '.bot' }
		@lastmsgs = import('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot)
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		array_insert(@lastmsgs, @discord, 0)
		if(array_index_exists(@lastmsgs, 50)) { array_remove(@lastmsgs, 50) }
		export('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot, @lastmsgs)
		# User's last 15 messages
		if(@discord['bot'] == false) { @loadBot = '.user' }
		@lastUserMsgs = import('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot.'.'.@discord['userid'])
		@isNewUser = import('DiscordBot.'.@discord['serverid'].'.new.user.'.@discord['userid'], false);
		if(!is_array(@lastUserMsgs)) { @lastUserMsgs = array() }
		array_set(@discord, 'newuser', @isNewUser)
		array_insert(@lastUserMsgs, @discord, 0)
		if(array_index_exists(@lastUserMsgs, 15)) { array_remove(@lastUserMsgs, 15) }
		export('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot.'.'.@discord['userid'], @lastUserMsgs)
	}
	
#Send data to leaderboard
	_discordBot_lb_process_message(@discord, @noXP);
	

#Send message to Minecraft players and/or console, if event not consumed
	if(array_contains(@config['Channels_Receive'], @discord['channel']) == true && is_consumed() == false) {	
		@userRoles = discord_member_get_roles(@discord['serverid'], @discord['username'])
	#check roles ranks
		_discordBot_process_role_ranks(@discord, @userRoles);
	#Set username color based on data previously set from Discord colors
	#keys system gives roles alphabetically, not server's order
		@usernamecolor = 'ad0'
		@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard', array())
		if(array_index_exists(@leaderboard, 'members', @discord['userid'], 'color')) { @usernamecolor = @leaderboard['members'][@discord['userid']]['color'] }
		@isAdmin = false
		foreach(@role in array_keys(@userRoles)) {
			if(array_contains_ic(@config['Role_Admins'], @role)) {
				@isAdmin = true
				break()
			}
		}
		foreach(@role in array_keys(@userRoles)) {
			if(array_contains_ic(array_keys(@config['Role_Colors']), @role)) {
				#admin colors: ensure an admin role gets picked for color
				if(@isAdmin == true && !array_contains_ic(@config['Role_Admins'], @role)) {
					continue()
				}
				@usernamecolor = @config['Role_Colors'][@role]
#dev				_db_msg_Console('chose role: '.@role, @discord['serverid'], 'debug')
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
		_db_mc_broadcast(@sendmsg, @sendto, @config['Console_Messages_Chat'])
		if(array_index_exists(@discord, 'attachments', 0, 'filename') && @config['URL_Broadcast'] == true) {
			foreach(@num: @attach in @discord['attachments']) {
				_db_mc_broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], @sendto, @config['Console_Messages_Chat'])
			}
		}
	}
}