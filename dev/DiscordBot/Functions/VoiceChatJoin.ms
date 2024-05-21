#Ping users to join VC when a user joins the channel, and record channel stats.
proc _vc_display_duration(@time) {
	@dateType = 'HH\'h\' mm\'m\' ss\'s\''
	@dl = ''
	if(@time < 60000) {
	#less than min
		@dateType = 'ss\'s\''
	} else if(@time >= 60000 && @time < 3600000) {
	#over 1 min
		@dateType = 'mm\'m\' ss\'s\''
	} else if(@time >= 3600000 && @time < 86400000) {
	#over 1 hour - uses above default.
		@dateType = 'HH\'h\' mm\'m\' ss\'s\''
	} else if(@time >= 86400000) {
	#over 1 day
		@dl = (simple_date('D', @time) - 1).'d '
	} 
	return(@dl.simple_date(@dateType, @time));
}

bind('discord_voice_joined', array('id': 'DiscordBot.VC.Join'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die() }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@vc = ''
	@isAdmin = false
	@isRole = false
	@usePing = false
	@userRoles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
	foreach(@rN: @rID in @userRoles) {
		if(array_contains_ic(@config['Role_Admins'], @rN) || array_contains(@config['Role_Admins'], @rID)) {
			@isAdmin = true
			break()
		}
	}
# Setup config
	if(array_index_exists(@config, 'VC_Options', @discord['channelid'])) {
		@vc = @config['VC_Options'][@discord['channelid']]
	} else if(array_index_exists(@config, 'VC_Options', @discord['channel'])) {
		@vc = @config['VC_Options'][@discord['channel']]
	} else {	
		@vc = array('VC_Ping_If_Role_Member': false, 'VC_Role_ID': 123)
	}
	if(array_contains(@userRoles, @vc['VC_Role_ID'])) { @isRole = true }
	if(@vc['VC_Ping_If_Role_Member'] == true) {
		if(@isRole == true) { @usePing = true }
	} else {
		if(@isRole == false) { @usePing = true }
		if(@isAdmin == true) { @usePing = false } 
	}
#Ping @VC role to come join the main VC channel.
	if(@usePing == true && @vc['VC_Role_ID'] != 123) {
	# Get last time the bot pinged the role
		@lastping = get_value('DiscordBot.VC.last.pings')
		if(!is_array(@lastping)) { @lastping = array() }
		if(!array_index_exists(@lastping, @vc['VC_Role_ID'])) { array_set(@lastping, @vc['VC_Role_ID'], 1230768000000) }
		if(import('DiscordBot.VC.'.@vc['VC_Role_ID'].'ping.in.progress') != true) {
			@timeout = 20000
	# :angrypingemoji: 1 ping every 12 hours only!
			if(time() > (@lastping[@vc['VC_Role_ID']] + @vc['VC_Ping_Timeout'])) {
				@discordMsg = replace(@vc['VC_Ping_Message'], '%RoleID%', '<@&'.@vc['VC_Role_ID'].'>')
				@discordMsg = replace(@discordMsg, '%UserID%', '<@'.@discord['userid'].'>')
				@discordMsg = replace(@discordMsg, '%ChannelName%', @discord['channel'])
				@discordMsg = replace(@discordMsg, '%Channel%', '<#'.@discord['channelid'].'>')
				@mcMsg = replace(@vc['VC_Ping_Message_MC'], '%User%', @discord['username'])
				@mcMsg = replace(@mcMsg, '%Channel%', @discord['channel'])
				export('DiscordBot.VC.'.@vc['VC_Role_ID'].'ping.in.progress', true)
			#If user is still in specific channel after 60 seconds (avoid ping on accidental connects)
				set_timeout(@timeout, closure(){
					if(discord_member_get_voice_channel(@discord['serverid'], @discord['userid']) == @discord['channelid']) {
						#Has the role just been mentioned?
						@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
						if(is_array(@cacheMsgs)) {
							foreach(@i in @cacheMsgs['server']) {
							# Only check messages that are posted within timeout period. 
								if(@cacheMsgs['messages'][@i]['time'] < (time() - @vc['VC_Ping_Timeout'])) {
									continue()
								}
								if(!array_index_exists(@cacheMsgs, 'messages', @i, 'message')) { continue() }
								if(reg_count('@'.@vc['VC_Role_Name'], @cacheMsgs['messages'][@i]['message']) > 0) {						
									@discordMsg = 'Hey I was going to do that ping!'
									break()
								}
							}
						}					
						discord_broadcast(@discord['serverid'], @vc['VC_Text_Channel_ID'], array('content': @discordMsg, 'allowed_mentions': array('parse': array('ROLE'))))
						_db_mc_broadcast(@mcMsg, 'player')
						@lastping[@vc['VC_Role_ID']] = time()
						store_value('DiscordBot.VC.last.pings', @lastping)
						@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats')
						if(!is_array(@stats)) { @stats = array('active': array(), 'activetime': array(), 'start': (time() - @timeout), 'end': '', 'users': array(), 'channel': @discord['channel']) }
						array_set(@stats, 'pinguser', @discord['username'])
						store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats', @stats)
					}
				});
				set_timeout((@timeout + 10000), closure(){
					export('DiscordBot.VC.'.@vc['VC_Role_ID'].'ping.in.progress', null)
				});
			}
		}
	}
#Save current users in channel.
	@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats')
	if(!is_array(@stats)) { 
		@stats = array('active': array(), 'activetime': array(), 'start': time(), 'end': '', 'users': array(), 'channel': @discord['channel'])
	}	
	if(!array_contains(@stats['active'], @discord['userid'])) { 
		@stats['active'][] = @discord['userid']
	}
	if(!array_contains(@stats['users'], @discord['userid'])) { 
		array_set(@stats['users'], @discord['userid'], @discord['username'])
	}
	if(!array_index_exists(@stats, 'activetime', @discord['userid'])) { array_set(@stats['activetime'], @discord['userid'], time()) }
	@stats['activetime'][@discord['userid']] = time()
	store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats', @stats)
# Send logs
	@logMsg = array('embeds': array())
	if(array_contains(@vc['VC_Logs'], 'Join')) {
		@userinfo = array()
		try {
			@userinfo = discord_member_info(@discord['serverid'], @discord['userid']);
		} catch(NotFoundException @ex) {
			export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid'])
		}
		if(!array_index_exists(@userinfo, 'avatar')) { array_set(@userinfo, 'avatar', 'https://cdn.discordapp.com/embed/avatars/0.png') }
		@embed = array(
			'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username']),
			'color': array('r': 66, 'g': 180, 'b': 129),
			'description': '<@'.@discord['userid'].'> joined voice channel: <#'.@discord['channelid'].'>',
			'thumbnail': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/1f4de.png',
			'footer': array('text': 'ID '.@discord['userid']),
			'timestamp': time()
		)
		@logMsg['embeds'][] = @embed;
		_discordBot_send_message(@logMsg, @discord['serverid'], 'log');
	}
}
#--------------------------------------------
bind('discord_voice_left', array('id': 'DiscordBot.VC.Leave'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die() }
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	# Setup config
	@vc = ''
	if(array_index_exists(@config, 'VC_Options', @discord['channelid'])) {
		@vc = @config['VC_Options'][@discord['channelid']]
	} else if(array_index_exists(@config, 'VC_Options', @discord['channel'])) {
		@vc = @config['VC_Options'][@discord['channel']]
	} else {
		@vc = array('VC_DM_Thanks': false)
	}	
	@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats')
	if(!is_array(@stats)) { die() }
	# Remove user from active in call
	if(array_contains(@stats['active'], @discord['userid'])) { array_remove_values(@stats['active'], @discord['userid']) }
	if(!array_index_exists(@stats, 'time')) { array_set(@stats, 'time', array()) }
	if(!array_index_exists(@stats, 'time', @discord['userid'])) { array_set(@stats['time'], @discord['userid'], 0) }
	@userTime = 0
	if(array_index_exists(@stats, 'activetime', @discord['userid'])) { 
		@userTime = time() - @stats['activetime'][@discord['userid']]
	} else {
		_db_msg_Console('Cannot compute VC join time for '@discord['username'].': Join event not recorded - Possibly Discord did not provide a join event to the bot.', @discord['serverid'], 'error')
		@userTime = 30000
	}
	@stats['time'][@discord['userid']] = @stats['time'][@discord['userid']] + @userTime
	@userinfo = array('bot': false)
	try {
		@userinfo = discord_member_info(@discord['serverid'], @discord['userid']);
	} catch(NotFoundException @ex) {
		export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid'])
	} 
	if(!array_index_exists(@userinfo, 'avatar')) { array_set(@userinfo, 'avatar', 'https://cdn.discordapp.com/embed/avatars/0.png') }
	#Log User Leave
	_db_msg_Console(@discord['username'].' VC time: '.@userTime.' (total '.@stats['time'][@discord['userid']].')', @discord['serverid'], 'debug')
	@logMsg = array('embeds': array())
	if(array_contains(@vc['VC_Logs'], 'Leave')) {
		@embed = array(
			'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username']),
			'color': array('r': 253, 'g': 70, 'b': 15),
			'description': '<@'.@discord['userid'].'> left voice channel: <#'.@discord['channelid'].'>',
			'thumbnail': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/1f4de.png',
			'footer': array('text': 'ID '.@discord['userid']),
			'timestamp': time()
		)
		@logMsg['embeds'][] = @embed;
	}
		
	#End of call
	if(!array_index_exists(@stats['active'], 0)) {
		#DM thanks
		if(@vc['VC_DM_Thanks'] == true && array_size(@stats['users']) > 1) {
			foreach(@userid: @username in @stats['users']) {
				@userRoles = ''
				try {
					@userRoles = discord_member_get_roles(@discord['serverid'], @userid)
				} catch(NotFoundException @ex) {
					_db_msg_Console('User '.@username.' <@'.@userid.'> was recently in Voice Chat, but now is not found on the server. Did they chat and leave?', @discord['serverid'])
					continue()
				}
				@otherVCUsers = array_shallow_clone(@stats['users'])
				array_remove_values(@otherVCUsers, @username);
				if(@vc['VC_DM_VC_Role'] == false) {
					if(array_contains_ic(@userRoles, @vc['VC_Role_ID'])) {
						continue()
					}
				}
				@isAdmin = false
				foreach(@rN: @rID in @userRoles) {
					if(array_contains_ic(@config['Role_Admins'], @rN) || array_contains(@config['Role_Admins'], @rID)) {
						@isAdmin = true
						break()
					}
				}		
				if(@isAdmin == true || @userinfo['bot'] == true) { continue() }
				@dmMsg = replace(@vc['VC_DM_Thanks_Message'], '%User%', @username)
				if(array_size(@otherVCUsers) < 2) {
					@dmMsg = replace(@dmMsg, '%OtherUsers%', array_implode(@otherVCUsers, ''))
				} else {
					@dmMsg = replace(@dmMsg, '%OtherUsers%', array_implode(array_normalize(@otherVCUsers)[..-2], ',').' and '.array_normalize(@otherVCUsers)[..-1])
				}
				# @dmMsg = replace(@dmMsg, '%TotalUsers%', array_implode(@stats['users'], ' and '))
				discord_private_message(@userid, @dmMsg);
			}
		}
		_db_msg_Console('A call was finished in the '.@discord['channel'].' channel! Joined: '.color(3).array_implode(@stats['users'], ', '), @discord['serverid'])
		#Save Stats
		@stats['end'] = time()
		array_remove(@stats, 'active')
		array_remove(@stats, 'activetime')
		@statType = ''
		if(array_size(@stats['users']) < 2) {
			@statType = '.alone'
		}			
		@lastVCStats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].@statType)
		if(!is_array(@lastVCStats)) { @lastVCStats = array() }
		array_insert(@lastVCStats, @stats, 0);
		_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/'.simple_date('MMyy', time()).'/'.@discord['serverid'].'_'.simple_date('MMyy', time()).'_VC_Stats'.@statType.'-'.@discord['channelid'].'.json', json_encode(@lastVCStats), 'overwrite')
		store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].@statType, @lastVCStats);
		clear_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats');	
	#End logs
		if(array_contains(@vc['VC_Logs'], 'Completed') && array_size(@stats['users']) > 1) {
		# send embed to channel, with fields of each caller and length
			@callLength = @stats['end'] - @stats['start']
			@embed = array(
			'color': array('r': 39, 'g': 175, 'b': 211),
			'title': 'Voice Call Completed',
			'description': '<#'.@discord['channelid'].'> | '.array_size(@stats['users']).' Users | Total Time: '._vc_display_duration(@callLength),
			'thumbnail': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/1f4f2.png',
			'fields': array(),
			'footer': array('icon_url': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/2705.png', 'text': 'Completed at'),
			'timestamp': time()
			)
			if(array_index_exists(@stats, 'pinguser')) {
				@embed['fields'][] = array('name': 'VC Ping', 'value': @stats['pinguser'], 'inline': true)
			}
			@usersMsg = ''
			foreach(@userID: @userName in @stats['users']) {
				@usersMsg = @usersMsg.'\n<@'.@userID.'>: '._vc_display_duration(@stats['time'][@userID])
			}
			@embed['fields'][] = array('name': 'All Users:' , 'value': @usersMsg, 'inline': true)
			@logMsg['embeds'][] = @embed;
		}
	} else {
		store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats', @stats);
	}
#Send Logs
	if(array_index_exists(@logMsg, 'embeds', 0)) {
		_discordBot_send_message(@logMsg, @discord['serverid'], 'log');
	}
}