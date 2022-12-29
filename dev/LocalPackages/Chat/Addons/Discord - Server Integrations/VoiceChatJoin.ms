#version 1.0-tmc
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
@e17qyi1 = ''
try {
	@e17qyi1 = yml_decode(read(import('Chat.config.dir').'/Discord_VC_config.yml'))
} catch(IOException @ex) {
	_msgAdmins('[Chat - Discord] VC Config file could not be read. '.@ex['message'])
	die()
} catch(FormatException @ex) {
	_msgAdmins('[Chat - Discord] VC Config file is improperly formatted.') 
	die()
}
if(@e17qyi1['VC_Role_ID'] == 123) {
	_msgAdmins('[Chat - Discord] VC Config file is still using defaults. Please configure it in order to use the VC Role Ping feature.') 
	die()
}
export('Chat.config.Discord.VC', @e17qyi1)


bind('discord_voice_joined', array('id': 'Discord.Server.monitor.VCjoin'), null, @discord) {
# Data: userid, username, nickname, channel (name)
# Note: import is auto globally saved (example #2), so use new variables to store edits needed
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
			@discordMsg = reg_replace('%RoleID%', '<@&'.@VCconfig['VC_Role_ID'].'>', @VCconfig['VC_Ping_Message'])
			@discordMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @VCconfig['VC_Ping_Message'])
			@discordMsg = reg_replace('%Channel%', @discord['channel'], @VCconfig['VC_Ping_Message'])
			@mcMsg = reg_replace('%User%', @discord['username'], @VCconfig['VC_Ping_Message_MC'])
			@mcMsg = reg_replace('%Channel%', @discord['channel'], @VCconfig['VC_Ping_Message_MC'])
	# :angrypingemoji: 1 ping every 12 hours only!
			if(time() > (@lastping + @VCconfig['VC_Ping_Timeout'])) {
				export('server.Discord.VC.ping.in.progress', true)
			#If user is still in specific channel after 60 seconds (avoid ping on accidental connects)
				set_timeout(@timeout, closure(){
					if(discord_member_get_voice_channel(@discord['userid']) == @VCconfig['VC_Channel_ID']) {
	#						console('still here')
						#Has the role just been mentioned?
						@lastmsgs = import('Chat.Discord.last.message')
						if(is_array(@lastmsgs)) {
							foreach(@index: @message in @lastmsgs) {
								if(reg_count('@'.@VCconfig['VC_Role_Name'], @message['message']) > 0) {
									@discordMsg = 'Hey I was going to do that ping!'
								}
							}
						}					
		#				discord_broadcast(@VCconfig['VC_Text_Channel_Name'], array('content': @discordMsg))
		console(@discordMsg)
						broadcast(@mcMsg, all_players())
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