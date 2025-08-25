# Welcome DM and Message for new Discord Server Members, and record invite used.
bind('discord_member_joined', array('id': 'DiscordBot.User.join'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@serverinfo = import('DiscordBot.Servers.Info.'.@discord['serverid'], array('name': @config['Server_Nickname']));
	@time = time();
	#This event gives display names under "nickname" index
	@userDisplay = @discord['username']
	@userDisplaydc = @discord['username']
	if(nequals_ic(@discord['username'], @discord['nickname'])) {
		@userDisplay = @discord['nickname'].' ('.@discord['username'].')'
		@userDisplaydc = @discord['nickname'].'  ` '.@discord['username'].' ` '
	}
	@consolejoinMsg = 'Member '.color(10).'joined: '.color(9).@userDisplay.color(8).' <@'.@discord['userid'].'>%PrevJoins%'.color('r');
	# @discordjoinMsg = strip_colors(@consolejoinMsg)
	@prevjoinsMsgC = ''
	@prevjoinsMsgD = ''
	@joinPrefix = 'Welcome'
	export('DiscordBot.'.@discord['serverid'].'.CacheUpdate', true)
# Log time(s) user joined Server
	@logJointimes = get_value('DiscordBot.'.@discord['serverid'].'.log.users.Join.Times')
	if(!is_array(@logJointimes)) { @logJointimes = array() }
	if(!array_index_exists(@logJointimes, @discord['userid'])) { array_set(@logJointimes, @discord['userid'], array()) }
	if(array_index_exists(@logJointimes, @discord['userid'], 0)) {
		@prevjoinsMsgC = ' Joins: '.array_implode(@logJointimes[@discord['userid']], ', ').' '
		@prevjoinsMsgD = '` -Joins: `'
		@joinPrefix = 'Welcome back'
		foreach(@jt in @logJointimes[@discord['userid']]) { @prevjoinsMsgD .= ' <t:'.substr(@jt, 0, 10).':f>' }
	}
	@consolejoinMsg = replace(@consolejoinMsg, '%PrevJoins%', @prevjoinsMsgC)
	# @discordjoinMsg = replace(@discordjoinMsg, '%PrevJoins%', @prevjoinsMsgD)
	array_insert(@logJointimes[@discord['userid']], @time, 0)
	store_value('DiscordBot.'.@discord['serverid'].'.log.users.Join.Times', @logJointimes)
	@sendJoinMsg = true
	@sendLogMsg = true
	if(array_index_exists(@config, 'Msg_Member_Join')) { @sendJoinMsg = @config['Msg_Member_Join'] }
	if(array_index_exists(@config, 'Log_Member_Join')) { @sendLogMsg = @config['Log_Member_Join'] }

	@joinMessage = @botconfig['Messages_Member_Join'][];
	if(array_index_exists(@config, 'Messages_Member_Join')) { 
		@joinMessage = @config['Messages_Member_Join'][];
	}
	@joinMessage['title'] = replace(@joinMessage['title'], '%User%', @userDisplaydc)
	@joinMessage['title'] = replace(@joinMessage['title'], '%Welcome%', @joinPrefix)
	@joinMessage['description'] = replace(@joinMessage['description'], '%User%', @userDisplaydc)
	@joinMessage['description'] = replace(@joinMessage['description'], '%UserID%', @discord['userid'])
	@joinPosition = array_size(discord_get_members(@discord['serverid'])) + 1;
	array_set(@joinMessage, 'footer', array('icon_url': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/23-20e3.png', 'text': @joinPosition));
	array_set(@joinMessage, 'timestamp', time())
	# array_set(@joinMessage, 'thumbnail', '')
	@invMessage = @botconfig['Log_Messages_Member_Join']
	if(array_index_exists(@config, 'Log_Messages_Member_Join')) { 
		@invMessage = @config['Log_Messages_Member_Join']
	}
	@invMessage = replace(@invMessage, '%User%', @userDisplaydc)
	@invMessage = replace(@invMessage, '%UserID%', @discord['userid'])
	@invMessage = replace(@invMessage, '%PrevJoins%', @prevjoinsMsgD)
# Log Invite Code Usage
	if(@config['Log_Invites'] == true) {
		@membersInfo = get_value('DiscordBot.'.@discord['serverid'].'.members.info')
		try {
			discord_retrieve_invites(@discord['serverid'], closure(@raw) { 
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
							@matches[] = @code
							@msgSuffix = 'Invite: '.color(3).@data['code'].color('r').' <'.color(10).@data['uses'].color('r').' > '.color(9).@previnv[@data['code']]['uses'].color('r').'>'
						}
					} else if(@data['uses'] == 1) {
						@matches[] = @code
						@msgSuffix = 'Invite: '.color(3).@data['code'].color('r').' <'.color(10).'New invite'.color('r').'>'
					}
				}	
				if(array_size(@matches) <= 0) {
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
				@invMessage = replace(@invMessage, '%InviteCode%', @results['code'])
				@invMessage = replace(@invMessage, '%Uses%', @results['use'])
				if(array_size(@matches) == 1) {
					@joinMessage['description'] = replace(@joinMessage['description'], '%Inviter%', ' Invited by: '.@results['inviter'])
					@joinMessage['description'] = replace(@joinMessage['description'], '%InviterID%', ' Invited by: <@'.@results['inviterid'].'>')
				} else {
					@joinMessage['description'] = replace(@joinMessage['description'], '%Inviter%', '')
					@joinMessage['description'] = replace(@joinMessage['description'], '%InviterID%', '')
				}
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
				if(@sendJoinMsg == true) {
					_discordBot_broadcast(@discord['serverid'], @config['Channels']['Join_Log'], array('embeds': @joinMessage));
				}
				if(@sendLogMsg == true) {
					_discordBot_broadcast(@discord['serverid'], '--log', @invMessage);
				}
				_db_msg_Console(@consolejoinMsg.' '.@msgSuffix, @discord['serverid']);
				_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Invites.yml', yml_encode(@inv, true), 'overwrite');
			});
		} catch(InsufficientPermissionException @ex) {
			if(string_ends_with(@ex['message'], 'MANAGE_SERVER')) {
				@msg = 'Invite Logging is Enabled, however I do not have permission to view invites!'
				_db_msg_Console('['.@discord['serverid'].'] '.@msg, @discord['serverid'])
				if(@sendLogMsg == true) {
					@invMessage = replace(@invMessage, '%InviteCode%', '')
					@invMessage = replace(@invMessage, '%Uses%', '')
					@invMessage = replace(@invMessage, '%Inviter%', '')
					@invMessage = replace(@invMessage, '%InviterID%', '')
					@invMessage = replace(@invMessage, '%InviterID1%', '')
					@joinMessage['description'] = replace(@joinMessage['description'], '%Inviter%', '')
					@joinMessage['description'] = replace(@joinMessage['description'], '%InviterID%', '')
					@invMessage .= '\n' 
				} else { 
					@invMessage = ''
				}
				if(@sendJoinMsg == true) {
					_discordBot_broadcast(@discord['serverid'], @config['Channels']['Join_Log'], array('embeds': @joinMessage));
				}
				if(@sendLogMsg == true) {
					_discordBot_broadcast(@discord['serverid'], '--log', @invMessage.@msg);
				}
			} else {
				_db_msg_Console('['.@discord['serverid'].'] '.@ex['message'], @discord['serverid'])
			}
		} catch(Exception @ex) {
			_db_msg_Console('['.@discord['serverid'].'] '.@ex['message'], @discord['serverid'])
		}
	#Log: Join Message
	} else {
		@invMessage = replace(@invMessage, '%InviteCode%', '')
		@invMessage = replace(@invMessage, '%Uses%', '')
		@invMessage = replace(@invMessage, '%Inviter%', '')
		@invMessage = replace(@invMessage, '%InviterID%', '')
		@invMessage = replace(@invMessage, '%InviterID1%', '')
		@joinMessage['description'] = replace(@joinMessage['description'], '%Inviter%', '')
		@joinMessage['description'] = replace(@joinMessage['description'], '%InviterID%', '')
		if(@sendJoinMsg == true) { _discordBot_broadcast(@discord['serverid'], @config['Channels']['Join_Log'], array('embeds': @joinMessage)); }
		if(@sendLogMsg == true) { _discordBot_broadcast(@discord['serverid'], '--log', @invMessage); }
	}
# Wait a few milliseconds to see if another bot insta-kicks first.
	set_timeout(1000, closure(){
		@currentroles = array()
		try {
			@currentroles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
		} catch (NotFoundException @ex) {
	# Assume user was insta-kicked: (example: account age does not meet server req.)
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
				@leaderboard['lastedit'] = @time
				export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
			}
		}
# Setup list of server members for reference in mentions
		_discordBot_dc_add_member(@discord);
# Welcome User DM
		if(@config['Welcome_Send_DM'] == true) {
			@welcomeDMMsg = reg_replace('%WelcomeChannel%', '<#'.@config['Channels']['Welcome_Message'].'>', @config['Welcome_DM_Message'])
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
			# Remove Admin roles and/or higher than bot roles
			@hr = import('DiscordBot.bot.roles.higher', array())
			@roleAdmin = false
			foreach(@rn: @rid in @currentroles) {
				@rm = false
				if(array_index_exists(@hr, @rid) || array_contains(@hr, @rn)) { @rm = true }
				if(array_contains_ic(@config['Role_Admins'], @rn) || array_contains(@config['Role_Admins'], @rid)) { @roleAdmin = true @rm = true }
				if(@rm == true) {
					array_remove(@currentroles, @rn)
				}
			}
			if(@roleAdmin == true) {
				_discordBot_broadcast(@discord['serverid'], @discord['userid'], array('dm': true, 'content': 'Hello, and welcome back to '.@serverinfo['name'].'! While I was giving you your old roles back I detected a Server Admin role. For security reasons I\'m not awarding that role, Message the server moderation team to reinstate any server access.'));
			}
			@doSetRoles = _discordBot_set_roles(@discord['serverid'], @discord['userid'], 'set', @currentroles, 'Member Rejoined, Previous Roles Restored', 'Join: Restore Previous Roles');
			if(@doSetRoles == true) {
				_db_msg_Console(color(2).'Rejoin: Previous roles restored.', @discord['serverid'])
			} else { 
				_db_msg_Console(color(12).'Rejoin: Previous roles NOT restored.', @discord['serverid'])
			}
		} else {
			if(is_array(@config['Welcome_Roles']) && @config['Welcome_Roles_Award'] == true) {
				array_push_all(@currentroles, @config['Welcome_Roles'])
				@doSetRoles = _discordBot_set_roles(@discord['serverid'], @discord['userid'], 'set', @currentroles, 'Join: Add Welcome Roles', 'Join: Welcome Roles');
				if(@doSetRoles == false) {
					_db_msg_Console(color(12).'New join: Welcome Roles were not saved.', @discord['serverid'])
				}
			}
		}
# Welcome User Messages
		if(@config['Welcome_Send_Message'] == true) {
			@welcomeMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @config['Welcome_Message'])
			_discordBot_broadcast(@discord['serverid'], @config['Channels']['Welcome_Message'], @welcomeMsg, closure(@ex){
				@msgids = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs')
				if(!is_array(@msgids)) { @msgids = array() }
				array_set(@msgids, @discord['userid'], @ex)
				export('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', @msgids)
			});	
		}
# Console Log
		if(@config['Log_Invites'] == false) { _db_msg_Console(@consolejoinMsg, @discord['serverid']) }
	});
