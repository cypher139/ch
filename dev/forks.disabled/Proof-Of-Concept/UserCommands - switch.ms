#version 1.0-tmc


/*

if channel in receive but not in send then dm output instead
*/




#Handle commands from Discord Users
# Data: userid, username, nickname, channel, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'Chat.Discord.cmd', 'priority': 'HIGH'), null, @discord) {
	@config = import('Chat.config.Discord')
	@adminChannel = import('Chat.config.Discord', array('Log_Channel': 'bot-logs'))['Log_Channel']
	#Setup list of server members
	@membersID = get_value('server.Discord.members.ID')
	if(!array_contains(@membersID, @discord['userid'])) {
		array_push(@membersID, @discord['userid'])
		store_value('server.Discord.members.ID', @membersID)
	}
	@membersnames = get_value('server.Discord.members.names')
	if(!array_contains(@membersnames, @discord['userid'])) {
		array_set(@membersnames, @config['Bot_Name'], @config['Bot_ID'])
		array_set(@membersnames, @discord['username'], @discord['userid'])
		store_value('server.Discord.members.names', @membersnames)
	}
/*	
	if(equals_ic('server-logs', @discord['channel']) == true) {
		@lastmsgs = import('Chat.Discord.last.message.logs')
		if(!is_array(@lastmsgs)) { @lastmsgs = array() }
		array_insert(@lastmsgs, @discord, 0)
		if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
		export('Chat.Discord.last.cmd.message.logs', @lastmsgs)
		console(@discord, false)
	}
*/	
	
	# PSAs
	if(_array_string_contains(parse_args(@discord['message']), 'kill')) {
		if(_array_string_contains(parse_args(@discord['message']), 'me')) {
			discord_broadcast(@discord['channel'], 'You are not alone! Call the Suicide and Crisis Lifeline at 988 or visit 988lifeline.org.')
		}
	}
	
