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
	_send_discord_message('Hi '.@discord['username'].@userTypeDisplay.'! \n My Current Commands are: \n`'.array_implode(@commandlist, ', ').'`'.@aliasDisplay, 'discord', @discord['userid'], 'dm')
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
	_send_discord_message(array('content': 'Hi '.@discord['username'].@userTypeDisplay.'!', 'embeds': @embeds), 'discord', @discord['userid'], 'dm')
	return(true)
}

proc _discordBot_cmd_cypher(@discord) {
	if(@discord['username'] != 'Cypher') {
		_send_discord_message('Cypher no Cyphing!', 'discord', @discord['SendChannel'], @discord['UseDM'])
	} else {
		_send_discord_message(array('embeds': array(array('footer': array('text': 'Cypher was here'), 'image': 'https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif'))), 'discord', @discord['SendChannel'], @discord['UseDM'])
	}
	return(true)
}

proc _discordBot_cmd_dm(@discord, @cmdargs) {
	@config = import('DiscordBot.config.Discord')
	@membernames = import('DiscordBot.members.names')
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
		if(array_index_exists(@cmdargs, 1)) {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord)
			if(!is_numeric(@userID)) {
				return('Cannot find settings for this user.')
			} else {
				@userSettings = @userConfig[@userID]
			}
		} else {
			@userID = @discord['userid']
			@userSettings = @userConfig[@discord['userid']]
		}
		@ret = 'DM settings for <@'.@userID.'>: '
		foreach(@set: @v in @userSettings) {
			if(is_boolean(@v)) {
				if(@v == true) {
					@vd = ':white_check_mark:'
				} else { 
					@vd = ':x:'
				}
			} else {
				@vd = '`'.@v.'`'
			}
			@ret = @ret.'`'.@set.':` '.@vd.'  '
		}
		return(@ret)
		
	case 'notifycontent':
	case 'nc':
		@suffix = ' to the Minecraft server and Discord Admin log channel.'
		if(!array_index_exists(@cmdargs, 1)) {
			@userType = 'your'
			@userID = @discord['userid']
			@userConfig[@userID]['NotifyContent'] = !@userConfig[@userID]['NotifyContent']
		} else if(@discord['admin'] == false) {
			return('NotAdmin')
		} else {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord)
			if(!is_numeric(@userID)) {
				switch(@userID) {
				case 'bot':
					return(array('embeds': array(array('footer': array('text': 'I don\'t know how to DM myself'),'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
				case 'self':
					@userID = @discord['userid']
				case 'notfound':
					return('NoUserFound')
				case 'multiple':
					return(false)
				}
			}
			if(!array_index_exists(@userConfig, @userID)) {	array_set(@userConfig, @userID, array('NotifyContent': true, 'URLReadback': false))	}
			@userType = 'that user\'s'
			@userConfig[@userID]['NotifyContent'] = !@userConfig[@userID]['NotifyContent']
		}
		if(@userConfig[@userID]['NotifyContent'] == true) {
			@ret = 'Content of '.@userType.' DMs with me shall be displayed'.@suffix
		} else {
			@ret = 'Content of '.@userType.' DMs with me *won\'t* be displayed'.@suffix	
		}
		export('DiscordBot.DMs.user.settings', @userConfig);
		store_value('DiscordBot.DMs.user.settings', @userConfig);
		return(@ret)
	case 'urlreadback':
	case 'url':
		if(!array_index_exists(@cmdargs, 1)) {
			@userType = 'your'
			@userID = @discord['userid']
			@userConfig[@userID]['URLReadback'] = !@userConfig[@userID]['URLReadback']
		} else if(@discord['admin'] == false) {
			return('NotAdmin')
		} else {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord)
			if(!is_numeric(@userID)) {
				switch(@userID) {
				case 'bot':
					return(array('embeds': array(array('footer': array('text': 'I don\'t know how to DM myself'),'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
				case 'self':
					@userID = @discord['userid']
				case 'notfound':
					return('NoUserFound')
				case 'multiple':
					return(false)
				}
			}
			if(!array_index_exists(@userConfig, @userID)) {	array_set(@userConfig, @userID, array('NotifyContent': true, 'URLReadback': false))	}
			@userType = 'that user\'s'
			@userConfig[@userID]['URLReadback'] = !@userConfig[@userID]['URLReadback']
		}
		if(@userConfig[@userID]['URLReadback'] == true) {
			@ret = 'I\'ll message the URL of attachments in '.@userType.' DMs with me.'
		} else {
			@ret = 'Ok, no more useless URL messages in '.@userType.' DMs with me.'	
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
		_send_discord_message(array('embeds': array(array('image': 'https://media.tenor.com/Ks8QMnG25nMAAAAC/kevin-hart-say-what.gif'))), 'discord', @discord['SendChannel'], @discord['UseDM'])
		die()
	}
	switch(rand(1,6)) {
	case 2:
		_send_discord_message(array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/uvxv8BBNFNYAAAAC/kid-child.gif'))), 'discord', @discord['SendChannel'], @discord['UseDM'])
	case 4:
		_send_discord_message(array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/pUW_A10-46MAAAAC/toddlers-and-tiaras-big-grin.gif'))), 'discord', @discord['SendChannel'], @discord['UseDM'])
	default:
		@sayicons = array('https://media.tenor.com/qJUcFWzUWlIAAAAd/xtina-christina-aguilera.gif', 'https://media.tenor.com/nMkuF8c3DV0AAAAC/zootopia-fox.gif', 'https://media.tenor.com/EJieOpbWHS8AAAAi/i-have-nothing-to-say-real-housewives-of-beverly-hills.gif')
		_send_discord_message(array('content': array_implode(@cmdargs, ' '), 'embeds': array(array('footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': 'requested by @'.@discord['username'])))), 'discord', @discord['SendChannel'], @discord['UseDM'])
	}
	return(true)
}


proc _discordBot_cmd_fakeban(@discord, @cmdargs) {
	@config = import('DiscordBot.config.Discord')
	@word = 'ban'
	if(array_index_exists(@cmdargs, 1)) {
		if(is_numeric(@cmdargs[1])) {
			@word = 'crunches'
		} else {
			@word = reg_replace('^@', '', @cmdargs[1])
			if(_array_string_contains(@config['Banned_Mentions'], @word)) { @word = 'ban' }
		}
	}
# Add plural if not present
	@words = reg_replace('(?<!s)$', 's', @word)
# Degrade if no arguments given
	if(!array_index_exists(@cmdargs, 0)) {
		@target = @discord['userid']
	} else {
		if(_array_string_contains(@config['Banned_Mentions'], @cmdargs[0])) { return('yea no I don\'t do that to *everyone*, you\'re crazy!') }
		@target = reg_replace('[<>@\\\\]+', '', @cmdargs[0])
		switch(@cmdargs[0]) {
		case 'me':
		case 'myself':
		case 'i':
			@target = @discord['userid']
		}
	}
	@membernames = get_value('DiscordBot.members.names')
	if(!is_array(@membernames)) { 
		@membernames = array()
		array_set(@membernames, @discord['username'], @discord['userid']) 
	}
	if(is_numeric(@target)) {
		if(@target == @config['Bot_ID']) {
			return(array('embeds': array(array('footer': array('text': 'I don\'t '.@word.' myself you retard'),'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
		}
		if(@target == @discord['userid'] && @discord['UseDM'] != 'dm') {
			return(array('content': 'You were really going to '.@word.' yourself?', 'embeds': array(array('image': 'https://media.tenor.com/6dPcTAmTgPUAAAAi/elmo-shrug.gif'))))
		}	
		try {
			@memberroles = discord_member_get_roles(@target)
		} catch (NotFoundException @ex) {
			discord_private_message(@discord['userid'], 'Fake Ban: Typo detected in user ID, using yourself instead :P')
			console('[Chat - Discord] Fake Ban: Typo detected in user ID: '.@target.'!', false)
			@target = @discord['userid']
		}
	} else {
		if(reg_count('^'.@config['Bot_Name'].'[#]?[0-9]{0,4}?$', @target) > 0) {
			return(array('embeds': array(array('footer': array('text': 'I identify as a different bot'),'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
		}
		@targetmatches = _array_string_match(array_keys(@membernames), @target)
		if(reg_count('[#][0-9]{4}$', @target) > 0 && !array_index_exists(@targetmatches, 0)) {
			@target = reg_replace('[#][0-9]{4}$', '', @target)
			@targetmatches = _array_string_match(array_keys(@membernames), @target)
		}
		if(equals_ic(@target, @discord['username']) || equals_ic(@target, @discord['nickname'])) {
			return(array('content': 'You were really going to '.@word.' yourself?', 'embeds': array(array('image': 'https://media.tenor.com/6dPcTAmTgPUAAAAi/elmo-shrug.gif'))))
		}	
		console('[Chat - Discord] Fake ban: debug: match: '.@targetmatches)
		
		if(!array_index_exists(@targetmatches, 0)) {
			discord_private_message(@discord['userid'], 'Fake Ban: Could not find User ID, using yourself instead :P')
			console('[Chat - Discord] Fake Ban: Could not find user ID for '.@target.'!', false)
			@target = @discord['userid']
		} else if(array_index_exists(@targetmatches, 1)) {
			discord_private_message(@discord['userid'], 'I found multiple users, not sure which one you meant to fake ban. Users Matched: \n'.array_implode(@targetmatches, ', '))
			console('[Chat - Discord] Fake Ban: Found multiple users, not sure which one was meant to fake ban. Users Matched: \n'.array_implode(@targetmatches, ', '), false)
			return(false)
		} else {
			@target = @membernames[array_implode(@targetmatches, '')]	
		}
			
	}
	#DM support: Redirect to "bot <action> DM'er"
	if(@discord['UseDM'] == 'dm') {
		@fromuser = @config['Bot_ID']
		@target = @discord['userid']
	} else {
		@fromuser = @discord['userid']
	}
	
	console('[Chat - Discord] <@'.@fromuser.'> '.@words.' <@'.@target.'>')
# If person has been pinged recently, timeout another ban	
	@lastping = import('DiscordBot.last.ping.'.@target)
	if(time() < (@lastping + 234567)) {
		return('Hey, give it a rest <@'.@discord['userid'].'>!')
	} else {
		switch(rand(1,9)) {
		case 2:
			return(array('embeds': array(array('image': 'https://media.tenor.com/F08xoCTJwPcAAAAC/stepbrothers-hose.gif'))))
		case 4:
			return(array('embeds': array(array('image': 'https://media.tenor.com/wAJE5rch0-cAAAAC/no-no-no-spider-man.gif'))))
		case 8:
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
	@config = import('DiscordBot.config.Discord')	
	if(@discord['UseDM'] != 'broadcast') { return('really? This isn\'t a server!') }
	@userroles = discord_member_get_roles(@discord['username'])
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
	discord_member_set_roles(@discord['userid'], @userroles)
	return(@msg)
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
	'fakeban': closure(@discord, @args) { return(_discordBot_cmd_fakeban(@discord, @args)); }
)

# Categories. 
# Only name of main command.
@ow7qU = array('help', 'ping', 'dm')
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