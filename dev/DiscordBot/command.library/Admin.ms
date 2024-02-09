proc _discordBot_cmd_wrf(@discord, @args) {
		if(!array_index_exists(@args, 0)) { @args = array('welcome') }
		@type = 'd'
		if(array_index_exists(@args, 1)) { if(@args[1] == 'mc') { @type = 'mc' } }
		@msg = ''
		@amount = 0
		@config = import('DiscordBot.config.'.@discord['serverid'])
		@guildInfo = import('DiscordBot.Guilds.Info.'.@discord['serverid'])
		@guildIconType = 'png'
		if(string_starts_with(@guildInfo['icon'], 'a_')) { @guildIconType = 'gif' }
		@suffix = ''
		switch(to_lower(substr(@args[0], 0, 1))) {
		case 'w':
			@suffix = 'welcomeroles'
			@msg = 'Members with only the Welcome Roles:'
		case 'n':
		case '0':		
			@suffix = 'none'
			@msg = 'Members with 0 roles:'
		default:
			return('Specify the type you want: WelcomeRoles for members with just welcome roles, None for those with no roles.')
		}
		@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles.'.@suffix)
		if(is_array(@roles)) {
			@amount = array_size(@roles)
		} else {
			_discordBot_update_members(@discord['serverid'])
			return('Role Data not populated yet, try again later.')
		}
		@mcreturn = @msg.'  '.color(9).@amount
		#DM list of IDs:
		@list = array()
		if(@amount > 0 && @discord['admin'] == true) {
			@membernames = get_value('DiscordBot.'.@discord['serverid'].'.members.names')
			foreach(@username: @userid in @membernames) {
				if(array_contains(@roles, @userid)) {
					@list[] = @username.' <'.@userid.'>'
				}
			}
			if(@type == 'd') {
				_discordBot_send_message(array('content': '```List of IDs:```\n'.array_implode(@list, '\n'), 'custom_split': '[\\s\\S]{1,1970}(?:>|$)'), @discord['serverid'], 'bot', @discord['userid'], 'dm')
			}
		}
		#Return
		return(array('MCCmd': array('list': @list, 'msg': @msg.' '.color(9).@amount), 'embeds': array(array('author': array('icon_url': 'https://cdn.discordapp.com/icons/'.@discord['serverid'].'/'.@guildInfo['icon'].'.'.@guildIconType, 'name': @guildInfo['name']),
'title': 'Welcome Roles Finder', 'description': @msg.' `'.@amount.'`', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'])))))
}

proc _discordBot_cmd_asremove(@discord, @args) {
	# Remove user from triggered state
	if(!array_index_exists(@args, 0)) { return(color(12).'Specify the Discord user ID to remove anti spam restrictions!') }
	if(!is_numeric(@args[0])) {
		return(color(12).'Discord Usernames are not supported in this command.')
	}
	@userid = @args[0]
	@asmembers = import('DiscordBot.'.@discord['serverid'].'.antispam.members');
	if(!is_array(@asmembers)) { 
		@asmembers = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
	}
	if(!is_array(@asmembers)) { return(color(12).'No Antispam user data found for this server.') }
	if(!array_index_exists(@asmembers, @userid)) { return(color(12).'Invalid User ID or User Not Found.') }
	@asTriggerCount = import('DiscordBot.'.@discord['serverid'].'.antispam.trigger', array())
	if(array_index_exists(@asTriggerCount, @userid)) { 
		if(!array_index_exists(@asmembers, @userid, 'triggercount')) { array_set(@asmembers[@userid], 'triggercount', 0) }
		@asmembers[@userid]['triggercount'] = @asmembers[@userid]['triggercount'] + @asTriggerCount[@userid]
		array_remove(@asTriggerCount, @userid)
		export('DiscordBot.'.@discord['serverid'].'.antispam.trigger', @asTriggerCount)
	}
	@asmembersR = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
	if(!is_array(@asmembersR)) { @asmembersR = array() }

	@username = @asmembers[@userid]['username']

	array_set(@asmembers[@userid], 'removed', time())
	array_set(@asmembers[@userid], 'removeuser', @discord['username'])
	array_set(@asmembersR, @userid, @asmembers[@userid])
	array_remove(@asmembers, @userid)
	store_value('DiscordBot.'.@discord['serverid'].'.antispam.members.removed', @asmembersR)
	store_value('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers)
	export('DiscordBot.user.'.@discord['userid'].'.ASTriggerMessage', null)
	#export('DiscordBot.'.@discord['serverid'].'.'.@userid.'.antispam.trigger', null)
	return('Removed '.@userid.' ('.@username.') from Anti-Spam restrictions.')
}


#Add Commands to list
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'welcomerolesfinder': array('alias': array('wrf'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_wrf(@discord, @args)); }),
	'asremove': array('alias': array('as'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_asremove(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)