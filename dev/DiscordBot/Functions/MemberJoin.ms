#version 1.2-tmc
# Requires CHDiscord build #85 or higher 
# - 70 - message callback, 81 - set role reason, 84 - invites, 85 - multiple guilds

#Welcome DM and Message for new Discord Server Members
bind('discord_member_joined', array('id': 'DiscordBot.User.join'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@time = time();
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
#Wait a few milliseconds to see if another bot insta-kicks first.
	set_timeout(500, closure(){ 
		@currentroles = array()
		try {
			@currentroles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
		} catch (NotFoundException @ex) {
	#Assume user was insta-kick (such as account age does not meet server req.)
			console('[Discord] New Join '.@discord['username'].' <@'.@discord['userid'].'> was not found on server. Were they insta-kicked??', false)
			die()
		} catch (Exception @ex) {
			console(@ex)
			die()
		}
#Setup list of server members for reference in mentions
		_discordBot_dc_add_member(@discord);
#Welcome User DM
		if(@config['Welcome_Send_DM'] == true) {
			@welcomeDMMsg = reg_replace('%WelcomeChannel%', '<#'.@config['Welcome_Text_Channel_ID'].'>', @config['Welcome_DM_Message'])
			try {
				discord_private_message(@discord['userid'], @welcomeDMMsg)
			} catch(Exception @ex) {
				console('[Discord] Cannot message '.@discord['username'].' <@'.@discord['userid'].'>, are they a bot?', false)
			}
		}
# If new member: Add Delineator roles, or roles new users need to have to access server
# If previous member: Restore old roles.
		@membersFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former.roles')   
		if(!is_array(@membersFR)) { @membersFR = array() }
		if(array_index_exists(@membersFR, @discord['userid']) && @config['Welcome_Roles_Restore'] == true) {
			array_push_all(@currentroles, @membersFR[@discord['userid']]['data'])
			discord_member_set_roles(@discord['serverid'], @discord['userid'], @currentroles, 'Previous Member Roles Restored')
			console('[Discord] '.color(2).'Previous roles restored.', false)
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
					console('[DiscordBot] ['.@discord['serverid'].'] Welcome role ID '.color('c').@id.color('r').' does not exist!', false)
				}
			}
		}
#Welcome User Messages
		if(@config['Welcome_Send_Message'] == true) {
			@welcomeMsg = reg_replace('%UserID%', '<@'.@discord['userid'].'>', @config['Welcome_Message'])
			discord_broadcast(@discord['serverid'], @config['Welcome_Text_Channel_Name'], @welcomeMsg, closure(@ex){
				@msgids = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs')
				if(!is_array(@msgids)) { @msgids = array() }
				array_set(@msgids, @discord['userid'], @ex)
				export('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', @msgids)
			});	
		}
#Log Invite Code Usage
		if(@config['Log_Invites'] == true) {
			@membersInfo = get_value('DiscordBot.'.@discord['serverid'].'.members.info')
			try {
				discord_retrieve_invites(@discord['serverid'], closure(@raw) { 
					@invMessage = @config['Log_Invites_Message']
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
								console('[DiscordBot] [Invite] '.color(3).@data['code'].color('r').' <'.color('a').@data['uses'].color('r').' > '.color(9).@previnv[@data['code']]['uses'].color('r').'>', false)
							}
						} else if(@data['uses'] == 1) {
							array_push(@matches, @code)
							console('[DiscordBot] [Invite] '.@data['code'].' <New invite>', false)
						}
					}
					
					if(array_size(@matches) == 0) {
						@invMessage = 'I could not figure out how **%User%** [%UserID%] joined!'
						console('[DiscordBot] [Invite] No invite code match found!', false)				
					}
					if(array_size(@matches) > 1) {
						@invMessage = '**%User%** [%UserID%] joined! I found multiple possible invites: \n `%InviteCode%`'
						console('[DiscordBot] [Invite] Multiple invite codes matched!! \n'.@matches, false)
						array_set(@results, 'code', @matches)
					}
					if(array_size(@matches) == 1) {
						@selectedinv = array_implode(@matches, '')
						@invitername = ''
						try { 
							@invitername = discord_member_info(@discord['serverid'], @inv[@selectedinv]['userid'])['username']
						} catch(Exception @ex) {
							@invitername = '<@'.@inv[@selectedinv]['userid'].'>'
						}
						@results = array('code': @inv[@selectedinv]['code'], 'inviter': @invitername, 'inviterid': @inv[@selectedinv]['userid'], 'use': @inv[@selectedinv]['uses'])
					}
					@invMessage = reg_replace('%User%', @discord['username'], @invMessage)
					@invMessage = reg_replace('%UserID%', @discord['userid'], @invMessage)
					@invMessage = reg_replace('%InviteCode%', @results['code'], @invMessage)
					@invMessage = reg_replace('%Uses%', @results['use'], @invMessage)
					@invMessage = reg_replace('%Inviter%', @results['inviter'], @invMessage)
					@invMessage = reg_replace('%InviterID%', @results['inviterid'], @invMessage)
					_discordBot_send_message(@invMessage, 'log', '', '', @discord['serverid'])
					array_set(@saveinv, @discord['userid'], @results)
					export('DiscordBot.'.@discord['serverid'].'.Welcome.inv', @saveinv)
					store_value('DiscordBot.'.@discord['serverid'].'.Invites', @inv)
					_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Invites.yml', yml_encode(@inv, true), 'overwrite')
				});
			} catch(InsufficientPermissionException @ex) {
				if(string_ends_with(@ex['message'], 'MANAGE_SERVER')) {
					@msg = 'Invite Logging is Enabled, however bot does not have permission to view invites!'
					console('[DiscordBot] ['.@guild.'] '.@msg, false)
					_discordBot_send_message(@msg, 'log', '', '', @discord['serverid'])
				} else {
					console('[DiscordBot] ['.@guild.'] '.@ex['message'], false)
				}
			} catch(Exception @ex) {
				console('[DiscordBot] ['.@guild.'] '.@ex['message'], false)
			}
		}
		
