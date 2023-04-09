#version 1.0-tmc
#requires CHDiscord build #70 or higher

#Welcome DM and Message for new Discord Server Members
bind('discord_member_joined', array('id': 'DiscordBot.User.join'), null, @event) {
	@config = import('DiscordBot.config.Discord')
	if(@config['Welcome_Text_Channel_Name'] == '' || @config['Welcome_Text_Channel_ID'] == '') { die() }
# Restore leaderboard entry	
	@leaderboard = import('DiscordBot.Leaderboard')
	@oldlb = get_value('DiscordBot.members.leaderboard.removed')
	if(is_array(@leaderboard) && is_array(@oldlb)) {
		if(array_index_exists(@oldlb, @event['userid'])) {
			array_set(@leaderboard['members'], @event['userid'], @oldlb[@event['userid']]['data'])
			@leaderboard['lastedit'] = time()
			export('DiscordBot.Leaderboard', @leaderboard)
		}
	}
#Wait a few seconds to avoid mention spam right at first.	
	set_timeout(5000, closure(){ 
		@currentroles = array()
		try {
			@currentroles = discord_member_get_roles(@event['userid'])
		} catch (NotFoundException @ex) {
	#Assume user was insta-kick (such as account age does not meet server req.)
			console('[Discord] New Join '.@event['username'].' <@'.@event['userid'].'> was not found on server. Were they insta-kicked??', false)
			die()
		} catch (Exception @ex) {
			console(@ex)
			die()
		}
#Welcome User DM
		if(@config['Welcome_Send_DM'] == true) {
			@welcomeDMMsg = reg_replace('%WelcomeChannel%', '<#'.@config['Welcome_Text_Channel_ID'].'>', @config['Welcome_DM_Message'])
			try {
				discord_private_message(@event['userid'], @welcomeDMMsg)
			} catch(Exception @ex) {
				console('[Discord] Cannot message '.@event['username'].' <@'.@event['userid'].'>, are they a bot?', false)
			}
		}
# If new member: Add Delineator roles, or roles new users need to have to access server
# If previous member: Restore old roles.
		@membersroles = get_value('DiscordBot.members.roles')   
		if(!is_array(@membersroles)) { @membersroles = array() }
		if(array_index_exists(@membersroles, @event['userid']) && @config['Welcome_Roles_Restore'] == true) {
			array_push_all(@currentroles, @membersroles[@event['userid']])
			discord_member_set_roles(@event['userid'], @currentroles)
			console('[Discord] '.color(2).'Previous roles restored.', false)
		} else {
			if(is_array(@config['Welcome_Roles'])) {
				array_push_all(@currentroles, @config['Welcome_Roles'])
				discord_member_set_roles(@event['userid'], @currentroles)
			}
		}
#Welcome User Messages
		@welcomeMsg = reg_replace('%UserID%', '<@'.@event['userid'].'>', @config['Welcome_Message'])
		discord_broadcast(@config['Welcome_Text_Channel_Name'], array('content': @welcomeMsg), closure(@ex){
			@msgids = get_value('DiscordBot.Welcome.msg.IDs')
			if(!is_array(@msgids)) { @msgids = array() }
			array_set(@msgids, @event['userid'], array('time': time(), 'id': @ex))
			store_value('DiscordBot.Welcome.msg.IDs', @msgids)
		});	
#Console Log
		@userDisplay = ''
		if(@event['username'] == @event['nickname']) {
			@userDisplay = @event['username'].' <@'.@event['userid'].'>'
		} else {
			@userDisplay = @event['nickname'].' ('.@event['username'].') <@'.@event['userid'].'>'
		}
		console('[Discord] Member '.color(10).'joined: '.color(9).@userDisplay, false)
	});
}

bind('discord_member_left', array('id': 'DiscordBot.User.leave'), null, @event) {
	@lbremove = 0
	@userDisplay = ''
	if(@event['username'] == @event['nickname']) {
		@userDisplay = @event['username'].' <@'.@event['userid'].'>'
	} else {
		@userDisplay = @event['nickname'].' ('.@event['username'].') <@'.@event['userid'].'>'
	}
	console('[Discord] Member '.color(12).'left: '.color(9).@userDisplay, false)
	@config = import('DiscordBot.config.Discord')
	if(!is_array(@config['Welcome_Roles'])) { die('plz fill welcome roles config') }

	# Remove user entry from internal storages
	@membernames = import('DiscordBot.members.names')
	if(is_array(@membernames)) { 
		if(array_contains(array_keys(@membernames), @event['username'])) {
			array_remove(@membernames, @event['username'])
			store_value('DiscordBot.members.names', @membernames)
			export('DiscordBot.members.names', @membernames)
		}
	}
	@memberIDs = import('DiscordBot.members.ID')
	if(is_array(@memberIDs)) { 
		if(array_contains(@memberIDs, @event['userid'])) {
			array_remove_values(@memberIDs, @event['userid'])
			store_value('DiscordBot.members.ID', @memberIDs)
			export('DiscordBot.members.ID', @memberIDs)
		}
	}
	@leaderboard = import('DiscordBot.Leaderboard')
	if(is_array(@leaderboard)) {
		if(array_index_exists(@leaderboard, 'members', @event['userid'])) { 
			if(@config['LB_Remove_On_Leave'] == true) { @lbremove = 1 } else { @lbremove = 0 }
			if(@leaderboard['members'][@event['userid']]['level'] < 6) { @lbremove = 1 }			
		}
	}
	
	# Remove Welcome message
	@msgids = get_value('DiscordBot.Welcome.msg.IDs')
	if(!is_array(@msgids)) { @msgids = array() }
	if(array_contains(array_keys(@msgids), @event['userid'])) {
		if(time() < (@msgids[@event['userid']]['time'] + @config['Welcome_Message_Timeout'])) { 
			# Remove leaderboard entry too
			if(is_array(@leaderboard)) {
				if(array_index_exists(@leaderboard, 'members', @event['userid'])) { @lbremove = 2 }
			}
			# Remove Welcome message
			try { 
				discord_delete_message(@config['Welcome_Text_Channel_Name'], @msgids[@event['userid']]['id'])
				console('[Discord] New joiner! Welcome message removed.', false)
			} catch(Exception @ex) {
				console('[Discord] Unable to remove Welcome Message! '.color('c').@ex['classType'].': '.@ex['message'], false)
			}
			array_remove(@msgids, @event['userid'])
			store_value('DiscordBot.Welcome.msg.IDs', @msgids)
		}
	}
	
	if(@lbremove != 0) { 
		if(@lbremove != 2) {
			@oldlb = get_value('DiscordBot.members.leaderboard.removed')
			if(!is_array(@oldlb)) { @oldlb = array() }
			array_set(@oldlb, @event['userid'], array('removed': time(), 'data': @leaderboard['members'][@event['userid']]))
			store_value('DiscordBot.members.leaderboard.removed', @oldlb)
		}
		array_remove(@leaderboard['members'], @event['userid'])
		@leaderboard['lastedit'] = time()
		export('DiscordBot.Leaderboard', @leaderboard)
	}
	
}