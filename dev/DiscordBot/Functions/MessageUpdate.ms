#Notify users of message Updates and reactions, and update bot message caches accordingly.
proc _db_update_message_cache(@discord, @updateType) {
	@return = array()
	@msgID = 0
	if(array_index_exists(@discord, 'id')) {
		@msgID = @discord['id']
	} else if(array_index_exists(@discord, 'messageid')) { 
		@msgID = @discord['messageid'] 
	} else { 
		return(false)
	}
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@userType = 'user'
	if(array_index_exists(@discord, 'channeltype')) {
		if(@discord['channeltype'] == 'TEXT') {
			array_remove(@discord, 'channeltype')
		}
	}
	if(@discord['bot'] == true) { @userType = 'bot' }
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array('messages': array(), 'bot': array(), 'user': array(), 'server': array()) }
	if(!array_index_exists(@cacheMsgs, @userType, @discord['userid'])) { array_set(@cacheMsgs[@userType], @discord['userid'], array()) }
	@addSi = false
	@addUi = false
	@prevData = 'Not Found'
	@newuser = _db_is_newmember(@discord['serverid'], @discord['userid']);
	#Find each index to edit
	@userIndex = array_index(@cacheMsgs[@userType][@discord['userid']], @msgID)
	@serverIndex = array_index(@cacheMsgs['server'], @msgID)
	if(!array_index_exists(@cacheMsgs, 'messages', @msgID)) {
		array_set(@cacheMsgs['messages'], @msgID, @discord)
	}
	# -- If index not found: Add message id to server/user indexes. -list for debug the index number
	if(@serverIndex < 0 || @serverIndex == null) {
		array_insert(@cacheMsgs['server'], @msgID, 0)
		@serverIndex = 0
		@addSi = true
	}
	if(@userIndex < 0 || @userIndex == null) {
		if(@discord['userid'] == @cacheMsgs['messages'][@msgID]['userid']) {
			array_insert(@cacheMsgs[@userType][@discord['userid']], @msgID, 0)
			@addUi = true
		}
		@userIndex = 0
	}
#cache limiter
	if(array_index_exists(@cacheMsgs['server'], @botconfig['Msg_Cache_Server'])) { array_remove(@cacheMsgs['server'], @botconfig['Msg_Cache_Server']) }	
	if(array_index_exists(@cacheMsgs[@userType][@discord['userid']], @botconfig['Msg_Cache_User']) && @newuser == false) { array_remove(@cacheMsgs[@userType][@discord['userid']], @botconfig['Msg_Cache_User']) }	
#edits
	@newData = array_deep_clone(@cacheMsgs['messages'][@msgID])
	switch(@updateType) {
	case 'edit':
		if(@addUi == false) { @prevData = @newData['message'] }
		if(@discord['userid'] != @newData['userid']) {
			@newData['userid'] = @discord['userid']
			@newData['username'] = @discord['username']
			array_insert(@cacheMsgs[@userType][@discord['userid']], @msgID, 0)
		}
		@newData['message'] = @discord['message']
		if(!array_index_exists(@newData, 'edits')) { @newData['edits'] = 0 }
		@newData['edits']++
		@newData['edittime'] = time()
		array_set(@return, 'after', @newData['message'])
	case 'addreaction':
	case 'removereaction':
		if(@addUi == true || @addSi == true) { if(!array_index_exists(@newData, 'message')) { array_set(@newData, 'message', '') }}
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
		_db_msg_Console('Message Cache update was given an invalid update type!', @discord['serverid'], 'debug')
		return(@return)
	}
	array_set(@cacheMsgs['messages'], @msgID, @newData)
	export('DiscordBot.'.@discord['serverid'].'.Cache.Messages', @cacheMsgs)
	array_set(@return, 'ui', @userIndex)
	array_set(@return, 'si', @serverIndex)
	array_set(@return, 'addui', @addUi)
	array_set(@return, 'addsi', @addSi)
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
	@addUi = ''
	@addSi = ''
	if(@saveMsg['addui'] == true) { @addUi = color(10).'+'.color('r') }
	if(@saveMsg['addsi'] == true) { @addSi = color(10).'+'.color('r') }
	_db_msg_Console(@userDisplay.'\'s Message Edit:  ['.@addUi.'ui: '.@saveMsg['ui'].'  '.@addSi.'si: '.@saveMsg['si'].']\n'.color(9).'B: '.color('r').@saveMsg['before'].'\n'.color(10).'A: '.color('r').@afterDisplay, @discord['serverid'], 'debug')
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
				case 40..50:
				case 69:
					@sendReply = true
				}
			}
			if(@sendReply == true) {
				_discordBot_send_message(array('reference_id': @discord['id'], 'content': @config['Reply_Message_Edit_Users'][@index]), @discord['serverid'], 'none', @discord['channel'])
			}
		}
	}
#check for command
	@isCmd = false
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) == true) {
		@isCmd = _discordBot_iscommand(@discord)
	}
	# Action command, all message output is handled from there.
	if(@isCmd == true) {
		consume();
		array_set(@discord, 'time', time())
		@isMention = _discordBot_ismention(@discord)
		if(@isMention == true) { @isMention = 'mention' }
		@return = _discordBot_handlecommand(@discord, 'edit', @isMention)
	}
}


bind('discord_reaction_added', array('id': 'DiscordBot.Message.React.Add', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	array_set(@discord, 'time', time());
	# Update Recent Messages with current data
	@saveMsg = _db_update_message_cache(@discord, 'addreaction')
	@addindex = ''
	if(@saveMsg['addui'] == true) { @addindex = color(10).'+ui'.color('r') }
	if(@saveMsg['addsi'] == true) { @addindex = @addindex.color(10).'+si'.color('r') }
	#Send to Admin Logs
	_db_msg_Console(color(9).@discord['username'].color(10).' added '.color(7).'reaction <'.@discord['emoji'].'> to a message. '.@addindex, @discord['serverid'], 'debug')
}

bind('discord_reaction_removed', array('id': 'DiscordBot.Message.React.Remove', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	array_set(@discord, 'time', time());
	
	# Update Recent Messages with current data
	@saveMsg = _db_update_message_cache(@discord, 'removereaction')
	@addindex = ''
	if(@saveMsg['addui'] == true) { @addindex = color(10).'+ui'.color('r') }
	if(@saveMsg['addsi'] == true) { @addindex = @addindex.color(10).'+si'.color('r') }
	#Send to Admin Logs
	_db_msg_Console(color(9).@discord['username'].color(12).' removed '.color(7).'reaction <'.@discord['emoji'].'> to a message. '.@addindex, @discord['serverid'], 'debug')
}