#Console Log
		@userDisplay = ''
		if(@discord['username'] == @discord['nickname']) {
			@userDisplay = @discord['username'].' <@'.@discord['userid'].'>'
		} else {
			@userDisplay = @discord['nickname'].' ('.@discord['username'].') <@'.@discord['userid'].'>'
		}
		console('[Discord] Member '.color(10).'joined: '.color(9).@userDisplay, false)
	});
# Get data from closures, save
	set_timeout(10000, closure(){
		@wm = import('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', array())
		@inv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())
		@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info')
		# add to array, remove imports
		if(!is_array(@joininfo)) { @joininfo = array() }
		foreach(@user: @data in @inv) {
		if(!array_index_exists(@joininfo, @user)) { array_set(@joininfo, @user, array()) }
			array_set(@joininfo[@user], 'time', @time);
			array_set(@joininfo[@user], 'user', @discord['username']);
			foreach(@k: @v in @data) {
				array_set(@joininfo[@user], @k, @v);
				# array('time': @time, 'wmid': @ex, 'user': @discord['username'], 'invite': @inv['code'], 'inviter': @inv['inviter'], 'inviterid': @inv['inviterid']))
			}
		}
		foreach(@user: @data in @wm) {
		if(!array_index_exists(@joininfo, @user)) { array_set(@joininfo, @user, array()) }
			array_set(@joininfo[@user], 'time', @time);
			array_set(@joininfo[@user], 'user', @discord['username']);
			array_set(@joininfo[@user], 'wmid', @data);
		}
		export('DiscordBot.'.@discord['serverid'].'.Welcome.msg.IDs', array())
		export('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())
		store_value('DiscordBot.'.@discord['serverid'].'.Join.info', @joininfo)
		# @jointimes = get_value('DiscordBot.'.@discord['serverid'].'.Join.times')
		# if(!is_array(@jointimes)) { @jointimes = array() }
		# array_set(@jointimes, @time, array('userid': @discord['userid'], 'user': @discord['username']))
		# store_value('DiscordBot.'.@discord['serverid'].'.Join.times', @jointimes)
		_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/Member-Join-Times.csv', @time.','.@discord['userid'].','.@discord['username'].'\n', 'Append')
	});
}

