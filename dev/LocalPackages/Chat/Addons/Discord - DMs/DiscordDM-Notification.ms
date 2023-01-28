#version 1.0-tmc
bind('discord_private_message_received', array('id': 'Discord.Server.monitor.DMs'), null, @discord) {
array_set(@discord, 'time', time())
#Don't save or notify if this is a command message
#todo: pass to command handler
if(reg_count('^[.!~]?[Cc][Hh][!@#%*/.$,=]', @discord['message']) > 0) { die() }

@config = import('Chat.config.Discord')

if(reg_count('^[.!~]?[Cc][Hh][!@#%*/.$,=]', @discord['message']) > 0) {
	#Extract Command
	@cmd = parse_args(reg_replace('^[.!~]?[Cc][Hh][!@#%*/.$,=]', '', @discord['message']))
	#Setup Arguments
	if(array_index_exists(@cmd, 1)) {
		@cmdargs = @cmd[cslice(1, array_size(@cmd) - 1)]
	} else {
		@cmdargs = array()
	}
	if(array_index_exists(@cmdargs, 0)) {
		@cmddisargs = array_implode(@cmdargs, ' ')
		@cmddis1 = 'Args: '.color(9).@cmddisargs
		if(reg_count('[\\s\\S]{1,1900}', @cmddisargs) > 1) {
			@cmddis2 = 'Args: '.@cmddisargs[cslice(0, 1900)].' ...'
		} else { @cmddis2 = 'Args: '.@cmddisargs }
	} else { @cmddis1 = '' @cmddis2 = '' }
	console('[Discord] '.@discord['username'].' used command in DM: '.color(3).@cmd[0].'  '.color('r').@cmddis1, false)
	discord_broadcast(@config['Log_Channel'], @discord['username'].' used command in DM: '.@cmd[0].'  '.strip_colors(@cmddis2))
} else { 
#Save recent DMs for future reference if needed
	@DMs = get_value('server.Discord.DMs.received')
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
	broadcast(color(9).'A DM was sent to the Discord Bot from ['.color(7).@discord['username'].color(9).'] Message: \n'.color(7).@discord['message'], all_players())
	console('[Discord] A DM was sent to the Discord Bot from ['.@discord['username'].' ('.@discord['userid'].') ] Message: \n'.@discord['message'].'\n Attached: '.@discord['attachments'], false)
	# .@discord['username'].'\n'@discord['message']
	if(reg_count('[\\s\\S]{1,1920}', @discord['message']) > 1) {
		@discord['message'] = @discord['message'][cslice(0, 1910)].' ...'
	}
	 # 'footer': array('icon_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Twemoji_1f4e9.svg/240px-Twemoji_1f4e9.svg.png', 'text': 'received from '.@discord['username']))
	discord_broadcast(@config['Log_Channel'], array('content': ':envelope_with_arrow:  I received a DM!', 'embeds': array(array('color': array('r': 109, 'g': 109, 'b': 109), 'title': @discord['username'], 'description': @discord['message']))))
	if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
		@urls = array()
		foreach(@num: @attach in @discord['attachments']) {
			if(@config['URL_Broadcast'] == true) {
				broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], all_players())
			}
			array_push(@urls, array('name': 'URL #'.(@num + 1), 'value': @attach['url'], 'inline': false))
			# discord_broadcast(@config['Log_Channel'], array('content': 'URL #'.(@num + 1).': '.@attach['url']))
		}
		discord_broadcast(@config['Log_Channel'], array('embeds': array(array('fields': @urls, 'color': array('r': 0, 'g': 0, 'b': 255), 'thumbnail': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Breezeicons-places-32-folder-download.svg/32px-Breezeicons-places-32-folder-download.svg.png', 'description': 'File List', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/562310124006277148.webp', 'text': 'I am not responsible for the quality of these files.')))))
	}
}
}