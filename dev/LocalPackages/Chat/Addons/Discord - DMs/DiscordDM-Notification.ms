#version 1.1-tmc

export('server.Discord.DMs.user.settings', get_value('server.Discord.DMs.user.settings'));

bind('discord_private_message_received', array('id': 'Discord.Server.monitor.DMs'), null, @discord) {
	array_set(@discord, 'time', time())
#Don't save or notify if this is a command message
	@config = import('Chat.config.Discord')
	if(reg_count(@config['CMD_Command_Prefix'], @discord['message']) > 0) {
		array_set(@discord, 'channel', @discord['userid'])
		@return = _chat_handlecommand(@discord, 'dm', 'dm')
	} else { 
	# Save recent DMs for future reference if needed
		@DMs = get_value('server.Discord.DMs.received')
		@userConfig = import('server.Discord.DMs.user.settings')
		if(is_array(@userConfig)) {
			if(!array_index_exists(@userConfig, @discord['userid'])) {
				array_set(@userconfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
			}	
		} else {
			@userConfig = array()
			array_set(@userConfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
		}
		# Save recent DMs for future reference if needed
		if(!is_array(@DMs)) { @DMs = array(array('message': 'Start Of Message List')) }
		array_insert(@DMs, @discord, 0)
		if(array_index_exists(@DMs, 20)) { 
			_write_file(import('Chat.logs.dir').'/Discord-DMs-Received.txt', '\n'.@DMs[20], 'append')
			array_remove(@DMs, 20)
		}
		@userDMs = get_value('server.Discord.DMs.user.'.@discord['userid'])
		if(!is_array(@userDMs)) { @userDMs = array(array('message': 'Start Of Message List')) }
		array_insert(@userDMs, @discord, 0)
		if(array_index_exists(@userDMs, 20)) { 
			_write_file(import('Chat.logs.dir').'/Discord-DMs-User-'.@discord['userid'].'.txt', '\n'.@userDMs[20], 'append')
			array_remove(@userDMs, 20)
		}
		store_value('server.Discord.DMs.received', @DMs)
		store_value('server.Discord.DMs.user.'.@discord['userid'], @userDMs)
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
				if(@num == 0) { @filenum = 'File: ' } else { @filenum = '  File #'.(@num + 1).': ' }
				@discord['message'] = @discord['message'].@filenum.@attach['filename']
			}
		}
		#Send Dm notification to Minecraft
		if(@userConfig[@discord['userid']]['NotifyContent'] == true) {
			_chat_mc_broadcast(color(9).'A DM was sent to the Discord Bot from ['.color(7).@discord['username'].color(9).'] Message: \n'.color(7).@discord['message'])
		}
		console('[Discord] A DM was sent to the Discord Bot from ['.@discord['username'].' ('.@discord['userid'].') ] Message: \n'.@discord['message'].'\n Attached: '.@discord['attachments'], false)
		if(reg_count('[\\s\\S]{1,1920}', @discord['message']) > 1) {
			@discord['message'] = @discord['message'][cslice(0, 1910)].' ...'
		}
		
		@msgembed = array(array('title': @discord['username'], 'color': array('r': 109, 'g': 109, 'b': 109), 'description': @discord['message']))
		#Get Avatar
		@leaderboards = import('server.Discord.members.leaderboard');
		if(is_array(@leaderboards)) {
			if(array_index_exists(@leaderboards, 'members', @discord['userid'], 'avatar')) {
				array_set(@msgembed[0], 'author', array('icon_url': 'https://cdn.discordapp.com/avatars/'.@discord['userid'].'/'.@leaderboards['members'][@discord['userid']]['avatar'].'.webp?size=48', 'name': @discord['username']))
				array_remove(@msgembed[0], 'title')
			}
		}
		
		if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
			@urls = array()
			foreach(@num: @attach in @discord['attachments']) {
				if(@config['URL_Broadcast'] == true && @userConfig[@discord['userid']]['NotifyContent'] == true) {
					_chat_mc_broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'])
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
					console(@ex)
				}
			}
		}
		
	# Send Dm Notification to Discord logs
		if(@userConfig[@discord['userid']]['NotifyContent'] == false) {
			@msgembed[0]['description'] = '<This user\'s message content is not shown in DM notifications>'
		}
		if(@userDMs[1]['message'] == 'Start Of Message List') {
			@dm1 = 'I received my first DM from '.@discord['username'].'!  `'.@discord['userid'].'`'
		} else {
			@dm1 = 'I received a DM!'
		}
		discord_broadcast(@config['Log_Channel'], array('content': ':envelope_with_arrow:  '.@dm1, 'embeds': @msgembed))
	}
}