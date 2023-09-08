#version 1.1-tmc
#Handle commands from Discord Users
# Data: userid, username, nickname, channel, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'DiscordBot.cmd', 'priority': 'HIGH'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@botinfo = import('DiscordBot.Bot.Info')
	@isCmd = false
	@isMention = ''
	@delmsg = true

# If channel is not authorized to send to, output to DM instead.
	if(!array_contains(@config['CMD_Channels_Send'], @discord['channel'])) { @discord['channel'] = @discord['userid'] @ChannelType = 'dm' } else { @ChannelType = 'broadcast' }

# Command in approved channels:
# Mentions, via batch, or server's set prefix
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) == true) {
	# Attachment: batch
	/* cut
		if(array_index_exists(@discord, 'attachments', 0, 'filename')) {
			@returns = array()
			foreach(@i: @attach in @discord['attachments']) {
				if(reg_count('[.][Tt][Xx][Tt]$', @attach['filename']) > 0) {
					#istxt
					#make http call
					# variables scoped, does not provide edits back.
					http_request(@attach['url'], array('blocking': true, 'success': closure(@data) {
						export('debug_data_'.@i, @data);
						if(@data['error'] == false) {
						#is first line approved batch #!Chat_Command_Batch
						
						# CMD_Default_Channel for broadcast option
						
							if(reg_count('^#!Chat_Command_Batch', @data['body']) > 0) {
								@commands = reg_split('\r?\n', @data['body'])
								@commands[0] = reg_replace('^#!Chat_Command_Batch', '', @commands[0])
								# send to proc
								@return = _discordBot_process_batchfile(@commands, @discord, @ChannelType)
							}
						} else {
							_db_msg_Console('Processing Batch file failed: '.@data, @discord['serverid'])
						}
					}));

	# return array of returns?

	# returns array:
					# error: false, reponseCode: 200, responseText: OK, body: all attachment file's lines
					# variables scoped, does not provide edits back.
					# crashes server if closure returns commands
					
				}
			}
		} else {
		*/
	# Normal Message
		
		
	#Wish support here
	# Prefix:
		if(reg_count(@config['CMD_Command_Prefix'], @discord['message']) > 0) {
			@isCmd = true
		}
	# Mentions:
		if(reg_count('^[@]'.@botconfig['Bot_Name'].'\\s', @discord['message']) > 0) {
			@isCmd = true
			@isMention = 'mention'
		}
		if(reg_count('^[@]'.@botinfo['displayname'].'\\s', @discord['message']) > 0) {
			@isCmd = true
			@isMention = 'mention'
		}
	}
	
	# Action command, all message output is handled from there.
	if(@isCmd == true) {
		consume();
		array_set(@discord, 'time', time())
		/*	
		Returns:
		false = no command found or error. (See debug return)
		true = success
		NotAdmin
		NoCmdGiven
		NotACmd
		*/
		@return = _discordBot_handlecommand(@discord, @ChannelType, @isMention)
			
		if(@delmsg == true && string(@return) != 'NotACmd') {
			try { 
				discord_delete_message(@discord['serverid'], @discord['channel'], @discord['id'])
			} catch(Exception @ex) {
				_db_msg_Console('Could not delete command message, Another bot running?', @discord['serverid'])
			}
		}
	}
}