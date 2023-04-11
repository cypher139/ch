#version 1.1-tmc

export('DiscordBot.DMs.user.settings', get_value('DiscordBot.DMs.user.settings'));

bind('discord_private_message_received', array('id': 'DiscordBot.DMs.Notification'), null, @discord) {
	array_set(@discord, 'time', time())
	@saveDM = array_deep_clone(@discord)
#Don't save or notify if this is a command message
	@config = import('DiscordBot.config.Discord')
	if(reg_count(@config['CMD_Command_Prefix'], @discord['message']) > 0) {
		array_set(@discord, 'channel', @discord['userid'])
		@return = _discordBot_handlecommand(@discord, 'dm', 'dm')
	} else { 
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
		_write_file(import('DiscordBot.logs.dir').'/Discord-DMs-User-'.@discord['userid'].'.json', json_encode(@userDMs), 'overwrite')
		store_value('DiscordBot.DMs.recent', @recentDMs)
		store_value('DiscordBot.DMs.log.'.@discord['userid'], @userDMs)
	#Message Display
		if(reg_count('^.+\\/\\/tenor\\.com\\/view', @discord['message']) > 0 && @config['URL_Broadcast'] == false) {
			@discord['message'] = '<Sent a GIF>'
		}
		if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
			if(@discord['message'] == '') {
				@discord['message'] = '<Sent a file> '
			} else {
				@discord['message'] = @discord['message'].'\n <Also attached file:> '
			}
			foreach(@num: @attach in @discord['attachments']) {
				@adesc = ''
				@filenum = 'File: '
				if(@num != 0) { @filenum = '  File #'.(@num + 1).': ' }
				if(@attach['description'] != '') { @adesc = color(3).'('.@attach['description'].')'.color('r') }
				@discord['message'] = @discord['message'].@filenum.@attach['filename'].@adesc
			}
		}
	# Send Dm notification to Minecraft and Console
		if(@userConfig[@discord['userid']]['NotifyContent'] == true) {
			_db_mc_broadcast(color(9).'[Discord Bot] New DM from ['.color(7).@discord['username'].color(9).'] Message: \n'.color(7).@discord['message'], 'players')
		}
		console('[Discord] '.color(9).'New DM from '.color('r').'['.@discord['username'].' ('.@discord['userid'].') ] '.color(9).'Message: \n'.color('r').@discord['message'], false)
		
		@msgembed = array(array('title': @discord['username'], 'color': array('r': 109, 'g': 109, 'b': 109), 'description': @discord['message']))
		#Get Avatar
		@leaderboards = import('DiscordBot.Leaderboard');
		if(is_array(@leaderboards)) {
			if(array_index_exists(@leaderboards, 'members', @discord['userid'], 'avatar')) {
				array_set(@msgembed[0], 'author', array('icon_url': 'https://cdn.discordapp.com/avatars/'.@discord['userid'].'/'.@leaderboards['members'][@discord['userid']]['avatar'].'.webp?size=48', 'name': @discord['username']))
				array_remove(@msgembed[0], 'title')
			}
		}
		if(reg_count('[\\s\\S]{1,1920}', @discord['message']) > 1) {
			@discord['message'] = @discord['message'][cslice(0, 1910)].' ...'
		}
	#Setup message URLs to embed and console
		if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
			@urls = array()
			foreach(@num: @attach in @discord['attachments']) {
				@adesc = ''
				@filenum = 'File: '
				if(@num != 0) { @filenum = 'File #'.(@num + 1).': ' }
				if(@attach['description'] != '') { @adesc = color(3).'('.@attach['description'].')'.color('r') }
				console(@filenum.@attach['filename'].@adesc.'\n'.color(1).@attach['url'], false)
				#
				if(@config['URL_Broadcast'] == true && @userConfig[@discord['userid']]['NotifyContent'] == true) {
					_db_mc_broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], 'players')
				}
				array_push(@urls, array('name': 'URL #'.(@num + 1), 'value': @attach['url'], 'inline': false))
			}
#			discord_broadcast(@config['Log_Channel'], array('embeds': array(array('fields': @urls, 'color': array('r': 0, 'g': 0, 'b': 255), 'thumbnail': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Breezeicons-places-32-folder-download.svg/32px-Breezeicons-places-32-folder-download.svg.png', 'description': 'File List', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/610596549327847434.gif', 'text': 'Use common sense, download at your own risk.')))))
			@urlembed = array('fields': @urls, 'color': array('r': 0, 'g': 0, 'b': 255), 'thumbnail': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Breezeicons-places-32-folder-download.svg/32px-Breezeicons-places-32-folder-download.svg.png', 'description': 'File List', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/610596549327847434.gif', 'text': 'Use common sense, download at your own risk.'))
			if(@userConfig[@discord['userid']]['NotifyContent'] == true) { array_push(@msgembed, @urlembed) }
			if(@userConfig[@discord['userid']]['URLReadback'] == true) {
				try {
					discord_private_message(@discord['userid'], array('embeds': array(@urlembed)))
				} catch(Exception @ex) {
					console('[Discord] URL Readback: '.color(12).@ex['classType'].': '.@ex['message'])
				}
			}
		}
		
	# Send Dm Notification to Discord logs
		if(@userConfig[@discord['userid']]['NotifyContent'] == false) {
			@msgtype = 'message content'
			if(array_index_exists(@discord, 'attachments', 0, 'filename') && @saveDM['message'] == '') { @msgtype = 'attachment' }
			if(array_index_exists(@discord, 'attachments', 1, 'filename')) { @msgtype = @msgtype.'s' }
			@msgembed[0]['description'] = '<This user\'s '.@msgtype.' is not shown in DM notifications>'
		}
		@dm1 = 'I received a DM!'
		if(array_size(@userDMs) < 2) {
			@dm1 = 'I received my first DM from '.@discord['username'].'!  `'.@discord['userid'].'`'
		}
		discord_broadcast(@config['Log_Channel'], array('content': ':envelope_with_arrow:  '.@dm1, 'embeds': @msgembed))
	}
}