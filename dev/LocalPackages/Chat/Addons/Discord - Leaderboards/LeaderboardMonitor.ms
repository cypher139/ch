#version 1.0-tmc
export('server.Discord.members.leaderboard', get_value('server.Discord.members.leaderboard'));
if(!is_array(import('server.Discord.members.leaderboard'))) {
	export('server.Discord.members.leaderboard', array('lastedit': time(), 'members': array()))
}
# Every 10 minutes store changes to leaderboard in RAM to the database
# Also publishes json to logs. A webserver can pull from this for a online leaderboard display. (sold separately sry)
set_interval(600000, 600000, closure(){ _chat_lb_update_database() });
_chat_lb_levelXP();

# Data: userid, username, nickname, channel, channelid, channeltype, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'Chat.Discord.monitor.Leaderboard', 'priority': 'MONITOR'), null, @discord) {
	@noXP = false
	@config = import('Chat.config.Discord')
	@userID = @discord['userid']
	# Do not count messages from Command spam channel or Channels marked as no XP earning.
	if(array_contains(@config['LB_NoXP_Channels'], @discord['channel'])) { @noXP = true }
	if(@discord['channel'] == @config['CMD_Default_Channel']) { @noXP = true }
	@leaderboard = import('server.Discord.members.leaderboard', get_value('server.Discord.members.leaderboard'));
	#Setup list of server members for reference in mentions
	_chat_dc_add_member(@discord) 
	
	if(!array_index_exists(@leaderboard, 'members', @userID)) {
		array_set(@leaderboard['members'], @userID, array('time': (time() - 70000), 'level': 0, 'xp': 0, 'username': @discord['username'], 'message_count': 0))
	}

# if user has last chatted in last rolling minute, do not award XP. (continues to count message)
	if((@leaderboard['members'][@userID]['time'] + 60000) > time()) {
		@noXP = true 
	} else {
#Check if user has a no XP earning role.
		@userRoles = discord_member_get_roles(@userID)
		foreach(@role in @userRoles) {
			if(array_contains(@config['LB_NoXP_RoleID'], @role)) {
				@noXP = true
				break()
			}
		}
	}


@leaderboard['members'][@userID]['message_count'] = @leaderboard['members'][@userID]['message_count'] + 1

if(@noXP == false) {
	@newxp = rand(@config['LB_XP_Per_Message'][0], @config['LB_XP_Per_Message'][1])
	@leaderboard['members'][@userID]['time'] = time()
	@leaderboard['members'][@userID]['xp'] = @leaderboard['members'][@userID]['xp'] + @newxp
} else {
# backdated time so immediate new message in XP earning channel can be counted
	@leaderboard['members'][@userID]['time'] = (time() - 60000)
}


@levelxp = import('server.Discord.leaderboard.levelXP')

# if current XP is greater than max for this level:
	if(@leaderboard['members'][@userID]['xp'] > @levelxp[@leaderboard['members'][@userID]['level']] && @noXP == false) {
	#Level up
		@newlevel = @leaderboard['members'][@userID]['level'] + 1
		@leaderboard['members'][@userID]['level'] = @newlevel
		@rankmsg = '!'
		@ranknums = array_sort(array_keys(@config['LB_Role_Rewards']), 'NUMERIC')
		@oldrank = ''
		# New level matches a role reward:
		if(array_index_exists(@ranknums, @newlevel)) {
		# Find old rank, by picking the rank before matching
			foreach(@j: @evalrank in @ranknums) {
				if(@newlevel == @evalrank) {
					#new role reward rankup
					@oldrank = @ranknums[(@j - 1)]
					if(@oldrank < 0) { @oldrank = 0 }
					break()
				}
			}
			@userRoles = array_normalize(@userRoles)
			store_value('Chat.debug.Discord.User.'.@userID.'.old.roles', @userRoles)
			#key name value id
			
			#remove old role
			array_remove_values(@userRoles, @config['LB_Role_Rewards'][@oldrank]['RoleID'])
			#place new role
			array_push(@userRoles, @config['LB_Role_Rewards'][@newlevel]['RoleID'])
			#set
			try { 
				discord_member_set_roles(@userID, @userRoles)
			} catch(Exception @ex) {
				console('[Discord] User ID not found on server, are they a bot? '.@ex['message'], false)
				die()
			}
			@rankmsg = ', and is now a '.@config['LB_Role_Rewards'][@newlevel]['RoleName'].'!'
		}
		_send_discord_message('<@'.@userID.'> just leveled up to level '.@newlevel.@rankmsg, 'discord', @discord['channel'])
	}

@leaderboard['lastedit'] = time()
export('server.Discord.members.leaderboard', @leaderboard)
}