#Notify users of message Updates and reactions, and update bot message caches accordingly.
proc _db_update_message_cache(@discord, @updateType, @isaction) {
	@return = array()
	@msgID = 0
	@msgUserID = @discord['userid']
	if(array_index_exists(@discord, 'messageuserid')) { @msgUserID = @discord['messageuserid'] }
	@userType = 'user'
	if(!array_index_exists(@discord, 'webhook')) { array_set(@discord, 'webhook', false) }
	if(array_index_exists(@discord, 'id')) {
		@msgID = @discord['id']
	} else if(array_index_exists(@discord, 'messageid')) { 
		@msgID = @discord['messageid']
		array_set(@discord, 'id', @discord['messageid'])
	} else { 
		return(false)
	}
	@idtime = rshift(@discord['id'], 22) + 1420070400000
	@time = time()
	@diff = @time - @idtime
	if(@diff > 2000 && @isaction != true) { console('updproc: '.@discord) }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	if(array_index_exists(@discord, 'channeltype')) {
		if(@discord['channeltype'] == 'TEXT') {
			array_remove(@discord, 'channeltype')
		}
	}
# Message: is from user or bot?
	@msgUserisBot = false
	try {
		@msgUserisBot = discord_member_info(@discord['serverid'], @msgUserID)['bot']
	} catch(NotFoundException @ex) {
		#try to find if a webhook. if such found continue
		@kw = import('DiscordBot.webhooks.list', array(array(), array()))
		if(array_contains(@kw[0], @msgUserID)) {
			@msgUserisBot = true
		} else {
			@checkwebhook = _discordBot_iswebhook(@msgUserID);
		}
	}
#Setup User message entry
	if(@discord['bot'] == true || @discord['webhook'] == true || @msgUserisBot == true) { @userType = 'bot' }
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array('messages': array(), 'bot': array(), 'user': array(), 'server': array()) }
	if(!array_index_exists(@cacheMsgs, @userType, @msgUserID)) { console(1) array_set(@cacheMsgs[@userType], @msgUserID, array()) }
	@addSi = false
	@addUi = false
	@prevData = 'Not Found'
#Find each index to edit
	@userIndex = array_index(@cacheMsgs[@userType][@msgUserID], @msgID)
	@serverIndex = array_index(@cacheMsgs['server'], @msgID)
	if(!array_index_exists(@cacheMsgs, 'messages', @msgID)) {
		array_set(@cacheMsgs['messages'], @msgID, @discord)
		if(array_index_exists(@discord, 'messageuserid')) {
			@cacheMsgs['messages'][@msgID]['userid'] = @discord['messageuserid']
		}
	}
	# -- If index not found: Add message id to server/user indexes. -list for debug the index number
	if(@serverIndex < 0 || @serverIndex == null) {
		array_insert(@cacheMsgs['server'], @msgID, 0)
		@serverIndex = 0
		@addSi = true
	}
	if(@userIndex < 0 || @userIndex == null) {
		# if(@discord['userid'] == @cacheMsgs['messages'][@msgID]['userid'] && @updateType != 'removereaction') {
		if(!array_index_exists(@cacheMsgs, @userType, @msgUserID, @msgID) && @updateType != 'removereaction') {
			array_insert(@cacheMsgs[@userType][@msgUserID], @msgID, 0)
			@addUi = true
		}
		@userIndex = 0
	}
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
			if(array_size(@newData['reactions'][@discord['emoji']]) <= 0) {
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
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	@idtime = rshift(@discord['id'], 22) + 1420070400000
	@time = time()
	@diff = @time - @idtime
	array_set(@discord, 'time', @time);
	@userType = 'User'
	if(@discord['bot']) { @userType = 'Bot' }
	if(@discord['webhook']) { @userType = 'Webhook' }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@userDisplay = _db_get_user_nick(@discord['userid'], @discord['serverid'], @discord['username'])
	@embedColor = array('r': 0, 'g': 0, 'b': 200)
	@memberInfo = array('color': @embedColor, 'avatar': 'https://cdn.discordapp.com/embed/avatars/0.png')
	if(@discord['webhook'] == true) {
		@iswebhook = _discordBot_iswebhook(@discord['userid']);
		@kwdata = import('DiscordBot.webhooks.data', array());
		if(array_index_exists(@kwdata, @discord['userid'])) {
			@memberInfo = @kwdata[@discord['userid']]
		}
	} else {
		try {
			@memberInfo = discord_member_info(@discord['serverid'], @discord['userid'])
		} catch(NotFoundException @ex) {
			#but how, you ask can a user update a message while also NOT part of your server? answer: Discord system messages.
			_db_msg_Console('Message Update from '.@discord['username'].' <'.@discord['userid'].'>: User not Found on server. Channel: '.@discord['channel'].' | Message: ('.@discord['id'].')\n'.@discord['message'], @discord['serverid'], 'debug')
			discord_request('GET', 'channels/'.@discord['channelid'].'/messages/'.@discord['id'], null, closure(@ex) {
				@debugupd8 = import('DiscordBot.debug.msg.update.nouser.msgs', array())
				@debugupd8[] = @ex
				export('DiscordBot.debug.msg.update.nouser.msgs', @debugupd8)
				console('Message: \n'.@ex) },
			closure(@ex) { console('get message: \n'.@ex) });
		}
	}
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
# Remaining items are not relevant if event is consumed.
	if(is_consumed()) { die() }
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
	@userDisplayType = ''
	if(@discord['bot']) { @userDisplayType = color(3).' (Bot)' }
	if(@discord['webhook']) { @userDisplayType = color(5).' (Webhook)' }
	if(@saveMsg['before'] != @saveMsg['after']) {
		if(@diff > 2000) {
			_db_msg_Console(color(9).@userDisplay.@userDisplayType.color(7).'  Message Edit:  ['.@addUi.'ui: '.@saveMsg['ui'].'  '.@addSi.'si: '.@saveMsg['si'].']\n'.color(9).'B: '.color('r').@saveMsg['before'].'\n'.color(10).'A: '.color('r').@afterDisplay, @discord['serverid'], 'debug')
		}
	} else if(@diff < 2000) {
		_db_msg_Console(color(9).@userDisplay.@userDisplayType.color(7).' Message embed? updated within '.color(12).@diff.'ms'.color(7).' of post'.'  ['.@discord['channel'].'  '.@addUi.'ui: '.@saveMsg['ui'].'  '.@addSi.'si: '.@saveMsg['si'].']', @discord['serverid'], 'debug')
	}
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
		@logbot = false
		if(array_index_exists(@config, 'Log_Message_Edit_Bot')) { @logbot = @config['Log_Message_Edit_Bot'] }
		if(@userType != 'User' && @logbot != true) { die() }
		_discordBot_broadcast(@discord['serverid'], '--log', array('embeds': array(@logMsg)));
	}
