#version 1.1-tmc
# Requires CHDiscord build #81 or higher 
# - 70 - message callback, 81 - set role reason

#Welcome DM and Message for new Discord Server Members
bind('discord_member_joined', array('id': 'DiscordBot.User.join'), null, @discord) {
	array_set(@discord, 'guild', import('DiscordBot.server.ID'))
	if(!array_contains(import('DiscordBot.Guilds'), @discord['guild'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['guild'])
# Restore leaderboard entry	
	@leaderboard = import('DiscordBot.'.@discord['guild'].'.Leaderboard')
	@oldlb = get_value('DiscordBot.'.@discord['guild'].'.members.former.leaderboard')
	if(is_array(@leaderboard) && is_array(@oldlb)) {
		if(array_index_exists(@oldlb, @discord['userid'])) {
			array_set(@leaderboard['members'], @discord['userid'], @oldlb[@discord['userid']])
			array_remove(@leaderboard['members'][@discord['userid']], 'removed')
			@leaderboard['lastedit'] = time()
			export('DiscordBot.'.@discord['guild'].'.Leaderboard', @leaderboard)
		}
	}
#Wait a few seconds to avoid mention spam right at first.	
	set_timeout(5000, closure(){ 
		@currentroles = array()
		try {
			@currentroles = discord_member_get_roles(@discord['userid'])
		} catch (NotFoundException @ex) {
	#Assume user was insta-kick (such as account age does not meet server req.)
			console('[Discord] New Join '.@discord['username'].' <@'.@discord['userid'].'> was not found on server. Were they insta-kicked??', false)
			die()
		} catch (Exception @ex) {
			console(@ex)
			die()
		}
#Setup list of server members for reference in mentions
		_discordBot_dc_add_member(@discord);
#Welcome User DM
		if(@config['Welcome_Send_DM'] == true) {
			@welcomeDMMsg = reg_replace('%WelcomeChannel%', '<#'.@config['Welcome_Text_Channel_ID'].'>', @config['Welcome_DM_Message'])
			try {
				discord_private_message(@discord['userid'], @welcomeDMMsg)
			} catch(Exception @ex) {
				console('[Discord] Cannot message '.@discord['username'].' <@'.@discord['userid'].'>, are they a bot?', false)
			}
		}
# If new member: Add Delineator roles, or roles new users need to have to access server
# If previous member: Restore old roles.
		@membersFR = get_value('DiscordBot.'.@discord['guild'].'.members.former.roles')   
		if(!is_array(@membersFR)) { @membersFR = array() }
		if(array_index_exists(@membersFR, @discord['userid']) && @config['Welcome_Roles_Restore'] == true) {
			array_push_all(@currentroles, @membersFR[@discord['userid']])
			discord_member_set_roles(@discord['userid'], @currentroles, 'Previous Member Roles Restored')
			console('[Discord] '.color(2).'Previous roles restored.', false)
		} else {
			if(is_array(@config['Welcome_Roles'])) {
				array_push_all(@currentroles, @config['Welcome_Roles'])
				discord_member_set_roles(@discord['userid'], @currentroles, 'Add Welcome Roles')
			}
		}
#Welcome User Messages
		@welcomeMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @config['Welcome_Message'])
		discord_broadcast(@config['Welcome_Text_Channel_Name'], array('content': @welcomeMsg), closure(@ex){
			@msgids = get_value('DiscordBot.'.@discord['guild'].'.Welcome.msg.IDs')
			if(!is_array(@msgids)) { @msgids = array() }
			array_set(@msgids, @discord['userid'], array('time': time(), 'id': @ex, 'user': @discord['username']))
			store_value('DiscordBot.'.@discord['guild'].'.Welcome.msg.IDs', @msgids)
		});	
#Console Log
		@userDisplay = ''
		if(@discord['username'] == @discord['nickname']) {
			@userDisplay = @discord['username'].' <@'.@discord['userid'].'>'
		} else {
			@userDisplay = @discord['nickname'].' ('.@discord['username'].') <@'.@discord['userid'].'>'
		}
		console('[Discord] Member '.color(10).'joined: '.color(9).@userDisplay, false)
	});
}

bind('discord_member_left', array('id': 'DiscordBot.User.leave'), null, @discord) {
	array_set(@discord, 'guild', import('DiscordBot.server.ID'))
	if(!array_contains(import('DiscordBot.Guilds'), @discord['guild'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['guild'])
	@lbremove = 0
	@userDisplay = ''
	if(@discord['username'] == @discord['nickname']) {
		@userDisplay = @discord['username'].' <@'.@discord['userid'].'>'
	} else {
		@userDisplay = @discord['nickname'].' ('.@discord['username'].') <@'.@discord['userid'].'>'
	}
	console('[Discord] Member '.color(12).'left: '.color(9).@userDisplay, false)

	# Remove user entry from internal storages
	@membersRoles = get_value('DiscordBot.'.@discord['guild'].'.members.roles')
	if(!is_array(@membersRoles)) { @membersRoles = array() }
	@membersFR = get_value('DiscordBot.'.@discord['guild'].'.members.former.roles')
	if(!is_array(@membersFR)) { @membersFR = array() }
	if(array_contains(array_keys(@membersRoles), @discord['userid'])) {
		array_set(@membersFR, @discord['userid'], array('removed': time(), 'data': @membersRoles[@discord['userid']]))
		array_remove(@membersRoles, @discord['userid'])
		store_value('DiscordBot.'.@discord['guild'].'.members.roles', @membersRoles)
	}
	
	@membersNames = import('DiscordBot.'.@discord['guild'].'.members.names')
	if(is_array(@membersNames)) { 
		if(array_contains(array_keys(@membersNames), @discord['username'])) {
			array_remove(@membersNames, @discord['username'])
			store_value('DiscordBot.'.@discord['guild'].'.members.names', @membersNames)
			export('DiscordBot.'.@discord['guild'].'.members.names', @membersNames)
		}
	}
	@membersID = import('DiscordBot.'.@discord['guild'].'.members.ID')
	if(is_array(@membersID)) { 
		if(array_contains(@membersID, @discord['userid'])) {
			array_remove_values(@membersID, @discord['userid'])
			store_value('DiscordBot.'.@discord['guild'].'.members.ID', @membersID)
			export('DiscordBot.'.@discord['guild'].'.members.ID', @membersID)
		}
	}
	@leaderboard = import('DiscordBot.'.@discord['guild'].'.Leaderboard')
	if(is_array(@leaderboard)) {
		if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { 
			if(@config['LB_Options']['Remove_On_Leave'] == true) { @lbremove = 1 }
			if(@leaderboard['members'][@discord['userid']]['level'] < 6) { @lbremove = 1 }		
		}
	}
	
	# Remove Welcome message
	@msgids = get_value('DiscordBot.'.@discord['guild'].'.Welcome.msg.IDs')
	@rmmsgids = 0
	if(!is_array(@msgids)) { @msgids = array() }
	if(array_contains(array_keys(@msgids), @discord['userid'])) {
		if(time() < (@msgids[@discord['userid']]['time'] + @config['Welcome_Message_Timeout'])) { 
			# Remove leaderboard entry too
			if(is_array(@leaderboard)) {
				if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { @lbremove = 2 }
			}
			# Remove Welcome message
			try { 
				discord_delete_message(@config['Welcome_Text_Channel_Name'], @msgids[@discord['userid']]['id'])
				console('[Discord] New joiner! Welcome message removed.', false)
			} catch(Exception @ex) {
				console('[Discord] Unable to remove Welcome Message! '.color('c').@ex['classType'].': '.@ex['message'], false)
			}
			array_remove(@msgids, @discord['userid'])
			@rmmsgids++
		} else {
			#Also, only write former roles if not new member
			store_value('DiscordBot.'.@discord['guild'].'.members.former.roles', @membersFR)
		}
		#Database Maintenance: 
		foreach(@k: @v in @msgids) {
			if(time() > (@v['time'] + 1209600000)) {
			# Join Date is past 2 weeks message removal limits, remove msgids and archive join time
				@rmmsgids++
				@user = ''
				if(array_index_exists(@v, 'user')) { @user = ','.@v['user'] }
				_write_file(import('DiscordBot.logs.dir').'/'.@discord['guild'].'/Archived-Join-Dates.csv', @v['time'].','.@k.@user.'\n', 'Append')
				array_remove(@msgids, @k)
			}
		}
		if(@rmmsgids != 0) { store_value('DiscordBot.'.@discord['guild'].'.Welcome.msg.IDs', @msgids) }
	}
	
	if(@lbremove != 0) { 
		if(@lbremove != 2) {
			@oldlb = get_value('DiscordBot.'.@discord['guild'].'.members.former.leaderboard')
			if(!is_array(@oldlb)) { @oldlb = array() }
			array_set(@oldlb, @discord['userid'], @leaderboard['members'][@discord['userid']])
			array_set(@oldlb[@discord['userid']], 'removed', time())
			store_value('DiscordBot.'.@discord['guild'].'.members.former.leaderboard', @oldlb)
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['guild'].'/Leaderboard_Removed.json', json_encode(@oldlb), 'Overwrite')
		}
		array_remove(@leaderboard['members'], @discord['userid'])
		@leaderboard['lastedit'] = time()
		export('DiscordBot.'.@discord['guild'].'.Leaderboard', @leaderboard)
	}
}