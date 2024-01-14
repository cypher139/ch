#Notify users of message Updates and reactions, and update bot message caches accordingly.
proc _db_update_message_cache(@discord, @updateType) {
	@botconfig = import('DiscordBot.config.Discord')
	@return = array()
	@invalidType = 'Message Cache update was given an invalid update type!'
	@loadBot = ''
	@loadBotUser = '.user'
	if(array_index_exists(@discord, 'channeltype')) {
		if(@discord['channeltype'] == 'TEXT') {
			array_remove(@discord, 'channeltype')
		}
	}
	if(@discord['bot'] == true) { @loadBot = '.bot' }
	#bug? if both last message and a user message loaded it will not actually export last message unless imported & cloned
	@lastServerMsgs = array_deep_clone(import('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot, array()))
	if(@discord['bot'] == true) { @loadBotUser = '.bot' }
	@lastUserMsgs = import('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBotUser.'.'.@discord['userid'], array())
	@userIndex = -12
	@serverIndex = -12
	@addSi = false
	@addUi = false
	@prevData = 'Not Found'
	#Find each index to edit
	foreach(@k: @message in @lastUserMsgs) {
		if(@message['id'] == @discord['id']) {
			@userIndex = @k
			break()
		}
	}
	foreach(@k2: @message2 in @lastServerMsgs) {
		if(@message2['id'] == @discord['id']) {
			@serverIndex = @k2
			break()
		}
	}
	# -- If index not found:
	if(@serverIndex < 0) {
		array_insert(@lastServerMsgs, @discord, 0)
		@serverIndex = 0
		@addSi = true
	}
	if(@userIndex < 0) {
		@isNewUser = import('DiscordBot.'.@discord['serverid'].'.new.user.'.@discord['userid'], false);
		@userDiscord = array_deep_clone(@discord)
		array_set(@userDiscord, 'newuser', @isNewUser)
		array_insert(@lastUserMsgs, @userDiscord, 0)
		@userIndex = 0
		@addUi = true
	}
#cache limiter
	if(array_index_exists(@lastServerMsgs, @botconfig['Msg_Cache_Server'])) { array_remove(@lastServerMsgs, @botconfig['Msg_Cache_Server']) }	
	if(array_index_exists(@lastUserMsgs, @botconfig['Msg_Cache_User'])) { array_remove(@lastUserMsgs, @botconfig['Msg_Cache_User']) }	
#edits
	@newData = array_deep_clone(@lastUserMsgs[@userIndex])
	switch(@updateType) {
	case 'edit':
		if(@addUi == false) { @prevData = @newData['message'] }
		@newData['message'] = @discord['message']
		if(!array_index_exists(@newData, 'edits')) { @newData['edits'] = 0 }
		@newData['edits']++
		@newData['edittime'] = time()
		array_set(@return, 'after', @newData['message'])
	case 'addreaction':
	case 'removereaction':
		if(@addUi == true || @addSi == true) { array_set(@newData, 'message', '') }
		# if reaction doesnt exist, add array Data
		if(array_index_exists(@newData, 'reactions')) { 
			@prevData = array_deep_clone(@newData['reactions'])
		} else {
			array_set(@newData, 'reactions', array()) 
		}
		if(!array_index_exists(@newData, 'reactions', @discord['emoji'])) { array_set(@newData['reactions'], @discord['emoji'], array()) }
		if(@updateType == 'addreaction') {
			@newData['reactions'][@discord['emoji']][] = @discord['userid']
		}			
		if(@updateType == 'removereaction') {
			array_remove_values(@newData['reactions'][@discord['emoji']], @discord['userid'])
			if(array_size(@newData['reactions'][@discord['emoji']]) == 0) {
				array_remove(@newData['reactions'], @discord['emoji'])
			}
		}
		array_set(@return, 'after', @newData['reactions'])
	default:
		_db_msg_Console(@invalidType, @discord['serverid'], 'debug')
		return(@return)
	}
	array_set(@lastUserMsgs, @userIndex, @newData)
	array_set(@lastServerMsgs, @serverIndex, @newData)
	export('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBot, @lastServerMsgs)
	export('DiscordBot.'.@discord['serverid'].'.last.message'.@loadBotUser.'.'.@discord['userid'], @lastUserMsgs)
	array_set(@return, 'ui', @userIndex)
	array_set(@return, 'si', @serverIndex)
	array_set(@return, 'before', @prevData)
return(@return)
}

bind('discord_message_updated', array('id': 'DiscordBot.Message.Update', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@time = time()
	array_set(@discord, 'time', @time);
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@userDisplay = _db_get_user_nick(@discord['userid'], @discord['serverid'], @discord['username'])
	@memberInfo = discord_member_info(@discord['serverid'], @discord['userid'])
	@embedColor = array('r': 0, 'g': 0, 'b': 200)
	#Message Formatting
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
			@filenum = 'File: '
			if(@num != 0) { @filenum = '  File #'.(@num + 1).': ' }
			@discord['message'] = @discord['message'].@filenum.@attach['filename']
		}
	}
# Update Recent Messages with current data	
	@saveMsg = _db_update_message_cache(@discord, 'edit')
# Remaining items are not relevant if event is consumed, or is a bot
	if(@discord['bot'] == true || is_consumed() == true) { die() }
# Find what changed, does not count added content
	@aSplit = parse_args(@saveMsg['after'])
	@bSplit = parse_args(@saveMsg['before'])
	if(array_size(@bSplit) == array_size(@aSplit)) {
		foreach(@i: @word in @aSplit) {
			if(@bSplit[@i] != @word) {
				@aSplit[@i] = color(11).@word.color('r')
			}
		}
	}
	@afterDisplay = array_implode(@aSplit, ' ')
# Send to Admin Logs
	_db_msg_Console(@userDisplay.'\'s Message Edit:  ui: '.@saveMsg['ui'].', si: '.@saveMsg['si'].'\n'.color(9).'B: '.color('r').@saveMsg['before'].'\n'.color(10).'A: '.color('r').@afterDisplay, @discord['serverid'], 'debug')
	if(@memberInfo['color'] != null) { @embedColor = @memberInfo['color'] }
	@logMsg = array('author': array('icon_url': @memberInfo['avatar'], 'name': @discord['username'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @discord['username'])),
	'title': 'Message Edited in <#'.@discord['channelid'].'>',
	'url': 'https://discordapp.com/channels/'.@discord['serverid'].'/'.@discord['channelid'].'/'.@discord['id'],
	'fields': array(array('name': 'Before', 'value': @saveMsg['before'], 'inline': false), array('name': 'After', 'value': @discord['message'], 'inline': false)),
	'footer': array('text': 'User ID: '.@discord['userid']),
	'color': @embedColor,
	'timestamp': time()
	)
	if(@saveMsg['before'] == 'Not Found') { array_remove(@logMsg['fields'], 0) }
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

bind('discord_reaction_added', array('id': 'DiscordBot.Message.React.Add', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	array_set(@discord, 'id', @discord['messageid'])
	_db_msg_Console(color(9).@discord['username'].color(10).' added '.color(7).'reaction <'.@discord['emoji'].'> to a message.', @discord['serverid'], 'debug')
	# Update Recent Messages with current data	
	@saveMsg = _db_update_message_cache(@discord, 'addreaction')
}

bind('discord_reaction_removed', array('id': 'DiscordBot.Message.React.Remove', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	array_set(@discord, 'id', @discord['messageid'])
	_db_msg_Console(color(9).@discord['username'].color(12).' removed '.color(7).'reaction <'.@discord['emoji'].'> to a message.', @discord['serverid'], 'debug')
	# Update Recent Messages with current data	
	@saveMsg = _db_update_message_cache(@discord, 'removereaction')
}
