# Handle commands from Discord Users
# Precompile command actions, made available for only these binds:
include_dir('../command.library')
_discordBot_init_cmd_list()
# Servers commands
bind('discord_message_received', array('id': 'DiscordBot.CMD.Servers', 'priority': 'HIGH'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@botinfo = import('DiscordBot.Bot.Info')
	@isCmd = false
	@isMention = ''

# If channel is not authorized to send to, output to DM instead.
	if(!array_contains(@config['CMD_Channels_Send'], @discord['channel'])) { @discord['channel'] = @discord['userid'] @ChannelType = 'dm' } else { @ChannelType = 'broadcast' }

# Command in approved channels:
# Mentions, via batch, or server's set prefix
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) == true) {
		export('DiscordBot.'.@discord['serverid'].'.CacheUpdate', true)
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
	
		@isCmd = _discordBot_iscommand(@discord)
		@isMention = _discordBot_ismention(@discord)
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
		if(@isMention == true) { @isMention = 'mention' }
		@return = _discordBot_handlecommand(@discord, @ChannelType, @isMention)
	}
}
# DM commands
bind('discord_private_message_received', array('id': 'DiscordBot.CMD.DMs', 'priority': 'HIGH'), null, @discord) {
	array_set(@discord, 'time', time())
	array_set(@discord, 'UseDM', 'dm')
	@botconfig = import('DiscordBot.config.Discord')
	@guilds = import('DiscordBot.Guilds')
	@userserver = 0
	@userServers = array()
# Default server ID to send
	foreach(@guild in @guilds) {
		if(array_contains(discord_get_members(@guild), @discord['userid'])) {
			@userServers[] = @guild
			@userserver = @guild
		}
	}
#Command check
	@isCmd = _discordBot_iscommand(@discord, 'id')
	if(!is_boolean(@isCmd)) {
		@userserver = @isCmd
		@isCmd = true
	}

	if(@isCmd == true) {
		consume();
		array_set(@discord, 'channel', @discord['userid']);
		array_set(@discord, 'serverid', @userserver);
		array_set(@discord, 'nickname', @discord['displayname']);
		@return = _discordBot_handlecommand(@discord, 'dm', 'dm')
		return(@return)
	}
}