proc _discordBot_cmd_codegen(@discord, @args) {	
	switch(rand(1,11)){
	case 4:
		return(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/password_strength.png'))))
	default:
		if(is_proc('_codegen')) {
			@time = time();
			@id = rand(25,120);
			@dmCode = @discord['UseDM'];
			@length = 8;
			@prefix = '';
			@options = array();
			if(array_index_exists(@args, 0)) {
				foreach(@i: @arg in @args) {
					if(reg_count('^[-/]?[PpDd]', @arg) > 0) {
						@dmCode = true;
						continue();
					}
					if(reg_count('^[-?]?[HhIi]', @arg) > 0) {
						return('Character types: lowercase, uppercase, number, symbol, full (all alphanumeric characters) or all (full + symbols). Extra character types: 8bit or 16bit for their respective numbers.');
					}
					#if arg more than numeric type: set length
					if(is_numeric(@arg)) {
						if(@arg > 6) {
							@length = @arg;
							continue();
						}
					}
					@options[] = @arg;
				}
			}
			if(!@options) { @options = 'full'; }
			if(@length > 500) { @length = 500; }
			x_new_thread(@id.@time, closure(){
				@code = _codegen(@length, @options);
				export(@id.@time, @code);
			});
			x_thread_join(@id.@time, 7000);
			@code = import(@id.@time);
			if(@code == null) { return('Error') }
			if(@dmCode == 'dm') {
				@prefix = 'Randomly Generated code: \n';
			}
			export(@id.@time, null);
			return(array('content': @prefix.'`'.@code.'`', 'dm': @dmCode));
		} else { return('NoCmd'); }
	}
}

proc _discordBot_cmd_dmoptions(@discord, @cmdargs) {
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@membernames = import('DiscordBot.'.@discord['serverid'].'.members.names')
	if(!is_array(@membernames)) { 
		@membernames = array()
		array_set(@membernames, @discord['username'], @discord['userid']) 
	}
	@userConfig = import('DiscordBot.DMs.user.settings');
	if(!is_array(@userConfig)) { @userConfig = get_value('DiscordBot.DMs.user.settings') }
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
		array_set(@userConfig, 'lastedit', time());
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
			@ret .= '`'.@set.':` '.@vd.'  '
		}
		return(@ret)
	}
	return('Last return')
}

