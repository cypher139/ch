# Autosave Keys
@x9db = import('DiscordBot.db.save.keys', array());
@x9db[] = 'bot.msg.IP.Review';
export('DiscordBot.db.save.keys', array_unique(@x9db));

_discordBot_db_autosave('bot.msg.IP.Review', 'load');

#Validate IP entry given
proc _db_validate_ip(@v, @discord) {
	@ret = 0;
	@arg = replace(reg_replace('[%][0]$', '', @v), '`', '');
	# 0 = success, 1 unrecognized, 2 username, 3 user bot, 4 user self, 5 lan, 6 gateway, 7 cgnat, 8 loopback, 9 cidrblock, 10 v4 > 255, 11 v4 broadcast
	@consoleMsg = array('ok', color(12).'Geo IP lookup: Invalid IP given: '.@arg, 
		color(8).'Geo IP lookup: '.color(4).@discord['username'].' tried to doxx fellow Discord user '.@arg.'.', color(8).'Geo IP lookup: '.color(4).@discord['username'].' tried to look up bot information.', color(8).'Geo IP lookup: '.color(4).@discord['username'].' tried to doxx themselves.',
		color(12).'Geo IP lookup: LAN IP given: '.@arg, color(12).'Geo IP lookup: Gateway LAN IP given: '.@arg, color(12).'Geo IP lookup: CGNAT reserved IP given: '.@arg, color(12).'Geo IP lookup: Loopback IP given: '.@arg,
		color(12).'Geo IP lookup: CIDR Block given: '.@arg, color(12).'Geo IP lookup: invalid v4 IP given: '.@arg, color(12).'Geo IP lookup: Broadcast IP given: '.@arg);
	@noip = false;
	@cmdNames = import('DiscordBot.Command.List.Name');
	if(array_index_exists(@cmdNames, reg_replace('\\W', '', @arg))) { return(1); }
	if(string_contains(@arg, '/')) { return(9); }
	#contains both or neither octet dividers.
	if(xor(string_contains(@arg, '.'), string_contains(@arg, ':')) === false) { @noip = true; }
	#v4:
	if(string_contains(@arg, '.') && !string_contains(@arg, ':')) {
		if(!is_numeric(replace(@arg, '.', ''))) { @noip = true; }
		if(reg_count('[.]', @arg) !== 3) { @noip = true; }
		foreach(@oct in split('.', @arg)) {
			if(@oct > 255) { @ret = 10; }
			if(@oct === 255) { @ret = 11; }
		}
	} 
	#v6:
	if(!string_contains(@arg, '.') && string_contains(@arg, ':')) {
		if(reg_count('[^0-9A-Fa-f]+', @arg) > 0 || reg_count('[:]', @arg) < 2) { @noip = true; }
	}
	#lan:
	@lan = if(string_starts_with(@arg, '10.') || string_starts_with(@arg, '172.16.') || string_starts_with(@arg, '192.168.') || string_starts_with(@arg, 'fc00:') || string_starts_with(@arg, 'fd00:'), true, false);
	#lan: link local:
	if(string_starts_with(@arg, '169.254.') || string_starts_with(@arg, 'fe80:')) { @lan = true; }
	#loopback
	@loop = if(string_starts_with(@arg, '127.') || string_ends_with(@arg, '::1'), true, false);
	#cgnat:
	@cgnat = false;
	if(string_starts_with(@arg, '100.')) {
		@split = reg_split('[.:]', @arg);
		if(@split[1] > 63 && @split[1] < 128) { @cgnat = true; }
	}
	if(@ret === 0) {
		if(@noip === true) {
			@ret = 1;
			@userCheck = 'string';
			@userCheck = _discordBot_cmd_proc_finduserID(@arg, @discord, true);
			if(is_numeric(@userCheck) || @userCheck === 'bot' || @userCheck === 'self') { @ret = 2; }
			if(@userCheck === 'bot') { @ret = 3; }
			if(@userCheck === 'self') { @ret = 4; }
		}
		if(@lan === true) {
			@ret = 5;
			if(string_ends_with(@arg, '.1')) { @ret = 6; }
		}
		if(@cgnat === true) { @ret = 7; }
		if(@loop === true) { @ret = 8; }
	}
	if(@ret > 0) { _db_msg_Console(@consoleMsg[@ret], @discord['serverid'], 'warning'); }
	return(@ret);
}


