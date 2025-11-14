proc _discordBot_cmd_codegen(@discord, @args) {	
	switch(rand(1,11)){
	case 4:
		return(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/password_strength.png'))));
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
			if(@code == null) { return('Error'); }
			if(@dmCode == 'dm') {
				@prefix = 'Randomly Generated code: \n';
			}
			export(@id.@time, null);
			return(array('content': @prefix.'`'.@code.'`', 'dm': @dmCode));
		} else { return('NoCmd'); }
	}
}

proc _discordBot_cmd_dmoptions(@discord, @cmdargs) {
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@membernames = import('DiscordBot.'.@discord['serverid'].'.members.names');
	if(!is_array(@membernames)) { 
		@membernames = array();
		@membernames[@discord['username']] = @discord['userid']; 
	}
	@userConfig = import('DiscordBot.DMs.user.settings');
	if(!is_array(@userConfig)) { @userConfig = get_value('DiscordBot.DMs.user.settings'); }
	if(is_array(@userConfig)) {
		if(!array_index_exists(@userConfig, @discord['userid'])) {
			@userConfig[@discord['userid']] = array('NotifyContent': true, 'URLReadback': false);
		}	
	} else {
		@userConfig = array();
		@userConfig[@discord['userid']] = array('NotifyContent': true, 'URLReadback': false);
	}
	
	if(!array_index_exists(@cmdargs, 0)) { @cmdargs = array('view'); }
	switch(string(@cmdargs[0])) {

	case 'notifycontent':
	case 'nc':
	case 'urlreadback':
	case 'url':
	case 'opt-out':
	case 'optout':
		@suffix = ' to the Minecraft server and Discord Admin log channel.';
		@ret = '';
		@userType = 'that user\'s';
		@userID = '';
		if(!array_index_exists(@cmdargs, 1)) {
			@userType = 'your';
			@userID = @discord['userid'];
		} else if(@discord['admin'] === false) {
			return('NotAdmin');
		} else {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord);
			if(!is_numeric(@userID)) {
				switch(@userID) {
				case 'bot':
					return(array('embeds': array(array('footer': array('text': 'I don\'t know how to DM myself'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))));
				case 'self':
					@userID = @discord['userid'];
				case 'notfound':
					return('NoUserFound');
				case 'multiple':
					return(false);
				}
			}
			if(!array_index_exists(@userConfig, @userID)) {	@userConfig[@userID] = array('NotifyContent': true, 'URLReadback': false);	}
		}
		switch(string(@cmdargs[0])) {
		case 'notifycontent':
		case 'nc':
			@userConfig[@userID]['NotifyContent'] = !@userConfig[@userID]['NotifyContent']
			if(@userConfig[@userID]['NotifyContent'] === true) {
				@ret = 'Content of '.@userType.' DMs with me shall be displayed'.@suffix;
			} else {
				@ret = 'Content of '.@userType.' DMs with me *won\'t* be displayed'.@suffix;
			}
		case 'urlreadback':
		case 'url':
			@userConfig[@userID]['URLReadback'] = !@userConfig[@userID]['URLReadback']
			if(@userConfig[@userID]['URLReadback'] === true) {
				@ret = 'I\'ll message the URL of attachments in '.@userType.' DMs with me.';
			} else {
				@ret = 'Ok, no more useless URL messages in '.@userType.' DMs with me.';
			}
		case 'opt-out':
		case 'optout':
			@userConfig[@userID]['NotifyContent'] = false;
			@userConfig[@userID]['URLReadback'] = false;
			@ret = 'Opt-out successful, Content of '.@userType.' DMs with me *won\'t* be displayed'.@suffix;
		}
		@userConfig['lastedit'] = time();
		export('DiscordBot.DMs.user.settings', @userConfig);
		store_value('DiscordBot.DMs.user.settings', @userConfig);
		return(@ret);
	case 'view':
	default:
		@userID = @discord['userid'];
		@userSettings = @userConfig[@discord['userid']];
		if(array_index_exists(@cmdargs, 1)) {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord);
			if(!is_numeric(@userID)) {
				return('Cannot find settings for this user.');
			} else {
				@userSettings = @userConfig[@userID];
			}
		}
		@ret = 'DM settings for <@'.@userID.'>: ';
		foreach(@set: @v in @userSettings) {
			@vd = '`'.@v.'`';
			if(is_boolean(@v)) {
				if(@v === true) {
					@vd = ':white_check_mark:';
				} else { 
					@vd = ':x:';
				}
			}
			@ret .= '`'.@set.':` '.@vd.'  ';
		}
		return(@ret);
	}
	return('Last return');
}

