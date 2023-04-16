#version 1.0-tmc
#requires CHDiscord build #76 or newer
#Voice Chat monitor:
/*
If:
 -- User has joined the monitored Voice Channel
 -- User has the specified "Voice Chat" ping role
 -- After 60 seconds User is still in voice channel
 -- "Voice Chat" ping role has not been pinged by the bot in over 12 hours
Then this will send a message to the ping role to come join voice chat
*/

bind('discord_voice_joined', array('id': 'DiscordBot.VC.Join'), null, @discord) {
# Note: import is auto globally saved (example #2), so use new variables to store edits needed
	@config = import('DiscordBot.config.Discord')
	if(@config['VC_Channel_ID'] == '' || @config['VC_Role_ID'] == '') { die() }
	@userroles = discord_member_get_roles(@discord['userid'])
	@stats = get_value('DiscordBot.VC.'.@discord['channelid'].'.current.stats')
	if(!is_array(@stats)) { @stats = array('start': time(), 'end': '', 'users': '', 'channel': @discord['channel']) }
	
	#Ping @VC role to come join the main VC channel.
	if(array_contains(@userroles, @config['VC_Role_ID']) && @discord['channel'] == @config['VC_Channel_Name']) {
	# Get last time the bot pinged the role
		@lastping = get_value('DiscordBot.last.ping.'.@config['VC_Role_ID'])
		if(@lastping == '' || @lastping == null) { @lastping = 1230768000000 }
		if(import('DiscordBot.VC.ping.in.progress') == true) { die() } else {
			@timeout = 60000
			@discordMsg = reg_replace('%RoleID%', '<@&'.@config['VC_Role_ID'].'>', @config['VC_Ping_Message'])
			@discordMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @discordMsg)
			@discordMsg = reg_replace('%Channel%', @discord['channel'], @discordMsg)
			@mcMsg = reg_replace('%User%', @discord['username'], @config['VC_Ping_Message_MC'])
			@mcMsg = reg_replace('%Channel%', @discord['channel'], @mcMsg)
	# :angrypingemoji: 1 ping every 12 hours only!
			if(time() > (@lastping + @config['VC_Ping_Timeout'])) {
				export('DiscordBot.VC.ping.in.progress', true)
			#If user is still in specific channel after 60 seconds (avoid ping on accidental connects)
				set_timeout(@timeout, closure(){
					if(discord_member_get_voice_channel(@discord['userid']) == @config['VC_Channel_ID']) {
						#Has the role just been mentioned?
						@lastmsgs = import('DiscordBot.last.message')
						if(is_array(@lastmsgs)) {
							foreach(@index: @message in @lastmsgs) {
								if(reg_count('@'.@config['VC_Role_Name'], @message['message']) > 0) {
									@discordMsg = 'Hey I was going to do that ping!'
								}
							}
						}					
						discord_broadcast(@config['VC_Text_Channel_Name'], array('content': @discordMsg))
						_db_mc_broadcast(@mcMsg, 'player')
						store_value('DiscordBot.last.ping.'.@config['VC_Role_ID'], time())
						@stats = get_value('DiscordBot.VC.'.@discord['channelid'].'.current.stats')
						if(!is_array(@stats)) { @stats = array('start': (time() - @timeout), 'end': '', 'users': '', 'channel': @discord['channel']) }
						array_set(@stats, 'pinguser', @discord['username'])
						store_value('DiscordBot.VC.'.@discord['channelid'].'.current.stats', @stats)
					}
				});
				set_timeout((@timeout + 10000), closure(){
					export('DiscordBot.VC.ping.in.progress', false)
				});
			}
		}
	}
	
	#Save current users in channel, only after 90 seconds so user is stayin
	set_timeout(90000, closure(){
		if(discord_member_get_voice_channel(@discord['userid']) == @discord['channelid']) {
			@currentVCUsers = get_value('DiscordBot.VC.'.@discord['channelid'].'.users.current')
			if(!is_array(@currentVCUsers)) { @currentVCUsers = array() }
			@totalVCUsers = get_value('DiscordBot.VC.'.@discord['channelid'].'.users.total')
			if(!is_array(@totalVCUsers)) { @totalVCUsers = array() }
			@stats = get_value('DiscordBot.VC.'.@discord['channelid'].'.current.stats')
			if(!is_array(@stats)) { 
				@stats = array('start': (time() - 90000), 'end': '', 'users': '', 'channel': @discord['channel'])
				store_value('DiscordBot.VC.'.@discord['channelid'].'.current.stats', @stats)
			}
				
			if(!array_contains(@currentVCUsers, @discord['userid'])) { 
				@currentVCUsers[] = @discord['userid']
				store_value('DiscordBot.VC.'.@discord['channelid'].'.users.current', @currentVCUsers)
			}
			if(!array_contains(@totalVCUsers, @discord['userid'])) { 
				array_set(@totalVCUsers, @discord['userid'], @discord['username'])
				store_value('DiscordBot.VC.'.@discord['channelid'].'.users.total', @totalVCUsers)
			}
		}
	});
	
}


