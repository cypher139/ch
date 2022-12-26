#version 1.0-tmc

#Welcome DM and Message for new Discord Server Members
bind('discord_member_joined', array('id': 'Discord.Server.userjoin'), null, @event) {
	@welcomeDM = get_value('server.Discord.Welcome.DM')
	@welcomemsg = get_value('server.Discord.Welcome.msg')
	if(@welcomemsg == '' || @welcomemsg == null) { @welcomemsg = ' to our Discord Server!' }

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
		if(@welcomeDM != '') { try(discord_private_message(@event['userid'], associative_array('content': @welcomeDM)),@fail, console('Cannot message '.@event['username'].' "'.@event['userid'].'", are they a bot?', false)) }
#Add Delineator roles, or roles new users need to have to access server
		if(has_value('server.Discord.Welcome.roles')) {
			@welcomeroles = get_value('server.Discord.Welcome.roles')
			#console(@currentroles)
			if(is_array(@welcomeroles)) {
				array_push_all(@currentroles, @welcomeroles)
				discord_member_set_roles(@event['userid'], @currentroles)
			} else {
				console('Welcome roles array not configured', false)
			}
		}
#Welcome User Messages
		discord_broadcast('general', associative_array('content': 'Welcome <@'.@event['userid'].'> '.@welcomemsg))
	})
}