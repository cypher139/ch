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


bind('discord_voice_joined', array('id': 'Discord.Server.monitor.VC.join'), null, @discord) {
# Data: userid, username, nickname, channel (name)
# Note: import is auto globally saved (example #2), so use new variables to store edits needed
	@VCconfig = import('Chat.config.Discord.VC')
	if(@VCconfig['VC_Channel_ID'] == '' || @VCconfig['VC_Role_ID'] == '') { die() }
	@userroles = discord_member_get_roles(@discord['userid'])
	@stats = get_value('Chat.Discord.VC.'.@discord['channel'].'.current.stats')
	if(!is_array(@stats)) { @stats = array('start': time(), 'end': '', 'users': '', 'channel': @discord['channel']) }
	
	
	#Ping @VC role to come join the main VC channel.
	if(array_contains(@userroles, @VCconfig['VC_Role_ID']) && @discord['channel'] == @VCconfig['VC_Channel_Name']) {
	# Get last time the bot pinged the role
		@lastping = get_value('server.Discord.last.ping.'.@VCconfig['VC_Role_ID'])
		if(@lastping == '' || @lastping == null) { @lastping = 1230768000000 }
		if(import('server.Discord.VC.ping.in.progress') == true) { die() } else {
			@timeout = 60000
			@discordMsg = reg_replace('%RoleID%', '<@&'.@VCconfig['VC_Role_ID'].'>', @VCconfig['VC_Ping_Message'])
			@discordMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @discordMsg)
			@discordMsg = reg_replace('%Channel%', @discord['channel'], @discordMsg)
			@mcMsg = reg_replace('%User%', @discord['username'], @VCconfig['VC_Ping_Message_MC'])
			@mcMsg = reg_replace('%Channel%', @discord['channel'], @mcMsg)
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
						discord_broadcast(@VCconfig['VC_Text_Channel_Name'], array('content': @discordMsg))
		console(@discordMsg)
						broadcast(@mcMsg, all_players())
						store_value('server.Discord.last.ping.'.@VCconfig['VC_Role_ID'], time())
						@stats = get_value('Chat.Discord.VC.'.@discord['channel'].'.current.stats')
						if(!is_array(@stats)) { @stats = array('start': time(), 'end': '', 'users': '', 'channel': @discord['channel']) }
						array_set(@stats, 'pinguser', @discord['username'])
						store_value('Chat.Discord.VC.'.@discord['channel'].'.current.stats', @stats)
					}
				});
				set_timeout((@timeout + 10000), closure(){
					export('server.Discord.VC.ping.in.progress', false)
				});
			}
		}
	}
	
	#Save current users in channel, only after 90 seconds so user is stayin
	set_timeout(90000, closure(){
		@currentVCUsers = get_value('Chat.Discord.VC.'.@discord['channel'].'.users.current')
		if(!is_array(@currentVCUsers)) { @currentVCUsers = array() }
		@totalVCUsers = get_value('Chat.Discord.VC.'.@discord['channel'].'.users.total')
		if(!is_array(@totalVCUsers)) { @totalVCUsers = array() }
		@stats = get_value('Chat.Discord.VC.'.@discord['channel'].'.current.stats')
		if(!is_array(@stats)) { 
			@stats = array('start': time(), 'end': '', 'users': '', 'channel': @discord['channel'])
			store_value('Chat.Discord.VC.'.@discord['channel'].'.current.stats', @stats)
		}
			
		if(!array_contains(@currentVCUsers, @discord['userid'])) { @currentVCUsers[] = @discord['userid'] }
		if(!array_contains(@totalVCUsers, @discord['userid'])) { array_set(@totalVCUsers, @discord['username'], @discord['userid']) }
		store_value('Chat.Discord.VC.'.@discord['channel'].'.users.current', @currentVCUsers)
		store_value('Chat.Discord.VC.'.@discord['channel'].'.users.total', @totalVCUsers)
	});
	
}


bind('discord_voice_left', array('id': 'Discord.Server.monitor.VC.leave'), null, @discord) {
# Data: userid, username, nickname, channel (name)
	@VCconfig = import('Chat.config.Discord.VC')
	if(@VCconfig['VC_Channel_ID'] == '' || @VCconfig['VC_Role_ID'] == '') { die() }
	@currentVCUsers = get_value('Chat.Discord.VC.'.@discord['channel'].'.users.current')
	if(!is_array(@currentVCUsers)) { @currentVCUsers = array() }
	@totalVCUsers = get_value('Chat.Discord.VC.'.@discord['channel'].'.users.total')
	if(!is_array(@totalVCUsers)) { @totalVCUsers = array() }
	
	if(array_contains(@currentVCUsers, @discord['userid'])) { array_remove_values(@currentVCUsers, @discord['userid']) }
	
	#End of call
	if(!array_index_exists(@currentVCUsers, 0)) {
		if(@VCconfig['VC_DM_Thanks'] == true) {
		#DM thanks
			foreach(@username: @userid in @totalVCUsers) {
				try {
					discord_private_message(@userid, @username.', '.@VCconfig['VC_DM_Thanks_Message'])
				} catch(NotFoundException @ex) {
					console('User '.@username.' "'.@userid.'" was recently in Voice Chat, but now is not found on the server. Did they chat and leave?', false)
					continue()
				}
			}
		}
		console('[Discord] Call Completed in the '.@discord['channel'].' channel! Users who joined: '.array_implode(array_keys(@totalVCUsers), ', '), false)
		clear_value('Chat.Discord.VC.'.@discord['channel'].'.users.current')
		clear_value('Chat.Discord.VC.'.@discord['channel'].'.users.total')
		
		@stats = get_value('Chat.Discord.VC.'.@discord['channel'].'.current.stats')
		if(!is_array(@stats)) { clear_value('Chat.Discord.VC.'.@discord['channel'].'.current.stats') die() }
		
		@stats['end'] = time()
		@stats['users'] = @totalVCUsers
		
		@lastmsgs = get_value('Chat.Discord.last.VC')
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		array_insert(@lastmsgs, @stats, 0)
		if(array_index_exists(@lastmsgs, 20)) {
			_write_file(import('Chat.config.dir').'/Archived-VC-Stats.txt', '\n'.@lastmsgs[20], 'append')
			array_remove(@lastmsgs, 20)
		}
		store_value('Chat.Discord.last.VC', @lastmsgs)		
	} else {
		store_value('Chat.Discord.VC.'.@discord['channel'].'.users.current', @currentVCUsers)
	}
}