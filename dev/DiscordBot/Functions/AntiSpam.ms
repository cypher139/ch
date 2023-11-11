#version 1.0-tmc

proc _db_as_dm(@discord) {
	try {
		discord_delete_message(@discord['serverid'], @discord['channelid'], @discord['id']);
		return(true)
	} catch(Exception @ex) {
		_db_msg_Console('  ['.@discord['serverid'].'] [AntiSpam] Cannot remove message "'.@discord['id'].'" from '.@discord['username'].' <@'.@discord['userid'].'> '.@ex['classType'].@ex['message'], @discord['serverid'])
		return(false)
	}
}		

#Check
bind('discord_message_received', array('id': 'DiscordBot.antispam.check', 'priority': 'HIGHEST'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	if(@discord['bot'] == true) { die() }
	@time = time();
	array_set(@discord, 'time', @time);
	@botconfig = import('DiscordBot.config.Discord');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@guildInfo = import('DiscordBot.Guilds.Info.'.@discord['serverid'], array('name': @config['Server_Nickname']));
	@asmembers = import('DiscordBot.'.@discord['serverid'].'.antispam.members');
	if(!is_array(@asmembers)) { 
		@asmembers = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
		if(!is_array(@asmembers)) { @asmembers = array() }
		export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	}
	@newLastMsgs = import('DiscordBot.'.@discord['serverid'].'.last.message.new.'.@discord['userid'], array())
	if(!is_array(@newLastMsgs)) { @newLastMsgs = array() }
	@newuser = import('DiscordBot.'.@discord['serverid'].'.new.user.'.@discord['userid'], false);
	@adduser = false
	@triggerReason = ''
	@triggerReasonalt = ''
	@lastUserMsgs = import('DiscordBot.'.@discord['serverid'].'.last.message.user.'.@discord['userid'], array())
	
# Record channels user has talked on recently
	@userchannels = import('DiscordBot.'.@discord['serverid'].'.user.chat.channels')
	if(!is_array(@userchannels)) { @userchannels = array() }
	if(array_index_exists(@userchannels, @discord['userid'])) {
		if(!array_contains(@userchannels[@discord['userid']], @discord['channelid'])) {
			@userchannels[@discord['userid']][] = @discord['channelid']
			export('DiscordBot.'.@discord['serverid'].'.user.chat.channels', @userchannels)
		}		
	} else {		
		array_set(@userchannels, @discord['userid'], array(@discord['channelid']))
		export('DiscordBot.'.@discord['serverid'].'.user.chat.channels', @userchannels)
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
				if(@lastUserMsgs[0]['channelid'] != @discord['channelid'] && @lastUserMsgs[1]['channelid'] != @discord['channelid'] && @lastUserMsgs[0]['channelid'] != @lastUserMsgs[1]['channelid']) { @dcount++ @triggerReasonalt = ' across 3 or more channels' }
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
			@triggerReason = 'Duplicated messages'.@triggerReasonalt
		}
	}	
# Checks for New Users:
	if(@newuser == true) {
	# New user has talked on most channels - unlikely unless spamming. **Set limit to around number of channels @everyone can talk on.**
		if(array_size(@userchannels[@discord['userid']]) >= @config['AS_New_User_Channel_Limit']) {
			@adduser = true
			@triggerReason = '*New* user talked on over '.@config['AS_New_User_Channel_Limit'].' different channels.'
		}
	}

# Add user to Triggered state:
	if(@adduser == true) {
		if(!array_index_exists(@asmembers, @discord['userid'])) {
			array_set(@asmembers, @discord['userid'], array('time': @time, 'username': @discord['username'], 'reason': @triggerReason))
			export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
			store_value('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
		}
	}
	
# !!! User is in Triggered state: !!!
	if(array_index_exists(@asmembers, @discord['userid'])) {
		consume();
		@actiontaken = '\n*Actions taken:*'
		@count = import('DiscordBot.'.@discord['serverid'].'.'.@discord['userid'].'.antispam.trigger', 0)
		@count++
		export('DiscordBot.'.@discord['serverid'].'.'.@discord['userid'].'.antispam.trigger', @count)
	#If first trigger:
		if(@count < 2) {
			@msgcount = 0
			if(@config['AS_Delete_Messages'] == true) {
			# Delete all messages recorded in the user's last message storage
				if(@newuser == true) {
					foreach(@message in @newLastMsgs) {
						@return = _db_as_dm(@message);
						if(@return == true) { @msgcount++ }
					}
				} else {
					foreach(@message in @lastUserMsgs) {
						@return = _db_as_dm(@message);
						if(@return == true) { @msgcount++ }
					}
				}
			}
			if(@msgcount > 0) {
				@actiontaken = @actiontaken.' Deleted '.@msgcount.' of user\'s recent messages'
			}
		# Message Admins, and DM user.
			if(@actiontaken == '\n*Actions taken:*') { @actiontaken = '' }
			_discordBot_send_message('__**Anti Spam alert**__\n User `'.@discord['username'].'`  '.@discord['userid'].' triggered Anti Spam protection!\n *Protection Reason:* '.@triggerReason.@actiontaken, @discord['serverid'], 'admin');
			_discordBot_send_message('Your recent activity at the server "'.@guildInfo['name'].'" has triggered their Anti Spam protection. You will need to message the moderators to reinstate access.', @discord['serverid'], 'death', @discord['userid'], 'dm')
		}
		if(@config['AS_Delete_Messages'] == true) {
			_db_as_dm(@discord);
		}
	} else {
	#User OK 
		#If a New User: record messages in special key
		if(@newuser == true) {
			array_insert(@newLastMsgs, @discord, 0)
			export('DiscordBot.'.@discord['serverid'].'.last.message.new.'.@discord['userid'], @newLastMsgs)
		}
	}
}