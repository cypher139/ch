#version 1.1-tmc

#Handle commands from Discord Users
# Data: userid, username, nickname, channel, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'DiscordBot.cmd', 'priority': 'HIGH'), null, @discord) {
	array_set(@discord, 'guild', import('DiscordBot.server.ID'))
	if(!array_contains(import('DiscordBot.Guilds'), @discord['guild'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['guild'])

# If channel is not authorized to send to, output to DM instead.	
	if(!array_contains(@config['CMD_Channels_Send'], @discord['channel'])) { @discord['channel'] = @discord['userid'] @ChannelType = 'dm' } else { @ChannelType = 'broadcast' }
#############	
	# PSAs

#######	
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) == true) {
		array_set(@discord, 'time', time())
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
							console('[Chat - Discord] Processing Batch file failed: '.@data)
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

		if(reg_count(@config['CMD_Command_Prefix'], @discord['message']) > 0) {
			consume()
			try { 
				discord_delete_message(@discord['channel'], @discord['id'])
			} catch(Exception @ex) {
				console('Another bot running?')
			}
		# Action command, all message output is handled from there.
		/*	
		Returns:
		false = no command found or error. (See debug return)
		true = success
		notadmin
		nocmdgiven
		NotACmd
		*/
			@return = _discordBot_handlecommand(@discord, @ChannelType)
		}
	}
}