# Handle commands from Discord Users
# Precompile command actions, made available for only these binds:
include_dir('../command.library')
_discordBot_init_cmd_list()
# Servers commands
bind('discord_message_received', array('id': 'DiscordBot.CMD.Servers', 'priority': 'HIGH'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@botinfo = import('DiscordBot.Bot.Info')
	@isCmd = false
	@isMention = ''
	@userType = 'User'
	if(@discord['bot']) { @userType = 'Bot' }
	if(@discord['webhook']) { @userType = 'Webhook' }
# If channel is not authorized to send to, output to DM instead.
	@dm = false
	if(!array_contains(@config['CMD_Channels_Send'], @discord['channel'])) { @discord['channel'] = @discord['userid'] @dm = true }

# Command in approved channels:
# Mentions, via batch, or server's set prefix
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) || array_contains(@config['CMD_Channels_Receive'], @discord['channelid'])) {
		export('DiscordBot.'.@discord['serverid'].'.CacheUpdate', true)
	# Attachment: batch

	# Normal Message
		
	# Wish support here
	
		@isCmd = _discordBot_iscommand(@discord)
	}
	
	# Action command, all message output is handled from there.
	if(@isCmd == true) {
		if(@userType == 'User') {
			consume();
			array_set(@discord, 'time', time())
			@isMention = _discordBot_ismention(@discord)
			/*	
			Returns:
			false = no command found or error. (See debug return)
			true = success
			NotAdmin
			NoCmdGiven
			NotACmd
			*/
			if(@isMention == true) { @isMention = 'mention' }
			@return = _discordBot_handlecommand(@discord, @dm, @isMention)
		} else {
			@botcolor = 15
			if(@userType == 'Bot') { @botcolor = 3 }
			if(@userType == 'Webhook') { @botcolor = 5 }
			_db_msg_Console(color(@botcolor).@userType.': '.color(9).@discord['nickname'].color(7).' tried using one of my commands!', @discord['serverid'])
		}
	}
}
#
# DM commands
bind('discord_private_message_received', array('id': 'DiscordBot.CMD.DMs', 'priority': 'HIGH'), null, @discord) {
	array_set(@discord, 'time', time())
	array_set(@discord, 'UseDM', true)
	@botconfig = import('DiscordBot.config.Bot')
	@servers = import('DiscordBot.Servers')
	@userserver = 0
	@userServers = array()
# Default server ID to send
	foreach(@serverID in @servers) {
		if(array_contains(discord_get_members(@serverID), @discord['userid'])) {
			@userServers[] = @serverID
			@userserver = @serverID
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