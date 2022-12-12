#version 1.0-tmc
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
	broadcast(color(9).'A DM was sent to the Discord Bot from ['.color(7).@discord['username'].color(9).'] Message: \n'.color(7).@discord['message'], all_players())
	console('A DM was sent to the Discord Bot from ['.@discord['username'].' ('.@discord['userid'].') ] Message: \n'.@discord['message'].'\n Attached: '.@discord['attachments'], false)

	if(array_index_exists(@discord, 'attachments', 0, 'filename') && import('Chat.Discord.Broadcast.URLs') == true) {
		foreach(@num: @attach in @discord['attachments']) {
			broadcast(color(8).'URL #'.(@num + 1).': '.@attach['url'], all_players())
		}
	}
}