proc _discordBot_cmd_transferroles(@discord, @args) {
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@fromroleAdmin = false
	@returnmsg = color(10).'Completed Roles transfer'
	@undo = false
	@fromroles = array()
	@toroles = array()
	if(!array_index_exists(@args, 0)) { return(color(12).'Specify the Discord user ID to copy from!') }
	if(!array_index_exists(@args, 1)) { return(color(12).'Specify the Discord user ID to copy to!') }
	@id0 = @args[0];
	@id1 = @args[1];
	if(array_index_exists(@args, 2)) { 
		if(!string_contains(array_implode(@args, ''), '@')) { return(color(12).'Cannot parse user IDs given.') }
		@test = split('@', array_implode(@args, ' '))
		if(!@test[0]) { array_remove(@test, 0) }
		if(array_size(@test) != 2) { return(color(12).'Cannot parse user IDs given ('.array_size(@test).')') }
		@id0 = @test[0];
		@id1 = @test[1];
	}
	@botperms = discord_get_permissions(@discord['serverid'])
	if(!array_contains(@botperms, 'ADMINISTRATOR') && !array_contains(@botperms, 'MANAGE_ROLES')) {	return('NoPerms'); }
	@fromID = @id0
	if(@id0 != 'undo') {
		@fromID = _discordBot_cmd_proc_finduserID(@id0, @discord)
	}
	if(!is_numeric(@fromID)) {
		switch(@fromID) {
		case 'bot':
			return(array('embeds': array(array('footer': array('text': 'Sorry, my roles are my roles.'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
		case 'self':
			@fromID = @discord['userid']
		case 'notfound':
			return('NoUserFound')
		case 'multiple':
			return('Error')
		case 'undo':
			@undo = true
		}
	}
	@toID = _discordBot_cmd_proc_finduserID(@id1, @discord)
	if(!is_numeric(@toID)) {
		switch(@toID) {
		case 'bot':
			return('Thanks for the compliment, but I\'m happy with my roles.')
		case 'self':
			@toID = @discord['userid']
		case 'notfound':
			return('NoUserFound')
		case 'multiple':
			return('Error')
		}
	}
	if(@fromID == @toID) { return(array('embeds': array(array('footer': array('text': 'Wait, whut? you wanna transfer roles to the same person?'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif')))) }
	@TRlog = get_value('DiscordBot.'.@discord['serverid'].'.log.roles.Transfer')
	if(!is_array(@TRlog)) { @TRlog = array() }
	
	# To User check
	try {
		@toroles = discord_member_get_roles(@discord['serverid'], @toID)
	} catch(Exception @ex) {
		return(color(12).'To ID Not Found on Server: '.@ex['message'])
	}
	
	# One transfer per user
	if(array_index_exists(@TRlog, @toID) && @undo == false) {
		#ignore if admin and yourself
		if(@discord['admin'] == true && @discord['userid'] == @toID) { @selfadmin = 1 } else {
			return(color(12).'Only one roles transfer is allowed per user account.')
		}
	}

	@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles')
	if(!is_array(@roles)) { 
		_discordBot_update_members(@discord['serverid']);
		@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles')
	}
	@rolesFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former.roles')
	if(!is_array(@rolesFR)) { @rolesFR = array() }
	@undoroles = get_value('DiscordBot.'.@discord['serverid'].'.set.roles.undo.Transfer')
	if(!is_array(@undoroles)) { @undoroles = array() }

	# From User check
	if(@undo == false) {
		try {
			@fromroles = discord_member_get_roles(@discord['serverid'], @fromID)
		} catch(Exception @ex) {
			if(is_array(@roles)) {
				if(array_index_exists(@roles, @fromID)) {
					@fromroles = @roles[@fromID]
					_db_msg_Console(color(14).'From ID: Not Found on Server, using internal cache.', @discord['serverid'])
				} else if(array_index_exists(@rolesFR, @fromID)) {
					@fromroles = @rolesFR[@fromID]
					_db_msg_Console(color(14).'From ID: Not Found on Server, using internal storage.', @discord['serverid'])
				} else {
					return(color(12).'From ID was Not Found on Server or internal cache!')
				}
			} else { return(color(12).'From ID was Not Found on Server; internal storage not initialized!') }
		}
	}
	# Admin roles nag
	foreach(@rn: @rid in @fromroles) {
		if(array_contains_ic(@config['Role_Admins'], @rn) || array_contains(@config['Role_Admins'], @rid)) {
			#ignore if admin and yourself
			if(@discord['admin'] == true && @discord['userid'] == @toID) { continue() }
			@fromroleAdmin = true
			array_remove(@fromroles, @rn)
		}
	}
	if(@fromroleAdmin == true) {
		@suffix = 'Message the server moderation team to reinstate any server access.'
		if(@discord['admin'] == true) { @suffix = 'Please verify this person before awarding any admin roles.' }
		@returnmsg = color(14).'A Server Admin role was detected! For security reasons I\'m not awarding that role. '.@suffix.'\n'.color(10).@returnmsg
	}
	
	@logMsg = 'Transfer Roles: From: '.@id0.'('.@fromID.') To: '.@id1.'('.@toID.')'
	#Undo support
	if(@undo == true) {
	#does not add from roles.
		if(array_index_exists(@undoroles, @toID)) {
			@toroles = @undoroles[@toID]
			@logMsg = 'Transfer Roles: Undid role transfer for '.@id1.'('.@toID.')'
			@returnmsg = 'Undid Roles transfer'
		} else {
			return(color(12).'That user does not have previous data to undo!')
		}
	} else {
	# adds from roles, not sets to!
		array_set(@undoroles, @toID, @toroles)
		store_value('DiscordBot.'.@discord['serverid'].'.set.roles.undo.Transfer', @undoroles)
		@toroles = array_merge(@toroles, @fromroles)
	}
	# _db_msg_Console(@toroles, @discord['serverid'], 'debug')
	# _db_msg_Console(@fromroles, @discord['serverid'], 'debug')
		
	@doSetRoles = _discordBot_set_roles(@discord['serverid'], @toID, 'set', @toroles, @logMsg, 'Transfer Roles');
	if(@doSetRoles == false) { return('Error') }
	#Save
	array_set(@TRlog, @toID, array('time': time(), 'fromuser': @fromID, 'issuer': @discord['userid']))
	if(@undo == true) { array_remove(@TRlog, @toID) }
	store_value('DiscordBot.'.@discord['serverid'].'.log.roles.Transfer', @TRlog)
	@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info')
	if(array_index_exists(@joininfo, @toID)) {
		array_set(@joininfo[@toID], 'return', 'true')
		store_value('DiscordBot.'.@discord['serverid'].'.Join.info', @joininfo)
	}
	@msgrolesreturn = color(10).@returnmsg.' for user '.color(3).@id1.color(10).'('.@toID.'), Roles set to:\n'.color('r').array_keys(@toroles)
	return(array('content': @returnmsg.' for user "'.color(3).@id1.'" ('.@toID.')', 'console': @msgrolesreturn))
}


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'codegen': array('alias': array('code', 'gibberish', 'generatecode', 'password'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_codegen(@discord, @args)); }),
	'dmoptions': array('alias': array('dm'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_dmoptions(@discord, @args)); }),
	'transferroles': array('alias': array('trroles'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_transferroles(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)