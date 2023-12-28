# Welcome DM and Message for new Discord Server Members, and record invite used.
bind('discord_member_joined', array('id': 'DiscordBot.User.join'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@time = time();
	#This event gives display names under "nickname" index
	@userDisplay = @discord['username']
	@userDisplaydc = @discord['username']
	if(nequals_ic(@discord['username'], @discord['nickname'])) {
		@userDisplay = @discord['nickname'].' ('.@discord['username'].')'
		@userDisplaydc = @discord['nickname'].'  ` '.@discord['username'].' ` '
	}
	@consolejoinMsg = 'Member '.color(10).'joined: '.color(9).@userDisplay.color(8).' <@'.@discord['userid'].'>'.color('r')
	export('DiscordBot.'.@discord['serverid'].'.CacheUpdate', true)
# Set New User for other checks
	export('DiscordBot.'.@discord['serverid'].'.new.user.'.@discord['userid'], true);
# Log Invite Code Usage
	if(@config['Log_Invites'] == true) {
		@membersInfo = get_value('DiscordBot.'.@discord['serverid'].'.members.info')
		try {
			discord_retrieve_invites(@discord['serverid'], closure(@raw) { 
				@invMessage = @config['Log_Invites_Message']
				@msgSuffix = ''
				# Convert raw arrays to associative
				@previnv = get_value('DiscordBot.'.@discord['serverid'].'.Invites')
				if(!is_array(@previnv)) {
					@previnv = array()
					foreach(@i: @invite in @raw) { array_set(@previnv, @invite['code'], @invite) }
					store_value('DiscordBot.'.@discord['serverid'].'.Invites', @previnv)
				}
				@inv = array_deep_clone(@previnv)
				foreach(@i: @invite in @raw) {
					array_set(@inv, @invite['code'], @invite)
					if(array_index_exists(@previnv, @invite['code'], 'leaves')) {
						array_set(@inv[@invite['code']], 'leaves', @previnv[@invite['code']]['leaves'])	
					}
					if(array_index_exists(@previnv, @invite['code'], 'username')) {
						array_set(@inv[@invite['code']], 'username', @previnv[@invite['code']]['username'])
					} else if(array_contains(@membersInfo, @invite['userid'])) {
						array_set(@inv[@invite['code']], 'username', @membersInfo[@invite['userid']]['username'])
					} 
				}
				@saveinv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv')
				if(!is_array(@saveinv)) { @saveinv = array() }
				@results = array('code': '', 'inviter': 'Not Found', 'inviterid': 0, 'use': 0)
				@matches = array()
				# Find Changed Uses Count
				foreach(@code: @data in @inv) {
					if(array_index_exists(@previnv, @data['code'])) {
						if(@data['uses'] > @previnv[@data['code']]['uses']) {
							array_push(@matches, @code)
							@msgSuffix = 'Invite: '.color(3).@data['code'].color('r').' <'.color(10).@data['uses'].color('r').' > '.color(9).@previnv[@data['code']]['uses'].color('r').'>'
						}
					} else if(@data['uses'] == 1) {
						array_push(@matches, @code)
						@msgSuffix = 'Invite: '.color(3).@data['code'].color('r').' <'.color(10).'New invite'.color('r').'>'
					}
				}	
				if(array_size(@matches) == 0) {
					@invMessage = 'I could not figure out how **%User%** [%UserID%] joined!'
					@msgSuffix = 'No invite code match found!'			
				}
				if(array_size(@matches) > 1) {
					@invMessage = '**%User%** [%UserID%] joined! I found multiple possible invites: \n`'.array_implode(@matches, '` `').'`'
					@msgSuffix = 'Multiple invite codes matched!! \n'.@matches
					array_set(@results, 'code', @matches)
				}
				if(array_size(@matches) == 1) {
					@selectedCode = array_implode(@matches, '')
					@invitername = ''
					@inviterinfo = ''
					try { 
						@inviterinfo = discord_member_info(@discord['serverid'], @inv[@selectedCode]['userid'])['username']
					} catch(Exception @ex) {
						@inviterinfo = ''
					}
					if(array_index_exists(@inv, @selectedCode, 'username')) {
						if(nequals_ic(@inviterinfo, @inv[@selectedCode]['username']) && @inviterinfo != '') {
							array_set(@inv[@selectedCode], 'previousname', @inv[@selectedCode]['username'])
							array_set(@inv[@selectedCode], 'username', @inviterinfo)
						}
						@invitername = @inv[@selectedCode]['username']
					} else if(@inviterinfo != '') {
						@invitername = @inviterinfo
						array_set(@inv[@selectedCode], 'username', @inviterinfo)
					} else {
						@invitername = '<@'.@inv[@selectedCode]['userid'].'>'
					}
					@results = array('code': @inv[@selectedCode]['code'], 'inviter': @invitername, 'inviterid': @inv[@selectedCode]['userid'], 'use': @inv[@selectedCode]['uses'])
				}
				@invMessage = replace(@invMessage, '%User%', @userDisplaydc)
				@invMessage = replace(@invMessage, '%UserID%', @discord['userid'])
				@invMessage = replace(@invMessage, '%InviteCode%', @results['code'])
				@invMessage = replace(@invMessage, '%Uses%', @results['use'])
				@invMessage = replace(@invMessage, '%Inviter%', @results['inviter'])
				@invMessage = replace(@invMessage, '%InviterID%', @results['inviterid'])
				if(@results['use'] < 2) { 
					@invMessage = replace(@invMessage, '%InviterID1%', @results['inviterid'])
				} else {
					@invMessage = replace(@invMessage, '%InviterID1%', '')
				}
				array_set(@saveinv, @discord['userid'], @results)
				export('DiscordBot.'.@discord['serverid'].'.Welcome.inv', @saveinv)
				store_value('DiscordBot.'.@discord['serverid'].'.Invites', @inv)
				# Logs
				_discordBot_send_message(@invMessage, @discord['serverid'], 'log');
				_db_msg_Console(@consolejoinMsg.' '.@msgSuffix, @discord['serverid']);
				_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Invites.yml', yml_encode(@inv, true), 'overwrite');
			});
		} catch(InsufficientPermissionException @ex) {
			if(string_ends_with(@ex['message'], 'MANAGE_SERVER')) {
				@msg = 'Invite Logging is Enabled, however I do not have permission to view invites!'
				_db_msg_Console('['.@guild.'] '.@msg, @discord['serverid'])
				_discordBot_send_message(@msg, @discord['serverid'], 'log')
			} else {
				_db_msg_Console('['.@guild.'] '.@ex['message'], @discord['serverid'])
			}
		} catch(Exception @ex) {
			_db_msg_Console('['.@guild.'] '.@ex['message'], @discord['serverid'])
		}
	}		
# Wait a few milliseconds to see if another bot insta-kicks first.
	set_timeout(1000, closure(){ 
		@currentroles = array()
		try {
			@currentroles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
		} catch (NotFoundException @ex) {
	#Assume user was insta-kick (such as account age does not meet server req.)
			_db_msg_Console('New Join '.@discord['username'].' <@'.@discord['userid'].'> was not found on server. Were they insta-kicked??', @discord['serverid'])
			die()
		} catch (Exception @ex) {
			_db_msg_Console(@ex, @discord['serverid'], 'debug')
			die()
		}
# Restore leaderboard entry	
	@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard')
	@oldlb = get_value('DiscordBot.'.@discord['serverid'].'.members.former.leaderboard')
	if(is_array(@leaderboard) && is_array(@oldlb)) {
		if(array_index_exists(@oldlb, @discord['userid'])) {
			array_set(@leaderboard['members'], @discord['userid'], @oldlb[@discord['userid']])
			array_remove(@leaderboard['members'][@discord['userid']], 'removed')
			@leaderboard['lastedit'] = time()
			export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
		}
	}
# Setup list of server members for reference in mentions
		_discordBot_dc_add_member(@discord);
# Welcome User DM
		if(@config['Welcome_Send_DM'] == true) {
			@welcomeDMMsg = reg_replace('%WelcomeChannel%', '<#'.@config['Welcome_Text_Channel_ID'].'>', @config['Welcome_DM_Message'])
			try {
				discord_private_message(@discord['userid'], @welcomeDMMsg)
			} catch(Exception @ex) {
				_db_msg_Console('Cannot message '.@discord['username'].' <@'.@discord['userid'].'>, are they a bot?', @discord['serverid'])
			}
		}
# If new member: Add Delineator roles, or roles new users need to have to access server
# If previous member: Restore old roles.
		@membersFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former.roles')   
		if(!is_array(@membersFR)) { @membersFR = array() }
		if(array_index_exists(@membersFR, @discord['userid']) && @config['Welcome_Roles_Restore'] == true) {
			array_push_all(@currentroles, @membersFR[@discord['userid']]['data'])
			discord_member_set_roles(@discord['serverid'], @discord['userid'], @currentroles, 'Previous Member Roles Restored')
			_db_msg_Console(color(2).'Previous roles restored.', @discord['serverid'])
		} else {
			if(is_array(@config['Welcome_Roles']) && @config['Welcome_Roles_Award'] == true) {
				array_push_all(@currentroles, @config['Welcome_Roles'])
				try {
					discord_member_set_roles(@discord['serverid'], @discord['userid'], @currentroles, 'Add Welcome Roles');
				} catch(NotFoundException @ex) {
					@id = ''
					foreach(@word in parse_args(@ex['message'])) {
						if(string_starts_with(@word, '"')) { @id = replace(@word, '"', '') }
					}
					_db_msg_Console('  '.@discord['serverid'].'] Welcome role ID '.color('c').@id.color('r').' does not exist!', @discord['serverid'])
				}
			}
		}
# Welcome User Messages
		if(@config['Welcome_Send_Message'] == true) {
			@welcomeMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @config['Welcome_Message'])
			discord_broadcast(@discord['serverid'], @config['Welcome_Text_Channel_Name'], @welcomeMsg, closure(@ex){
				@msgids = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs')
				if(!is_array(@msgids)) { @msgids = array() }
				array_set(@msgids, @discord['userid'], @ex)
				export('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', @msgids)
			});	
		}
# Console Log
		if(@config['Log_Invites'] == false) { _db_msg_Console(@consolejoinMsg, @discord['serverid']) }
	});
# Unset New User for other checks
	set_timeout(@config['AS_New_User_Time'], closure(){
		export('DiscordBot.'.@discord['serverid'].'.new.user.'.@discord['userid'], false);
	});
# Get data from closures, save
	set_timeout(10000, closure(){
		@wm = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', array())
		@inv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())
		@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info')
		if(!is_array(@joininfo)) { @joininfo = array() }
		@isMember = true
		try {
			@test = discord_member_info(@discord['serverid'], @discord['userid'])
		} catch(Exception @ex) {
			@isMember = false
			_db_msg_Console('['.@discord['userid'].'] '.@discord['username'].' joined ... and left!??', @discord['serverid'])
		}
		if(!array_index_exists(@joininfo, @discord['userid']) && @isMember == true) { 
			array_set(@joininfo, @discord['userid'], array())
			array_set(@joininfo[@discord['userid']], 'time', @time);
			array_set(@joininfo[@discord['userid']], 'user', @discord['username']);
		}
		if(array_index_exists(@inv, @discord['userid'])) { 
			if(@isMember == true) {
				foreach(@k: @v in @inv[@discord['userid']]) {
					array_set(@joininfo[@discord['userid']], @k, @v);
				}
			}
			array_remove(@inv, @discord['userid'])
		}
		if(array_index_exists(@wm, @discord['userid'])) { 
			if(@isMember == true) {
				array_set(@joininfo[@discord['userid']], 'wmid', @wm[@discord['userid']]);
			}
			array_remove(@wm, @discord['userid'])
		}
		if(@isMember == true) {
			store_value('DiscordBot.'.@discord['serverid'].'.Join.info', @joininfo)
			# @jointimes = get_value('DiscordBot.'.@discord['serverid'].'.Join.times')
			# if(!is_array(@jointimes)) { @jointimes = array() }
			# array_set(@jointimes, @time, array('userid': @discord['userid'], 'user': @discord['username']))
			# store_value('DiscordBot.'.@discord['serverid'].'.Join.times', @jointimes)
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Member-Join-Times.csv', @time.','.@discord['userid'].','.@discord['username'].'\n', 'Append')
		} else {
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Member-Join_Left-Times.csv', @time.','.@discord['userid'].','.@discord['username'].'\n', 'Append')
		}
		export('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', @wm);
		export('DiscordBot.'.@discord['serverid'].'.Welcome.inv', @inv);
	});
}