proc _discordBot_cmd_transferroles(@discord, @args) {
	@botperms = discord_get_permissions(@discord['serverid']);
	if(!array_contains(@botperms, 'ADMINISTRATOR') && !array_contains(@botperms, 'MANAGE_ROLES')) {	return('NoPerms'); }
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@fromroleAdmin = false;
	@fromOnServer = false;
	@returnmsg = color(10).'Completed roles transfer';
	@undo = false;
	@fromroles = array();
	@toroles = array();
	if(!array_index_exists(@args, 0)) { return(color(12).'Specify the Discord user ID to copy from!'); }
	if(!array_index_exists(@args, 1)) { return(color(12).'Specify the Discord user ID to copy to!'); }
	#Setup IDs
	@id0 = @args[0];
	@id1 = @args[1];
	if(array_index_exists(@args, 2)) { 
		if(!string_contains(array_implode(@args, ''), '@')) { return(color(12).'Cannot parse user IDs given.'); }
		@test = split('@', array_implode(@args, ' '));
		if(!@test[0]) { array_remove(@test, 0); }
		if(array_size(@test) != 2) { return(color(12).'Cannot parse user IDs given ('.array_size(@test).')'); }
		@id0 = @test[0];
		@id1 = @test[1];
	}
	@fromID = if(@id0 == 'undo', @id0, _discordBot_cmd_proc_finduserID(@id0, @discord));
	if(!is_numeric(@fromID)) {
		switch(@fromID) {
		case 'bot':
			return(array('ret': false, 'embeds': array(array('footer': array('text': 'Sorry, my roles are my roles.'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))));
		case 'self':
			@fromID = @discord['userid'];
		case 'notfound':
			@fromID = @id0;
			#cache validation happens later
		case 'multiple':
			return('Error');
		case 'undo':
			@undo = true;
		}
	}
	@toID = _discordBot_cmd_proc_finduserID(@id1, @discord);
	if(!is_numeric(@toID)) {
		switch(@toID) {
		case 'bot':
			return('Thanks for the compliment, but I\'m happy with my roles.');
		case 'self':
			@toID = @discord['userid'];
		case 'notfound':
			return(array('content': 'To User ID given not found on server.', 'prefix': array('confirm', 2)));
		case 'multiple':
			return('Error');
		}
	}
	if(@fromID === @toID) { return(array('ret': false, 'embeds': array(array('footer': array('text': 'Wait, whut? you wanna transfer roles to the same person?'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif')))); }
	@TRlog = get_value('DiscordBot.'.@discord['serverid'].'.log.roles.Transfer');
	if(!is_array(@TRlog)) { @TRlog = array(); }
	
	# To User check
	try {
		@toroles = discord_member_get_roles(@discord['serverid'], @toID);
	} catch(NotFoundException @ex) {
		return(color(12).'To ID was Not Found on the Server, check ID for typos.');
	} catch(Exception @ex) {
		return(color(12).'To ID was Not Found on Server: '.@ex['message']);
	}
	@toNick = discord_member_info(@discord['serverid'], @toID)['displayname'];
	# From nickname check
	@fromNick = @fromID;
	try {
		@fromNick = discord_member_info(@discord['serverid'], @fromID)['displayname'];
		@fromOnServer = true;
	} catch(NotFoundException @ex) {
		@fromOnServer = false;
		@formerData = get_value('DiscordBot.'.@discord['serverid'].'.members.former');
		if(is_array(@formerData)) {
			# name on join
			if(array_index_exists(@formerData, @fromID, 'user')) { @fromNick = @formerData[@fromID]['user']; }
			# name on leave
			if(array_index_exists(@formerData, @fromID, 'username')) { @fromNick = @formerData[@fromID]['username']; }
			if(array_index_exists(@formerData, @fromID, 'nickname')) { @fromNick = @formerData[@fromID]['nickname']; }
		}
	}
	@selfadmin = false;
	if(@discord['admin'] === true && @discord['userid'] === @toID) { @selfadmin = true; }
	# One transfer per user
	if(array_index_exists(@TRlog, @toID, 'r') && @undo === false) {
		#ignore if admin and yourself
		if(!@selfadmin) {
			return(array('prefix': array('confirm', 0), 'content': color(12).@toNick.' has already received roles in a role transfer, and cannot receive roles again. Only one roles transfer is allowed per user account.'));
		}
	}
	# One transfer transaction per sender
	if(array_index_exists(@TRlog, @fromID, 's') && @undo === false) {
		#ignore if admin and yourself
		if(!@selfadmin) {
			return(array('prefix': array('confirm', 0), 'content': color(12).@fromNick.' has already performed a roles transfer to another user and cannot send roles again.'));
		}
	}

	@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles');
	if(!is_array(@roles)) { 
		_discordBot_update_members(@discord['serverid']);
		@roles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles');
	}
	@rolesFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former.roles');
	if(!is_array(@rolesFR)) { @rolesFR = array(); }
	@undoroles = get_value('DiscordBot.'.@discord['serverid'].'.set.roles.undo.Transfer');
	if(!is_array(@undoroles)) { @undoroles = array(); }

	# From User roles check
	if(@undo === false) {
		try {
			@fromroles = discord_member_get_roles(@discord['serverid'], @fromID);
		} catch(NotFoundException @ex) {
		# Check caches for roles
			@fc = 0;
			@fcmsg = array('or internal caches!', color(11).'Found in internal roles cache', color(10).'Found in former members roles cache', color(9).'Found in json search of current month\'s logs.', color(9).'Found in json search of logs.');
			if(is_array(@roles)) {
				if(array_index_exists(@roles, @fromID)) {
					@fromroles = @roles[@fromID];
					@fc = 1;
				} else if(array_index_exists(@rolesFR, @fromID, 'data')) {
					@fromroles = @rolesFR[@fromID]['data'];
					@fc = 2;
				} else if(function_exists('list_files')) {
					@currentMonth = simple_date('MMyy', time());
					foreach(@file in list_files(import('DiscordBot.config.dir').'/'.@discord['serverid'].'/'.@currentMonth)) {
						if(!string_ends_with(@file, 'membersRoles.json')) {continue();}
						@data = json_decode(read(file_resolve(@discord['serverid'].'/'.@currentMonth.'/'.@file)));
						if(array_index_exists(@data, @id0)) { @fc = 3; @fromroles = @data[@id0]; }
					}
					if(@fc !== 3) {
						# Not recommended due to potential for main thread stall, only here as backup
						@highDate = 0;
						foreach(@monthDir in list_files(import('DiscordBot.config.dir').'/'.@discord['serverid'])) {
							if(length(@monthDir) !== 4) { continue(); }
							foreach(@file in list_files(@discord['serverid'].'/'.@monthDir)) {
								if(!string_ends_with(@file, 'membersRoles.json')) {continue();}
								@data = json_decode(read(file_resolve(import('DiscordBot.config.dir').'/'.@discord['serverid'].'/'.@monthDir.'/'.@file)));
								if(array_index_exists(@data, @id0)) {
									if(parse_date('MM-dd-yy', split('_', @file)[1]) > @highDate) {
										@fc = 4;
										@highDate = parse_date('MM-dd-yy', split('_', @file)[1]);
										@fromroles = @data[@id0];
									}
								}
							}
						}
					}
				}
				_db_msg_Console(color(14).'Transfer Roles: From ID is Not on Server, '.@fcmsg[@fc], @discord['serverid']);
				if(@fc === 0) { return(array('content': color(12).'From ID is Not on Server, '.@fcmsg[0], 'prefix': array('confirm', 2))); }			
			} else { return(array('content': color(12).'From ID was Not Found on Server; internal storage not initialized!', 'prefix': array('confirm', 0))); }
		}
	}
	if(array_size(@fromroles) < 1) { return(array('content': color(14).'From ID had no roles.', 'prefix': array('confirm', 2))); }
	# Security checks
	# Remove admin roles.
	foreach(@rn: @rid in @fromroles) {
		if(array_contains_ic(@config['Role_Admins'], @rn) || array_contains(@config['Role_Admins'], @rid)) {
			# Ignore if you are admin and transferring to yourself
			if(@discord['admin'] === true && @discord['userid'] === @toID) { continue(); }
			@fromroleAdmin = true;
			array_remove(@fromroles, @rn);
		}
	}
	if(@fromroleAdmin === true) {
	# Disallow awarding roles from existing admin
		if(@fromOnServer === true && !@discord['admin']) {
			return(array('ret': false, 'embeds': array(array('footer': array('text': 'i saw that, nice try. no super cool permissions for you.'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))));
		}
	# Nag message
		@suffix = if(@discord['admin'] === true, 'Please verify this person before awarding any admin roles.', 'Message the server moderation team to reinstate any server access.');
		@returnmsg = color(14).'A Server Admin role was detected! For security reasons I\'m not awarding that role. '.@suffix.'\n'.color(10).@returnmsg;
	}
	
	@logMsg = 'Transfer Roles: From: '.@fromNick.'('.@fromID.') To: '.@toNick.' ('.@toID.')';
	#Undo support
	if(@undo === true) {
	#does not add from roles.
		if(array_index_exists(@undoroles, @toID)) {
			@toroles = @undoroles[@toID];
			@logMsg = 'Transfer Roles: Undid role transfer for '.@toNick.'('.@toID.')';
			@returnmsg = 'Undid Roles transfer';
		} else {
			return(color(12).'That user does not have previous data to undo!');
		}
	} else {
	# adds from roles, not sets to!
		@undoroles[@toID] = @toroles;
		store_value('DiscordBot.'.@discord['serverid'].'.set.roles.undo.Transfer', @undoroles);
		@toroles = array_merge(@toroles, @fromroles);
	}
# _db_msg_Console(@toroles, @discord['serverid'], 'debug');
# _db_msg_Console(@fromroles, @discord['serverid'], 'debug');
		
	@doSetRoles = _discordBot_set_roles(@discord['serverid'], @toID, 'set', @toroles, @logMsg, 'Transfer Roles');
	if(@doSetRoles === false) { return('Error'); }
	#Save
	@issuerName = if(@discord['userid'] === 777378696782657084, 'MC: '.@discord['username'], @discord['userid']);
	@TRlog[@toID]['r'] = array('time': time(), 'fromuser': @fromID, 'issuer': @issuerName);
	@TRlog[@fromID]['s'] = array('time': time(), 'touser': @toID, 'issuer': @issuerName);
	if(@undo === true) { array_remove(@TRlog[@TRlog[@toID]['fromuser']], 's'); array_remove(@TRlog[@toID], 'r'); }
	store_value('DiscordBot.'.@discord['serverid'].'.log.roles.Transfer', @TRlog);
	@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info');
	if(array_index_exists(@joininfo, @toID)) {
		@joininfo[@toID]['return'] = 'true';
		store_value('DiscordBot.'.@discord['serverid'].'.Join.info', @joininfo);
	}
	@msgrolesreturn = color(10).@returnmsg.' from user "'.color(3).@fromNick.'"'.color(8).' ('.@fromID.')'.' to user "'.color(11).@toNick.'"'.color(8).' ('.@toID.')'.color(10).', Roles set to:\n'.color('r').if(is_associative(@toroles), array_keys(@toroles), @toroles);
	return(array('prefix': array('confirm', 1), 'content': @returnmsg.' from user "'.color(3).@fromNick.'" to user '.if(@discord['userid'] === 777378696782657084, color(11).'"'.@toNick.'"', '<@'.@toID.'>'), 'console': @msgrolesreturn));
}


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array());
@mIu7 = array(	
	'codegen': array('alias': array('code', 'gibberish', 'generatecode', 'password'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_codegen(@discord, @args)); },
			'help': 'Generate a random set of letters, numbers and symbols.', 'usage': '[Code length (8)] [Code type (full)] [Code type 2] [Code type 3] [dm]', 'usagenote': '"dm": Send the code to only your DMs for extra privacy.. as much as could be afforded on a social media platform\n Code types: Lowercase, Uppercase, Number, Symbol, 8bit, 16bit, or Full (which is lower,upper,number)'),
	'dmoptions': array('alias': array('dm'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_dmoptions(@discord, @args)); },
			'help': 'Configure Notfication Privacy Options regarding when you DM the bot.', 'usage': '<options: notifycontent, urlreadback, opt-out>', 'usagenote': 'When you send a DM to the bot, a notification of your DM is sent to each server\'s log channel. You may request that the message content is not displayed in the notification.\n"notifycontent": Toggles displaying your message content in the DM notifications.\n"urlreadback": Toggles DM\'ing you a link to the last sent DM\'s attachments.\n"opt-out": Sets notifycontent and url readback to disabled. You cannot opt-out of sending the notification.'),
	'transferroles': array('alias': array('trroles'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_transferroles(@discord, @args)); },
			'help': 'Transfer Discord server roles from one account to another. Useful for users reconnecting with your server after they had to switch to a new account.', 'usage': '<From Username or User ID, or undo> <To Username or User ID>', 'usagenote': '-- For server security, any designated server admin roles are not given in the transfer. If you are expecting such a role contact the server\'s moderation team.\n-- Only ONE role transfer is allowed per receiving Discord account.\n-- If the From user has since left the server, the bot will make an effort to search through it\'s internal role cache to find the roles the user had. Depending on the time elapsed this effort may not be successful.\n"undo" as the from username: Undoes a transfer roles transaction for the specified "to" username, and restores the roles of the "to" user to their previous state before the transfer occured.')
);
@c3lx = array_merge(@c3lx, @mIu7);
export('DiscordBot.Command.List', @c3lx);