bind('discord_member_left', array('id': 'DiscordBot.User.leave'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@lbremove = 0
	@userDisplay = ''
	if(@discord['username'] == @discord['nickname']) {
		@userDisplay = @discord['username'].' <@'.@discord['userid'].'>'
	} else {
		@userDisplay = @discord['nickname'].' ('.@discord['username'].') <@'.@discord['userid'].'>'
	}
	console('[Discord] Member '.color(12).'left: '.color(9).@userDisplay, false)

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
			if(@config['LB_Options']['Remove_On_Leave'] == true) { @lbremove = 1 }
			if(@leaderboard['members'][@discord['userid']]['level'] < 6) { @lbremove = 1 }		
		}
	}
	
# Remove Welcome message and save invite data
	@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info')
	@joininfoFR = get_value('DiscordBot.'.@discord['serverid'].'.members.former')
	if(!is_array(@joininfo)) { @joininfo = array() }
	if(!is_array(@joininfoFR)) { @joininfoFR = array() }
	@invmsgSuffix = ', but I didn\'t figure out how they had joined it.'
	if(array_contains(array_keys(@joininfo), @discord['userid'])) {
	# Add leave stats to invite used
		if(!is_array(@joininfo[@discord['userid']]['code']) && @joininfo[@discord['userid']]['code'] != '') {
			@inv = get_value('DiscordBot.'.@discord['serverid'].'.Invites')
			if(!is_array(@inv)) { @inv = array() }
			if(@config['Log_Invites'] == true) {
				_discordBot_send_message('**'.@discord['username'].'** left the server, they were invited by *'.@joininfo[@discord['userid']]['inviter'].'*', 'log', '', '', @discord['serverid'])
			}
			if(array_index_exists(@inv, @joininfo[@discord['userid']]['code'])) {
				if(!array_index_exists(@inv, @joininfo[@discord['userid']]['code'], 'leaves')) { array_set(@inv[@joininfo[@discord['userid']]['code']], 'leaves', 0) }
				@inv[@joininfo[@discord['userid']]['code']]['leaves']++
				# @inv[@joininfo[@discord['userid']]['code']]['uses']--
				#Discord does not decrement uses number
				store_value('DiscordBot.'.@discord['serverid'].'.Invites', @inv)
			}
		} else if(@config['Log_Invites'] == true) {
			if(is_array(@joininfo[@discord['userid']]['code'])) { @invmsgSuffix = ', but I\'m not sure which of these invites were used: `'.array_implode(@joininfo[@discord['userid']]['code'], '  ').'`' }
			_discordBot_send_message(@discord['username'].' left the server'.@invmsgSuffix, 'log', '', '', @discord['serverid'])
		}
	# New Members:	
		if(time() < (@joininfo[@discord['userid']]['time'] + @config['Welcome_Message_Timeout'])) { 
			# Remove leaderboard entry, but don't record in former entry
			if(is_array(@leaderboard)) {
				if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { @lbremove = 2 }
			}
			# Remove Welcome message
			try { 
				discord_delete_message(@discord['serverid'], @config['Welcome_Text_Channel_Name'], @joininfo[@discord['userid']]['wmid'])
				console('[Discord] New joiner! Welcome message removed.', false)
			} catch(Exception @ex) {
				console('[Discord] Unable to remove Welcome Message! '.color('c').@ex['classType'].': '.@ex['message'], false)
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
	} else if(@config['Log_Invites'] == true) {
		_discordBot_send_message(@discord['username'].' left the server'.@invmsgSuffix, 'log', '', '', @discord['serverid'])
	}
	
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