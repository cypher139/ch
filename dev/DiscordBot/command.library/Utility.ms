#version 1.0-tmc
proc _discordBot_cmd_dmoptions(@discord, @cmdargs) {
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@membernames = import('DiscordBot.'.@discord['serverid'].'.members.names')
	if(!is_array(@membernames)) { 
		@membernames = array()
		array_set(@membernames, @discord['username'], @discord['userid']) 
	}
	@userConfig = import('DiscordBot.DMs.user.settings', get_value('DiscordBot.DMs.user.settings'));
	if(is_array(@userConfig)) {
		if(!array_index_exists(@userConfig, @discord['userid'])) {
			array_set(@userConfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
		}	
	} else {
		@userConfig = array()
		array_set(@userConfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
	}
	
	if(!array_index_exists(@cmdargs, 0)) { @cmdargs = array('view') }
	switch(string(@cmdargs[0])) {

	case 'notifycontent':
	case 'nc':
	case 'urlreadback':
	case 'url':
	case 'opt-out':
	case 'optout':
		@suffix = ' to the Minecraft server and Discord Admin log channel.'
		@ret = ''
		@userType = 'that user\'s'
		@userID = ''
		if(!array_index_exists(@cmdargs, 1)) {
			@userType = 'your'
			@userID = @discord['userid']
		} else if(@discord['admin'] == false) {
			return('NotAdmin')
		} else {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord)
			if(!is_numeric(@userID)) {
				switch(@userID) {
				case 'bot':
					return(array('embeds': array(array('footer': array('text': 'I don\'t know how to DM myself'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
				case 'self':
					@userID = @discord['userid']
				case 'notfound':
					return('NoUserFound')
				case 'multiple':
					return(false)
				}
			}
			if(!array_index_exists(@userConfig, @userID)) {	array_set(@userConfig, @userID, array('NotifyContent': true, 'URLReadback': false))	}
		}
		switch(string(@cmdargs[0])) {
		case 'notifycontent':
		case 'nc':
			@userConfig[@userID]['NotifyContent'] = !@userConfig[@userID]['NotifyContent']
			if(@userConfig[@userID]['NotifyContent'] == true) {
				@ret = 'Content of '.@userType.' DMs with me shall be displayed'.@suffix
			} else {
				@ret = 'Content of '.@userType.' DMs with me *won\'t* be displayed'.@suffix	
			}
		case 'urlreadback':
		case 'url':
			@userConfig[@userID]['URLReadback'] = !@userConfig[@userID]['URLReadback']
			if(@userConfig[@userID]['URLReadback'] == true) {
				@ret = 'I\'ll message the URL of attachments in '.@userType.' DMs with me.'
			} else {
				@ret = 'Ok, no more useless URL messages in '.@userType.' DMs with me.'	
			}
		case 'opt-out':
		case 'optout':
			@userConfig[@userID]['NotifyContent'] = false
			@userConfig[@userID]['URLReadback'] = false
			@ret = 'Opt-out successful, Content of '.@userType.' DMs with me *won\'t* be displayed'.@suffix
		}
		export('DiscordBot.DMs.user.settings', @userConfig);
		store_value('DiscordBot.DMs.user.settings', @userConfig);
		return(@ret)
	case 'view':
	default:
		@userID = @discord['userid']
		@userSettings = @userConfig[@discord['userid']]
		if(array_index_exists(@cmdargs, 1)) {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord)
			if(!is_numeric(@userID)) {
				return('Cannot find settings for this user.')
			} else {
				@userSettings = @userConfig[@userID]
			}
		}
		@ret = 'DM settings for <@'.@userID.'>: '
		foreach(@set: @v in @userSettings) {
			@vd = '`'.@v.'`'
			if(is_boolean(@v)) {
				if(@v == true) {
					@vd = ':white_check_mark:'
				} else { 
					@vd = ':x:'
				}
			}
			@ret = @ret.'`'.@set.':` '.@vd.'  '
		}
		return(@ret)
	}
	return('Last return')
}

proc _discordBot_cmd_transferroles(@discord, @args) {
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@fromroleAdmin = false
	@returnmsg = color('a').'Roles transfer for Discord User "'.color(3).@args[1].'" '
	if(!array_index_exists(@args, 0)) { return(color('c').'Specify the Discord user ID to copy from!') }
	if(!array_index_exists(@args, 1)) { return(color('c').'Specify the Discord user ID to copy to!') }
	if(!array_index_exists(@args, 2)) { @args[] = 'none' }
	if(!is_numeric(@args[0]) || !is_numeric(@args[1])) {
		if(@args[0] != 'undo') {
			return(color('c').'Discord Usernames are not supported in this command.')
		}
	}
	@TRlog = get_value('DiscordBot.'.@discord['serverid'].'.log.roles.Transfer')
	if(!is_array(@TRlog)) { @TRlog = array() }
	
	# To User check
	try {
		@toroles = discord_member_get_roles(@discord['serverid'], @args[1])
	} catch(Exception @ex) {
		return(color('c').'To ID Not Found on Server: '.@ex['message'])
	}
	
	# One transfer per user
	if(array_index_exists(@TRlog, @args[1]) && @args[2] != 'undo' && @args[0] != 'undo') {
		#ignore if admin and yourself
		if(@discord['admin'] == true && @discord['userid'] == @args[1]) { @selfadmin = 1 } else {
			return(color('c').'Only one roles transfer is allowed per user account.')
		}
	}

	@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles')
	if(!is_array(@roles)) { 
		_discordBot_update_members(@discord['serverid']);
		@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles')
	}
	@rolesFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former.roles')
	if(!is_array(@rolesFR)) { @rolesFR = array() }
	@fromroles = ''
	@toroles = ''
	@saveoldroles = get_value('DiscordBot.'.@discord['serverid'].'.debug.roles.Transfer.undo')
	if(!is_array(@saveoldroles)) { @saveoldroles = array() }

	# From User check
	try {
		@fromroles = discord_member_get_roles(@discord['serverid'], @args[0])
	} catch(Exception @ex) {
		if(is_array(@roles)) {
			if(array_index_exists(@roles, @args[0])) {
				@fromroles = @roles[@args[0]]
				_db_msg_Console(color('e').'From ID: Not Found on Server, using internal cache.', @discord['serverid'])
			} else if(array_index_exists(@rolesFR, @args[0])) {
				@fromroles = @rolesFR[@args[0]]
				_db_msg_Console(color('e').'From ID: Not Found on Server, using internal storage.', @discord['serverid'])
			} else {
				return(color('c').'From ID was Not Found on Server or internal cache!')
			}
		} else { return(color('c').'From ID was Not Found on Server; internal storage not initialized!') }
	}
	
	# Admin roles nag
	foreach(@rn: @rid in @fromroles) {
		if(array_contains_ic(@config['Role_Admins'], @rn) || array_contains(@config['Role_Admins'], @rid)) {
			#ignore if admin and yourself
			if(@discord['admin'] == true && @discord['userid'] == @args[1]) { continue() }
			@fromroleAdmin = true
			array_remove(@fromroles, @rn)
		}
	}
	if(@fromroleAdmin == true) {
		@suffix = 'Message the server moderation team to reinstate any server access.'
		if(@discord['admin'] == true) { @suffix = 'Please verify this person before awarding any admin roles.' }
		@returnmsg = 'A Server Admin role was detected! For security reasons I\'m not awarding that role, '.@suffix.'\n'.@returnmsg
	}
		
	#Undo support
	if(@args[0] == 'undo' || @args[2] == 'undo') {
	#does not add from roles.
		if(array_index_exists(@saveoldroles, @args[1])) {
			@toroles = @saveoldroles[@args[1]]
		} else {
			return(color('c').'That user does not have previous data to undo!')
		}
	} else {
	# adds from roles, not sets to!
		array_set(@saveoldroles, @args[1], @toroles)
		store_value('DiscordBot.'.@discord['serverid'].'.debug.roles.Transfer.undo', @saveoldroles)
		@toroles = array_merge(@toroles, @fromroles)
	}
	# _db_msg_Console(@toroles, @discord['serverid'], 'debug')
	# _db_msg_Console(@fromroles, @discord['serverid'], 'debug')
		
	try {
		discord_member_set_roles(@discord['serverid'], @args[1], @toroles)
	} catch(Exception @ex) {
		_db_msg_Console(color('c').'Transfer roles: set roles failed: '.@ex['classType'].@ex['message'], @discord['serverid'])
		return('NoPerms')
	}
	#Save 
	array_set(@TRlog, @args[1], array('time': time(), 'fromuser': @args[0], 'issuer': @discord['userid']))
	store_value('DiscordBot.'.@discord['serverid'].'.log.roles.Transfer', @TRlog)
	@msgrolesreturn = color('a').'Discord User '.color(3).@args[1].color('a').' had their Roles set to:\n'.color('r').array_keys(@toroles)
	return(array('content': @returnmsg.color('a').'successful.', 'console': @msgrolesreturn))
}


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'dmoptions': array('alias': array('dm'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_dmoptions(@discord, @args)); }),
	'transferroles': array('alias': array('trroles'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_transferroles(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)