/*	
	# Find if this is a wish or normal chat.
	@wish = _wish_finder('discord', @discord['message'], @discord['username'])
	if(@wish['wish'] != true) { 
		if(@dev == true) { msg(@wish['message']) }
		die()
	}
# Are there available wishes?

	
# Is a wish! perform action 
	@grantwish = _wish_granter(@wish['action'], @wish['target'], @player)
	if(@grantwish['success'] == true) {
		broadcast(@grantwish['message'])
	} else {
		if(@dev == true) { msg(@grantwish['message']) }
	}
*/	
	if(array_contains(@config['CMD_Channels_Receive'], @discord['channel']) == true && reg_count('^[.!~]?[Cc][Hh][!@#%*/.$,=]', @discord['message']) > 0) {
		consume()
		discord_delete_message(@discord['channel'], @discord['id'])
		array_set(@discord, 'time', time())
	#Extract Command
	@cmd = parse_args(reg_replace('^[.!~]?[Cc][Hh][!@#%*/.$,=]', '', @discord['message']))
	#Setup Arguments
	if(array_index_exists(@cmd, 1)) {
		@cmdargs = @cmd[cslice(1, array_size(@cmd) - 1)]
	} else {
		@cmdargs = array()
	}
#Save Recent Messages for reference	
	@lastmsgs = import('Chat.Discord.last.cmd.message')
	if(!is_array(@lastmsgs)) { @lastmsgs = array() }
	array_insert(@lastmsgs, @discord, 0)
	if(array_index_exists(@lastmsgs, 20)) { array_remove(@lastmsgs, 20) }
	export('Chat.Discord.last.cmd.message', @lastmsgs)
	#no command given
	if(!array_index_exists(@cmd, 0)) {
		discord_broadcast(@discord['channel'], array('embeds': array(array('description': 'Ooooh! I can\'t wait to see what command you enter next!', 'footer': array('text': '...or not'), 'image': 'https://media.tenor.com/hrg1biY9FbsAAAAC/awesome-minions.gif'))))
		die()
	}
	if(array_index_exists(@cmdargs, 0)) { @cmddis1 = 'Args: '.color(9).@cmdargs } else { @cmddis1 = '' }
	console('[Discord] '.@discord['username'].' used command: '.color(3).@cmd[0].'  '.color('r').@cmddis1, false)
	discord_broadcast(@adminChannel, @discord['username'].' used command '.@cmd[0].'  '.strip_colors(@cmddis1))


/*
@actions = array(
    'command': closure() { handlerForCommand(); },
);
if(!array_index_exists(@actions, @command)) {
    return; // Is standard message
}
@actions[@command]();
*/

# make 1 letter 

	switch(@cmd[0]) {
	case 'help':
		@admincommandlist = array('wrf', 'mc_give', 'readdm', 'senddm')
		@commandlist = array('cypher', 'say', 'fban', 'poop', 'afk', 'makemeadmin', 'code', 'passwordlist')
		@userroles = array_keys(discord_member_get_roles(@discord['username']))
		@userType = @discord['username']
		foreach(@role in @userroles) {
			if(array_contains_ic(import('Chat.config.Discord')['Role_Admins'], @role)) {
				@userType = 'Admin'
				array_push_all(@commandlist, @admincommandlist)
				break()
			}
		}
		array_sort(@commandlist, 'STRING')
		discord_private_message(@discord['userid'], 'Hi '.@userType.'! \n My Current Commands are: \n'.array_implode(@commandlist, ', '))
	case 'cypher':
		if(@discord['username'] != 'Cypher') {
			discord_broadcast(@discord['channel'], array('content': 'Cypher no Cyphing!'))
		} else {
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'Cypher was here'), 'image': 'https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif'))))
		}
	case 'say':
		if(!array_index_exists(@cmdargs, 0)) {
			discord_broadcast(@discord['channel'], array('embeds': array(array('image': 'https://media.tenor.com/Ks8QMnG25nMAAAAC/kevin-hart-say-what.gif'))))
			die()
		}
		switch(rand(1,6)) {
		case 2:
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/uvxv8BBNFNYAAAAC/kid-child.gif'))))
		case 4:
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'no. XD'), 'image':'https://media.tenor.com/pUW_A10-46MAAAAC/toddlers-and-tiaras-big-grin.gif'))))
		default:
			@sayicons = array('https://media.tenor.com/qJUcFWzUWlIAAAAd/xtina-christina-aguilera.gif', 'https://media.tenor.com/nMkuF8c3DV0AAAAC/zootopia-fox.gif', 'https://media.tenor.com/EJieOpbWHS8AAAAi/i-have-nothing-to-say-real-housewives-of-beverly-hills.gif')
			_send_discord_message(array('content': array_implode(@cmdargs, ' '), 'embeds': array(array('footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': 'requested by @'.@discord['username'])))), 'discord', @discord['channel'])
		}
	case 'fban':
	case 'fakeban':
	#todo: command cannot be run in DM
	if(!array_index_exists(@cmdargs, 0)) {
		@fbanned = @discord['userid']
	} else {
		@fbanned = reg_replace('[<>@\\\\]+', '', @cmdargs[0])
	}
	switch(@cmdargs[0]) {
	case 'me':
	case 'myself':
	case 'i':
		@fbanned = @discord['userid']
	}
	@membernames = get_value('server.Discord.members.names')
	if(!is_array(@membernames)) { 
		@membernames = array()
		array_set(@membernames, @discord['username'], @discord['userid']) 
	}
	if(is_numeric(@fbanned)) {
		if(@fbanned == @config['Bot_ID']) {
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'I don\'t ban myself you retard'),'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
			die()
		}
		if(@fbanned == @discord['userid']) {
			discord_broadcast(@discord['channel'], array('content': 'You really gonna ban yourself?', 'embeds': array(array('image': 'https://media.tenor.com/6dPcTAmTgPUAAAAi/elmo-shrug.gif'))))
			die()
		}	
		try {
			@memberroles = discord_member_get_roles(@fbanned)
		} catch (NotFoundException @ex) {
			discord_private_message(@discord['userid'], 'Fake Ban: Typo detected in user ID, using yourself instead :P')
			console('[Chat - Discord] Fake Ban: Typo detected in user ID: '.@fbanned.'!', false)
			@fbanned = @discord['userid']
		}
	} else {
		if(reg_count('^'.@config['Bot_Name'].'[#]?[0-9]{0,4}?$', @fbanned) > 0) {
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'I identify as a different bot'),'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
			die()
		}
		@fbanmatches = _array_string_match(array_keys(@membernames), @fbanned)
		if(reg_count('[#][0-9]{4}$', @fbanned) > 0 && !array_index_exists(@fbanmatches, 0)) {
			@fbanned = reg_replace('[#][0-9]{4}$', '', @fbanned)
			@fbanmatches = _array_string_match(array_keys(@membernames), @fbanned)
		}
		if(equals_ic(@fbanned, @discord['username']) || equals_ic(@fbanned, @discord['nickname'])) {
			discord_broadcast(@discord['channel'], array('content': 'You really gonna ban yourself?', 'embeds': array(array('image': 'https://media.tenor.com/6dPcTAmTgPUAAAAi/elmo-shrug.gif'))))
			die()
		}	
		console(@fbanmatches)
		
		if(!array_index_exists(@fbanmatches, 0)) {
			discord_private_message(@discord['userid'], 'Fake Ban: Could not find User ID, using yourself instead :P')
			console('[Chat - Discord] Fake Ban: Could not find user ID for '.@fbanned.'!', false)
			@fbanned = @discord['userid']
		} else if(array_index_exists(@fbanmatches, 1)) {
			discord_private_message(@discord['userid'], 'I found multiple users, not sure which one you meant to fake ban. Users Matched: \n'.array_implode(@fbanmatches, ', '))
			console('[Chat - Discord] Fake Ban: Found multiple users, not sure which one was meant to fake ban. Users Matched: \n'.array_implode(@fbanmatches, ', '), false)
			die()
		} else {
			@fbanned = @membernames[array_implode(@fbanmatches, '')]	
		}
			
	}
	console('<@'.@discord['userid'].'> bans <@'.@fbanned.'>')
