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
#---
proc _vc_user_joined(@discord, @type, @chan = array(), @vc) {
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@channel = ''
	@chid = ''
	@vc = ''
	@move = false
	switch(string(@type)) {
	case 'move':
		if(array_index_exists(@discord, 'joined')) {
			@channel = @discord['joined']
			@chid = @discord['joinedid']
			@move = true
		}
	default:
		if(array_index_exists(@discord, 'channel')) {
			@channel = @discord['channel']
			@chid = @discord['channelid']
		}
	}
	if(@channel == '' || @chid == '') { _db_msg_Console('VC Join was not passed Channel data.\n'.@discord, @discord['serverid'], 'error') return(false) }
	if(array_index_exists(@config, 'VC_Options', @chid)) {
		@vc = @config['VC_Options'][@chid]
	} else if(array_index_exists(@config, 'VC_Options', @channel)) {
		@vc = @config['VC_Options'][@channel]
	} else {	
		@vc = array('VC_Logs': array('Join', 'Leave', 'Completed'), 'VC_Ping_If_Role_Member': false, 'VC_Role_ID': 123)
	}
#Save current users in channel.
	@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.Live')
	if(!is_array(@stats)) { @stats = array('users': array(), 'channels': array()) }
	if(!array_index_exists(@stats, 'channels', @chid)) {
		array_set(@stats['channels'], @chid, array('active': array(), 'activetime': array(), 'start': time(), 'end': '', 'users': array(), 'channel': @channel, 'channelid': @chid))
	}	
	if(!array_contains(@stats['channels'][@chid]['active'], @discord['userid'])) { 
		@stats['channels'][@chid]['active'][] = @discord['userid']
	}
	if(!array_contains(@stats['channels'][@chid]['users'], @discord['userid'])) { 
		array_set(@stats['channels'][@chid]['users'], @discord['userid'], @discord['username'])
	}
	if(!array_index_exists(@stats['channels'][@chid], 'activetime', @discord['userid'])) { array_set(@stats['channels'][@chid]['activetime'], @discord['userid'], time()) }
	@stats['channels'][@chid]['activetime'][@discord['userid']] = time()
	@return = true
	if(@move == false && array_contains(@vc['VC_Logs'], 'Join')) {
		@userinfo = array()
		try {
			@userinfo = discord_member_info(@discord['serverid'], @discord['userid']);
		} catch(NotFoundException @ex) {
			export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid'])
		}
		if(!array_index_exists(@userinfo, 'avatar')) { array_set(@userinfo, 'avatar', 'https://cdn.discordapp.com/embed/avatars/0.png') }
		@return = array(
			'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username']),
			'color': array('r': 66, 'g': 180, 'b': 129),
			'description': '<@'.@discord['userid'].'> joined voice channel: <#'.@chid.'>',
			'thumbnail': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/1f4de.png',
			'footer': array('text': 'ID '.@discord['userid']),
			'timestamp': time()
		)
	}
	store_value('DiscordBot.'.@discord['serverid'].'.VC.Live', @stats)
