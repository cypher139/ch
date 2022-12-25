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

#Voice Chat monitor:
/*
If:
 -- User has joined the monitored Voice Channel
 -- User has the specified "Voice Chat" ping role
 -- After 60 seconds User is still in voice channel
 -- "Voice Chat" ping role has not been pinged by the bot in over 12 hours
Then this will send a message to the ping role to come join voice chat
*/

# Load Voice Chat Configs
@vcconfig = ''
try {
	@vcconfig = yml_decode(read(import('Chat.config.dir').'/Discord_VC_config.yml'))
} catch(IOException @ex) {
	_msgAdmins('[Chat - Discord] VC Config file could not be read. '.@ex['message'])
	die()
} catch(FormatException @ex) {
	_msgAdmins('[Chat - Discord] VC Config file is improperly formatted.') 
	die()
}
if(@vcconfig['VC_Role_ID'] == 123) {
	_msgAdmins('[Chat - Discord] VC Config file is still using defaults. Please configure it in order to use the VC Role Ping feature.') 
	die()
}
export('Chat.config.Discord.VC', @vcconfig)


bind('discord_voice_joined', array('id': 'Discord.Server.monitor.VCjoin'), null, @discord) {
# Data: userid, username, nickname, channel (name)
	@VCconfig = import('Chat.config.Discord.VC')
	if(@VCconfig['VC_Channel_ID'] == '' || @VCconfig['VC_Role_ID'] == '') { die() }

	#Discord User: Must have VC role
	@userroles = discord_member_get_roles(@discord['userid'])
	if(array_contains(@userroles, @VCconfig['VC_Role_ID']) && @discord['channel'] == @VCconfig['VC_Channel_Name']) {

	# Get last time the bot pinged the role
		@lastping = get_value('server.Discord.last.ping.'.@VCconfig['VC_Role_ID'])
		if(@lastping == '' || @lastping == null) { @lastping = 1230768000000 }
		if(import('server.Discord.VC.ping.in.progress') == true) { die() } else {
			@timeout = 60000
			@VCconfig['VC_Ping_Message'] = reg_replace('%RoleID%', '<@&'.@VCconfig['VC_Role_ID'].'>', @VCconfig['VC_Ping_Message'])
			@VCconfig['VC_Ping_Message'] = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @VCconfig['VC_Ping_Message'])
			@VCconfig['VC_Ping_Message'] = reg_replace('%Channel%', @discord['channel'], @VCconfig['VC_Ping_Message'])
			@VCconfig['VC_Ping_Message_MC'] = reg_replace('%User%', @discord['username'], @VCconfig['VC_Ping_Message_MC'])
			@VCconfig['VC_Ping_Message_MC'] = reg_replace('%Channel%', @discord['channel'], @VCconfig['VC_Ping_Message_MC'])
	# :angrypingemoji: 1 ping every 12 hours only!
			if(time() > (@lastping + @VCconfig['VC_Ping_Timeout'])) {
				export('server.Discord.VC.ping.in.progress', true)
			#If user is still in specific channel after 60 seconds (avoid ping on accidental connects)
				set_timeout(@timeout, closure(){
					if(discord_member_get_voice_channel(@discord['userid']) == @VCconfig['VC_Channel_ID']) {
	#						console('still here')
						#Has the role just been mentioned?
						if(is_array(@lastmsgs)) {
						@lastmsgs = import('Chat.Discord.last.message')
							foreach(@index: @message in @lastmsgs) {
								if(reg_count('@'.@VCconfig['VC_Role_Name'], @message['message']) > 0) {
									@VCconfig['VC_Ping_Message'] = 'Hey I was going to do that ping!'
								}
							}
						}					
						discord_broadcast(@VCconfig['VC_Text_Channel_Name'], array('content': @VCconfig['VC_Ping_Message']))
						broadcast(@VCconfig['VC_Ping_Message_MC'], all_players())
						store_value('server.Discord.last.ping.'.@VCconfig['VC_Role_ID'], time())
					}
				});
				set_timeout((@timeout + 10000), closure(){
					export('server.Discord.VC.ping.in.progress', false)
				});
			}
# time test			} else {console('nope')}
		}
	}
}