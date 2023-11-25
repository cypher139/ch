bind('discord_message_updated', array('id': 'DiscordBot.Message.Update', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@time = time()
	array_set(@discord, 'time', @time);
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@userDisplay = _db_get_user_nick(@discord['userid'], @discord['serverid'], @discord['username'])
	@memberInfo = discord_member_info(@discord['serverid'], @discord['userid'])
#Save Recent Messages for reference	
	@loadBot = ''
	@loadBotUser = '.user'
	if(array_index_exists(@discord, 'channeltype')) {
		if(@discord['channeltype'] == 'TEXT') {
			array_remove(@discord, 'channeltype')
		}
	}
	# Server's last 50 messages
	if(@discord['bot'] == true) { @loadBot = '.bot' }
	#bug? if both last message and a user message loaded it will not actually export last message unless imported & cloned
	@lastServerMsgs = array_deep_clone(import('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot, array()))
	# User's last 30 messages
	if(@discord['bot'] == true) { @loadBotUser = '.bot' }
	@lastUserMsgs = import('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBotUser.'.'.@discord['userid'], array())
	@index = null
	@sindex = null
	@beforemsg = 'Not Found'
	foreach(@k: @message in @lastUserMsgs) {
		if(@message['id'] == @discord['id']) {
			@index = @k
			@beforemsg = @message['message']
			@lastUserMsgs[@k]['message'] = @discord['message']
			if(!array_index_exists(@lastUserMsgs, @k, 'edits')) { @lastUserMsgs[@k]['edits'] = 0 }
			@lastUserMsgs[@k]['edits']++
			@lastUserMsgs[@k]['edittime'] = @time
			break()
		}
	}
	foreach(@k: @message2 in @lastServerMsgs) {
		if(@message2['id'] == @discord['id']) {
			@sindex = @k
			@beforemsg = @message2['message']
			@lastServerMsgs[@k]['message'] = @discord['message']
			if(!array_index_exists(@lastServerMsgs, @k, 'edits')) { @lastServerMsgs[@k]['edits'] = 0 }
			@lastServerMsgs[@k]['edits']++
			@lastServerMsgs[@k]['edittime'] = @time
			# console(4)
			break()
		}
	}

	export('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot, @lastServerMsgs)
	export('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBotUser.'.'.@discord['userid'], @lastUserMsgs)

# Remaining items are not relevant if event is consumed, or is a bot
	if(@discord['bot'] == true || is_consumed() == true) { die() }
	if(@beforemsg == 'Not Found') { die(@beforemsg) }
	_db_msg_Console(@userDisplay.'\'s Message Edit:  ui: '.@index.', si: '.@sindex.'\nBefore: '.@beforemsg.'\nAfter: '.@lastUserMsgs[@index]['message'], @discord['serverid'], 'debug')
	@msgColor = array('r': 0, 'g': 0, 'b': 200)
	if(@memberInfo['color'] != null) { @msgColor = @memberInfo['color'] }
#Send to Admin Logs	
	@logMsg = array('author': array('icon_url': @memberInfo['avatar'], 'name': @discord['username'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @discord['username'])),
	'title': 'Message Edited in <#'.@discord['channelid'].'>',
	'url': 'https://discordapp.com/channels/'.@discord['serverid'].'/'.@discord['channelid'].'/'.@discord['id'],
	'fields': array(array('name': 'Before', 'value': @beforemsg, 'inline': false), array('name': 'After', 'value': @lastUserMsgs[@index]['message'], 'inline': false)),
	'footer': array('text': 'User ID: '.@discord['userid']),
	'color': @msgColor,
	'timestamp': time()
	)
	if(@config['Log_Message_Edit'] == true) {
		_discordBot_send_message(array('embeds': array(@logMsg)), @discord['serverid'], 'log')
	}
#Reply message to User
	if(@config['Reply_Message_Edit'] == true) {
		if(!is_associative(@config['Reply_Message_Edit_Users'])) { _db_msg_Console('Config "Reply_Message_Edit_Users" is not formatted properly, use format username: message', @discord['serverid'], 'error') die() }
		if(array_index_exists(@config, 'Reply_Message_Edit_Users', @discord['username']) || array_index_exists(@config, 'Reply_Message_Edit_Users', @discord['userid'])) {
			@sendReply = true
			@index = @discord['username']
			if(!array_index_exists(@config, 'Reply_Message_Edit_Users', @discord['username'])) { @index = @discord['userid'] }
			if(@config['Reply_Message_Edit_Users'][@index] == '' || @config['Reply_Message_Edit_Users'][@index] == null) {
				@config['Reply_Message_Edit_Users'][@index] = 'Thanks for that message edit!'
			}
			if(array_index_exists(@config, 'Reply_Message_Edit_Random')) {
				@sendReply = false
				if(!is_numeric(@config['Reply_Message_Edit_Random'])) { @config['Reply_Message_Edit_Random'] = 20 }
				switch(rand(1, @config['Reply_Message_Edit_Random'])) {
				case 4:
				case 10:
				case 50:
				case 40..49:
				case 69:
					@sendReply = true
				}
			}
			if(@sendReply == true) {
				_discordBot_send_message(array('reference_id': @discord['id'], 'content': @config['Reply_Message_Edit_Users'][@index]), @discord['serverid'], 'none', @discord['channel'])
			}
		}
	}
}