# Add listed IP(s) from cypher139's IP Blacklist script's IP ping messages to the IP Blacklist file.
proc _discordBot_cmd_pingblacklist(@discord, @args) {
	# Requires IP Blacklist script and working shell command.
	if(!is_proc('_geoip_lookup')) { return('NoCmd'); }
	@ret = true;
	if(!@discord['admin']) { return('NotAdmin'); }
	@botconfig = import('DiscordBot.config.Bot');
	@cacheID = import('DiscordBot.bot.msg.IP.Review');
	if(!is_array(@cacheID)) { @cacheID = array(); }
	if(!array_index_exists(@cacheID, 'c')) { @cacheID['c'] = array(); }
	if(!array_index_exists(@cacheID, 'r')) { @cacheID['r'] = array(); }
	@messageID = @discord['id'];
	@isReaction = array_index_exists(@discord, 'messageuserid');
	if(@isReaction) {
		@messageID = @discord['id'];
		# if(@discord['messageuserid'] !== @botconfig['Bot_ID']) { return('RequireBotMsg'); }
	} else {
	# Get message ID from args
		foreach(@arg in @args) {
			if(array_index_exists(@cacheID, @arg)) {
				@messageID = @arg;
				break();
			}
		}
	}
# Check if cache reports the message was already acted upon
	if(array_contains(@cacheID['c'], @messageID)) { return('DuplicateCmd'); }
#Get IP list
	@checkIPs = array();
	if(array_index_exists(@cacheID, @messageID)) { @checkIPs = @cacheID[@messageID]; }
	#No Valid Message ID / No IPs found: Try to parse message
	if(array_size(@checkIPs) < 1) {
		if(array_index_exists(@discord, 'message')) {
			foreach(@word in parse_args(@discord['message'])) {
				@word = replace(@word, '`', '');
				if(xor(string_contains(@word, '.'), string_contains(@word, ':')) && !string_contains(@word, '/')) { @checkIPs[] = @word; } else { continue(); }
			}
		}
		foreach(@i: @v in @checkIPs) {
			@vip = _db_validate_ip(@v, @discord);
			if(@vip > 0) { array_remove(@checkIPs, @i); }
		}
	}
# Action IPs
	if(array_size(@checkIPs) > 0) {
	#Get
		@blacklistIP = import('ipbl.config.IPBlacklist');
		if(!is_array(@blacklistIP)) { array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()); }
		# Get player name(s) from IP database
		@ipuserdata = import('primus.database.IP');
		if(!is_array(@ipuserdata)) { @ipuserdata = array(); }
	#Add
		@addip = array();
		@reviewip = array();
		@userdisplay = '';
		foreach(@rawip in @checkIPs) {
			# remove v6's end "%0", ufw doesn't support.
			@ip = replace(reg_replace('[%][0]$', '', @rawip), '`', '');
			# Check for player names, don't add if found.
			if(array_index_exists(@ipuserdata, @ip) && !array_contains(@cacheID['r'], @messageID)) {
				@reviewip[@ip] = @ipuserdata[@ip];
				@userdisplay .= '\n'.@ip.': `'.array_implode(@ipuserdata[@ip], ', ').'`';
				continue();
			}
			@blacklistIP['IP_Blacklist'][] = @ip;
			@addip[] = @ip;
		}
	#Write
		if(array_size(@addip) > 0) { _ipbl_save_config(@blacklistIP); }
	#Log
		@s = if(array_size(@checkIPs) > 1, 's', '');
		_db_msg_Console(color(9).@discord['username'].color(10).' blacklisted IP'.@s.': '.color(7).array_implode(@addip, ', '), @discord['serverid']);
		@cacheID['c'][] = @messageID;
		if(array_size(@reviewip) > 0) {
			_discordBot_broadcast(@discord['serverid'], @discord['channelid'], array('content': 'These IPs have connected with a player name; If you wish to confirm blacklisting these IPs, *react to this message*.'.@userdisplay, 'reference_id': @messageID), 'bot', closure(@msgID){
				@cacheID = import('DiscordBot.bot.msg.IP.Review');
				if(!is_array(@cacheID)) { @cacheID = array(); }
				if(!array_index_exists(@cacheID, 'r')) { @cacheID['r'] = array(); }
				@cacheID[@msgID] = array_keys(@reviewip);
				@cacheID['lastedit'] = time();
				@cacheID['r'][] = @msgID;
				if(array_size(@cacheID) > 400) {
					@selectKey = array_keys(@cacheID);
					array_remove(@cacheID, @selectKey[0]);
					array_remove(@cacheID, @selectKey[1]);
					_db_msg_Console('[ipr-review] IP review msg Cache: b: '.array_size(@selectKey).' | a: '.array_size(@cacheID).' | picked: '.@selectKey[0].' / '.@selectKey[1], @discord['serverid'], 'debug');
				}
				export('DiscordBot.bot.msg.IP.Review', @cacheID);
				return(true);
			});
		}
		if(array_size(@cacheID) > 400) {
			@selectKey = array_keys(@cacheID);
			array_remove(@cacheID, @selectKey[0]);
			array_remove(@cacheID, @selectKey[1]);
			_db_msg_Console('[ipr] IP review msg Cache: b: '.array_size(@selectKey).' | a: '.array_size(@cacheID).' | picked: '.@selectKey[0].' / '.@selectKey[1].' | '.array_index_exists(@cacheID, @selectKey[0]), @discord['serverid'], 'debug');
		}
		_discordBot_add_reaction(@discord['serverid'], @discord['channelid'], @messageID, '💩');
	} else {
		@cacheID['c'][] = @messageID;
		@ret = array('content': 'Oh! Either the message selected is no longer in my review list, or no valid IPs were provided!');
		_discordBot_add_reaction(@discord['serverid'], @discord['channelid'], @messageID, '❔');
	}
	@cacheID['lastedit'] = time();
	export('DiscordBot.bot.msg.IP.Review', @cacheID);
	return(@ret);
}



