#version 1.0-tmc


proc _discordBot_cmd_cypher(@discord) {
	if(@discord['username'] != 'Cypher') {
		_discordBot_send_message('Cypher no Cyphing!', 'discord', @discord['serverid'], @discord['SendChannel'], @discord['UseDM'])
	} else {
		_discordBot_send_message(array('embeds': array(array('footer': array('text': 'Cypher was here'), 'image': 'https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif'))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
	}
	return(true)
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


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'ping': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_ping(@discord, @args)); }),
	'cypher': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord) { return(_discordBot_cmd_cypher(@discord)); }),
	'say': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_say(@discord, @args)); }),
	'poo': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_poo(@discord, @args)); }),
	'fakeadmin': array('alias': array('sudo', 'makemeadmin'), 'admin': false, 'category': 'Fun', 'cmd': closure(@discord) { return(_discordBot_cmd_fakeadmin(@discord)); }),
	'fakeban': array('alias': array('fban', 'fb'), 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_fakeban(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)