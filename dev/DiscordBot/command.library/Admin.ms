proc _discordBot_cmd_wrf(@discord, @args) {
	if(is_proc('_discordBot_WelcomeRolesFinder')) {
		if(!array_index_exists(@args, 0)) { @args = array('welcome') }
		@return = _discordBot_WelcomeRolesFinder(@args[0], @discord['serverid'])
		if(!is_array(@return)) { return('Error') }
		if(reg_count('^[WwNn0]', @args[0]) == 0) { return('Specify the type you want: WelcomeRoles for members with just welcome roles, None for those with no roles.') }
		#DM list of IDs:
		if(array_index_exists(@return, 'list', 0) && @discord['admin'] == true) {
			_discordBot_send_message(array('content': '```List of IDs:```\n'.array_implode(@return['list'], '\n'), 'custom_split': '[\\s\\S]{1,1970}(?:>|$)'), @discord['serverid'], 'bot', @discord['userid'], 'dm')
		}
		return(array('embeds': array(array('title': 'Welcome Roles Finder', 'description': @return['amount'].' '.@return['msg'], 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'])))))
		
	} else {
		return('NoCmd')
	}
}


proc _discordBot_cmd_asremove(@discord, @args) {
	# Remove user from triggered state
	if(!array_index_exists(@args, 0)) { return(color('c').'Specify the Discord user ID to remove anti spam restrictions!') }
	if(!is_numeric(@args[0])) {
		return(color('c').'Discord Usernames are not supported in this command.')
	}
	@userid = @args[0]
	@asmembers = import('DiscordBot.'.@discord['serverid'].'.antispam.members');
	if(!is_array(@asmembers)) { 
		@asmembers = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members')
	}
	if(!is_array(@asmembers)) { return(color('c').'No Antispam user data found for this server.') }
	if(!array_index_exists(@asmembers, @userid)) { return(color('c').'Invalid User ID or User Not Found.') }
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
	#export('DiscordBot.'.@discord['serverid'].'.'.@userid.'.antispam.trigger', null)
	return('Removed "'.@userid.' ('.@username.') from Anti-Spam restrictions.')
}


#Add Commands to list
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'welcomerolesfinder': array('alias': array('wrf'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { 
		if(!array_index_exists(@args, 0)) { @args = array('arg') }
		return(_discordBot_cmd_wrf(@discord, @args));
	}),
	'asremove': array('alias': array('as'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_asremove(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)