# Lookup ASN number, ISP, and country of any IP address, using the GeoIP shell command lookup feature.
proc _discordBot_cmd_geoiplookup(@discord, @args) {
	# Requires IP Blacklist script and working shell command.
	if(!is_proc('_geoip_lookup')) { return('NoCmd'); }
	@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()));
	@raw = if(array_contains(@args, 'raw'), true, false);
	if(@raw) { array_remove_values(@args, 'raw'); }
	@cacheID = import('DiscordBot.bot.msg.IP.Review');
	if(!is_array(@cacheID)) { @cacheID = array(); }
	if(!array_index_exists(@cacheID, 'i')) { @cacheID['i'] = array(); }
	@cache = false;
	@messageID = 0;
	@isReaction = array_index_exists(@discord, 'messageuserid');
	if(@isReaction) {
		if(array_index_exists(@cacheID, @discord['id'])) {
		# Check if cache reports the message was already acted upon
			if(array_contains(@cacheID['i'], @discord['id'])) { return('DuplicateCmd'); }
			@cache = true;
			@messageID = @discord['id'];
		}
	# } else { 
		# return('RequireReaction');
	} else {
	# Get message ID from args
		foreach(@arg in @args) {
			if(array_index_exists(@cacheID, @arg)) {
				@cache = true;
				@messageID = @arg;
				break();
			}
		}
	}
	@checkIPs = if(@cache, @cacheID[@messageID][], @args[]);
	#no IPs given, try to parse message
	if(array_size(@checkIPs) < 1) {
		@useMessage = '';
		if(array_index_exists(@discord, 'message')) {
			foreach(@word in parse_args(@discord['message'])) {
				@word = replace(@word, '`', '');
				if(xor(string_contains(@word, '.'), string_contains(@word, ':')) && !string_contains(@word, '/')) { @checkIPs[] = @word; } else { continue(); }
			}
		}
	}
	@rawIPData = array();
	@msgIPData = array('GeoIP Database Lookup Results:');
	# Validate IPs
	foreach(@i: @v in @checkIPs) {
		if(@v === 'raw') { array_remove(@checkIPs, @i); }
		if(@i > 5) { @msgIPData[] = 'Sorry, this command only supports a few IP addresses at a time.'; break(); }
		@vip = _db_validate_ip(@v, @discord);
		switch(@vip) {
		# 0 = success, 1 unrecognized, 2 username, 3 user bot, 4 user self, 5 lan, 6 gateway, 7 cgnat, 8 loopback, 9 cidrblock
		case 1:
			array_remove(@checkIPs, @i);
		case 2..4:
		#username
			array_remove(@checkIPs, @i);
			@say = array('https://media.tenor.com/uvxv8BBNFNYAAAAC/kid-child.gif', 'https://imgs.xkcd.com/comics/wisdom_of_the_ancients.png', 'https://imgs.xkcd.com/comics/second.png', 'https://imgs.xkcd.com/comics/security.png');
			@footer = 'You thought you had me on that one, didn\'t you? no. XD';
			if(@vip === 3) { @footer = 'Haha, I don\'t give up that easily.'; }
			if(@vip === 4) { @footer = 'You were really going to go that far, huh?'; }
			return(array('MC': '[Server] Discordian "'.@discord['username'].'" tried to trick me! It was not effective.', 'embed': array('footer': array('text': @footer), 'image': array_get_rand(@say))));
		case 5..6:
		#LAN or gateway
			@say = array('https://media.tenor.com/NsarNwOAsf8AAAAd/pipp-petals-worried.gif', 'https://media.tenor.com/QSb5JWCCpzkAAAAd/typing-eric-cartman.gif', 'https://media.tenor.com/4KP456_GUqQAAAAd/infinate-forever.gif', 'https://media.tenor.com/GJLm5GaIKkcAAAAd/rj45-izojo.gif', 'https://media.tenor.com/BKZatJG2ofgAAAAd/linux-breakin.gif');
			@footer = 'Party time!';
			if(@vip === 6) {
				@say = array('https://media.tenor.com/B6tCkBJVo7kAAAAd/kayizer-kayizerserver.gif', 'https://media.tenor.com/8wD_c9iWsP4AAAAd/ksp-forum-502-bad-gateway.gif', 'https://media.tenor.com/hOgPINkCBA4AAAAd/jayz2cents-computers.gif');
				@footer = 'That company went out of business years ago.';
			}
			return(array('MC': '[Server] Discordian "'.@discord['username'].'" tried to enter a private party! It was not effective.', 'embed': array('footer': array('text': @footer), 'image': array_get_rand(@say))));
		case 7:
		#CGNAT
			@say = array('https://media.tenor.com/zfvF3qUe2GAAAAAd/tallon-griekspoor-shoo.gif', 'https://media.tenor.com/HsYDYDbRcpIAAAAd/chicken-chicken-bro.gif');
			@footer = 'Bugged out eh?';
			return(array('MC': '[Server] Discordian "'.@discord['username'].'" likes bugs!', 'embed': array('footer': array('text': @footer), 'image': array_get_rand(@say))));
		case 8:
		case 10..11:
		#loopback
		#v4 > 255
		#v4 broadcast
			@say = array('https://media.tenor.com/v0m0sgjo5G4AAAAd/rollin-keep-rollin.gif', 'https://media.tenor.com/x8MVeW7sF4MAAAAd/hot-wheels.gif', 'https://media.tenor.com/-VVnFMnHTCoAAAAd/balthazar-chien.gif', 'https://media.tenor.com/eosED7PskfIAAAAd/funny-you.gif', 'https://media.tenor.com/pyth4Zs3xqMAAAAd/look-in-the-mirror-pam.gif', 'https://media.tenor.com/QQ2qpJ4XhWkAAAAd/inefablejuly-cat-talking-to-itself-on-the-mirror.gif');
			@footer = 'Keep Calm and Keep Rolling on.';
			return(array('MC': '[Server] Discordian "'.@discord['username'].'" is rollin!', 'embed': array('footer': array('text': @footer), 'image': array_get_rand(@say))));
		case 9:
			array_remove(@checkIPs, @i);
			return('CIDR Blocks are not supported in this command');
		}
	}
	# Get IP data
	@ipdb = array();
	@ipdb = _geoip_lookup(@checkIPs, @raw);
	if(!is_array(@ipdb)) {
		@useMsg = '';
		switch(string(@ipdb)) {
		case 'NoPerms':
			@useMsg = 'This command requires configuration to use, see bot server logs.';
		case 'NoIP':
			@useMsg = 'A Given IP was invalid.';
		case 'DBUpdate':
			@useMsg = 'Required Database files are being updated. Try re-running your query later.';
		default:
			@useMsg = 'An error occured, see bot server logs.';
		}
		return(@useMsg);
	}
	# Parse
	foreach(@ip in @checkIPs) {
		@listIPData = '`'.@ip.'` ';
		if(array_index_exists(@blacklistIP, 'IP_Blacklist')) {
			if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
				@listIPData .= ' <<IP present on blacklist>>';
			}
		}
		if(@raw === true) { @rawIPData[] = @ip.@ipdb[@ip]['raw']; }
		if(@ipdb[@ip]['c'] != '') { @listIPData .= ' Country: '.@ipdb[@ip]['c']; }
		if(@ipdb[@ip]['cn'] != '') { @listIPData .= ' :flag_'.to_lower(@ipdb[@ip]['cn']).':'; }
		if(@ipdb[@ip]['rc'] != '') { @listIPData .= ' Registered Country: '.@ipdb[@ip]['rc']; }
		if(@ipdb[@ip]['rcn'] != '') { @listIPData .= ' :flag_'.to_lower(@ipdb[@ip]['rcn']).':'; }
		if(@ipdb[@ip]['asn'] != '') { @listIPData .= ' ASN: '.@ipdb[@ip]['asn']; }
		if(@ipdb[@ip]['aso'] != '') { @listIPData .= ' | '.to_lower(@ipdb[@ip]['aso']); }
		if(@ipdb[@ip]['asn'] != '' && array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb[@ip]['asn'])) {
			if(@blacklistIP['Discovered_ASNs'][@ipdb[@ip]['asn']] > 0) { @listIPData .= ' <ASN present on blacklist>'; } else { @listIPData .= ' <Past ASN>'; }
		}
		if(@listIPData !== '`'.@ip.'` ') { @msgIPData[] = @listIPData; }
	}
	# Returns
	if(@raw === true) { _discordBot_broadcast(@discord['serverid'], @discord['userid'], array('dm': true, 'content': array_implode(@rawIPData, '\n')), 'bot'); }
	if(array_size(@msgIPData) < 2) { @msgIPData[] = '`None Found`'; }
	if(@cache) {
		@cacheID['i'][] = @messageID;
		@s = if(array_size(@cacheID[@messageID]) > 1, 's', '');
		_db_msg_Console(color(9).@discord['username'].color(10).' requested ISP data for IP'.@s.': '.color(7).array_implode(@cacheID[@messageID], ', '), @discord['serverid']);
		_discordBot_add_reaction(@discord['serverid'], @discord['channelid'], @discord['id'], '🪪');
		@cacheID['lastedit'] = time();
		export('DiscordBot.bot.msg.IP.Review', @cacheID);
	}
	return(array_implode(@msgIPData, '\n'));
}

#Add Commands to list
@c3lx = import('DiscordBot.Command.List', array());
@mIu7 = array(
	'geoiplookup': array('alias': array('geoip'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_geoiplookup(@discord, @args)); },
			'help': 'Get basic Geo IP information for an IP Address, such as ASN ID and the organization name.', 'usage': '<IP Address, or IP Ping log Message ID> [2nd IP] [3rd IP] [4th IP] [5th IP]', 'usagenote': '- Checking LAN or otherwise non-public IPs might get you sent a meme.\n- Supports using a Message ID from the bot\'s IP Ping log messages.'),
	'pingblacklist': array('alias': array('nocloudforyou', 'banip', 'blockip'), 'admin': true, 'category': 'Minecraft', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_pingblacklist(@discord, @args)); },
			'help': 'Take the IP addresses listed in a message sent by the bot, and add them to the bot\'s IP Blacklist file.', 'usage': '<Message ID>', 'usagenote': 'Recommend using Reactions on an IP Ping log message from the bot.')
);
@c3lx = array_merge(@c3lx, @mIu7);
export('DiscordBot.Command.List', @c3lx);