#version 1.1-tmc
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
# DM commands
bind('discord_private_message_received', array('id': 'DiscordBot.CMD.DMs', 'priority': 'HIGH'), null, @discord) {
	array_set(@discord, 'time', time())
	@botconfig = import('DiscordBot.config.Discord')
	@saveDM = array_deep_clone(@discord)
	@guildcfgNotify = array()
	@guildcfgCmd = array()
	@guildcfgChannel = array()
	@guildcfgURL = array()
	@userserver = 0
	@userServers = array()
	@avatar = 'https://cdn.discordapp.com/embed/avatars/0.png'
	@gf = 0
	foreach(@guild in import('DiscordBot.Guilds')) {
		@cfg = import('DiscordBot.config.'.@guild)
		if(@cfg['DM_Notify'] == true) {	array_push(@guildcfgNotify, @guild) }
		array_set(@guildcfgCmd, @guild, @cfg['CMD_Command_Prefix']);
		array_set(@guildcfgChannel, @guild, @cfg['Log_Channel']);
		array_set(@guildcfgURL, @guild, @cfg['URL_Broadcast']);
		if(array_contains(discord_get_members(@guild), @discord['userid'])) {
			@userServers[] = @guild
			@gf++
			@userserver = @guild
			if(@gf < 2) {
				@avatar = discord_member_info(@guild, @discord['userid'])['avatar']
			}
		}
	}

#Command check
	@isCmd = false
	# Check for each server's Command prefix
	foreach(@serverid: @cmdprefix in @guildcfgCmd) {
		if(reg_count(@cmdprefix, @discord['message']) > 0 && array_contains(@userServers, @serverid)) {
			@isCmd = true
			@userserver = @serverid
			break()
		} 
	}
	# Prefix not found, check for first word matches a command name
	if(@isCmd == false) {
		@cmdList = import('DiscordBot.Command.List.Name')
		@check = parse_args(@discord['message'])
		if(is_array(@cmdList) && array_size(@check) > 0) {
			if(array_index_exists(@cmdList, to_lower(@check[0]))) {
				@isCmd = true
			}
		}
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