# If person has been pinged recently, timeout another ban	
	@lastping = import('server.Discord.last.ping.'.@fbanned)
	if(time() < (@lastping + 234567)) {
		discord_broadcast(@discord['channel'], array('content': 'Hey, give it a rest <@'.@discord['userid'].'>!'))
	} else {
		switch(rand(1,8)) {
		case 2:
			discord_broadcast(@discord['channel'], array('embeds': array(array('image': 'https://media.tenor.com/F08xoCTJwPcAAAAC/stepbrothers-hose.gif'))))
		case 3:
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'Elmo says ...'), 'image': 'https://media.tenor.com/6dPcTAmTgPUAAAAi/elmo-shrug.gif'))))
		case 4:
			discord_broadcast(@discord['channel'], array('embeds': array(array('image': 'https://media.tenor.com/wAJE5rch0-cAAAAC/no-no-no-spider-man.gif'))))
		case 8:
			discord_broadcast(@discord['channel'], array('embeds': array(array('image': 'https://media.tenor.com/t_CPo-CUWGAAAAAC/izzy-mlp.gif'))))
		default:
			discord_broadcast(@discord['channel'], array('content': '<@'.@discord['userid'].'> bans <@'.@fbanned.'>'))
			export('server.Discord.last.ping.'.@fbanned, time())
		}
	}

	case 'wrf':
	@userroles = array_keys(discord_member_get_roles(@discord['username']))
	@isAdmin = false
	foreach(@role in @userroles) {
		if(array_contains_ic(import('Chat.config.Discord')['Role_Admins'], @role)) {
			@isAdmin = true
			break()
		}
	}
	if(@isAdmin != true) { discord_private_message(@discord['userid'], 'You need to be a Server Admin to use that.') die() }
	
	if(is_proc('_chat_cmd_wrf')) {
		if(!array_index_exists(@cmdargs, 0)) { @cmdargs = array('arg') }
		@return = _chat_cmd_wrf(@cmdargs[0])
		
		if(reg_count('^[WwNn]', @cmdargs[0]) > 0) {
			discord_broadcast(@discord['channel'], @return['amount'].' '.@return['msg'])
			@IDs = array_implode(@return['list'], '\n')
			if(reg_count('[\\s\\S]{1,1970}(?:>|$)', @IDs) > 1) {
				@split = array()
				@count = reg_count('[\\s\\S]{1,2000}(?:>|$)', @IDs)
				discord_private_message(@discord['userid'], '```List of IDs:```')
				for(@i = 1, @i <= @count, @i++) {
					@match = reg_match('[\\s\\S]{1,2000}(?:>|$)', @IDs)[0]
					array_push(@split, @match)
					@IDs = @IDs[cslice(length(@match), (length(@IDs) - 1))]
			#debug		discord_private_message(@discord['userid'], '```#'.@i.'```')
					discord_private_message(@discord['userid'], @match)
				}
			} else {
			discord_private_message(@discord['userid'], '```List of IDs:``` \n'.@IDs)
			}
		} else {		
			if(array_index_exists(@return, 'zero')) {
				discord_broadcast(@discord['channel'], array('embeds': array(array('title': 'Welcome Roles Finder', 'description': @return['zero'].' members were detected as having 0 roles.', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'].'. Use "wrf noroles" to view IDs.')))))
				# discord_broadcast(@discord['channel'], @return['zero'].' members were detected as having 0 roles. \n Use "wrf norole" to view IDs.')
			}
			if(array_index_exists(@return, 'welcome')) {
				discord_broadcast(@discord['channel'], array('embeds': array(array('title': 'Welcome Roles Finder', 'description': @return['welcome'].' members were detected as having only the Welcome Roles.', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'].'. Use "wrf welcomeroles" to view IDs.')))))
		}
		}
	} else {
		discord_broadcast(@discord['channel'], 'A required command module is not installed.')
	}
	case 'poop':
	case 'poo':
		# why is this?
		@poo = array('https://media.tenor.com/RiMH8x8TCRIAAAAC/potty-hehasrisen.gif', 'https://media.tenor.com/hCl_7woCXdcAAAAC/good-job-pooping.gif', 'https://media.tenor.com/qe2PONg34GQAAAAC/rhino-poop.gif', 'https://media.tenor.com/GQQCv59WJzAAAAAC/white-chicks.gif', 'https://media.tenor.com/n7DjU3bi514AAAAC/poop.gif')
		discord_broadcast(@discord['channel'], array('embeds': array(array('image': array_get_rand(@poo)))))
	case 'sudo':
	case 'makemeadmin':
		@userroles = discord_member_get_roles(@discord['username'])
		store_value('Chat.Discord.test.roles.'.@discord['username'], @userroles)
		@isAdmin = false
		foreach(@role in array_keys(@userroles)) {
			if(array_contains_ic(import('Chat.config.Discord')['Role_Admins'], @role)) {
				@isAdmin = true
				break()
			}
		}
		if(@isAdmin = true) { discord_private_message(@discord['userid'], 'really? You\'re already a server Admin!') }
		
		if(array_contains(@userroles, @config['Fake_Admin_Role'])) {
			discord_private_message(@discord['userid'], 'really? you trippin. you already a '.@config['Fake_Admin_Rolename'].'. Fine, I\'ll remove your admin status.')
			foreach(@rolename: @roleid in @userroles) {
				if(@roleid == @config['Fake_Admin_Role']) {
					array_remove(@userroles, @rolename)
					break()
				}
			}
		} else {
			array_push(@userroles, @config['Fake_Admin_Role'])
			discord_broadcast(@discord['channel'], '<@'.@discord['userid'].'> is now a '.@config['Fake_Admin_Rolename'].'!')
		}
		discord_member_set_roles(@discord['userid'], @userroles)
	case 'code':
	case 'gibberish':
	case 'gibberishgenerator':
	case 'codegen':
	case 'password':
		switch(rand(1,10)){
		case 4:
			discord_broadcast(@discord['channel'], array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/password_strength.png'))))
		default:
			if(is_proc('_codegen')) {	
				@dmCode = false
				if(array_index_exists(@cmdargs, 0)) {
					if(reg_count('^[-]?[PpDd]', @cmdargs[0]) > 0) {
						@dmCode = true
						array_remove(@cmdargs, 0)
					}
				}
				if(array_index_exists(@cmdargs, 0) && is_numeric(@cmdargs[0])) { 
					if(@cmdargs[0] > 512) { @length = 512 } else { @length = @cmdargs[0] }
				} else { @length = 8 }
				if(array_index_exists(@cmdargs, 1)) { @type1 = @cmdargs[1] } else { @type1 = 'full' }
				if(array_index_exists(@cmdargs, 2)) { @type2 = @cmdargs[2] } else { @type2 = '' }
				x_new_thread('CodeGenerator', closure(){
					@code = _codegen(@length, @type1, @type2)
					if(@dmCode == true) {
						discord_private_message(@discord['userid'], 'Randomly Generated code: \n'.@code)
					} else {
						discord_broadcast(@discord['channel'], @code)
					}
				});
			} else {
				discord_broadcast(@discord['channel'], 'A required command module is not installed.')
			}
		}
	case 'listpassword':
	case 'listpasswords':
	case 'passwords':	
	case 'lp':
	case 'passwordlist':
		switch(rand(1,4)) {
			case 2:
			if(is_proc('_codegen')) {	
				@results = array()		
				array_resize(@results, rand(5, 15)) 
				x_new_thread('CodeGenerator', closure(){
					foreach(@k: @v in @results) {
						@results[@k] = _codegen(rand(5, 21), rand(0, 5), rand(0, 5))
					}
					console(@results)
					discord_broadcast(@discord['channel'], 'Password for <redacted>: '.array_implode(@results, '\nPassword for <redacted>: '))
				});	
			} else {
				discord_broadcast(@discord['channel'], 'A required command module is not installed.')
			}
			case 3:
				discord_broadcast(@discord['channel'], array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/security.png')))) 
			default:
				discord_broadcast(@discord['channel'], array('embeds': array(array('image': 'https://media.tenor.com/KDm053TyIgEAAAAC/portal.gif'))))
		}
	default:
		discord_private_message(@discord['userid'], 'I have no idea what that command was about.')
	}

	}
}