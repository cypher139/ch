#version 1.0-tmc
/*
proc _discordBot_cmd_helpOLD(@discord) {
	@config = import('DiscordBot.config.Discord')
	@userType = 'User'
	try (
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
		foreach(@role in @userroles) {
			if(array_contains_ic(@config['Role_Admins'], @role)) {
				@userType = 'Admin'
				break()
			}
		}
	)
	@userTypeDisplay = ''
	@aliasDisplay = ''
	@admincommandlist = array_deep_clone(import('DiscordBot.Command.List.Admin', array()))
	@aliaseslist = array_deep_clone(import('DiscordBot.Command.List.Alias', array()))
	@commandlist = array_keys(import('DiscordBot.Command.List', array()))
	foreach(@cmd in @commandlist) {
		if(@userType != 'Admin') {
			if(array_contains_ic(@admincommandlist, @cmd)) {
				array_remove_values(@commandlist, @cmd)
			}
		}
		if(length(@cmd) < 3) { array_push(@aliaseslist, @cmd) }
		if(array_contains(@aliaseslist, @cmd)) {
			array_remove_values(@commandlist, @cmd)
		}
	}
	array_sort(@commandlist, 'STRING')
	array_sort(@aliaseslist, 'STRING')
	if(@userType == 'Admin') {
		@userTypeDisplay = ' (Admin)'
		@aliasDisplay = '\n\nAliases:'.array_implode(array_unique(@aliaseslist), ', ')
	}
	_discordBot_send_message('Hi '.@discord['username'].@userTypeDisplay.'! \n My Current Commands are: \n`'.array_implode(@commandlist, ', ').'`'.@aliasDisplay, 'discord', @discord['userid'], 'dm')
	return(true)
}
*/
proc _discordBot_cmd_ping(@discord, @args) {
	return('pong')
}

