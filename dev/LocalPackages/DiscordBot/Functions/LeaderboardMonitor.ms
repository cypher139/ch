#version 1.0-tmc

#todo: add commands:
/* 
give/remove xp, rank
*/

export('DiscordBot.Leaderboard', get_value('DiscordBot.Leaderboard'));
export('DiscordBot.Leaderboard.last.save', time());
if(!is_array(import('DiscordBot.Leaderboard'))) {
	export('DiscordBot.Leaderboard', array('lastedit': time(), 'members': array()))
}
# Every 10 minutes store changes to leaderboard in RAM to the database
# Also publishes json to logs. A webserver can pull from this for a online leaderboard display. (sold separately sry)
set_interval(600000, 100000, closure(){ _discordBot_lb_update_database() });
_discordBot_lb_levelXP();

# Data: userid, username, nickname, channel, channelid, channeltype, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'DiscordBot.monitor.Leaderboard', 'priority': 'MONITOR'), null, @discord) {
	@noXP = false
	@config = import('DiscordBot.config.Discord')
	@userID = @discord['userid']
	@levelxp = import('DiscordBot.Leaderboard.levelXP')
	# Do not count messages from Command spam channel or Channels marked as no XP earning.
	if(array_contains(@config['LB_NoXP_Channels'], @discord['channel'])) { @noXP = true }
	if(@discord['channel'] == @config['CMD_Default_Channel']) { @noXP = true }
	@leaderboard = import('DiscordBot.Leaderboard', get_value('DiscordBot.Leaderboard'));
	@xptimer = import('DiscordBot.Leaderboard.xptimer', array('test': 123))
	if(!array_index_exists(@xptimer, @userID)) {
		array_set(@xptimer, @userID, (time() - 70000))
	}
	#Setup list of server members for reference in mentions
	_discordBot_dc_add_member(@discord);
	
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
			die()
		}
		foreach(@role in @userRoles) {
			if(array_contains(@config['LB_NoXP_RoleID'], @role)) {
				@noXP = true
				break()
			}
		}
	}
# Increment Message count and XP
	@leaderboard['members'][@userID]['msg_count'] = @leaderboard['members'][@userID]['msg_count'] + 1
	@leaderboard['members'][@userID]['last_msg'] = time()
	if(@noXP == false) {
		@newxp = rand(@config['LB_XP_Per_Message'][0], @config['LB_XP_Per_Message'][1])
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
		die()
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
		@ranknums = array_sort(array_keys(@config['LB_Role_Rewards']), 'NUMERIC')
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
				@currentrank = @config['LB_Role_Rewards'][@rank]
				@newrankname = @config['LB_Role_Rewards'][@rank]['RoleName']
				@rankup = true
				break()
			}
			#In Between two ranks
			if(@newlevel < @rank && @newlevel > @lastrank) {
				#No level ups yet
				if(@lastrank == 0) { 
					break()
				} else {
					@currentrank = @config['LB_Role_Rewards'][@lastrank]
					break()
				}
			}
			#Has highest rank
			if(array_size(@ranknums) - 1 == @i && @newlevel > @rank) {
				@currentrank = @config['LB_Role_Rewards'][@rank]
				break()
			}
		}
		@userRoles = array_normalize(@userRoles)
		@saveoldroles = import('DiscordBot.debug.roles.Leaderboard.undo', get_value('DiscordBot.debug.roles.Leaderboard.undo'))
		if(!is_array(@saveoldroles)) { @saveoldroles = array() }
		array_set(@saveoldroles, @discord['userid'], @userRoles)
		export('DiscordBot.debug.roles.Leaderboard.undo', @saveoldroles)
		
	# Remove old role rewards
		if(@config['LB_Stack_Role_Rewards'] == false) {
			foreach(@role in @config['LB_Role_Rewards']) {
				array_remove_values(@userRoles, @role['RoleID'])
			}
		}
	# Place and Set new role
		# console(@currentrank)
		if(@currentrank != '') {
			array_push(@userRoles, @currentrank['RoleID'])
			#Set New roles
			try { 
				discord_member_set_roles(@userID, @userRoles)
			} catch(Exception @ex) {
				die()
			}
		}
/*
		console(@currentrank)
		console(@oldroles)
		console(@userRoles)		
*/		

# Message out
		@discordMsg = reg_replace('%UserID%', '<@'.@userID.'>', @config['LB_Level_Up_Message'])
		if(@newrankname == '') {
			@discordMsg = reg_replace('%Level%', 'Level '.@leaderboard['members'][@userID]['level'].'!', @discordMsg)
		} else {
			@discordMsg = reg_replace('%Level%', @newrankname.'!  ('.@leaderboard['members'][@userID]['level'].')', @discordMsg)
		}
		console('[Discord] Level Up: '.@discord['username'].' <@'.@userID.'> '.color(3).@oldlevel.color('r').' -> '.color(10).@leaderboard['members'][@userID]['level'].' '.color(6).@newrankname, false)
		@sendMsg = true
		@sendMsgtoLog = false
		if(@config['LB_Level_Up_Announce_OnlyReward'] == true) {
			if(@rankup != true) {
				@sendMsg = false
			}
		} 
		if(@newlevel < @config['LB_Level_Up_Announce_Start'] || @newlevel > @config['LB_Level_Up_Announce_End']) {
			@sendMsgtoLog = true
		}
		if(@config['LB_Level_Up_Announce'] == false) {
			@sendMsg = false
		}
		if(@sendMsg == true) {
			@type = 'broadcast'
			@sendchannel = @discord['channel']
			switch(string(@config['LB_Level_Up_Announce'])) {
			case 'log':
				@sendchannel = @config['Log_Channel'] 
			case 'dm':
				@type = 'dm'
				@sendchannel = @discord['userid']
			}
			if(@sendMsgtoLog == true) { @sendchannel = @config['Log_Channel'] @type = 'broadcast' }
			_send_discord_message(@discordMsg, 'confirm', @sendchannel, @type)
		}
	}
#Save edits
	@leaderboard['lastedit'] = time()
	export('DiscordBot.Leaderboard', @leaderboard)
	export('DiscordBot.Leaderboard.xptimer', @xptimer)
}