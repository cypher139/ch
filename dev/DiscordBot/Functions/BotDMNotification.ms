# Notify connected servers of any DMs sent to the Bot.
export('DiscordBot.DMs.user.settings', get_value('DiscordBot.DMs.user.settings'));
proc _db_format_msg_attach(@discord, @url = false) {
	@ret = @discord['message']
	if(reg_count('^.+\\/\\/tenor\\.com\\/view', @discord['message']) > 0 && @url == false) {
		@ret = '<Sent a GIF>'
	}
	if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
		if(@discord['message'] == '') {
			@ret = '<Sent a file> '
		} else {
			@ret = @discord['message'].'\n <Also attached file:> '
		}
		foreach(@num: @attach in @discord['attachments']) {
			@adesc = ''
			@filenum = 'File: '
			if(@num != 0) { @filenum = '  File #'.(@num + 1).': ' }
			if(@attach['description'] != '') { @adesc = color(3).'('.@attach['description'].')'.color('r') }
			@ret = @ret.@filenum.@attach['filename'].@adesc
		}
	}
	return(@ret)
}

bind('discord_private_message_received', array('id': 'DiscordBot.DMs.Notification'), null, @discord) {
	array_set(@discord, 'time', time())
	@saveDM = array_deep_clone(@discord)
	array_set(@discord, 'UseDM', 'dm')
# Command check: #Don't save or notify if this is a command message
	@isCmd = _discordBot_iscommand(@discord)
	if(@isCmd == true || is_consumed() == true) { die() }
#Else, not a command.
	@botconfig = import('DiscordBot.config.Bot')
	@guildcfgNotify = array()
	@guildcfgCmd = array()
	@guildcfgChannel = array()
	@guildcfgURL = array()
	@guildcfgNM = array()
	@userserver = 0
	@userServers = array()
	@avatar = 'https://cdn.discordapp.com/embed/avatars/0.png'
	@gf = 0
	foreach(@guild in import('DiscordBot.Guilds')) {
		@cfg = import('DiscordBot.config.'.@guild)
		if(@cfg['DM_Notify'] == true) {	@guildcfgNotify[] = @guild }
		array_set(@guildcfgCmd, @guild, @cfg['CMD_Command_Prefix']);
		array_set(@guildcfgChannel, @guild, @cfg['Log_Channel']);
		array_set(@guildcfgURL, @guild, @cfg['URL_Broadcast']);
		if(array_index_exists(@cfg, 'DM_Notify_NonMember')) { array_set(@guildcfgNM, @guild, @cfg['DM_Notify_NonMember']) } else { array_set(@guildcfgNM, @guild, false) }
		if(array_contains(discord_get_members(@guild), @discord['userid'])) {
			@userServers[] = @guild
			@gf++
			@userserver = @guild
			if(@gf < 2) {
				@avatar = discord_member_info(@guild, @discord['userid'])['avatar']
			}
		}
	}
# User settings
	@recentDMs = get_value('DiscordBot.DMs.recent')
	@userConfig = import('DiscordBot.DMs.user.settings')
	if(is_array(@userConfig)) {
		if(!array_index_exists(@userConfig, @discord['userid'])) {
			array_set(@userConfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
		}	
	} else {
		@userConfig = array()
		array_set(@userConfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
	}
#AS: check if user is under Anti Spam
	@isAS = import('DiscordBot.bot.antispam.triggers')
	if(!is_array(@isAS)) { 
		@isAS = get_value('DiscordBot.bot.antispam.triggers')
		if(!is_array(@isAS)) { @isAS = array('active': array(), 'msgs': array(), 'lastedit': 0, 'total': 0) }
	}
# Save recent DMs for future reference if needed
	@newDM = array()
	array_set(@newDM, @discord['time'], @discord['userid'])
	if(!is_array(@recentDMs)) { @recentDMs = array() }
	array_insert(@recentDMs, @newDM, 0)
	
	@userDMs = get_value('DiscordBot.DMs.log.'.@discord['userid'])
	if(!is_array(@userDMs)) { @userDMs = array() }
	if(array_index_exists(@saveDM, 'attachments', 0, 'filename')) {
		foreach(@num: @attach in @saveDM['attachments']) {
			if(@attach['description'] == '') { array_remove(@saveDM['attachments'][@num], 'description') }
		}
	} else { array_remove(@saveDM, 'attachments') }
	array_remove(@saveDM, 'userid')
	array_insert(@userDMs, @saveDM, 0)
	_write_file(import('DiscordBot.logs.dir').'/DMs/UserDMs-'.@discord['userid'].'.json', json_encode(@userDMs), 'overwrite')
	store_value('DiscordBot.DMs.recent', @recentDMs)
	store_value('DiscordBot.DMs.log.'.@discord['userid'], @userDMs)
			
# Message Display:
	@mcMsg = _db_format_msg_attach(@discord, @botconfig['URL_Broadcast']);
# Send DM notification to Minecraft and Console
	if(@userConfig[@discord['userid']]['NotifyContent'] == true && !array_index_exists(@isAS, 'active', @discord['userid'])) {
		_db_mc_broadcast(color(9).'[Discord Bot] New DM from ['.color(7).@discord['username'].color(9).'] Message: \n'.color(7).@mcMsg, 'players');
	}
	_db_msg_Console(color(9).'DM from '.color(11).@discord['username'].color('r').' <@'.@discord['userid'].'> '.color(9).'Message: \n'.color('r').@mcMsg, 'bot');
	
#Setup message URLs to embed and console
	@urlembed = array()
	if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
		@urls = array()
		foreach(@num: @attach in @discord['attachments']) {
			@adesc = ''
			@filenum = 'File: '
			if(@num != 0) { @filenum = 'File #'.(@num + 1).': ' }
			if(@attach['description'] != '') { @adesc = color(3).'('.@attach['description'].')'.color('r') }
			console(@filenum.@attach['filename'].@adesc.'\n'.color(1).@attach['url'], false)
			#
			if(@botconfig['URL_Broadcast'] == true && @userConfig[@discord['userid']]['NotifyContent'] == true) {
				_db_mc_broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], 'players')
			}
			array_push(@urls, array('name': 'URL #'.(@num + 1), 'value': @attach['url'], 'inline': false))
		}
		@urlembed = array('fields': @urls, 'color': array('r': 0, 'g': 0, 'b': 255), 'thumbnail': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Breezeicons-places-32-folder-download.svg/32px-Breezeicons-places-32-folder-download.svg.png', 'description': 'File List', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/610596549327847434.gif', 'text': 'Use common sense, download at your own risk.'))
		if(@userConfig[@discord['userid']]['URLReadback'] == true) {
			try {
				discord_private_message(@discord['userid'], array('embeds': array(@urlembed)))
			} catch(Exception @ex) {
				_db_msg_Console('[DiscordBot] URL Readback: '.color(12).@ex['classType'].': '.@ex['message'])
			}
		}
	}	