bind('discord_voice_left', array('id': 'DiscordBot.VC.Leave'), null, @discord) {
	@config = import('DiscordBot.config.Discord')
	if(@config['VC_Channel_ID'] == '' || @config['VC_Role_ID'] == '') { die() }
	@currentVCUsers = get_value('DiscordBot.VC.'.@discord['channelid'].'.users.current')
	if(!is_array(@currentVCUsers)) { @currentVCUsers = array() }
	@totalVCUsers = get_value('DiscordBot.VC.'.@discord['channelid'].'.users.total')
	if(!is_array(@totalVCUsers)) { @totalVCUsers = die() }
	
	if(array_contains(@currentVCUsers, @discord['userid'])) { array_remove_values(@currentVCUsers, @discord['userid']) }
	
	#End of call
	if(!array_index_exists(@currentVCUsers, 0)) {
		#DM thanks
		if(@config['VC_DM_Thanks'] == true && array_size(@totalVCUsers) > 1) {
			foreach(@userid: @username in @totalVCUsers) {
				@UserRole = ''
				try {
					@UserRole = discord_member_get_roles(@userid)
				} catch(NotFoundException @ex) {
					console('[Discord] User '.@username.' <@'.@userid.'> was recently in Voice Chat, but now is not found on the server. Did they chat and leave?', false)
					continue()
				}	
				if(@config['VC_DM_VC_Role'] == false) {
					if(array_contains_ic(@UserRole, @config['VC_Role_ID'])) {
						continue()
					}
				}
				@dmMsg = reg_replace('%User%', @username, @config['Welcome_DM_Message'])
				discord_private_message(@userid, @dmMsg)
			}
		}
		console('[Discord] Call Completed in the '.@discord['channel'].' channel! Users who joined: '.array_implode(@totalVCUsers, ', '), false)
		#Save Stats
		clear_value('DiscordBot.VC.'.@discord['channelid'].'.users.current')
		clear_value('DiscordBot.VC.'.@discord['channelid'].'.users.total')
		@stats = get_value('DiscordBot.VC.'.@discord['channelid'].'.current.stats')
		if(!is_array(@stats)) { die() }
		
		@stats['end'] = time()
		@stats['users'] = @totalVCUsers
		@lastmsglone = ''
		if(array_size(@totalVCUsers) < 2) {
			@lastmsglone = '.alone'
		}			
		@lastmsgs = get_value('DiscordBot.last.VC'.@lastmsglone)
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		array_insert(@lastmsgs, @stats, 0)
		if(array_index_exists(@lastmsgs, 20)) {
			_write_file(import('DiscordBot.logs.dir').'/Discord-VC-Stats'.@lastmsglone.'.txt', '\n'.@lastmsgs[20], 'append')
			array_remove(@lastmsgs, 20)
		}
		store_value('DiscordBot.last.VC'.@lastmsglone, @lastmsgs)
		clear_value('DiscordBot.VC.'.@discord['channelid'].'.current.stats')		
	} else {
		store_value('DiscordBot.VC.'.@discord['channelid'].'.users.current', @currentVCUsers)
	}
}