#version 1.1-tmc

#Handle commands from Discord Users
# Data: userid, username, nickname, channel, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'Chat.Discord.cmd', 'priority': 'HIGH'), null, @discord) {
	@config = import('Chat.config.Discord')
# If channel is not authorized to send to, output to DM instead.	
	if(!array_contains(@config['CMD_Channels_Send'], @discord['channel'])) { @discord['channel'] = @discord['userid'] @ChannelType = 'dm' } else { @ChannelType = 'broadcast' }
	}
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) == true) {
		array_set(@discord, 'time', time())


			}
		} else {
	# Normal Message
		
		
	#Wish support here

		if(reg_count(@config['CMD_Command_Prefix'], @discord['message']) > 0) {
			consume()
			discord_delete_message(@discord['channel'], @discord['id'])
		# Action command, all message output is handled from there.
		/*	
		Returns:
		false = no command found or error. (See debug return)
		true = success
		notadmin
		nocmdgiven
		NotACmd
		*/
			@return = _chat_handlecommand(@discord, @ChannelType)
		}
	}
}