# Send DM notification to each Discord server logs (if enabled)	
	foreach(@guild in @guildcfgNotify) {
	#Check: If user not a member of guild
		if(!array_contains(@userServers, @guild)) {
			if(@guildcfgNM[@guild] == false) {
				continue()
			}
		}
		@dcMsg = _db_format_msg_attach(@discord, @guildcfgURL[@guild]);
		@msgembed = array(array('title': @discord['username'], 'color': array('r': 109, 'g': 109, 'b': 109), 'description': @dcMsg))
	#Get Avatar and embed color info
		@userinfo = array('avatar': @avatar)
		@userinfo = discord_member_info(@guild, @discord['userid']);
		if(array_index_exists(@userinfo, 'avatar')) {
			array_set(@msgembed[0], 'author', array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @discord['username'])));
			array_set(@msgembed[0], 'thumbnail', @userinfo['avatar'].'?size=48');
			array_remove(@msgembed[0], 'title');
		}		
		if(array_index_exists(@userinfo, 'color')) {
			if(@userinfo['color'] != null) {
				array_set(@msgembed[0], 'color', @userinfo['color'])
			}
		}
	#Limit message characters
		if(reg_count('[\\s\\S]{1,1920}', @dcMsg) > 1) {
			@dcMsg = @dcMsg[cslice(0, 1910)].' ...'
		}
	# Include message content?
		# Antispam: No, don't read back DM spam - some spammers also spam the message to bot when AS DM's to tell them that they are timed out.
		if(array_index_exists(@isAS, 'active', @discord['userid'])) {
			@oserver = ''
			if(@guild != @isAS['active'][@discord['userid']]) { @oserver = ' on another server' }
			@dcMsg = '<<<Anti Spam protection is active for this user'.@oserver.'.>>>'
			if(array_contains(@isAS['msgs'][@discord['userid']], sha1(@discord['message']))) {
				@dcMsg = @dcMsg.'\nThe same spam that triggered Anti Spam was just DMed to me.'
			} else {
				@dcMsg = @dcMsg.'\nTo avoid repeating spam their message is not displayed here.'
			}
		} else if(@userConfig[@discord['userid']]['NotifyContent'] == true) {	
		#Yes, include Urls if present
			if(array_size(@urlembed) > 0) {	@msgembed[] = @urlembed }
		} else {
		# No, don't display content as requested
			@msgtype = 'message content'
			if(array_index_exists(@discord, 'attachments', 0, 'filename') && @saveDM['message'] == '') { @msgtype = 'attachment' }
			if(array_index_exists(@discord, 'attachments', 1, 'filename')) { @msgtype = @msgtype.'s' }
			@dcMsg = '<<<user '.@msgtype.' not displayed>>>'
		}
		@dm1 = 'I received a DM!'
		if(array_size(@userDMs) < 2) {
			@dm1 = 'I received my first DM from '.@discord['username'].'!  `'.@discord['userid'].'`'
		}
		@msgembed[0]['description'] = @dcMsg
		try {
			discord_broadcast(@guild, @guildcfgChannel[@guild], array('content': ':envelope_with_arrow:  '.@dm1, 'embeds': @msgembed))
		} catch(InsufficientPermissionException @ex) {
			@msg = @ex['message']
			if(string_ends_with(@ex['message'], 'VIEW_CHANNEL')) {
				@msg = 'Bot cannot view Log Channel! ('.@guildcfgChannel[@guild].')'
			}
			_db_msg_Console('['.@guild.'] '.@msg, 'bot')
		} catch(Exception @ex) {
			_db_msg_Console('['.@guild.'] '.@ex['message'], 'bot')
		}
	}
}