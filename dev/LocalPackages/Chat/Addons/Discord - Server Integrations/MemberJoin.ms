#version 1.0-tmc
#requires CHDiscord build #70 or higher

# Load Configs
@5ft2vkb = ''
try {
	@5ft2vkb = yml_decode(read(import('Chat.config.dir').'/Discord_Member_config.yml'))
} catch(IOException @ex) {
	_msgAdmins('[Chat - Discord] Member Config file could not be read. '.@ex['message'])
	die()
} catch(FormatException @ex) {
	_msgAdmins('[Chat - Discord] Member Config file is improperly formatted.') 
	die()
}
if(@5ft2vkb['Welcome_Text_Channel_Name'] == 'default') {
	_msgAdmins('[Chat - Discord] Member Config file is still using defaults. Please configure it in order to use the welcome message feature.') 
	die()
}
export('Chat.config.Discord.Member', @5ft2vkb)

#Welcome DM and Message for new Discord Server Members
bind('discord_member_joined', array('id': 'Discord.Server.userjoin'), null, @event) {
	@config = import('Chat.config.Discord.Member')
	if(@config['Welcome_Text_Channel_Name'] == '' || @config['Welcome_Text_Channel_ID'] == '') { die() }

#Wait a few seconds to avoid mention spam right at first.	
	set_timeout(5000, closure(){ 
		try {
			@currentroles = discord_member_get_roles(@event['userid'])
		} catch (NotFoundException @ex) {
	#Assume user was insta-kick (such as account age does not meet server req.)
			console('New Join '.@event['username'].' "'.@event['userid'].'" was not found on server. Were they insta-kicked??', false)
			die()
		}
#Welcome User DM
		if(@config['Send_Welcome_DM'] == true) {
			@welcomeDMMsg = reg_replace('%WelcomeChannel%', '<#'.@config['Welcome_Text_Channel_ID'].'>', @config['Welcome_DM_Message'])
			try {
				discord_private_message(@event['userid'], @welcomeDMMsg)
			} catch(Exception @ex) {
				console('Cannot message '.@event['username'].' "'.@event['userid'].'", are they a bot?', false)
			}
		}
#Add Delineator roles, or roles new users need to have to access server
			# console(@config['Welcome_Roles'])
			if(is_array(@config['Welcome_Roles'])) {
				array_push_all(@currentroles, @config['Welcome_Roles'])
				discord_member_set_roles(@event['userid'], @currentroles)
			} else {
				console('Welcome roles not configured', false)
			}
#Welcome User Messages
		@welcomeMsg = reg_replace('%UserID%', '<@'.@event['userid'].'>', @config['Welcome_Message'])
		discord_broadcast(@config['Welcome_Text_Channel_Name'], array('content': @welcomeMsg), closure(@ex){
			@msgids = get_value('server.Discord.Welcome.msg.IDs')
			if(!is_array(@msgids)) { @msgids = array() }
			array_set(@msgids, @event['userid'], array('time': time(), 'id': @ex))
			store_value('server.Discord.Welcome.msg.IDs', @msgids)
		});	
	});
}

bind('discord_member_left', array('id': 'Discord.Server.userleft'), null, @event) {
	@config = import('Chat.config.Discord.Member')
	console(@event)
	# @config['Welcome_Message_Timeout']
	@msgids = get_value('server.Discord.Welcome.msg.IDs')
	if(!is_array(@msgids)) { @msgids = array() }
	if(array_contains(array_keys(@msgids), @event['userid'])) {
		if(time() < (@msgids[@event['userid']]['time'] + @config['Welcome_Message_Timeout'])) { 
			discord_delete_message('general', @msgids[@event['userid']]['id'])
			array_remove(@msgids, @event['userid'])
			store_value('server.Discord.Welcome.msg.IDs', @msgids)
		}
	}
}