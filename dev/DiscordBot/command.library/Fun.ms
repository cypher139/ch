proc _discordBot_cmd_cypher(@discord) {
	@return = ''
	if(@discord['username'] != 'Cypher') {
		@return = 'Cypher no Cyphing!'
	} else {
		@return = array('embeds': array(array('footer': array('text': 'Cypher was here'), 'image': 'https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif')))
	}
	return(@return)
}


proc _discordBot_cmd_say(@discord, @cmdargs) {
	@return = ''
	if(!array_index_exists(@cmdargs, 0)) {
		return(array('embeds': array(array('image': 'https://media.tenor.com/Ks8QMnG25nMAAAAC/kevin-hart-say-what.gif'))))
	}
	switch(rand(1,6)) {
	case 2:
		@return = array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/uvxv8BBNFNYAAAAC/kid-child.gif')))
	case 4:
		@return = array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/pUW_A10-46MAAAAC/toddlers-and-tiaras-big-grin.gif')))
	default:
		@sayicons = array('https://media.tenor.com/qJUcFWzUWlIAAAAd/xtina-christina-aguilera.gif', 'https://media.tenor.com/nMkuF8c3DV0AAAAC/zootopia-fox.gif', 'https://media.tenor.com/EJieOpbWHS8AAAAi/i-have-nothing-to-say-real-housewives-of-beverly-hills.gif')
		@return = array('content': array_implode(@cmdargs, ' '), 'embeds': array(array('footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': 'requested by @'.@discord['username']))))
	}
	return(@return)
}


proc _discordBot_cmd_fakeban(@discord, @cmdargs, @type) {
	@botconfig = import('DiscordBot.config.Bot')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@word = 'ban'
	@fromuser = @discord['userid']
	@target = ''
	@test = ''
	# Degrade if no arguments given
	if(!array_index_exists(@cmdargs, 0)) {
		@target = @discord['userid']
	} else {
		@target = to_lower(reg_replace('[<>@\\\\]+', '', @cmdargs[0]))
		switch(@cmdargs[0]) {
		case 'me':
		case 'myself':
		case 'i':
			@target = @discord['userid']
		case 'everyone':
		case 'here':
			return('yea no I don\'t do that to *everyone*, you\'re crazy!') 
		}
	}
	#compute Target
	if(@discord['UseDM'] == 'dm') {
		#DM support: Redirect to "bot <action> DM'er"
		@fromuser = @botconfig['Bot_ID']
		@target = @discord['userid']
	} else {
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
	}
	if(!is_numeric(@target)) {
		_db_msg_Console('Fake Ban: non-numeric target! '.@target, @discord['serverid'], 'debug')
		@target = @discord['userid']
	}
	#Select Word
	@test2 = ''
	if(!array_index_exists(@cmdargs, 1)) {
		@cmdargs[] = @word
		# if(!is_numeric(@cmdargs[1])) { @test2 = @cmdargs[1] }
	}
	if(is_numeric(@cmdargs[1])) {
		@word = 'crunches'
	} else {
		@word = reg_replace('^@', '', @cmdargs[1])
		if(string_ends_with('here', to_lower(@word)) || string_ends_with('everyone', to_lower(@word))) { @word = 'ban' }
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

proc _discordBot_cmd_quote(@discord, @args) {
	if(!array_index_exists(@args, 0)) { @args = array('none') }
	@quote = ''
	@image = ''
	switch(@args[0]) {
	case 'poo':
	# why is this?
		@image = array_get_rand(array('https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif', 'https://media.tenor.com/hCl_7woCXdcAAAAC/good-job-pooping.gif', 'https://media.tenor.com/qe2PONg34GQAAAAC/rhino-poop.gif', 'https://media.tenor.com/GQQCv59WJzAAAAAC/white-chicks.gif', 'https://media.tenor.com/n7DjU3bi514AAAAC/poop.gif'))
	case 'stoned':
		@quote = 'Bruh you just deleted a long a*s comment I was posting because it was in the wrong channel (which I get) but dam that’s a b*tch and I wish it would maybe dm me a copy of what I said or something that could not make me have to type it all out again.'
	case 'tatsu':
		@image = 'https://cdn.discordapp.com/attachments/499672534812196874/676498575244394516/ol.PNG'
	default:
		@quote = 'Cypher can cypher but not decypher\nCypher no decyphering'
	}
	@return = array()
	if(@quote != '') { array_set(@return, 'content', @quote) }
	if(@image != '') { array_set(@return, 'embeds', array(array('image': @image))) }
	return(@return)
}


proc _discordBot_cmd_1to100(@discord, @args) {
	@number = split('', rand(1,100))
	@msg = ''
	foreach(@i in @number) {
		switch(@i) {
		case 0:
			@msg = @msg.':zero: '
		case 1:
			@msg = @msg.':one: '
		case 2:
			@msg = @msg.':two: '
		case 3:
			@msg = @msg.':three: '
		case 4:
			@msg = @msg.':four: '
		case 5:
			@msg = @msg.':five: '
		case 6:
			@msg = @msg.':six: '			
		case 7:
			@msg = @msg.':seven: '			
		case 8:
			@msg = @msg.':eight: '			
		case 9:
			@msg = @msg.':nine: '
		}
	}
	return(@msg)
}

proc _discordBot_cmd_cointoss(@discord, @args) {
	@count = 1
	@numbers = array()
	@msg = ''
	@heads = 0
	@tails = 0
	if(array_index_exists(@args, 0)) {
		if(is_numeric(@args[0])) {
			@count = @args[0]
		}
	}
	if(@count < 0) { @count = 0 }
	if(@count > 50000) { @count == 123 }
	for(@i = 0, @i < @count, @i++) {
		@rand = rand(1,100)
		@numbers[] = @rand
		if(@rand % 2 == 1) { @heads++ } else { @tails++ }
	}
	if(@count == 0) {
		@msg = array('embeds': array(array('footer': array('text': '0000000000000'), 'image': 'https://media.tenor.com/VLkOCkFolbQAAAAC/toss-coin-flip.gif')))
	} else if(@count == 1) {
		if(@heads == 1) { @msg = '**Heads**' }
		if(@tails == 1) { @msg = '**Tails**' }
	} else {
		@msg = '**'.@count.'** tosses yielded'
		if(@heads > 0) { @msg = @msg.'  **'.@heads.'** Heads' }
		if(@tails > 0) { @msg = @msg.'  **'.@tails.'** Tails' }
	}
	if(!is_array(@msg)) {
		return(array('content': ':cd: '.@msg, 'console': @numbers))
	}
	return(@msg)
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
		@userroles[] = @config['Fake_Admin_Role']
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
	'poo': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_quote(@discord, array('poo'))); }),
	'quote': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_quote(@discord, @args)); }),
	'cointoss': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_cointoss(@discord, @args)); }),
	'1to100': array('alias': '', 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_1to100(@discord, @args)); }),
	'fakeadmin': array('alias': array('sudo', 'makemeadmin'), 'admin': false, 'category': 'Fun', 'cmd': closure(@discord) { return(_discordBot_cmd_fakeadmin(@discord)); }),
	'fakeban': array('alias': array('fban', 'fb'), 'admin': false, 'category': 'Fun', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_fakeban(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)