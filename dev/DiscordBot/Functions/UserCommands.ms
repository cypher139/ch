# Handle commands from Discord Users
# Precompile command actions, made available for only these binds:
include_dir('../command.library');
_discordBot_init_cmd_list();
# Servers commands
bind('discord_message_received', array('id': 'DiscordBot.CMD.listen.Message', 'priority': 'HIGH'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die(); }
	@discord['listener'] = 'message';
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@botinfo = import('DiscordBot.Bot.Info');
	@isCmd = false;
	@isMention = '';
	@userType = 'User';
	@userColor = 15;
	if(@discord['bot']) { @userType = 'Bot'; @userColor = 3; }
	if(@discord['webhook']) { @userType = 'Webhook'; @userColor = 5; }
# If channel is not authorized to send to, output to DM instead.
	@dm = false;
	if(!array_contains(@config['CMD_Channels_Send'], @discord['channel']) && !array_contains(@config['CMD_Channels_Send'], @discord['channelid'])) { 
		@discord['channel'] = @discord['userid'];
		@dm = true;
	}
# Command in approved channels:
# Mentions, via batch, or server's set prefix
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) || array_contains(@config['CMD_Channels_Receive'], @discord['channelid'])) {
		export('DiscordBot.'.@discord['serverid'].'.CacheUpdate', true);
	# Attachment: batch

	# Normal Message
		
	# Wish support here
	
		@isCmd = _discordBot_iscommand(@discord);
	}
	# Action command, all message output is handled from there.
	if(@isCmd === true) {
		if(@userType === 'User') {
			consume();
			@discord['time'] = time();
			@isMention = _discordBot_ismention(@discord);
			/*	
			Returns:
			false = no command found or error. (See debug return);
			true = success
			NotAdmin
			NoCmdGiven
			NotACmd
			*/
			if(@isMention === true) { @isMention = 'mention'; }
			@return = _discordBot_handlecommand(@discord, @dm, @isMention);
		} else {
			_db_msg_Console(color(@userColor).@userType.': '.color(9).@discord['nickname'].color(7).' tried using one of my commands!', @discord['serverid']);
		}
	}
}
#
bind('discord_reaction_added', array('id': 'DiscordBot.CMD.listen.Reaction.Add', 'priority': 'HIGH'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die(); }
	@discord['id'] = @discord['messageid'];
	@discord['listener'] = 'reactionadd';
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@botinfo = import('DiscordBot.Bot.Info');
	@isCmd = false;
	@isMention = '';
	@isRR = false;
	@userType = 'User';
	@return = null;
	if(@discord['bot']) { @userType = 'Bot'; }
	# Webhook not available for thie event. if(@discord['webhook']) { @userType = 'Webhook'; }
# If channel is not authorized to send to, output to DM instead.
	@dm = false;
	if(!array_contains(@config['CMD_Channels_Send'], @discord['channel']) && !array_contains(@config['CMD_Channels_Send'], @discord['channelid'])) { 
		@discord['channel'] = @discord['userid'];
		@dm = true;
	}
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) || array_contains(@config['CMD_Channels_Receive'], @discord['channelid'])) {
		export('DiscordBot.'.@discord['serverid'].'.CacheUpdate', true);
		@isCmd = _discordBot_iscommand(@discord);
	}
	if(array_contains(@config['Reaction_Roles_Messages'], @discord['id'])) { @isCmd = true; @isRR = true;}
	if(@isCmd === true) {
		if(@userType === 'User') {
			consume();
			@discord['time'] = time();
			@return = _discordBot_handlecommand(@discord, @dm, 'reaction');
		}
	}
}
#
bind('discord_reaction_removed', array('id': 'DiscordBot.CMD.listen.Reaction.Remove', 'priority': 'HIGH'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die(); }
	@discord['id'] = @discord['messageid'];
	@discord['listener'] = 'reactionremove';
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@botinfo = import('DiscordBot.Bot.Info');
	@isCmd = false;
	@isMention = '';
	@isRR = false;
	@userType = 'User';
	@return = null;
	if(@discord['bot']) { @userType = 'Bot'; }
	# Commands currently not setup for usage on remove emoji, unless command requires toggling depending on reaction present or not. - e.g. reaction roles.
	if(array_contains(@config['Reaction_Roles_Messages'], @discord['id'])) { @isCmd = true; @isRR = true;}
	if(@isRR === true) {
		if(@userType === 'User') {
			consume();
			@discord['time'] = time();
			@return = _discordBot_handlecommand(@discord, false, 'reaction');
		}
	}
}


#
#
# DM commands
bind('discord_private_message_received', array('id': 'DiscordBot.CMD.listen.DM', 'priority': 'HIGH'), null, @discord) {
	@discord['time'] = time();
	@discord['listener'] = 'dm';
	@discord['UseDM'] = true;
	@botconfig = import('DiscordBot.config.Bot');
	@servers = import('DiscordBot.Servers');
	@userserver = 0
	@userServers = array();
# Default server ID to send
	foreach(@serverID in @servers) {
		if(array_contains(discord_get_members(@serverID), @discord['userid'])) {
			@userServers[] = @serverID;
			@userserver = @serverID;
		}
	}
#Command check
	@isCmd = _discordBot_iscommand(@discord, 'id');
	if(!is_boolean(@isCmd)) {
		@userserver = @isCmd;
		@isCmd = true;
	}
	if(@isCmd === true) {
		consume();
		@discord['channel'] = @discord['userid'];
		@discord['channelid'] = @discord['userid'];
		@discord['serverid'] = @userserver;
		@discord['nickname'] = @discord['displayname'];
		@return = _discordBot_handlecommand(@discord, 'dm', 'dm');
		return(@return);
	}
}