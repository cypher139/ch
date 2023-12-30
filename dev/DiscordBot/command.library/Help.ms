proc _discordBot_cmd_ping(@discord, @args) {
	return('pong')
}

proc _discordBot_cmd_help(@discord) {
	@config = import('DiscordBot.config.Discord')
	@userTypeDisplay = ''
	@cmdList = import('DiscordBot.Command.List')
	if(!is_array(@cmdList)) { _db_msg_Console('Command list not initialized', 'debug') return(false) }
	@cmdListName = array()
	# @adminCmdList = array()
	@cmdListAlias = array()
	@categoriesList = array()
	
	foreach(@cmd: @data in @cmdList) {
		@lCmd = to_lower(@cmd)
		if(@discord['admin'] == false && @data['admin'] == true) { continue() }
		@cmdListName[] = @lCmd
		if(is_array(@data['alias']) && @discord['admin'] == true) {
			if(array_index_exists(@data, 'alias', 0)) {
				foreach(@a in @data['alias']) {
					@cmdListAlias[] = to_lower(@a)
				}
			}
		}
		if(!array_index_exists(@categoriesList, @data['category'])) { array_set(@categoriesList, @data['category'], array()) }
		array_push(@categoriesList[@data['category']], @lCmd)
	}
	

	if(@discord['admin'] == true) { @userTypeDisplay = ' (Admin)' }
	@fields = array()
	foreach(@cat: @list in @categoriesList) {
		if(@discord['admin'] == false && @cat == 'Admin') { continue() }
		array_push(@fields, array('name': @cat, 'value': '`'.array_implode(array_sort(@list, 'STRING'), '` `').'`', 'inline': false))
	}
	@embeds = array(array('fields': @fields, 'color': array('r': 255, 'g': 204, 'b': 0), 'description': 'Command List', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/925074738437570600.webp?size=32', 'text': 'the cool bot.')))
	if(@discord['admin'] == true) { 
		array_sort(@cmdListAlias, 'STRING')
		@aliasembed = array('fields': array(array('name': 'Aliases', 'value': '`'.array_implode(array_unique(@cmdListAlias), '` `').'`', 'inline': false)), 'color': array('r': 170, 'g': 221, 'b': 0))
		@embeds[] = @aliasembed
	}
	_discordBot_send_message(array('content': 'Hi '.@discord['username'].@userTypeDisplay.'!', 'embeds': @embeds), @discord['serverid'], 'discord', @discord['userid'], 'dm')
	return(true)
}


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'help': array('alias': '', 'admin': false, 'category': 'Utility', 'cmd': closure(@discord) { return(_discordBot_cmd_help(@discord)); }),
	'ping': array('alias': '', 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_ping(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)