bind('discord_member_left', array('id': 'DiscordBot.User.leave'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@lbremove = 0
	@invmsgSuffix = ''
	@consoleMsgSuffix = ''
	@userDisplay = @discord['username']
	@userDisplaydc = @discord['username']
	if(nequals_ic(@discord['username'], @discord['nickname'])) {
		@userDisplay = @discord['nickname'].' ('.@discord['username'].')'
		@userDisplaydc = @discord['nickname'].'  ` '.@discord['username'].' ` '
	}
# Remove user entry from internal storages
	@membersRoles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles')
	if(!is_array(@membersRoles)) { @membersRoles = array() }
	@membersFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former.roles')
	if(!is_array(@membersFR)) { @membersFR = array() }
	if(array_contains(array_keys(@membersRoles), @discord['userid'])) {
		array_set(@membersFR, @discord['userid'], array('removed': time(), 'data': @membersRoles[@discord['userid']]))
		array_remove(@membersRoles, @discord['userid'])
		store_value('DiscordBot.'.@discord['serverid'].'.members.roles', @membersRoles)
	}
	@membersNames = import('DiscordBot.'.@discord['serverid'].'.members.names')
	if(is_array(@membersNames)) { 
		if(array_contains(array_keys(@membersNames), @discord['username'])) {
			array_remove(@membersNames, @discord['username'])
			store_value('DiscordBot.'.@discord['serverid'].'.members.names', @membersNames)
			export('DiscordBot.'.@discord['serverid'].'.members.names', @membersNames)
		}
	}
	@membersID = import('DiscordBot.'.@discord['serverid'].'.members.ID')
	if(is_array(@membersID)) { 
		if(array_contains(@membersID, @discord['userid'])) {
			array_remove_values(@membersID, @discord['userid'])
			store_value('DiscordBot.'.@discord['serverid'].'.members.ID', @membersID)
			export('DiscordBot.'.@discord['serverid'].'.members.ID', @membersID)
		}
	}
	@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard')
	if(is_array(@leaderboard)) {
		if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { 
			if(@leaderboard['members'][@discord['userid']]['level'] > 0) {
				@invmsgSuffix = '-Level: '.@leaderboard['members'][@discord['userid']]['level']
				@consoleMsgSuffix = 'Level: '.@leaderboard['members'][@discord['userid']]['level']
			}
			if(@config['LB_Options']['Remove_On_Leave'] == true) { @lbremove = 1 }
			if(@leaderboard['members'][@discord['userid']]['level'] < 6) { @lbremove = 1 }		
		}
	}
# Remove Welcome message and save invite data
	@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info')
	@joininfoFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former')
	if(!is_array(@joininfo)) { @joininfo = array() }
	if(!is_array(@joininfoFR)) { @joininfoFR = array() }
	if(!array_index_exists(@joininfo, @discord['userid'])) {
		@wm = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', array())
		@inv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())	
		if(array_index_exists(@inv, @discord['userid']) || array_index_exists(@wm, @discord['userid'])) {
			array_set(@joininfo, @discord['userid'], array())
			array_set(@joininfo[@discord['userid']], 'time', time());
			array_set(@joininfo[@discord['userid']], 'code', '');
			array_set(@joininfo[@discord['userid']], 'user', @discord['username']);
		}
		if(array_index_exists(@inv, @discord['userid'])) { 
			foreach(@k: @v in @inv[@discord['userid']]) {
				array_set(@joininfo[@discord['userid']], @k, @v);
			}
		}
		if(array_index_exists(@wm, @discord['userid'])) { array_set(@joininfo[@discord['userid']], 'wmid', @wm[@discord['userid']]) }
	}
	# @invmsgSuffix = ', but I didn\'t figure out how they had joined it.'
	@wmres = ''
	if(array_contains(array_keys(@joininfo), @discord['userid'])) {
	# Add leave stats to invite used
		if(!is_array(@joininfo[@discord['userid']]['code']) && @joininfo[@discord['userid']]['code'] != '') {
			@inv = get_value('DiscordBot.'.@discord['serverid'].'.Invites')
			if(!is_array(@inv)) { @inv = array() }
			if(array_index_exists(@inv, @joininfo[@discord['userid']]['code'])) {
				@invmsgSuffix = @invmsgSuffix.' -Inviter: '.@joininfo[@discord['userid']]['inviter']
				@consoleMsgSuffix = @consoleMsgSuffix.' Invite: '.@joininfo[@discord['userid']]['code']
				if(!array_index_exists(@inv, @joininfo[@discord['userid']]['code'], 'leaves')) { array_set(@inv[@joininfo[@discord['userid']]['code']], 'leaves', 0) }
				@inv[@joininfo[@discord['userid']]['code']]['leaves']++
				# @inv[@joininfo[@discord['userid']]['code']]['uses']--
				#Discord does not decrement uses number
				store_value('DiscordBot.'.@discord['serverid'].'.Invites', @inv)
			}
		} else if(is_array(@joininfo[@discord['userid']]['code'])) { 
			@matches = array_implode(@joininfo[@discord['userid']]['code'], '  ')
			@invmsgSuffix = ', but I\'m not sure which of these invites were used: `'.@matches.'`'
			@consoleMsgSuffix = ' Invites: '.@matches
		}
	# New Members:
		if(time() < (@joininfo[@discord['userid']]['time'] + @config['Welcome_Message_Timeout'])) {
			# Remove leaderboard entry, but don't record in former entry
			if(is_array(@leaderboard)) {
				if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { @lbremove = 2 }
			}
			# Remove Welcome message
			if(array_index_exists(@joininfo, @discord['userid'], 'wmid')) {
				try { 
					discord_delete_message(@discord['serverid'], @config['Welcome_Text_Channel_Name'], @joininfo[@discord['userid']]['wmid'])
					@wmres = color(8).' <New join>'
				} catch(Exception @ex) {
					@wmres = ' Unable to remove Welcome Message!\n'.color('c').@ex['classType'].': '.@ex['message']
				}
			}
		} else {
			#Also, only write former roles if not a new member
			store_value('DiscordBot.'.@discord['serverid'].'.members.former.roles', @membersFR)
		}
		array_set(@joininfoFR, @discord['userid'], @joininfo[@discord['userid']])
		array_set(@joininfoFR[@discord['userid']], 'removed', time())
		store_value('DiscordBot.'.@discord['serverid'].'.members.former', @joininfoFR)
		array_remove(@joininfo, @discord['userid'])
		store_value('DiscordBot.'.@discord['serverid'].'.Join.info', @joininfo)	
	}
#Send Logs
	if(@config['Log_Invites'] == true) {
		if(@invmsgSuffix != '') {
			@invmsgSuffix = '`'.@invmsgSuffix.'`'
		}
		_discordBot_send_message('**'.@userDisplaydc.'** left the server. '.@invmsgSuffix, @discord['serverid'], 'log')
	}
	_db_msg_Console('Member '.color(12).'left: '.color(9).@userDisplay.color(8).' <@'.@discord['userid'].'> '.@consoleMsgSuffix.color('r').@wmres, @discord['serverid'])
#Remove Leaderboard entry, save entry if not a new member
	if(@lbremove != 0) { 
		if(@lbremove != 2) {
			@oldlb = get_value('DiscordBot.'.@discord['serverid'].'.members.former.leaderboard')
			if(!is_array(@oldlb)) { @oldlb = array() }
			array_set(@oldlb, @discord['userid'], @leaderboard['members'][@discord['userid']])
			array_set(@oldlb[@discord['userid']], 'removed', time())
			store_value('DiscordBot.'.@discord['serverid'].'.members.former.leaderboard', @oldlb)
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Leaderboard_Removed.json', json_encode(@oldlb), 'Overwrite')
		}
		array_remove(@leaderboard['members'], @discord['userid'])
		@leaderboard['lastedit'] = time()
		export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
	}
}