proc _discordBot_cmd_help(@discord) {
	@config = import('DiscordBot.config.Discord')
	@userTypeDisplay = ''
	@admincommandlist = array_deep_clone(import('DiscordBot.Command.List.Admin', array()))
	@aliaseslist = array_deep_clone(import('DiscordBot.Command.List.Alias', array()))
	@categorieslist = array_deep_clone(import('DiscordBot.Command.List.Categories', array()))
	if(@discord['admin'] == false) {
		array_remove(@categorieslist, 'Admin')
		foreach(@cmd in @admincommandlist) {
			array_remove_values(@aliaseslist, @cmd)
		}
	} else { @userTypeDisplay = ' (Admin)' }
	array_sort(@aliaseslist, 'STRING')
	@fields = array()
	foreach(@cat: @list in @categorieslist) {
		if(@discord['admin'] == false && @cat == 'Admin') { continue() }
		array_push(@fields, array('name': @cat, 'value': '`'.array_implode(array_sort(@list, 'STRING'), '` `').'`', 'inline': false))
	}
	@embeds = array(array('fields': @fields, 'color': array('r': 255, 'g': 204, 'b': 0), 'description': 'Command List', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/925074738437570600.webp?size=32', 'text': 'the cool bot.')))
	@aliasembed = array('fields': array(array('name': 'Aliases', 'value': '`'.array_implode(array_unique(@aliaseslist), '` `').'`', 'inline': false)), 'color': array('r': 170, 'g': 221, 'b': 0))
	if(@discord['admin'] == true) { array_push(@embeds, @aliasembed) }
	_discordBot_send_message(array('content': 'Hi '.@discord['username'].@userTypeDisplay.'!', 'embeds': @embeds), @discord['serverid'], 'discord', @discord['userid'], 'dm')
	return(true)
}

proc _discordBot_cmd_cypher(@discord) {
	if(@discord['username'] != 'Cypher') {
		_discordBot_send_message('Cypher no Cyphing!', 'discord', @discord['serverid'], @discord['SendChannel'], @discord['UseDM'])
	} else {
		_discordBot_send_message(array('embeds': array(array('footer': array('text': 'Cypher was here'), 'image': 'https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif'))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
	}
	return(true)
}

proc _discordBot_cmd_dm(@discord, @cmdargs) {
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
	case 'view':
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
		
	case 'notifycontent':
	case 'nc':
	case 'urlreadback':
	case 'url':
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
		}
		export('DiscordBot.DMs.user.settings', @userConfig);
		store_value('DiscordBot.DMs.user.settings', @userConfig);
		return(@ret)
	default:
		return(false)
	}
	return('Last return')
}

proc _discordBot_cmd_say(@discord, @cmdargs) {
	if(!array_index_exists(@cmdargs, 0)) {
		_discordBot_send_message(array('embeds': array(array('image': 'https://media.tenor.com/Ks8QMnG25nMAAAAC/kevin-hart-say-what.gif'))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
		die()
	}
	switch(rand(1,6)) {
	case 2:
		_discordBot_send_message(array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/uvxv8BBNFNYAAAAC/kid-child.gif'))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
	case 4:
		_discordBot_send_message(array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/pUW_A10-46MAAAAC/toddlers-and-tiaras-big-grin.gif'))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
	default:
		@sayicons = array('https://media.tenor.com/qJUcFWzUWlIAAAAd/xtina-christina-aguilera.gif', 'https://media.tenor.com/nMkuF8c3DV0AAAAC/zootopia-fox.gif', 'https://media.tenor.com/EJieOpbWHS8AAAAi/i-have-nothing-to-say-real-housewives-of-beverly-hills.gif')
		_discordBot_send_message(array('content': array_implode(@cmdargs, ' '), 'embeds': array(array('footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': 'requested by @'.@discord['username'])))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
	}
	return(true)
}


proc _discordBot_cmd_fakeban(@discord, @cmdargs) {
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@word = 'ban'
	@fromuser = @discord['userid']
	@target = ''
	@test = ''
	#DM support: Redirect to "bot <action> DM'er"
	if(@discord['UseDM'] == 'dm') {
		@fromuser = @botconfig['Bot_ID']
		@target = @discord['userid']
	}
	# Degrade if no arguments given
	if(!array_index_exists(@cmdargs, 0)) {
		@target = @discord['userid']
	} else {
		if(_array_string_contains(array('@everyone', '@here'), @cmdargs[0])) { return('yea no I don\'t do that to *everyone*, you\'re crazy!') }
		@target = reg_replace('[<>@\\\\]+', '', @cmdargs[0])
		switch(@cmdargs[0]) {
		case 'me':
		case 'myself':
		case 'i':
			@target = @discord['userid']
		}
	}
	#compute Target
	@targettype = _discordBot_cmd_proc_finduserID(@target, @discord)
	switch(string(@targettype)) {
	case 'bot':
		@target = @botconfig['Bot_ID']
	case 'self':
		@target = @discord['userid']
	case 'notfound':
		discord_private_message(@discord['userid'], 'Typo detected in user ID, using yourself instead :P')
		@target = @discord['userid']
	case 'multiple':
		return(false)
	default:
		@target = @targettype
		if(!is_numeric(@targettype)) {
			@target = @discord['userid']
		}
	}
	if(array_index_exists(@cmdargs, 0)) {
		array_remove(@cmdargs, 0)
	}
	if(!is_numeric(@target)) {
		_db_msg_Console('Fake Ban: non-numeric target! '.@target, @discord['serverid'], 'debug')
		@target = @discord['userid']
	}
	#Select Word
	@test2 = ''
	if(!array_index_exists(@cmdargs, 0)) {
		array_push(@cmdargs, @word)
		# if(!is_numeric(@cmdargs[0])) { @test2 = @cmdargs[0] }
	}
	if(is_numeric(@cmdargs[0])) {
		@word = 'crunches'
	} else {
		@word = reg_replace('^@', '', @cmdargs[0])
		if(_array_string_contains(@botconfig['Banned_Mentions'], @word)) { @word = 'ban' }
	}
	# Add plural if not present
	@words = reg_replace('(?<!s)$', 's', @word)
	#Target checks: bot or self
	if(@target == @botconfig['Bot_ID']) {
		return(array('embeds': array(array('footer': array('text': 'I identify as a different bot named '.@word),'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
	}
	if(@target == @discord['userid']) {
		return(array('content': 'You were really going to '.@word.' yourself?', 'embeds': array(array('image': 'https://media.tenor.com/6dPcTAmTgPUAAAAi/elmo-shrug.gif'))))
	}	

	_db_msg_Console('<@'.@fromuser.'> '.@words.' <@'.@target.'>', @discord['serverid'])
# If person has been pinged recently, timeout another ban	
	@lastping = import('DiscordBot.last.ping.'.@target)
	if(time() < (@lastping + 234567)) {
		return('Hey, give it a rest <@'.@discord['userid'].'>!')
	} else {
		switch(rand(1,8)) {
		case 2:
			return(array('embeds': array(array('image': 'https://media.tenor.com/F08xoCTJwPcAAAAC/stepbrothers-hose.gif'))))
		case 7:
			return(array('embeds': array(array('image': 'https://media.tenor.com/t_CPo-CUWGAAAAAC/izzy-mlp.gif'))))
		default:
			export('DiscordBot.last.ping.'.@target, time())
			return('<@'.@fromuser.'> '.@words.' <@'.@target.'>')
		}
	}
}

proc _discordBot_cmd_poo(@discord, @args) {
	# why is this?
	@poo = array('https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif', 'https://media.tenor.com/hCl_7woCXdcAAAAC/good-job-pooping.gif', 'https://media.tenor.com/qe2PONg34GQAAAAC/rhino-poop.gif', 'https://media.tenor.com/GQQCv59WJzAAAAAC/white-chicks.gif', 'https://media.tenor.com/n7DjU3bi514AAAAC/poop.gif')
	return(array('embeds': array(array('image': array_get_rand(@poo)))))
	}
		
proc _discordBot_cmd_fakeadmin(@discord) {	
	@msg = false
	@config = import('DiscordBot.config.'.@discord['serverid'])	
	if(@discord['UseDM'] != 'broadcast') { return('really? This isn\'t a server!') }
	@userroles = discord_member_get_roles(@discord['serverid'], @discord['username'])
# debug		store_value('DiscordBot.test.roles.'.@discord['username'], @userroles)
	if(@discord['admin'] == true) { discord_private_message(@discord['userid'], 'really? You\'re already a server Admin!') }
	
	if(array_contains(@userroles, @config['Fake_Admin_Role'])) {
		discord_private_message(@discord['userid'], 'really? you trippin. you already a '.@config['Fake_Admin_Rolename'].'. Fine, I\'ll remove your admin status.')
		foreach(@rolename: @roleid in @userroles) {
			if(@roleid == @config['Fake_Admin_Role']) {
				array_remove(@userroles, @rolename)
				break()
			}
		}
		@msg = true
	} else {
		array_push(@userroles, @config['Fake_Admin_Role'])
		@msg = '<@'.@discord['userid'].'> is now a **'.@config['Fake_Admin_Rolename'].'**!'
	}
	discord_member_set_roles(@discord['serverid'], @discord['userid'], @userroles, 'Fake Admin Role command')
	return(@msg)
}

proc _discordBot_cmd_mcwhitelist(@discord, @args) {
	@config = import('DiscordBot.config.'.@discord['serverid'])	
	@wllog = get_value('DiscordBot.server.whitelist.info')	
	@stats = array('NoUsesRemain': array(), 'AlreadyListed': array(), 'UserNotFound': array(), 'Success': array())
	if(!is_array(@wllog)) { @wllog = array('Whitelisted': array(), 'log': array(), 'uses': array()) }
	if(!array_index_exists(@wllog, 'uses', @discord['userid'])) { array_set(@wllog['uses'], @discord['userid'], 0) }
	@useList = false

	# User Must be an admin or have the required role to proceed.
	if(@discord['admin'] == true) { 
		@useList = true	
	} else {	
		try (
			@userRoles = discord_member_get_roles(@discord['serverid'], @discord['username'])
			foreach(@rolename: @roleid in @userRoles) {
				if(equals_ic(@config['Whitelist_Role'], @rolename) || @config['Whitelist_Role'] == @roleid) {
					@useList = true
					break()
				}
			}
		)
	}
	if(@useList == false) {
		return('This keycard has expired: please check The Coffee Shop for a new keycard.')
	}
	foreach(@user in @args) {
	# Limit how many whitelists a Discord user can use unless they are an admin.
		if(@wllog['uses'][@discord['userid']] >= @config['Whitelist_Allowed_Uses'] && @discord['admin'] == false) { 
			array_push(@stats['NoUsesRemain'], @user)
			continue()
		}
		if(pwhitelisted(@user)) {
			array_push(@stats['AlreadyListed'], @user)
			continue()
		} else {
			try {
				set_pwhitelisted(@user, true);
			} catch(NotFoundException @ex) {
				array_push(@stats['UserNotFound'], @user)
				continue()
			}
			array_push(@wllog['Whitelisted'], @user)
			array_set(@wllog['log'], time(), array('user': @user, 'from': @discord['userid'], 'fromuser': @discord['username']))
			@wllog['uses'][@discord['userid']]++
			array_push(@stats['Success'], @user)
		}
	}
	store_value('DiscordBot.server.whitelist.info', @wllog)

	#Send log Messages to User and server logs.
	if(array_size(@stats['Success']) > 0) {
		@s = ''
		if(array_size(@stats['Success']) > 1) { @s = 's' }
		@return = ' Whitelisted User'.@s.': `'.array_implode(@stats['Success'], '` `').'`'
		@adminmsg = '\n(Total whitelistings from '.@discord['username'].': '.@wllog['uses'][@discord['userid']].')'
		_discordBot_send_message('**'.@discord['username'].'**'.@return.@adminmsg, @discord['serverid'], 'admin');
		_db_msg_Console(color(9).@discord['username'].color(10).@return.color('r').@adminmsg, @discord['serverid']);
		@return = ':white_check_mark: '.@return
	}
	if(array_size(@stats['AlreadyListed']) > 0) {
		@s = ''
		if(array_size(@stats['AlreadyListed']) > 1) { @s = 's' }
		@return = @return.'\n:information_source: User'.@s.' `'.array_implode(@stats['AlreadyListed'], '` `').'` were already Whitelisted!'
	}
	if(array_size(@stats['NoUsesRemain']) > 0) {
		@s = ''
		if(array_size(@stats['NoUsesRemain']) > 1) { @s = 's' }
		@return = @return.'\n :warning: *You do not have enough remaining whitelist uses!* Contact the admins for assistance in whitelisting User'.@s.': `'.array_implode(@stats['NoUsesRemain'], '` `').'`'
		@adminmsg = @discord['username'].' does not have any more remaining uses to whitelist User'.@s.' `'.array_implode(@stats['NoUsesRemain'], '`  `').'`'
		_discordBot_send_message(@adminmsg, @discord['serverid'], 'admin')
		_db_msg_Console(color(14).@adminmsg, @discord['serverid'])
	}
	if(array_size(@stats['UserNotFound']) > 0) {
		@s = ''
		if(array_size(@stats['UserNotFound']) > 1) { @s = 's' }
		@return = @return.'\n:information_source: User'.@s.': `'.array_implode(@stats['UserNotFound'], '` `').'` were not found!'
	}
	return(@return)
}


#Add Commands to list
@pnqx = import('DiscordBot.Command.List.Admin', array())
@aqzy = import('DiscordBot.Command.List.Alias', array())
@c3lx = import('DiscordBot.Command.List', array())
@ow7q = import('DiscordBot.Command.List.Categories', array('Utility': array('help')))


#All commands
#Must list command caller here, and list all aliases here as well.
@yky5 = array(	
	'help': closure(@discord) { return(_discordBot_cmd_help(@discord)); },
	'ping': closure(@discord, @args) { return(_discordBot_cmd_ping(@discord, @args)); },
	'dm': closure(@discord, @args) { return(_discordBot_cmd_dm(@discord, @args)); },
	'cypher': closure(@discord) { return(_discordBot_cmd_cypher(@discord)); },
	'say': closure(@discord, @args) { return(_discordBot_cmd_say(@discord, @args)); },
	'poo': closure(@discord, @args) { return(_discordBot_cmd_poo(@discord, @args)); },
	'fakeadmin': closure(@discord) { return(_discordBot_cmd_fakeadmin(@discord)); },
	'fakeop': closure(@discord) { return(_discordBot_cmd_fakeadmin(@discord)); },
	'sudo': closure(@discord) { return(_discordBot_cmd_fakeadmin(@discord)); },
	'makemeadmin': closure(@discord) { return(_discordBot_cmd_fakeadmin(@discord)); },
	'fban': closure(@discord, @args) { return(_discordBot_cmd_fakeban(@discord, @args)); },
	'fakeban': closure(@discord, @args) { return(_discordBot_cmd_fakeban(@discord, @args)); },
	'whitelist': closure(@discord, @args) { return(_discordBot_cmd_mcwhitelist(@discord, @args)); }
)

# Categories. 
# Only name of main command.
@ow7qU = array('help', 'ping', 'dm', 'whitelist')
@ow7qF = array('cypher', 'say', 'fakeadmin', 'fakeban')


if(!array_index_exists(@ow7q, 'Utility')) { array_set(@ow7q, 'Utility', array()) }
if(!array_index_exists(@ow7q, 'Fun')) { array_set(@ow7q, 'Fun', array()) }
@ow7q['Utility'] = array_unique(array_merge(@ow7q['Utility'], @ow7qU))
@ow7q['Fun'] = array_unique(array_merge(@ow7q['Fun'], @ow7qF))
@c3lx = array_merge(@c3lx, @yky5)
#Aliases:
array_push(@aqzy, 'sudo', 'makemeadmin', 'fban', 'fakeop')
#Admin:
# array_push(@pnqx, 'wrf', 'welcomerolesfinder')
export('DiscordBot.Command.List', @c3lx)
# export('DiscordBot.Command.List.Admin', array_unique(@pnqx))
export('DiscordBot.Command.List.Alias', array_unique(@aqzy))
export('DiscordBot.Command.List.Categories', @ow7q)