#version 1.1-tmc
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
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
# Note: import is auto globally saved (example #2), so use new variables to store edits needed
	@vc = ''
	@isAdmin = false
	@isRole = false
	@usePing = false
	# if(@config['VC_Channel_ID'] == '' || @config['VC_Role_ID'] == '') { die() }
	@userroles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
	foreach(@role: @roleid in @userroles) {
		if(array_contains_ic(@config['Role_Admins'], @role)) {
			@isAdmin = true
			break()
		}
	}
#setup config
	if(array_index_exists(@config, 'VC_Options', @discord['channelid'])) {
		@vc = @config['VC_Options'][@discord['channelid']]
	} else if(array_index_exists(@config, 'VC_Options', @discord['channel'])) {
		@vc = @config['VC_Options'][@discord['channel']]
	} else {	
		@vc = array('VC_Ping_If_Role_Member': false, 'VC_Role_ID': 123)
	}
	if(array_contains(@userroles, @vc['VC_Role_ID'])) { @isRole = true }
	if(@vc['VC_Ping_If_Role_Member'] == true) {
		if(@isRole == true) { @usePing = true }
	} else {
		if(@isRole == false) { @usePing = true }
		if(@isAdmin == true) { @usePing = false } 
	}
	#Ping @VC role to come join the main VC channel.
	if(@usePing == true && @vc['VC_Role_ID'] != 123) {
	# Get last time the bot pinged the role
		@lastping = get_value('DiscordBot.last.ping.'.@vc['VC_Role_ID'])
		if(@lastping == '' || @lastping == null) { @lastping = 1230768000000 }
		if(import('DiscordBot.'.@discord['serverid'].'.VC.ping.in.progress') == true) { die() } else {
			@timeout = 60000
			@discordMsg = reg_replace('%RoleID%', '<@&'.@vc['VC_Role_ID'].'>', @vc['VC_Ping_Message'])
			@discordMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @discordMsg)
			@discordMsg = reg_replace('%Channel%', @discord['channel'], @discordMsg)
			@mcMsg = reg_replace('%User%', @discord['username'], @vc['VC_Ping_Message_MC'])
			@mcMsg = reg_replace('%Channel%', @discord['channel'], @mcMsg)
	# :angrypingemoji: 1 ping every 12 hours only!
			if(time() > (@lastping + @vc['VC_Ping_Timeout'])) {
				export('DiscordBot.'.@discord['serverid'].'.VC.ping.in.progress', true)
			#If user is still in specific channel after 60 seconds (avoid ping on accidental connects)
				set_timeout(@timeout, closure(){
					if(discord_member_get_voice_channel(@discord['serverid'], @discord['userid']) == @discord['channelid']) {
						#Has the role just been mentioned?
						@lastmsgs = import('DiscordBot.'.@discord['serverid'].'.last.message')
						if(is_array(@lastmsgs)) {
							foreach(@index: @message in @lastmsgs) {
							# Only check messages that are posted within timeout period. 
								if(@message['time'] < (time() - @vc['VC_Ping_Timeout'])) {
									continue()
								}
								if(reg_count('@'.@vc['VC_Role_Name'], @message['message']) > 0) {						
									@discordMsg = 'Hey I was going to do that ping!'
									break()
								}
							}
						}					
						discord_broadcast(@discord['serverid'], @vc['VC_Text_Channel_ID'], @discordMsg)
						_db_mc_broadcast(@mcMsg, 'player')
						store_value('DiscordBot.last.ping.'.@vc['VC_Role_ID'], time())
						@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.current.stats')
						if(!is_array(@stats)) { @stats = array('start': (time() - @timeout), 'end': '', 'users': '', 'channel': @discord['channel']) }
						array_set(@stats, 'pinguser', @discord['username'])
						store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.current.stats', @stats)
					}
				});
				set_timeout((@timeout + 10000), closure(){
					export('DiscordBot.'.@discord['serverid'].'.VC.ping.in.progress', false)
				});
			}
		}
	}
	
	#Save current users in channel, only after 90 seconds so user is stayin
	set_timeout(90000, closure(){
		if(discord_member_get_voice_channel(@discord['serverid'], @discord['userid']) == @discord['channelid']) {
			@currentVCUsers = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.current')
			if(!is_array(@currentVCUsers)) { @currentVCUsers = array() }
			@totalVCUsers = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.total')
			if(!is_array(@totalVCUsers)) { @totalVCUsers = array() }
			@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.current.stats')
			if(!is_array(@stats)) { 
				@stats = array('start': (time() - 90000), 'end': '', 'users': '', 'channel': @discord['channel'])
				store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.current.stats', @stats)
			}
				
			if(!array_contains(@currentVCUsers, @discord['userid'])) { 
				@currentVCUsers[] = @discord['userid']
				store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.current', @currentVCUsers)
			}
			if(!array_contains(@totalVCUsers, @discord['userid'])) { 
				array_set(@totalVCUsers, @discord['userid'], @discord['username'])
				store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.total', @totalVCUsers)
			}
		}
	});
}


