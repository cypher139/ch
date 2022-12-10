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


bind('discord_private_message_received', array('id': 'Discord.Server.monitor.DMs'), null, @discord) {
#Save recent DMs for future reference if needed
	@DMs = get_value('server.Discord.DMs.received')
	if(!is_array(@DMs)) { @DMs = array(array('message': 'initialized DM Array')) }
	array_set(@discord, 'time', time())
	array_insert(@DMs, @discord, 0)
	if(array_index_exists(@DMs, 20)) { array_remove(@DMs, 20) }
	store_value('server.Discord.DMs.received', @DMs)
#Message Display
	if(reg_count('^.+\\/\\/tenor\\.com\\/view', @discord['message']) > 0 && import('Chat.Discord.Broadcast.URLs') == false) {
		@discord['message'] = '<Sent a GIF>'
	}
	if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
		if(@discord['message'] == '') {			
			@discord['message'] = '<Sent a file> '
		} else {
			@discord['message'] = @discord['message'].'\n <Also attached file:> '
		}
		foreach(@num: @attach in @discord['attachments']) {
			if(@num == 0) { @filenum = 'File: ' } else { @filenum = '  File #'.(@num + 1).': ' }
			@discord['message'] = @discord['message'].@filenum.@attach['filename']
		}
	}
	broadcast(all_players(), color(9).'A DM was sent to the Discord Bot from ['.color(7).@discord['username'].color(9).'] Message: \n'.color(7).@discord['message'])
	console('A DM was sent to the Discord Bot from ['.@discord['username'].' ('.@discord['userid'].') ] Message: \n'.@discord['message'].'\n Attached: '.@discord['attachments'], false)

	if(array_index_exists(@discord, 'attachments', 0, 'filename') && import('Chat.Discord.Broadcast.URLs') == true) {
		foreach(@num: @attach in @discord['attachments']) {
			broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], all_players())
		}
	}
		

}


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