# Get data from closures, save
	set_timeout(10000, closure(){
		@wm = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', array())
		@inv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())
		@rejoiner = false
		if(array_index_exists(@logJointimes, @discord['userid'], 1)) { @rejoiner = true }
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
			array_set(@joininfo[@discord['userid']], 'return', @rejoiner);
			array_set(@joininfo[@discord['userid']], 'position', @joinPosition);
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
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Member-Join-Times.csv', @time.','.@discord['userid'].','.@discord['username'].'\n', 'Append')
		} else {
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Member-Join_Left-Times.csv', @time.','.@discord['userid'].','.@discord['username'].'\n', 'Append')
		}
		export('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', @wm);
		export('DiscordBot.'.@discord['serverid'].'.Welcome.inv', @inv);
	});
}

bind('discord_member_left', array('id': 'DiscordBot.User.leave'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die() }
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@lbremove = 0
	@leavePosition = array_size(discord_get_members(@discord['serverid']));
	@displays = array('position': @leavePosition, 'code': '', 'inviter': '', 'leaves': '', 'level': '')
	@userDisplay = @discord['username']
	@userDisplaydc = @discord['username']
	if(nequals_ic(@discord['username'], @discord['nickname'])) {
		@userDisplay = @discord['nickname'].' ('.@discord['username'].')'
		@userDisplaydc = @discord['nickname'].'  ` '.@discord['username'].' ` '
	}
# Get number of leaves
	@logJointimes = get_value('DiscordBot.'.@discord['serverid'].'log.users.Join.Times')
	if(!is_array(@logJointimes)) { @logJointimes = array() }
	if(!array_index_exists(@logJointimes, @discord['userid'])) { array_set(@logJointimes, @discord['userid'], array()) }
	@userLeaves = array_size(@logJointimes[@discord['userid']])
	if(@userLeaves > 1) {
		@displays['leaves'] = '-Leaves: '.@userLeaves
	}
# Remove user entry from internal storages
	@membersRoles = get_value('DiscordBot.'.@discord['serverid'].'.members.roles')
	if(!is_array(@membersRoles)) { @membersRoles = array() }
	@membersFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former.roles')
	if(!is_array(@membersFR)) { @membersFR = array() }
	if(array_index_exists(@membersRoles, @discord['userid'])) {
		array_set(@membersFR, @discord['userid'], array('removed': time(), 'data': array_normalize(@membersRoles[@discord['userid']])))
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
				@displays['level'] = '-Level: '.@leaderboard['members'][@discord['userid']]['level']
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
	@wmres = ''
	if(array_index_exists(@joininfo, @discord['userid'])) {
		if(array_index_exists(@joininfo, @discord['userid'], 'position')) {
			@displays['position'] = @joininfo[@discord['userid']]['position'];
		}
	# Add leave stats to invite used
		if(array_index_exists(@joininfo, @discord['userid'], 'code')) {
			if(is_array(@joininfo[@discord['userid']]['code'])) {
			# Multiple Invite Matches
				@matches = array_implode(@joininfo[@discord['userid']]['code'], '  ')
				@displays['inviter'] = '-Invites: I\'m not sure which one: '.@matches
			} else if(@joininfo[@discord['userid']]['code'] != '') {
			# Single Invite Match
				@inv = get_value('DiscordBot.'.@discord['serverid'].'.Invites')
				if(!is_array(@inv)) { @inv = array() }
				if(array_index_exists(@inv, @joininfo[@discord['userid']]['code'])) {
					@displays['inviter'] = ' -Inviter: '.@joininfo[@discord['userid']]['inviter']
					@displays['code'] = ' Invite: '.@joininfo[@discord['userid']]['code']
					if(!array_index_exists(@inv, @joininfo[@discord['userid']]['code'], 'leaves')) { array_set(@inv[@joininfo[@discord['userid']]['code']], 'leaves', 0) }
					@inv[@joininfo[@discord['userid']]['code']]['leaves']++
					store_value('DiscordBot.'.@discord['serverid'].'.Invites', @inv)
				}
			}
		}
		array_set(@joininfoFR, @discord['userid'], @joininfo[@discord['userid']])
		array_set(@joininfoFR[@discord['userid']], 'removed', time())
	# New Members:
		if(time() < (@joininfo[@discord['userid']]['time'] + @config['Welcome_Message_Timeout'])) {
			# Remove leaderboard entry, but don't record in former entry
			if(is_array(@leaderboard)) {
				if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { @lbremove = 2 }
			}
			# Remove Welcome message
			if(array_index_exists(@joininfo, @discord['userid'], 'wmid')) {
				@hasPerm = _db_check_perms('delete', @discord['serverid'], @config['Channels']['Welcome_Message']);
				if(@hasPerm) {
					try { 
						discord_delete_message(@discord['serverid'], @config['Channels']['Welcome_Message'], @joininfo[@discord['userid']]['wmid'])
						@wmres = color(8).' <New join>'
					} catch(Exception @ex) {
						@wmres = ' Unable to remove Welcome Message!\n'.color(12).@ex['classType'].': '.@ex['message']
					}
				} else {
					@wmres = ' Member Leave was Not allowed to remove '.@discord['username'].'\'s welcome message.';
					@config = import('DiscordBot.config.'.@discord['serverid']);
					if(array_index_exists(@config, 'Nag_Server')) { _discordBot_broadcast(@discord['serverid'], @config['Nag_Server'], array('prefix': array('confirm', false), 'dm': true, 'content': @wmres), 'Bot') }
				}
			}
		} else {
			#Also, only write former roles if not a new member
			store_value('DiscordBot.'.@discord['serverid'].'.members.former', @joininfoFR)
			store_value('DiscordBot.'.@discord['serverid'].'.members.former.roles', @membersFR)
		}
		array_remove(@joininfo, @discord['userid'])
		store_value('DiscordBot.'.@discord['serverid'].'.Join.info', @joininfo)	
	} else {
	#If no join info write roles data.
		array_set(@joininfoFR, @discord['userid'], array('user': @discord['username']))
		array_set(@joininfoFR[@discord['userid']], 'removed', time())
		store_value('DiscordBot.'.@discord['serverid'].'.members.former', @joininfoFR)
		store_value('DiscordBot.'.@discord['serverid'].'.members.former.roles', @membersFR)
	}
#Send Logs
	@sendLeaveMsg = true
	if(array_index_exists(@config, 'Msg_Member_Leave')) { @sendLeaveMsg = @config['Msg_Member_Leave'] }
	if(@sendLeaveMsg == true) {
		@leaveMessage = @botconfig['Messages_Member_Leave'][];
		if(array_index_exists(@config, 'Messages_Member_Leave')) { 
			@leaveMessage = @config['Messages_Member_Leave'][];
		}
		@leaveMessage['title'] = replace(@leaveMessage['title'], '%User%', @userDisplaydc)
		@leaveMessage['description'] = replace(@leaveMessage['description'], '%User%', @userDisplaydc)
		@leaveMessage['description'] = replace(@leaveMessage['description'], '%UserID%', @discord['userid'])
		@leaveMessage['description'] = replace(@leaveMessage['description'], '%Level%', @displays['level'])
		if(@displays['position'] > 0) {	array_set(@leaveMessage, 'footer', array('icon_url': 'https://twitter.github.io/twemoji/v/14.0.2/72x72/23-20e3.png', 'text': @displays['position'])); }
		array_set(@leaveMessage, 'timestamp', time())
		_discordBot_broadcast(@discord['serverid'], @config['Channels']['Join_Log'], array('embeds': @leaveMessage));
	}
	@sendLogMsg = true
	if(array_index_exists(@config, 'Log_Member_Leave')) { @sendLogMsg = @config['Log_Member_Leave'] }
	if(@sendLogMsg == true) {
		@leaveMsg = @botconfig['Log_Messages_Member_Leave']
		if(array_index_exists(@config, 'Log_Messages_Member_Leave')) { 
			@leaveMsg = @config['Log_Messages_Member_Leave']
		}
		@leaveMsg = replace(@leaveMsg, '%User%', @userDisplaydc)
		@leaveMsg = replace(@leaveMsg, '%UserID%', @discord['userid'])
		@leaveMsg = replace(@leaveMsg, '%InviteCode%', @displays['code'])
		@leaveMsg = replace(@leaveMsg, '%Level%', @displays['level'])
		@leaveMsg = replace(@leaveMsg, '%Inviter%', @displays['inviter'])
		@leaveMsg = replace(@leaveMsg, '%PrevJoins%', @displays['leaves'])
		_discordBot_broadcast(@discord['serverid'], '--log', @leaveMsg);
	}
	_db_msg_Console('Member '.color(12).'left: '.color(9).@userDisplay.color(8).' <@'.@discord['userid'].'> '.array_implode(@displays, ' ').color('r').@wmres, @discord['serverid'])
#Remove Leaderboard entry, save entry if not a new member
	if(@lbremove != 0) { 
		if(@lbremove != 2) {
			@oldlb = get_value('DiscordBot.'.@discord['serverid'].'.members.former.leaderboard')
			if(!is_array(@oldlb)) { @oldlb = array() }
			array_set(@oldlb, @discord['userid'], @leaderboard['members'][@discord['userid']])
			array_set(@oldlb[@discord['userid']], 'removed', time())
			store_value('DiscordBot.'.@discord['serverid'].'.members.former.leaderboard', @oldlb)
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Leaderboard_Removed.json', json_encode(@oldlb), 'Overwrite')
			if(array_index_exists(@config, 'LB_Options', 'Web_Publish')) {
				if(@config['LB_Options']['Web_Publish'] == true) {
					_write_file(@botconfig['LB_Web_Path'].'/'.@discord['serverid'].'/Leaderboard_'.@discord['serverid'].'_Removed.json', json_encode(array('guild': @leaderboard['guild'], 'options': @leaderboard['options'], 'members': @oldlb, 'lastedit': time())), 'overwrite')
				}
			}
		}
		array_remove(@leaderboard['members'], @discord['userid'])
		@leaderboard['lastedit'] = time()
		export('DiscordBot.'.@discord['serverid'].'.Leaderboard', @leaderboard)
	}
}