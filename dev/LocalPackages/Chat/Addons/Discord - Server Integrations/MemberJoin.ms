#version 1.0-tmc
#requires CHDiscord build #70 or higher

#Welcome DM and Message for new Discord Server Members
bind('discord_member_joined', array('id': 'Discord.Server.monitor.User.join'), null, @event) {
	@config = import('Chat.config.Discord')
	if(@config['Welcome_Text_Channel_Name'] == '' || @config['Welcome_Text_Channel_ID'] == '') { die() }
#Wait a few seconds to avoid mention spam right at first.	
	set_timeout(5000, closure(){ 
		try {
			@currentroles = discord_member_get_roles(@event['userid'])
		} catch (NotFoundException @ex) {
	#Assume user was insta-kick (such as account age does not meet server req.)
			console('[Chat - Discord] New Join '.@event['username'].' <@'.@event['userid'].'> was not found on server. Were they insta-kicked??', false)
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
				console('[Chat - Discord] Cannot message '.@event['username'].' <@'.@event['userid'].'>, are they a bot?', false)
			}
		}
# If new member: Add Delineator roles, or roles new users need to have to access server
# If previous member: Restore old roles.
		@membersroles = get_value('server.Discord.members.roles')   
		if(!is_array(@membersroles)) { @membersroles = array() }
		if(array_index_exists(@membersroles, @event['userid']) && @config['Welcome_Roles_Restore'] == true) {
			array_push_all(@currentroles, @membersroles[@event['userid']])
			discord_member_set_roles(@event['userid'], @currentroles)
			console('[Chat - Discord] '.color(2).'Previous roles restored.', false)
		} else {
			if(is_array(@config['Welcome_Roles'])) {
				array_push_all(@currentroles, @config['Welcome_Roles'])
				discord_member_set_roles(@event['userid'], @currentroles)
			}
		}
#Welcome User Messages
		@welcomeMsg = reg_replace('%UserID%', '<@'.@event['userid'].'>', @config['Welcome_Message'])
		discord_broadcast(@config['Welcome_Text_Channel_Name'], array('content': @welcomeMsg), closure(@ex){
			@msgids = get_value('server.Discord.Welcome.msg.IDs')
			if(!is_array(@msgids)) { @msgids = array() }
			array_set(@msgids, @event['userid'], array('time': time(), 'id': @ex))
			store_value('server.Discord.Welcome.msg.IDs', @msgids)
		});	
#Console Log
		if(@event['username'] == @event['nickname']) {
			@userDisplay = @event['username'].' <@'.@event['userid'].'>'
		} else {
			@userDisplay = @event['nickname'].' ('.@event['username'].') <@'.@event['userid'].'>'
		}
		console('[Discord] Member '.color(10).'joined: '.color(9).@userDisplay, false)
	});
}

bind('discord_member_left', array('id': 'Discord.Server.monitor.User.leave'), null, @event) {
	if(@event['username'] == @event['nickname']) {
		@userDisplay = @event['username'].' <@'.@event['userid'].'>'
	} else {
		@userDisplay = @event['nickname'].' ('.@event['username'].') <@'.@event['userid'].'>'
	}
	console('[Discord] Member '.color(12).'left: '.color(9).@userDisplay, false)
	@config = import('Chat.config.Discord')
	if(!is_array(@config['Welcome_Roles'])) { die('plz fill welcome roles config') }

	# Remove user entry from internal storages
	@membernames = import('server.Discord.members.names')
	if(is_array(@membernames)) { 
		if(array_contains(array_keys(@membernames), @event['username'])) {
			array_remove(@membernames, @event['username'])
			store_value('server.Discord.members.names', @membernames)
			export('server.Discord.members.names', @membernames)
		}
	}
	@memberIDs = import('server.Discord.members.ID')
	if(is_array(@memberIDs)) { 
		if(array_contains(@memberIDs, @event['userid'])) {
			array_remove_values(@memberIDs, @event['userid'])
			store_value('server.Discord.members.ID', @memberIDs)
			export('server.Discord.members.ID', @memberIDs)
		}
	}
	
	# Remove Welcome message
	@msgids = get_value('server.Discord.Welcome.msg.IDs')
	if(!is_array(@msgids)) { @msgids = array() }
	if(array_contains(array_keys(@msgids), @event['userid'])) {
		if(time() < (@msgids[@event['userid']]['time'] + @config['Welcome_Message_Timeout'])) { 
			try { 
				discord_delete_message(@config['Welcome_Text_Channel_Name'], @msgids[@event['userid']]['id'])
				console('[Discord] New joiner! Welcome message removed.', false)
			} catch(Exception @ex) {
				console('[Discord] Unable to remove Welcome Message!'.@ex, false)
			}
			array_remove(@msgids, @event['userid'])
			store_value('server.Discord.Welcome.msg.IDs', @msgids)
		}
	}
}