# Setup config
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
				@discordMsg = replace(@discordMsg, '%ChannelName%', @channel)
				@discordMsg = replace(@discordMsg, '%Channel%', '<#'.@chid.'>')
				@mcMsg = replace(@vc['VC_Ping_Message_MC'], '%User%', @discord['username'])
				@mcMsg = replace(@mcMsg, '%Channel%', @channel)
				export('DiscordBot.VC.'.@vc['VC_Role_ID'].'ping.in.progress', true)
			#If user is still in specific channel after 60 seconds (avoid ping on accidental connects)
				set_timeout(@timeout, closure(){
					if(discord_member_get_voice_channel(@discord['serverid'], @discord['userid']) == @chid) {
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
						@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.Live')
						if(!is_array(@stats)) { @stats = array('users': array(), 'channels': array()) }
						if(!array_index_exists(@stats, 'channels', @chid)) {
							array_set(@stats['channels'], @chid, array('active': array(), 'activetime': array(), 'start': (time() - @timeout), 'end': '', 'users': array(), 'channel': @channel, 'channelid': @chid))
						}
						array_set(@stats['channels'][@chid], 'pinguser', @discord['username'])
						store_value('DiscordBot.'.@discord['serverid'].'.VC.Live', @stats)
					}
				});
				set_timeout((@timeout + 5000), closure(){
					export('DiscordBot.VC.'.@vc['VC_Role_ID'].'ping.in.progress', null)
				});
			}
		}
	}
	return(@return)
}
#---
proc _vc_user_left(@discord, @type, @chan = array(), @vc) {
	# @botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@channel = ''
	@chid = ''
	@move = false
	switch(string(@type)) {
	case 'move':
		if(array_index_exists(@discord, 'left')) {
			@channel = @discord['left']
			@chid = @discord['leftid']
			@move = true
		}
	default:
		if(array_index_exists(@discord, 'channel')) {
			@channel = @discord['channel']
			@chid = @discord['channelid']
		}
	}
	if(@channel == '' || @chid == '') { _db_msg_Console('VC leave was not passed Channel data.\n'.@discord, @discord['serverid'], 'error') return(false) }
# Setup config
	@vc = ''
	if(array_index_exists(@config, 'VC_Options', @chid)) {
		@vc = @config['VC_Options'][@chid]
	} else if(array_index_exists(@config, 'VC_Options', @channel)) {
		@vc = @config['VC_Options'][@channel]
	} else {
		@vc = array('VC_Logs': array('Join', 'Leave', 'Completed'), 'VC_DM_Thanks': false)
	}
	@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.Live')
	if(!is_array(@stats)) { @stats = array('users': array(), 'channels': array()) }
# Remove user from active in call
	if(array_contains(@stats['channels'][@chid]['active'], @discord['userid'])) { array_remove_values(@stats['channels'][@chid]['active'], @discord['userid']) }
	if(!array_index_exists(@stats['channels'][@chid], 'time')) { array_set(@stats['channels'][@chid], 'time', array()) }
	if(!array_index_exists(@stats['channels'][@chid], 'time', @discord['userid'])) { array_set(@stats['channels'][@chid]['time'], @discord['userid'], 0) }
	@userTime = 0
	if(array_index_exists(@stats['channels'][@chid], 'activetime', @discord['userid'])) { 
		@userTime = time() - @stats['channels'][@chid]['activetime'][@discord['userid']]
	} else {
		_db_msg_Console('Cannot compute VC join time for '.@discord['username'].': Join event not recorded - Possibly Discord did not provide a join event to the bot.', @discord['serverid'], 'error')
		@userTime = 30000
	}
	@stats['channels'][@chid]['time'][@discord['userid']] = @stats['channels'][@chid]['time'][@discord['userid']] + @userTime
# Log User Leave
	_db_msg_Console(@discord['username'].' VC time: '.@userTime.' (total '.@stats['channels'][@chid]['time'][@discord['userid']].')', @discord['serverid'], 'debug')
	@return = array('usertime': @stats['channels'][@chid]['time'][@discord['userid']])
	if(@move == false && array_contains(@vc['VC_Logs'], 'Leave')) {
		@userinfo = array('bot': false)
		try {
			@userinfo = discord_member_info(@discord['serverid'], @discord['userid']);
		} catch(NotFoundException @ex) {
			export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid'])
		}
		if(!array_index_exists(@userinfo, 'avatar')) { array_set(@userinfo, 'avatar', 'https://cdn.discordapp.com/embed/avatars/0.png') }
		array_set(@return, 'Leave', array(
			'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username']),
			'color': array('r': 253, 'g': 70, 'b': 15),
			'description': '<@'.@discord['userid'].'> left voice channel: <#'.@chid.'>',
			'thumbnail': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/1f4de.png',
			'footer': array('text': 'ID '.@discord['userid']),
			'timestamp': time()
		))
	}
	store_value('DiscordBot.'.@discord['serverid'].'.VC.Live', @stats)
