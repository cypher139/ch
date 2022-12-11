#version 1.0-tmc

#Welcome DM and Message for new Discord Server Members
bind('discord_member_joined', array('id': 'Discord.Server.userjoin'), null, @event) {
	@welcomeDM = get_value('server.Discord.Welcome.DM')
	@welcomemsg = get_value('server.Discord.Welcome.msg')
	if(@welcomemsg == '' || @welcomemsg == null) { @welcomemsg = ' to our Discord Server!' }
#Welcome User DM
	if(@welcomeDM != '') { discord_private_message(@event['userid'], associative_array('content': @welcomeDM)) }
#Wait 20 seconds to avoid mention spam right at first.	
	set_timeout(20000, closure(){ 
#Get current roles, add a couple delineator roles?
		@currentroles = discord_member_get_roles(@event['userid'])
		@welcomeroles = get_value('server.Discord.Welcome.roles')
		#console(@currentroles)
		if(!is_array(@currentroles)) { @currentroles = array() }
		if(is_array(@welcomeroles)) {
			array_push_all(@currentroles, @welcomeroles)
		}

		discord_member_set_roles(@event['userid'], @currentroles)
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
bind('discord_voice_joined', array('id': 'Discord.Server.monitor.VCjoin'), null, @discord) {
# Data: userid, username, nickname, channel (name)
# -- after 60 seconds if user still in channel, and their roles have vc, and vc role not pinged by ch in over 24 hours, and in general, ping vc
	@ChannelID = get_value('server.Discord.VC.channel')
	@VCRoleID = get_value('server.Discord.VC.role')
	if(@ChannelID == '' || @VCRoleID == '') { die() }

	#Discord User: Must have VC role
	@userroles = discord_member_get_roles(@discord['userid'])
	if(array_contains(@userroles, @VCRoleID)) {

	# get last ping time
		@lastping = get_value('server.Discord.last.ping.'.@VCRoleID)
		if(@lastping == '' || @lastping == null) { 
			@lastping = time() - 864123456
			store_value('server.Discord.last.ping.'.@VCRoleID, time())
		}
	# :angrypingemoji: 1 ping every 12 hours only!
		if(time() > (@lastping + 43200000)) {
		#If user is still in specific channel after 60 seconds (avoid ping on accidental connects)
		set_timeout(60000, closure(){
			if(discord_member_get_voice_channel(@discord['userid']) == @ChannelID) {
	#			console('still here')
				discord_broadcast('voice-chat', array('content': '<@&'.@VCRoleID.'> <@'.@discord['userid'].'> is ready to voice chat in the General channel! Come join for another fun time talking with your fellow members!'))
				broadcast(all_players(), @discord['username'].' is ready to voice chat in the General voice chat channel! If you are on the Discord, Come join for another fun time talking with your fellow members!')
				store_value('server.Discord.last.ping.'.@VCRoleID, time())
			}
		})
		}
	}
}