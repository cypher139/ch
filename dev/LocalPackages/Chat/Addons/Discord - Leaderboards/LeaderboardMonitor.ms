#version 1.0-tmc
export('server.Discord.members.leaderboard', get_value('server.Discord.members.leaderboard'));
export('server.Discord.members.leaderboard.last.save', time());
if(!is_array(import('server.Discord.members.leaderboard'))) {
	export('server.Discord.members.leaderboard', array('lastedit': time(), 'members': array()))
}
# Every 10 minutes store changes to leaderboard in RAM to the database
# Also publishes json to logs. A webserver can pull from this for a online leaderboard display. (sold separately sry)
set_interval(600000, 60000, closure(){ _chat_lb_update_database() });
_chat_lb_levelXP();

# Data: userid, username, nickname, channel, channelid, channeltype, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'Chat.Discord.monitor.Leaderboard', 'priority': 'MONITOR'), null, @discord) {
	@noXP = false
	@config = import('Chat.config.Discord')
	@userID = @discord['userid']
	@levelxp = import('server.Discord.leaderboard.levelXP')
	# Do not count messages from Command spam channel or Channels marked as no XP earning.
	if(array_contains(@config['LB_NoXP_Channels'], @discord['channel'])) { @noXP = true }
	if(@discord['channel'] == @config['CMD_Default_Channel']) { @noXP = true }
	@leaderboard = import('server.Discord.members.leaderboard', get_value('server.Discord.members.leaderboard'));
	#Setup list of server members for reference in mentions
	_chat_dc_add_member(@discord) 
	
	if(!array_index_exists(@leaderboard, 'members', @userID)) {
		array_set(@leaderboard['members'], @userID, array('time': (time() - 70000), 'level': 0, 'xp': 0, 'username': @discord['username'], 'message_count': 0))
	}

# If user has last chatted in last rolling minute, do not award XP. (continues to count message)
	if((@leaderboard['members'][@userID]['time'] + 60000) > time()) {
		@noXP = true 
	} else {
# Check if user has a no XP earning role.
		try { 
			@userRoles = discord_member_get_roles(@userID)
		} catch(Exception @ex) {
			die()
		}
		foreach(@role in @userRoles) {
			if(array_contains(@config['LB_NoXP_RoleID'], @role)) {
				@noXP = true
				break()
			}
		}
	}
# Incrememnt Message count and XP
	@leaderboard['members'][@userID]['message_count'] = @leaderboard['members'][@userID]['message_count'] + 1

	if(@noXP == false) {
		@newxp = rand(@config['LB_XP_Per_Message'][0], @config['LB_XP_Per_Message'][1])
		@leaderboard['members'][@userID]['time'] = time()
		@leaderboard['members'][@userID]['xp'] = @leaderboard['members'][@userID]['xp'] + @newxp
	} else {
	# backdated time so immediate new message in XP earning channel can be counted
		@leaderboard['members'][@userID]['time'] = (time() - 60000)
	}


# If current XP is greater than the max for this level:
	if(@leaderboard['members'][@userID]['xp'] > @levelxp[@leaderboard['members'][@userID]['level']] && @noXP == false) {
		@currentrank = ''
		@newlevel = @leaderboard['members'][@userID]['level'] + 1
		@leaderboard['members'][@userID]['level'] = @newlevel
		@rankmsg = '!'
		@ranknums = array_sort(array_keys(@config['LB_Role_Rewards']), 'NUMERIC')
		@oldroles = array_sort(array_normalize(@userRoles), 'NUMERIC')
	#Find rank
		foreach(@i: @range in @ranknums) {
			if(@i == 0) {
				@lastrank = 0
			} else {
				@lastrank = @ranknums[(@i - 1)]
			}
			if(@newlevel == @range) {
				@currentrank = @config['LB_Role_Rewards'][@range]
				@rankmsg = ', and is now a '.@config['LB_Role_Rewards'][@range]['RoleName'].'!'
				break()
			}
			if(@newlevel < @range && @newlevel > @lastrank) {
				@currentrank = @config['LB_Role_Rewards'][@ranknums[(@i - 1)]]
				break()
			}
		}
		@userRoles = array_normalize(@userRoles)
		store_value('Chat.debug.Discord.User.'.@userID.'.old.roles', @userRoles)
		
	# Remove old role rewards
		if(@config['LB_Stack_Role_Rewards'] == false) {
			foreach(@role in @config['LB_Role_Rewards']) {
				array_remove_values(@userRoles, @role['RoleID'])
			}
		}
	# Place new role
		array_push(@userRoles, @currentrank['RoleID'])
	#Set New roles
		try { 
			discord_member_set_roles(@userID, @userRoles)
		} catch(Exception @ex) {
			die()
		}
	}
	
	@discordMsg = reg_replace('%UserID%', '<@'.@userID.'>', @config['LB_Level_Up_Message'])
	@discordMsg = reg_replace('%Level%', @newlevel.@rankmsg, @discordMsg)
	console('[Discord] '.@discord['username'].' '.@discordMsg, false)
	# _send_discord_message('<@'.@userID.'> just leveled up to level '.@newlevel.@rankmsg, 'discord', @discord['channel'])

#Save edits
	@leaderboard['lastedit'] = time()
	export('server.Discord.members.leaderboard', @leaderboard)
}