#version 0.9-tmc

@k7Gjli1 = ''
try {
	@k7Gjli1 = yml_decode(read(import('Chat.config.dir').'/Discord_CrossServer_config.yml'))
} catch(IOException @ex) {
	_msgAdmins('[Chat - Discord] CS Config file could not be read. '.@ex['message'])
	die()
} catch(FormatException @ex) {
	_msgAdmins('[Chat - Discord] CS Config file is improperly formatted.') 
	die()
}
	if(array_contains(@k7Gjli1['Server_1_Channels'], 'default')) {
		_msgAdmins('[Chat - Discord] CS Config file is still using default values. Please configure it in order to use Cross-Server chat features.') 
		die()
	}
export('Chat.config.Discord.CS', @k7Gjli1)

#Send Discord User message to Minecraft Players.
bind('discord_message_received', array('id': 'Chat.Discord.Cross-Server'), null, @discord) {
	@config = import('Chat.config.Discord')
	@configCS = import('Chat.config.Discord.CS')
	#Setup list of server members for reference in mentions
	@membersID = get_value('server.Discord.members.ID')
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('server.Discord.members.ID', @membersID)
	}
	@membersnames = get_value('server.Discord.members.names')
	if(!array_contains(@membersnames, @discord['userid'])) {
		array_set(@membersnames, @discord['username'], @discord['userid'])
		store_value('server.Discord.members.names', @membersnames)
	}

	if(reg_count('^[!@#%*/.$,=~]?[Cc][Hh][!@#%*/.$,=~]', @discord['message']) > 0) { die() }

#Find if in server 1 channel or server 2 channel
#broadcast content to opposite, embed (from: user)
#userroles color: color embed
	if(array_contains(@configCS['Server_1_Channels'], @discord['channel'])) { @server1 = true } else { @server1 = false } 
	if(array_contains(@configCS['Server_2_Channels'], @discord['channel'])) { @server2 = true } else { @server2 = false } 
	console(@server1.' <> '.@server2)

	if(xor(@server1, @server2) == true) {
		array_set(@discord, 'time', time())
		if(@server1 == true) {
			@channel = @configCS['Server_2_Channels_Send']
		} else {
			@channel = @configCS['Server_1_Channels_Send']
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
				if(@num == 0) { @filenum = 'File: ' } else { @filenum = '  File #'.(@num + 1).': ' }
				@discord['message'] = @discord['message'].@filenum.@attach['filename']
			}
		}
	#Save Recent Messages for reference	
	if(reg_count('^[!~]?[Cc][Hh][!@#%*/.$,=]', @discord['message']) == 0) {
		@lastmsgs = import('Chat.Discord.CS.last.message')
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		array_insert(@lastmsgs, @discord, 0)
		if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
		export('Chat.Discord.CS.last.message', @lastmsgs)
	}	
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
	#Set username color based on data previously set from Discord colors
	#keys system gives roles alphabetically, not server's order
		@usernamecolor = 3
		@isAdmin = false
		foreach(@role in @userroles) {
			if(array_contains_ic(@config['Role_Admins'], @role)) {
				@isAdmin = true
				break()
			}
		}
		foreach(@role in @userroles) {
			if(array_contains_ic(array_keys(@config['Role_Colors']), @role)) {
				#admin colors: ensure an admin role gets picked for color
				if(@isAdmin == true && !array_contains_ic(@config['Role_Admins'], @role)) {
					continue()
				}		
				@usernamecolor = '#'.@config['Role_Colors'][@role]
				#Only go with first role found
				break()
			}
		}
	#Send
	# Remove mention of all user pings entirely
	foreach(@entry in @config['Banned_Pings']) {
		@discord['message'] = reg_replace(@entry, '', @discord['message'])
	}
		@sendarray = array('content': @discord['message'], 'embeds': array(array('color': _hex_to_rgb(@usernamecolor), 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': 'Chat from '.@discord['username']))))
 # array('content': @discord['message'], 'embeds': array(array('color': _hex_to_rgb(@usernamecolor), 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': @discord['username']))))
#send file links
		if(array_index_exists(@discord, 'attachments', 0, 'filename') && @configCS['URL_Broadcast'] == true) {
			@urls = array()
			foreach(@num: @attach in @discord['attachments']) {
				array_push(@urls, array('name': 'URL #'.(@num + 1), 'value': @attach['url'], 'inline': false))
				# discord_broadcast(@adminChannel, array('content': 'URL #'.(@num + 1).': '.@attach['url']))
			}
			array_set(@sendarray['embeds'][0], 'fields', @urls)
		}
		
		
		
		_send_discord_message(@sendarray, 'cross', @channel)
	}
}