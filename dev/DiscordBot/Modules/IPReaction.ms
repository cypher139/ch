# Autosave Keys
@x8db = import('DiscordBot.db.save.keys', array())
@x8db[] = 'bot.msg.IP.Review'
export('DiscordBot.db.save.keys', array_unique(@x8db))

export('DiscordBot.bot.msg.IP.Review', get_value('DiscordBot.bot.msg.IP.Review'))

# Add listed IP(s) from cypher139's IP Blacklist script's IP ping messages to the IP Blacklist file, upon using the configured emoji.
bind('discord_reaction_added', array('id': 'DiscordBot.IP.React', 'priority': 'MONITOR'), null, @discord) {
	# custom emoji given with <>
	if(is_null(import('ipbl.config.dir'))) { die('IP Blacklist functions are not loaded, skipping') }
	array_set(@discord, 'time', time());
	@serverConfig = import('ipbl.config.Server')
	@botconfig = import('DiscordBot.config.Bot')
# IP ping logs are only sent to the Primary guild.
	if(@discord['serverid'] != @botconfig['Primary_Guild']) { die() }
	@config = import('DiscordBot.config.'.@discord['serverid'])
	# if(!array_index_exists(@config, 'Special_Emoji')) { die() }
	if(@discord['messageuserid'] != @botconfig['Bot_ID']) { die() }
# Check if channel is the ping log channel or log Channel
	@logChannel = ''
	if(array_index_exists(@config, 'Channels', 'Ping_Log')) { @logChannel = @config['Channels']['Ping_Log'] } else { @logChannel = @config['Channels']['Log'] }
	if(@discord['channelid'] != @logChannel && @discord['channel'] != @logChannel) { die() }
# Check if emoji used if the configured emoji to act upon
	@doAction = '';
	if(array_index_exists(@config, 'Reaction_Actions', @discord['emoji'])) { @doAction = @config['Reaction_Actions'][@discord['emoji']]
	} else if(array_index_exists(@config, 'Reaction_Actions', reg_replace('[0-9]', '', @discord['emoji']))) { @doAction = @config['Reaction_Actions'][reg_replace('[0-9]', '', @discord['emoji'])]
	} else { die() }
# Verify if user is an admin
	@userRoles = array()
	try {
		@userRoles = discord_member_get_roles(@discord['serverid'], @discord['userid'])
	} catch(NotFoundException @ex) {
		export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid'])
	} 
	@isAdmin = false;
	foreach(@rN: @rID in @userRoles) {
		if(array_contains_ic(@config['Role_Admins'], @rN) || array_contains(@config['Role_Admins'], @rID)) {
			@isAdmin = true;
			break();
		}
	}
		# remove encasing <>, in case it is not included in config.
		# foreach(@act: @em in @config['Special_Emoji']) {
			# if(reg_replace('[<>]', '', @discord['emoji']) == reg_replace('[<>]', '', @em)) { 
				# @doAction = @act
				# break();
			# }
		# }
	# } else {
		# die()
	# }
	@cacheID = import('DiscordBot.bot.msg.IP.Review')
	if(!is_array(@cacheID)) { @cacheID = array() }
#Actions
	switch(string(@doAction)) {
	case 'PingGetISP':
		@e = false
		if(!array_index_exists(@cacheID, 'i')) { array_set(@cacheID, 'i', array()) }
	# Check if cache reports the message was already acted upon
		if(array_contains(@cacheID['i'], @discord['messageid'])) { die('i') }
	# Action IPs
		if(array_index_exists(@cacheID, @discord['messageid'])) {
			@msgIPData = array('ISP Database Lookup Results:')
			@blacklistIP = import('ipbl.config.IPBlacklist', array())
		#Get IP datas
			@ipdb = _geoip_lookup(@cacheID[@discord['messageid']]);
			if(is_array(@ipdb)) {
				foreach(@ip in @cacheID[@discord['messageid']]) {
					if(@serverConfig['Ping_Message_LookupIP_DB'] != true) { break() }
					@listIPData = '`'.@ip.'`: '
					if(@ipdb[@ip]['cn'] != '') { @listIPData .= ':flag_'.to_lower(@ipdb[@ip]['cn']).':' }
					if(@ipdb[@ip]['rcn'] != '') { @listIPData .= ', reg: :flag_'.to_lower(@ipdb[@ip]['rcn']).': ' }
					# if(@ipdb[@ip]['c'] != '') { @listIPData .= ' '.'Country: '.@ipdb[@ip]['c'] }
					if(@ipdb[@ip]['asn'] != '') { @listIPData .= ' ASN: '.@ipdb[@ip]['asn'] }
					if(@ipdb[@ip]['aso'] != '') { @listIPData .= ' | '.@ipdb[@ip]['aso'] }
					if(@ipdb[@ip]['asn'] != '' && array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb[@ip]['asn'])) {
						if(@blacklistIP['Discovered_ASNs'][@ipdb[@ip]['asn']] > 0) { @listIPData .= ' <ASN has IPs on Blacklist>' } else { @listIPData .= ' <Past ASN>' }
					}
					if(@listIPData != '`'.@ip.'`: ') { @msgIPData[] = @listIPData; }
				}
			} else { 
				@useMsg = ''
				switch(string(@ipdb)) {
				case 'NoPerms':
					@useMsg = 'This command requires configuration to use, see bot server logs.';
				case 'NoIP':
					@useMsg = 'A Given IP was invalid.';
				case 'DBUpdate':
					@useMsg = 'Required Database files are being updated. Try re-running your query later.';
					@e = true
				default:
					@useMsg = 'An error occured, see bot server logs.';
				}
				@msgIPData[] = @useMsg;
			}
		#Log
			@s = ''
			if(array_size(@cacheID[@discord['messageid']]) > 1) { @s = 's' }
			_db_msg_Console(color(9).@discord['username'].color(10).' requested ISP data for IP'.@s.': '.color(7).array_implode(@cacheID[@discord['messageid']], ', '), @discord['serverid'])
			_discordBot_broadcast(@discord['serverid'], '--ping', array('content': array_implode(@msgIPData, '\n'), 'reference_id': @discord['messageid']), 'bot');
			if(!@e) { 
				@cacheID['i'][] = @discord['messageid'];
				discord_request('PUT', 'channels/'.@discord['channelid'].'/messages/'.@discord['messageid'].'/reactions/%F0%9F%AA%AA/@me', null, closure(@ex) { @react = 1 }, closure(@ex) { console('reaction failed: \n'.@ex) });
			}
		} else {
			_discordBot_broadcast(@discord['serverid'], @discord['userid'], array('dm': true, 'content': 'Sorry, The message selected is no longer in my review list!', @discord['serverid']), 'bot');
			@cacheID['i'][] = @discord['messageid'];
		}
		array_set(@cacheID, 'lastedit', time());
		export('DiscordBot.bot.msg.IP.Review', @cacheID);
	case 'PingBlacklist':
		if(!@isAdmin) {
			_discordBot_broadcast(@discord['serverid'], '--ping', array('content': 'Sorry <@'.@discord['userid'].'>, this command is only for server moderators.', 'reference_id': @discord['messageid']), 'bot')
			die();
		}
		if(!array_index_exists(@cacheID, 'c')) { array_set(@cacheID, 'c', array()) }
		if(!array_index_exists(@cacheID, 'r')) { array_set(@cacheID, 'r', array()) }
		array_set(@cacheID, 'lastedit', time())
	# Check if cache reports the message was already acted upon
		if(array_contains(@cacheID['c'], @discord['messageid'])) { die('c') }
	# Action IPs
		if(array_index_exists(@cacheID, @discord['messageid'])) {
		#Get
			@blacklistIP = import('ipbl.config.IPBlacklist')
			if(!is_array(@blacklistIP)) { array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()) }
			# Get player name(s) from IP database
			@ipuserdata = import('primus.database.IP');
			if(!is_array(@ipuserdata)) { @ipuserdata = array() }
		#Add
			@addip = array()
			@reviewip = array()
			@userdisplay = ''
			foreach(@rawip in @cacheID[@discord['messageid']]) {
				# remove v6's end "%0", ufw doesn't support.
				@ip = reg_replace('[%][0]$', '', @rawip)
				# Check for player names, don't add if found.
				@userdisplay = ''
				if(array_index_exists(@ipuserdata, @ip) && !array_contains(@cacheID['r'], @discord['messageid'])) {
					array_set(@reviewip, @ip, @ipuserdata[@ip]);
					@userdisplay .= '\n'.@ip.': `'.array_implode(@ipuserdata[@ip], ', ').'`'
					continue();
				}
				@blacklistIP['IP_Blacklist'][] = @ip
				@addip[] = @ip
			}
		#Write
		if(array_size(@addip) > 0) {
			export('ipbl.config.IPBlacklist', @blacklistIP);
			_ipbl_save_config();
		}
		#Log
			@s = ''
			if(array_size(@cacheID[@discord['messageid']]) > 1) { @s = 's' }
			_db_msg_Console(color(9).@discord['username'].color(10).' blacklisted IP'.@s.': '.color(7).array_implode(@addip, ', '), @discord['serverid'])
			@cacheID['c'][] = @discord['messageid']
			if(array_size(@reviewip) > 0) {
				_discordBot_broadcast(@discord['serverid'], '--ping', array('content': 'These IPs have connected with a player name; If you wish to confirm blacklisting these IPs, *react to this message*.'.@userdisplay, 'reference_id': @discord['messageid']), 'bot', closure(@msgID){
					@cacheID = import('DiscordBot.bot.msg.IP.Review')
					if(!is_array(@cacheID)) { @cacheID = array() }
					if(!array_index_exists(@cacheID, 'r')) { array_set(@cacheID, 'r', array()) }
					array_set(@cacheID, @msgID, array_keys(@reviewip))
					array_set(@cacheID, 'lastedit', time())
					@cacheID['r'][] = @msgID;
					if(array_size(@cacheID) > 400) {
						@key = array_keys(@cacheID)
						array_remove_values(@key, 'c')
						array_remove_values(@key, 'r')
						array_remove(@cacheID, array_sort(@key, 'NUMERIC')[0])
					}
					export('DiscordBot.bot.msg.IP.Review', @cacheID)
					return(true)
				});
			}
			export('DiscordBot.bot.msg.IP.Review', @cacheID)
			discord_request('PUT', 'channels/'.@discord['channelid'].'/messages/'.@discord['messageid'].'/reactions/%E2%9C%85/@me', null, closure(@ex) { @react = 1 }, closure(@ex) { console('reaction failed: \n'.@ex) });
		} else {
			_discordBot_broadcast(@discord['serverid'], @discord['userid'], array('dm': true, 'content': 'Sorry, The message selected is no longer in my review list! You\'ll need to manually add the IP address in question to the bot\'s blacklist file.'), 'bot');
			@cacheID['c'][] = @discord['messageid']
			export('DiscordBot.bot.msg.IP.Review', @cacheID)
		}
	default:
		die()
	}
}