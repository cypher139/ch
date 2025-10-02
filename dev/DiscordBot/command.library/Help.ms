proc _discordBot_cmd_ping(@discord, @args) {
	return('pong');
}

proc _discordBot_cmd_help(@discord, @args) {
	@config = import('DiscordBot.config.Bot');
	@userTypeDisplay = '';
	if(@discord['admin'] === true) { @userTypeDisplay = ' (Admin)'; }
	@cmdList = import('DiscordBot.Command.List');
	if(!is_array(@cmdList)) { _db_msg_Console('Command list not initialized', 'debug') return(false); }
	@cmdListName = array();
	@cmdListAlias = array();
	@categoriesList = array();
	@cmdHelp = '_?';
	@cmdHelpD = '';
	@embeds = array();
	@fields = array();
	foreach(@cmd: @data in @cmdList) {
		@lCmd = to_lower(@cmd);
		if(@discord['admin'] === false && @data['admin'] === true) { continue(); }
		@cmdListName[] = @lCmd;
		if(is_array(@data['alias'])) {
			if(array_index_exists(@data, 'alias', 0)) {
				foreach(@a in @data['alias']) {
					@cmdListAlias[to_lower(@a)] = @lCmd;
				}
			}
		}
		if(!array_index_exists(@categoriesList, @data['category'])) { @categoriesList[@data['category']] = array(); }
		array_push(@categoriesList[@data['category']], @lCmd);
	}
	#Specific command:
	foreach(@c in @args) {
		@arg = replace(to_lower(@c), '"', '');
		@arg = replace(@arg, "'", '');
		if(array_index_exists(@cmdList, @arg)) {
			@cmdHelp = @arg;
			@cmdHelpD = @arg;
			break();
		} else if(array_index_exists(@cmdListAlias, @arg)) {
			@cmdHelp = @cmdListAlias[@arg];
			@cmdHelpD = @arg;
			break();
		}
	} else { @cmdHelp = '_showall'; }

	switch(@cmdHelp) {
	case '_showall':
#All Commands
		foreach(@cat: @list in @categoriesList) {
			if(@discord['admin'] === false && @cat == 'Admin') { continue(); }
			@fields[] = array('name': @cat, 'value': '`'.array_implode(array_sort(@list, 'STRING'), '` `').'`', 'inline': false);
		}
		@embeds[] = array('fields': @fields, 'color': array('r': 255, 'g': 204, 'b': 0), 'description': 'Command List', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/925074738437570600.webp?size=32', 'text': 'the cool bot.'));
		if(@discord['admin'] === true) { 
			@embeds[] = array('fields': array(array('name': 'Aliases', 'value': '`'.array_implode(array_keys(@cmdListAlias), '` `').'`', 'inline': false)), 'color': array('r': 170, 'g': 221, 'b': 0));
		}
	case '_?':
# Command Not recognized
		@say = array('https://media.tenor.com/ABXdCH0UQEYAAAAd/bunny-wth.gif', 'https://media.tenor.com/UPhAUsA9UGkAAAAd/huh-cat-huh-m4rtin.gif', 'https://media.tenor.com/DESSJFJ8_XkAAAAd/confused-cat-confused.gif');
		@embeds[] = array('footer': array('icon_url': 'https://cdn.discordapp.com/emojis/925074738437570600.webp?size=32', 'text': 'the cool bot.'), 'image': array_get_rand(@say));
	default:
# Individual command help
		if(@discord['admin'] === false && @cmdList[@cmdHelp]['admin'] === true) {
			@fields[] = array('name': 'Admin Required', 'value': 'This command requires server admin priviliges in order to use it.', 'inline': false);
		} else {
			if(@cmdHelp != @cmdHelpD) {
				@fields[] = array('name': 'alias for:', 'value': '`.'.@cmdHelp.'`', 'inline': false);
			}
			if(array_index_exists(@cmdList, @cmdHelp, 'usage')) {
				@fields[] = array('name': 'usage', 'value': '< Required > / [ Optional ] / ( Default value ) \n`.'.@cmdHelpD.' '.@cmdList[@cmdHelp]['usage'].'`', 'inline': false);
			}
			@entry = 'No Help Text entry for "'.@cmdHelp.'"!'
			if(array_index_exists(@cmdList, @cmdHelp, 'help')) { @entry = @cmdList[@cmdHelp]['help'] }
			@fields[] = array('name': 'help text', 'value': @entry, 'inline': false);
			if(array_index_exists(@cmdList, @cmdHelp, 'usagenote')) {
				@fields[] = array('name': 'note:', 'value': @cmdList[@cmdHelp]['usagenote'], 'inline': false);
			}
			if(array_index_exists(@cmdList, @cmdHelp, 'mcperm')) {
				@str = array('pre': '', 'm': '', 's': '', 'r': '', 'perm': '', 'cmd': '');
				if(array_contains(@cmdList[@cmdHelp]['mcperm']['flags'], 's')) { @str['s'] = 'your Minecraft player'; }
				if(array_contains(@cmdList[@cmdHelp]['mcperm']['flags'], 'r')) { @str['r'] = 'the receiving player'; }
				if(@str['s'] != '' && @str['r'] != '') { @str['pre'] = 'Either '; @str['m'] = ' or '; }
				if(array_contains(@cmdList[@cmdHelp]['mcperm']['flags'], 'a')) { @str['pre'] = '**Both** '; @str['m'] = ' and '; }
				if(array_index_exists(@cmdList, @cmdHelp, 'mcperm', 'cmd') && array_index_exists(@cmdList, @cmdHelp, 'mcperm', 'perm')) { @str['cmd'] = '\n or '; }
				if(array_index_exists(@cmdList, @cmdHelp, 'mcperm', 'cmd')) {
					if(!array_index_exists(@cmdList, @cmdHelp, 'mcperm', 'perm')) { @str['perm'] = ''; }
					@slash = '';
					if(!string_starts_with(@cmdList[@cmdHelp]['mcperm']['cmd'], '/')) { @slash = '/'; }
					@str['cmd'] .= 'Ability to use command: `'.@slash.@cmdList[@cmdHelp]['mcperm']['cmd'].'`';
				}
				if(array_index_exists(@cmdList, @cmdHelp, 'mcperm', 'perm')) {
					if(is_array(@cmdList[@cmdHelp]['mcperm']['perm'])) {
						@str['perm'] .= '`'.array_implode(@cmdList[@cmdHelp]['mcperm']['perm'], '` `').'`';
					} else {
						@str['perm'] .= '`'.@cmdList[@cmdHelp]['mcperm']['perm'].'`';
					}
				}
				@fields[] = array('name': 'in-game permissions:', 'value': @str['perm'].@str['cmd'].'\n\n*check applies to:* '.@str['pre'].@str['s'].@str['m'].@str['r'], 'inline': false);
			}
			if(@discord['admin'] === true) {
				@a = array();
				foreach(@alias: @cmd in @cmdListAlias) {
					if(@cmd == @cmdHelp) {
						@a[] = @alias;
					}
				}
				if(@a) { @fields[] = array('name': 'aliases', 'value': '`'.array_implode(@a, '` `').'`', 'inline': false); }
			}	
		}
		@embeds[] = array('fields': @fields, 'color': array('r': 100, 'g': 204, 'b': 0), 'description': 'Help for Command: '.@cmdHelpD, 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/925074738437570600.webp?size=32', 'text': 'the cool bot.'));
	}
	return(array('content': 'Hi '.@discord['username'].@userTypeDisplay.'!', 'embeds': @embeds, 'dm': 'dm'));
}


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array());
@mIu7 = array(
	'help': array('alias': '', 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_help(@discord, @args)); },
			'help': 'View Information about all the bot\'s commands and their features!. Specify a Command Name to view usage info about that command.', 'usage': '[command name]'),
	'ping': array('alias': '', 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_ping(@discord, @args)); },
			'help': 'Tests the bot\'s response time to make sure that all systems are functioning.')
);
@c3lx = array_merge(@c3lx, @mIu7);
export('DiscordBot.Command.List', @c3lx);