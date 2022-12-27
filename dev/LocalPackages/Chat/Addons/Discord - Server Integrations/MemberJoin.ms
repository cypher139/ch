#version 1.0-tmc
#requires CHDiscord build #70 or higher

# Load Configs
@config = ''
try {
	@config = yml_decode(read(import('Chat.config.dir').'/Discord_Member_config.yml'))
} catch(IOException @ex) {
	_msgAdmins('[Chat - Discord] Member Config file could not be read. '.@ex['message'])
	die()
} catch(FormatException @ex) {
	_msgAdmins('[Chat - Discord] Member Config file is improperly formatted.') 
	die()
}
if(@config['Welcome_Text_Channel_Name'] == 'default') {
	_msgAdmins('[Chat - Discord] Member Config file is still using defaults. Please configure it in order to use the welcome message feature.') 
	die()
}
export('Chat.config.Discord.Member', @config)

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
			@config['Welcome_DM_Message'] = reg_replace('%WelcomeChannel%', '<#'.@config['Welcome_Text_Channel_ID'].'>', @config['Welcome_DM_Message'])
			try {
				discord_private_message(@event['userid'], @config['Welcome_DM_Message'])
			} catch(Exception @ex) {
				console('Cannot message '.@event['username'].' "'.@event['userid'].'", are they a bot?', false)
			}
		}
#Add Delineator roles, or roles new users need to have to access server
		if(has_value('server.Discord.Welcome.roles')) {
			@welcomeroles = get_value('server.Discord.Welcome.roles')
			console(@config['Welcome_Roles'])
			if(is_array(@welcomeroles)) {
				array_push_all(@currentroles, @welcomeroles)
				discord_member_set_roles(@event['userid'], @currentroles)
			} else {
				console('Welcome roles not configured', false)
			}
		}
#Welcome User Messages
		@config['Welcome_Message'] = reg_replace('%UserID%', '<@'.@event['userid'].'>', @config['Welcome_Message'])
		discord_broadcast(@config['Welcome_Text_Channel_Name'], array('content': @config['Welcome_Message']), closure(@ex){
			@welcomemsgs = get_value('server.Discord.Welcome.msg.IDs')
			if(!is_array(@welcomemsgs)) { @welcomemsgs = array() }
			array_set(@welcomemsgs, @event['userid'], array('time': time(), 'id': @ex))
			store_value('server.Discord.Welcome.msg.IDs', @welcomemsgs)
		});	
	});
}

bind('discord_member_left', array('id': 'Discord.Server.userleft'), null, @event) {
	@config = import('Chat.config.Discord.Member')
	console(@event)
	@config['Welcome_Message_Timeout']
	@welcomemsgs = get_value('server.Discord.Welcome.msg.IDs')
	if(!is_array(@welcomemsgs)) { @welcomemsgs = array() }
	if(array_contains(array_keys(@welcomemsgs), @event['userid'])) {
		if(time() < (@welcomemsgs[@event['userid']]['time'] + @config['Welcome_Message_Timeout'])) { 
			discord_delete_message('general', @welcomemsgs[@event['userid']]['id'])
			array_remove(@welcomemsgs, @event['userid'])
			store_value('server.Discord.Welcome.msg.IDs', @welcomemsgs)
		}
	}
}