#Reply message to User
	if(@config['Reply_Message_Edit'] == true && @userType == 'User' && @diff > 2000) {
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
				_discordBot_broadcast(@discord['serverid'], @discord['channel'], array('reference_id': @discord['id'], 'content': @config['Reply_Message_Edit_Users'][@index]));
			}
		}
	}
#check for command
	@isCmd = false
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) || array_contains(@config['CMD_Channels_Receive'], @discord['channelid'])) {
		@isCmd = _discordBot_iscommand(@discord)
	}
	# Action command, all message output is handled from there.
	if(@isCmd == true) {
		if(@userType == 'User') {
			consume();
			array_set(@discord, 'time', time())
			@isMention = _discordBot_ismention(@discord)
			if(@isMention == true) { @isMention = 'mention' }
			@return = _discordBot_handlecommand(@discord, 'edit', @isMention)
		} else {
			@botcolor = 15
			if(@userType == 'Bot') { @botcolor = 3 }
			if(@userType == 'Webhook') { @botcolor = 5 }
			_db_msg_Console(color(@botcolor).@userType.': '.color(9).@userDisplay.color(7).' tried using one of my commands!', @discord['serverid'])
		}
	}
}


bind('discord_reaction_added', array('id': 'DiscordBot.Message.React.Add', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	#Check: Ignore sending messages about Ping log emoji use
	@isIPemoji = false
	@logChannel = ''
	if(array_index_exists(@config, 'Channels', 'Ping_Log')) { @logChannel = @config['Channels']['Ping_Log'] } else { @logChannel = @config['Channels']['Log'] }
	if(@discord['messageuserid'] == @botconfig['Bot_ID']) {
		if(@discord['channelid'] == @logChannel || @discord['channel'] == @logChannel) {
			if(array_index_exists(@config, 'Reaction_Actions', @discord['emoji'])) { 
				@isIPemoji = true
			} else if(array_index_exists(@config, 'Reaction_Actions', reg_replace('[0-9]', '', @discord['emoji']))) {
				@isIPemoji = true
			}
		}
	}
	# if(@isIPemoji == false) { console('bind-ra:'.@discord) }
	array_set(@discord, 'time', time());
	# Update Recent Messages with current data
	@saveMsg = _db_update_message_cache(@discord, 'addreaction', @isIPemoji)
	if(@isIPemoji == true) { die() }
	@addindex = ''
	if(@saveMsg['addui'] == true) { @addindex = color(10).'+ui'.color('r') }
	if(@saveMsg['addsi'] == true) { @addindex .= color(10).'+si'.color('r') }
	#Send to Admin Logs
	_db_msg_Console(color(9).@discord['username'].color(10).' added '.color(7).'reaction <'.@discord['emoji'].'> to a message in '.@discord['channel'].'  '.@addindex, @discord['serverid'], 'debug')
}

bind('discord_reaction_removed', array('id': 'DiscordBot.Message.React.Remove', 'priority': 'MONITOR'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@isIPemoji = false
	@logChannel = ''
	if(array_index_exists(@config, 'Channels', 'Ping_Log')) { @logChannel = @config['Channels']['Ping_Log'] } else { @logChannel = @config['Channels']['Log'] }
	#Due to discord stuff reaction removed can't have messageuserid given without extra work, use cache as workaround:
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages')
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array('messages': array(), 'bot': array(), 'user': array(), 'server': array()) }
	if(array_index_exists(@cacheMsgs, 'messages', @discord['messageid'])) {
		if(@cacheMsgs['messages'][@discord['messageid']]['userid'] == @botconfig['Bot_ID']) {
			if(@discord['channelid'] == @logChannel || @discord['channel'] == @logChannel) {
				if(array_index_exists(@config, 'Reaction_Actions', @discord['emoji'])) { 
					@isIPemoji = true
				} else if(array_index_exists(@config, 'Reaction_Actions', reg_replace('[0-9]', '', @discord['emoji']))) {
					@isIPemoji = true
				}
			}
		}
	}
	array_set(@discord, 'time', time());
	# Update Recent Messages with current data
	@saveMsg = _db_update_message_cache(@discord, 'removereaction', @isIPemoji)
	if(@isIPemoji == true) { die() }
	@addindex = ''
	if(@saveMsg['addui'] == true) { @addindex = color(10).'+ui'.color('r') }
	if(@saveMsg['addsi'] == true) { @addindex .= color(10).'+si'.color('r') }
	#Send to Admin Logs
	_db_msg_Console(color(9).@discord['username'].color(12).' removed '.color(7).'reaction <'.@discord['emoji'].'> to a message in '.@discord['channel'].'  '.@addindex, @discord['serverid'], 'debug')
}