bind('discord_voice_left', array('id': 'DiscordBot.VC.Leave'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	#setup config
	@vc = ''
	if(array_index_exists(@config, 'VC_Options', @discord['channelid'])) {
		@vc = @config['VC_Options'][@discord['channelid']]
	} else if(array_index_exists(@config, 'VC_Options', @discord['channel'])) {
		@vc = @config['VC_Options'][@discord['channel']]
	} else {	
		@vc = array('VC_DM_Thanks': false)
	}
	# if(@config['VC_Channel_ID'] == '' || @config['VC_Role_ID'] == '') { die() }
	@totalVCUsers = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.total')
	if(!is_array(@totalVCUsers)) { die() }
	@currentVCUsers = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.current')
	if(!is_array(@currentVCUsers)) { @currentVCUsers = array() }
	
	if(array_contains(@currentVCUsers, @discord['userid'])) { array_remove_values(@currentVCUsers, @discord['userid']) }
	
	#End of call
	if(!array_index_exists(@currentVCUsers, 0)) {
		#DM thanks
		if(@vc['VC_DM_Thanks'] == true && array_size(@totalVCUsers) > 1) {
			foreach(@userid: @username in @totalVCUsers) {
				@UserRole = ''
				try {
					@UserRole = discord_member_get_roles(@discord['serverid'], @userid)
				} catch(NotFoundException @ex) {
					console('['.@config['Server_Nickname'].'] User '.@username.' <@'.@userid.'> was recently in Voice Chat, but now is not found on the server. Did they chat and leave?', false)
					continue()
				}
				@otherVCUsers = array_shallow_clone(@totalVCUsers)
				array_remove_values(@otherVCUsers, @username);
				if(@vc['VC_DM_VC_Role'] == false) {
					if(array_contains_ic(@UserRole, @vc['VC_Role_ID'])) {
						continue()
					}
				}
				@isAdmin = false
				foreach(@role: @roleid in @UserRole) {
					if(array_contains_ic(@config['Role_Admins'], @role)) {
						@isAdmin = true
						break()
					}
				}				
				if(@isAdmin == true) { continue() }
				@dmMsg = reg_replace('%User%', @username, @vc['VC_DM_Thanks_Message'])
				if(array_size(@otherVCUsers) < 2) {
					@dmMsg = reg_replace('%OtherUsers%', array_implode(@otherVCUsers, ''), @dmMsg)
				} else {
					@dmMsg = reg_replace('%OtherUsers%', array_implode(@otherVCUsers[..-2], ',').' and '.@otherVCUsers[..-1], @dmMsg)
				}
				# @dmMsg = reg_replace('%TotalUsers%', array_implode(@totalVCUsers, ' and '), @dmMsg)
				discord_private_message(@userid, @dmMsg);
			}
		}
		console('['.@config['Server_Nickname'].'] Call Completed in the '.@discord['channel'].' channel! Users who joined: '.color(3).array_implode(@totalVCUsers, ', '), false)
		#Save Stats
		clear_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.current');
		clear_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.total');
		@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.current.stats')
		if(!is_array(@stats)) { die() }
		
		@stats['end'] = time()
		@stats['users'] = @totalVCUsers
		@lastmsglone = ''
		if(array_size(@totalVCUsers) < 2) {
			@lastmsglone = '.alone'
		}			
		@lastmsgs = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].@lastmsglone)
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		array_insert(@lastmsgs, @stats, 0);
		_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/VC-Stats'.@lastmsglone.'-'.@discord['channelid'].'.json', json_encode(@lastmsgs), 'overwrite')
		store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].@lastmsglone, @lastmsgs);
		clear_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.current.stats');
	} else {
		store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.users.current', @currentVCUsers);
	}
}