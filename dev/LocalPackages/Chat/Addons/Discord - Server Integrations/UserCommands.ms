#version 1.0-tmc

# .members.names

/*
https://tenor.com/view/twenty-century-fox-meme-gfy-go-fuck-yourself-meme-get-lost-gif-26260205
https://tenor.com/view/fuck-wtf-gif-21705501
https://tenor.com/view/stepbrothers-hose-gif-20871115
*/

# Load Discord Command Configs
@7bgrgf5 = ''
try {
	@7bgrgf5 = yml_decode(read(import('Chat.config.dir').'/Discord_Commands_config.yml'))
} catch(IOException @ex) {
	_msgAdmins('[Chat - Discord] Commands Config file could not be read. '.@ex['message'])
	die()
} catch(FormatException @ex) {
	_msgAdmins('[Chat - Discord] Commands Config file is improperly formatted.') 
	die()
} catch(Exception @ex) {
	_msgAdmins('[Chat - Discord] There was an error with the Commands Config file. '.@ex['message']) 
	die()
}
if(array_contains(@7bgrgf5['Channels_Receive'], 'default')) {
	_msgAdmins('[Chat - Discord] Config file is still using default values. Please configure it in order to use various Discord features.') 
	die()
}
export('Chat.config.Discord.Commands', @7bgrgf5)


#Handle commands from Discord Users
# Data: userid, username, nickname, channel, message, id, attachments {{url, filename, description}}
bind('discord_message_received', array('id': 'Chat.Discord.cmd'), null, @discord) {
	@config = import('Chat.config.Discord.Commands')
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
	
	if(array_contains(@config['Channels_Receive'], @discord['channel']) == true && reg_count('^[!~]?[Cc][Hh][!@#%*/.$,=]', @discord['message']) > 0) {
		discord_delete_message(@discord['channel'], @discord['id'])
		array_set(@discord, 'time', time())
	#Extract Command
	@cmd = parse_args(reg_replace('^[!~]?[Cc][Hh][!@#%*/.$,=]', '', @discord['message']))
	console(@cmd)
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
	console('cmd: '.@cmd[0])
	console('cmda: '.@cmdargs)
	switch(@cmd[0]) {
	case 'help':
		@commandlist = array('cypher', 'say', 'fban')
		discord_private_message(@discord['userid'], 'Current Commands: \n'.array_implode(@commandlist, ', '))
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
		switch(rand(1,5)) {
		case 2:
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'no. XD'), 'image': 'https://media.tenor.com/uvxv8BBNFNYAAAAC/kid-child.gif'))))
		case 3:
			discord_broadcast(@discord['channel'], array('embeds': array(array('footer': array('text': 'no. XD'), 'image':'https://media.tenor.com/pUW_A10-46MAAAAC/toddlers-and-tiaras-big-grin.gif'))))
		default:
			@sayicons = array('https://media.tenor.com/qJUcFWzUWlIAAAAd/xtina-christina-aguilera.gif', 'https://media.tenor.com/nMkuF8c3DV0AAAAC/zootopia-fox.gif', 'https://media.tenor.com/EJieOpbWHS8AAAAi/i-have-nothing-to-say-real-housewives-of-beverly-hills.gif')
			discord_broadcast(@discord['channel'], array('embeds': array(array('thumbnail': array_get_rand(@sayicons), 'description': array_implode(@cmdargs, ' '), 'footer': array('text': '@'.@discord['username'].' made me do this')))))
		}
	case 'fban':
	case 'fakeban':
	if(!array_index_exists(@cmdargs, 0)) {
		@fbanned = @discord['userid']
	} else {
		@fbanned = reg_replace('[<>@\\\\]+', '', @cmdargs[0])
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

	default:
		discord_private_message(@discord['userid'], 'I have no idea what that command was about.')
	}

	}
}