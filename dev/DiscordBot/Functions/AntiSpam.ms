#version 1.0-tmc
#Check
bind('discord_message_received', array('id': 'DiscordBot.antispam.check', 'priority': 'HIGHEST'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	if(@discord['bot'] == true) { die() }
	@time = time();
	array_set(@discord, 'time', @time);
	@botconfig = import('DiscordBot.config.Discord');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@asmembers = import('DiscordBot.'.@discord['serverid'].'.antispam.members');
	if(!is_array(@asmembers)) { 
		@asmembers = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
		if(!is_array(@asmembers)) { @asmembers = array() }
		export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	}
	@lastmsgs = import('DiscordBot.'.@discord['serverid'].'.last.message.new.'.@discord['userid'])
	if(!is_array(@lastmsgs)) { @lastmsgs = array() }
	@newuser = import('DiscordBot.'.@discord['serverid'].'.new.user.'.@discord['userid'], false);
	@adduser = false
	
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
# Checks for New Users:
	if(@newuser == true) {
	# New user has talked on most channels - unlikely unless spamming. **Set limit to around number of channels @everyone can talk on.**
		if(array_size(@userchannels[@discord['userid']]) >= @config['AS_New_User_Channel_Limit']) {
			@adduser = true
		}
	}

# Add user to triggered state
	if(@adduser == true) {
		if(!array_index_exists(@asmembers, @discord['userid'])) {
			array_set(@asmembers, @discord['userid'], array('time': @time, 'username': @discord['username']))
			export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
			store_value('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
		}
	}
	
# User is in Triggered state
	if(array_index_exists(@asmembers, @discord['userid'])) {
		consume();
		@count = import('DiscordBot.'.@discord['serverid'].'.'.@discord['userid'].'.antispam.trigger', 0)
		@count++
		export('DiscordBot.'.@discord['serverid'].'.'.@discord['userid'].'.antispam.trigger', @count)
		if(@count < 2) {
			# If first run: Delete all messages listed from last.message.new.userid & message Admins and user.
			foreach(@message in @lastmsgs) {
				try {
					discord_delete_message(@message['serverid'], @message['channelid'], @message['id']);
				} catch(Exception @ex) {
					_db_msg_Console('  ['.@discord['serverid'].'] [AntiSpam] Cannot remove message "'.@message['id'].'" from '.@discord['username'].' <@'.@discord['userid'].'> '.@ex['classType'].@ex['message'], @discord['serverid'])
				}
			}
				# _discordBot_send_message(@message, @guild, @from, @channel, @type, @option) {
		# Message Admins, and DM user.
			_discordBot_send_message('I\'ve triggered Anti Spam actions upon user: `'.@discord['username'].'`  '.@discord['userid'].', and have deleted this user\'s recent messages. You may want to review further actions such as kick or ban.', @discord['serverid'], 'admin');
			_discordBot_send_message('You have triggered this server\'s Anti Spam protection. You will need to message the moderators of this server to reinstate access.', @discord['serverid'], 'death', @discord['userid'], 'dm')
		}
		try {
			discord_delete_message(@discord['serverid'], @discord['channelid'], @discord['id']);
		} catch(Exception @ex) {
			_db_msg_Console('  ['.@discord['serverid'].'] [AntiSpam] Cannot remove message "'.@discord['id'].'" from '.@discord['username'].' <@'.@discord['userid'].'> '.@ex['classType'].@ex['message'], @discord['serverid'])
		}
	} else {
#User OK, record last message if a new user
		if(@newuser == true) {
			array_insert(@lastmsgs, @discord, 0)
			export('DiscordBot.'.@discord['serverid'].'.last.message.new.'.@discord['userid'], @lastmsgs)
		}
	}
}