# End of Call, or no?
	@chmem = discord_channel_members(@discord['serverid'], @chid)
	if(array_index_exists(@chmem, 0)) {
	# Disconnect Bots if no users in VC
		@botnum = 0
		if(@vc['VC_DC_Bots'] == true) {
			foreach(@userid in @chmem) {
				@userinfo = ''
				try {
					@userinfo = discord_member_info(@discord['serverid'], @userid);
				} catch(NotFoundException @ex) {
					continue()
				}
				if(@userinfo['bot'] == true) { @botnum++ }
			}
			if(@botnum == array_size(@chmem) && @botnum != 0) {
				foreach(@userid in @chmem) {
					try {
						discord_member_move_voice_channel(@discord['serverid'], @userid, null)
					} catch(Exception @ex) {
						_db_msg_Console('VC disconnect: failed to remove User <@'.@userid.'> from '.@channel.'\n'.@ex, @discord['serverid'], 'error')
						continue()
					}
				}
			}
		}
	} else {
		@r2 = _vc_user_0_left(@discord, @channel, @chid);
		if(is_array(@r2)) { 
			array_set(@return, 'Completed', @r2)
		}
	}
	return(@return)
}
#---
proc _vc_user_0_left(@discord, @channel, @chid, @type) {
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	# Setup config
	@vc = ''
	if(array_index_exists(@config, 'VC_Options', @chid)) {
		@vc = @config['VC_Options'][@chid]
	} else if(array_index_exists(@config, 'VC_Options', @channel)) {
		@vc = @config['VC_Options'][@channel]
	} else {
		@vc = array('VC_Logs': array('Join', 'Leave', 'Completed'), 'VC_DM_Thanks': false)
	}	
	if(@channel == '' || @chid == '') { _db_msg_Console('VC 0 leave was not passed Channel data.\n'.@discord, @discord['serverid'], 'error') return(false) }
	
	@stats = get_value('DiscordBot.'.@discord['serverid'].'.VC.Live')
	if(!is_array(@stats)) { @stats = array('users': array(), 'channels': array()) }
	#End of call
	@return = true
	if(!array_index_exists(@stats, 'channels', @chid, 'active', 0) || !array_index_exists(discord_channel_members(@discord['serverid'], @chid), 0)) {
		#DM thanks
		if(@vc['VC_DM_Thanks'] == true && array_size(@stats['channels'][@chid]['users']) > 1) {
			foreach(@userid: @username in @stats['channels'][@chid]['users']) {
				@userRoles = ''
				@userinfo = ''
				try {
					@userRoles = discord_member_get_roles(@discord['serverid'], @userid)
					@userinfo = discord_member_info(@discord['serverid'], @userid);
				} catch(NotFoundException @ex) {
					_db_msg_Console('User '.@username.' <@'.@userid.'> was recently in Voice Chat, but now is not found on the server. Did they chat and leave?', @discord['serverid'])
					continue()
				}
				@otherVCUsers = array_shallow_clone(@stats['channels'][@chid]['users'])
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
				try {
					discord_private_message(@userid, @dmMsg);
				} catch(Exception @ex) {
					_db_msg_Console('User '.@username.' <@'.@userid.'> did not accept a VC DM.\n'.@ex, @discord['serverid'])
					continue()
				}
			}
		}
		_db_msg_Console('A call was finished in the '.@channel.' channel! Joined: '.color(3).array_implode(@stats['channels'][@chid]['users'], ', '), @discord['serverid'])
		#Save Stats
		@stats['channels'][@chid]['end'] = time()
		array_remove(@stats['channels'][@chid], 'active')
		array_remove(@stats['channels'][@chid], 'activetime')
		@statType = ''
		if(array_size(@stats['channels'][@chid]['users']) < 2) {
			@statType = '.alone'
		}			
		@lastVCStats = get_value('DiscordBot.'.@discord['serverid'].'.VC.'.@chid.@statType)
		if(!is_array(@lastVCStats)) { @lastVCStats = array() }
		array_insert(@lastVCStats, @stats['channels'][@chid], 0);
		_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/'.simple_date('MMyy', time()).'/'.@discord['serverid'].'_'.simple_date('MMyy', time()).'_VC_Stats'.@statType.'-'.@chid.'.json', json_encode(@lastVCStats), 'overwrite')
		store_value('DiscordBot.'.@discord['serverid'].'.VC.'.@chid.@statType, @lastVCStats);
	#End logs
		if(array_contains(@vc['VC_Logs'], 'Completed') && array_size(@stats['channels'][@chid]['users']) > 1) {
		# send embed to channel, with fields of each caller and length
			@callLength = @stats['channels'][@chid]['end'] - @stats['channels'][@chid]['start']
			@return = array(
			'color': array('r': 39, 'g': 175, 'b': 211),
			'title': 'Voice Call Completed',
			'description': '<#'.@chid.'> | '.array_size(@stats['channels'][@chid]['users']).' Users | Total Time: '._vc_display_duration(@callLength),
			'thumbnail': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/1f4f2.png',
			'fields': array(),
			'footer': array('icon_url': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/2705.png', 'text': 'Completed at'),
			'timestamp': time()
			)
			if(array_index_exists(@stats['channels'][@chid], 'pinguser')) {
				@return['fields'][] = array('name': 'VC Ping', 'value': @stats['channels'][@chid]['pinguser'], 'inline': true)
			}
			@usersMsg = ''
			foreach(@userID: @userName in @stats['channels'][@chid]['users']) {
				@usersMsg = @usersMsg.'\n<@'.@userID.'>: '._vc_display_duration(@stats['channels'][@chid]['time'][@userID])
			}
			@return['fields'][] = array('name': 'All Users:' , 'value': @usersMsg, 'inline': true)
		}
	#clear stats
		array_remove(@stats['channels'], @chid)
		store_value('DiscordBot.'.@discord['serverid'].'.VC.Live', @stats)
	}
	return(@return)
}

###------------------------------------------

bind('discord_voice_joined', array('id': 'DiscordBot.VC.Join'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	_db_msg_Console(color(10).'VC <'.@discord['channel'].'>  + '.@discord['username'], @discord['serverid'], 'debug')
#Debug	
clear_value('DiscordBot.'.@discord['serverid'].'.VC.'.@discord['channelid'].'.live.stats');
#####
#Save current users in channel, and ping VC role if available.
	@ret = _vc_user_joined(@discord);
# Send logs
	@logMsg = array()
	if(is_array(@ret)) {
		@logMsg[] = @ret
	}
	if(array_index_exists(@logMsg, 0)) {
		_discordBot_send_message(array('embeds': @logMsg), @discord['serverid'], 'log');
	}
}
#--------------------------------------------
bind('discord_voice_left', array('id': 'DiscordBot.VC.Leave'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	_db_msg_Console(color(12).'VC <'.@discord['channel'].'>  - '.@discord['username'], @discord['serverid'], 'debug')
#Save current users in channel.
	@ret = _vc_user_left(@discord);
# Send logs
	@logMsg = array()
	if(is_array(@ret)) {
		if(array_index_exists(@ret, 'Leave')) {
			@logMsg[] = @ret['Leave'];
		}
		if(array_index_exists(@ret, 'Completed')) {
			@logMsg[] = @ret['Completed'];
		}
	}	
	if(array_index_exists(@logMsg, 0)) {
		_discordBot_send_message(array('embeds': @logMsg), @discord['serverid'], 'log');
	}
}
#--------------------------------------------
bind('discord_voice_moved', array('id': 'DiscordBot.VC.Move'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	_db_msg_Console(color(14).'VC <'.@discord['left'].'> -> <'.@discord['joined'].'>  '.color(10).@discord['username'], @discord['serverid'], 'debug')
	@embeds = array()
# Sync Channel status
	@ret = _vc_user_left(@discord, 'move');
	if(is_array(@ret)) { 
		if(array_index_exists(@ret, 'Completed')) {
			@embeds[] = @ret['Completed']
		}
	}
	@ret2 = _vc_user_joined(@discord, 'move');
#Send Logs
	@userinfo = array()
	try {
		@userinfo = discord_member_info(@discord['serverid'], @discord['userid']);
	} catch(NotFoundException @ex) {
		export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid'])
	}
	if(!array_index_exists(@userinfo, 'avatar')) { array_set(@userinfo, 'avatar', 'https://cdn.discordapp.com/embed/avatars/0.png') }
	@ret3 = array(
	'color': array('r': 250, 'g': 235, 'b': 0),
	'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username']),
	'description': '<@'.@discord['userid'].'> switched voice channels: <#'.@discord['leftid'].'> -> <#'.@discord['joinedid'].'>',
	'thumbnail': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/1f68f.png',
	'fields': array(array('name': 'Channel Time', 'value': _vc_display_duration(@ret['usertime']), 'inline': true)),
	'footer': array('text': 'ID '.@discord['userid']),
	'timestamp': time()
	)
	@embeds[] = @ret3
	if(array_index_exists(@embeds, 0)) {
		_discordBot_send_message(array('embeds': @embeds), @discord['serverid'], 'log');
	}
}