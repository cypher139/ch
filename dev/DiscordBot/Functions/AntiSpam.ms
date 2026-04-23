# Anti Spam functions: 
# - Check if user is repeating messages, new user chatting on too many channels, etc.
# - Then remove messages and alert admins if matching patterns were identified!

# Autosave Keys
@x8db = import('DiscordBot.db.save.keys', array());
@x8db[] = 'antispam.members';
@x8db[] = 'bot.antispam.triggers';
export('DiscordBot.db.save.keys', array_unique(@x8db));

# -------------

proc _db_as_dm(@discord, @isFirst = false, @isCS = false) {
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages');
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array(); }
	if(@isCS === true) {
		# CS relay messages: Get matching msg id for this user on this server
		@cacheID = import('DiscordBot.CS.UserMessage.relay.ID');
		if(!is_array(@cacheID)) { @cacheID = array(); }
		if(!array_index_exists(@cacheID, @discord['serverid'], @discord['userid'])) { return(false); }
		@discord['id'] = @cacheID[@discord['serverid']][@discord['userid']];
		@cacheID['lastedit'] = time();
		array_remove(@cacheID[@discord['serverid']], @discord['userid']);
		export('DiscordBot.CS.UserMessage.relay.ID', @cacheID);
		@config = import('DiscordBot.config.'.@discord['serverid']);
		@discord['channelid'] = @config['Channels']['Minecraft'];
		if(array_index_exists(@config, 'Channels', 'CS')) { @discord['channelid'] = @config['Channels']['CS']; }
	} else if(array_index_exists(@cacheMsgs, 'messages', @discord['id'], 'deleted')) {
		#Normal Messages
		if(@cacheMsgs['messages'][@discord['id']]['deleted'] === true) {
			_db_msg_Console('[AntiSpam] Message ID '.@discord['id'].' already deleted?!  <first:'.@isFirst.'> [Channel: '.@discord['channel'].']', @discord['serverid'], 'debug');
			return(false);
		}
	}
	#Try/catch not supported for delete Message's no permission.
	@hasPerm = _db_check_perms('delete', @discord['serverid'], @discord['channelid']);
	if(@hasPerm) {
		try {
			discord_delete_message(@discord['serverid'], @discord['channelid'], @discord['id']);
			if(array_index_exists(@cacheMsgs, 'messages', @discord['id'])) {
				@cacheMsgs['messages'][@discord['id']]['deleted'] = true;
				export('DiscordBot.'.@discord['serverid'].'.Cache.Messages', @cacheMsgs);
			}
			return(@discord['id']);
		# } catch(InsufficientPermissionException @ex) {
		} catch(Exception @ex) {
			_db_msg_Console('  ['.@discord['serverid'].'] [AntiSpam] Cannot remove message "'.@discord['id'].'" from '.@discord['username'].' <@'.@discord['userid'].'> '.@ex['classType'].@ex['message'], @discord['serverid']);
			return(false);
		}
	} else {
		@nopermsMsg = 'AntiSpam: Not allowed to delete '.@discord['username'].'\'s spam messages.';
		_db_msg_Console(@nopermsMsg, @discord['serverid'], 'error');
		@config = import('DiscordBot.config.'.@discord['serverid']);
		if(array_index_exists(@config, 'Nag_Server')) { _discordBot_broadcast(@discord['serverid'], @config['Nag_Server'], array('prefix': array('confirm', false), 'dm': true, 'content': @nopermsMsg), 'Bot'); }
		return(false);
	}
}

# -------------

bind('discord_message_received', array('id': 'DiscordBot.antispam.check', 'priority': 'HIGHEST'), null, @discord) {
	if(!array_contains(import('DiscordBot.Servers'), @discord['serverid'])) { die(); }
	if(@discord['bot'] === true) { die(); }
	@time = time();
	@time123 = @time - 12345;
	@time60 = @time - 60000;
	@time4 = @time - 5000;
	@discord['time'] = @time;
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@guildInfo = import('DiscordBot.Servers.Info.'.@discord['serverid'], array('name': @config['Server_Nickname']));
	@safeURLChan = false;
	if(array_index_exists(@config, 'AS_Safe_URL_Channels')) {
		if(array_contains(@config['AS_Safe_URL_Channels'], @discord['channel']) || array_contains(@config['AS_Safe_URL_Channels'], @discord['channelid'])) { @safeURLChan = true; }
	}
	@flagDesc = array(
		'newlimit': '*New* user has talked on more than the limit of %count% different channels.',
		'newglobalping': '*New* user used a global mention: `%word%`',
		'newdomain': '*New* user sent a link to domain %domain% which is blacklisted for posting by new users.',
		'dupe': 'Duplicated same message',
		'fastchannel': 'Chatted on %count% channels too quickly',
		'fastmsg': 'Sent messages very quickly',
		'chansafe': 'URL containing a non-whitelisted domain `%d%` was sent on safe channel `%channel%`',
		's-rpchar': '%count% non-alphabet characters present: %list%', 
		's-chan': 'were sent on at least %count% channels',
		's-url': 'contains an URL',
		's-img': 'contains a screenshot or image'
	);
	@imageHostingSites = array('imgur.com');
	@dmtimeout = 60000;
	@asmembers = import('DiscordBot.'.@discord['serverid'].'.antispam.members');
	if(!is_array(@asmembers)) { 
		@asmembers = get_value('DiscordBot.'.@discord['serverid'].'.antispam.members');
		if(!is_array(@asmembers)) { @asmembers = array('lastedit': 0); }
		export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers);
	}
	@cacheMsgs = import('DiscordBot.'.@discord['serverid'].'.Cache.Messages');
	if(!is_array(@cacheMsgs)) { @cacheMsgs = array(); }
	@newuser = _db_is_newmember(@discord['serverid'], @discord['userid']);
	@adduser = false;
	@lastUserMsgs = array();
	@userFlags = array();
	if(array_index_exists(@cacheMsgs, 'user', @discord['userid'])) {
		foreach(@userMsgID in @cacheMsgs['user'][@discord['userid']]) {
			@lastUserMsgs[] = @cacheMsgs['messages'][@userMsgID];
		}
	}
# Record channels user has talked on recently
	@userchannels = import('DiscordBot.'.@discord['serverid'].'.Cache.User.Channels');
	if(!is_array(@userchannels)) { @userchannels = array(); }
	if(array_index_exists(@userchannels, @discord['userid'])) {
		if(!array_contains(@userchannels[@discord['userid']], @discord['channelid'])) {
			@userchannels[@discord['userid']][] = @discord['channelid'];
			export('DiscordBot.'.@discord['serverid'].'.Cache.User.Channels', @userchannels);
		}		
	} else {		
		@userchannels[@discord['userid']] = array(@discord['channelid']);
		export('DiscordBot.'.@discord['serverid'].'.Cache.User.Channels', @userchannels);
	}

	
##### -------------------
#Checks
#Sub Flags checks
	@urlRegex = '([\\w+]+\\:\\/\\/)?([\\w\\d-]+\\.)*([\\w-]+[\\.\\:]\\w+)([\\/\\?\\=\\&\\#.]?[\\w-]+)*\\/?'
	@messageURLs = array();
	# {0: https://cdn.website.com/folder?var=1, 1: https://, 2: cdn. (null if no sub), 3: website.com, 4: /folder?var=1}
	# Check message data for certain patterns
	if(@discord['message'] != '') {
		# Message contains: URL:
		if(reg_count(@urlRegex, @discord['message']) > 0) {
			@userFlags[] = 's-url';
			@messageURLs = reg_match_all(@urlRegex, @discord['message']);
		# Check if any URL links to an image (popular to avoid reupload for each spam message)
			@fileExt = reg_match('[.](?<ext>[\\w]{0,5})(?:\\?|$|h|\\s)', @discord['message']);
			if(array_index_exists(@fileExt, 'ext')) {
				if(array_contains(array('png', 'jpg', 'jpeg', 'webp', 'gif', 'webm'), @fileExt['ext'])) { @userFlags[] = 's-img'; }
			}
		# Check each URL: is domain is an image hosting site (some sites ex. imgur do not include a file extension in url)
			foreach(@i: @url in @messageURLs) {
				@domain = if(is_null(@url[2]), @url[3], @url[2].@url[3]);
				if(array_contains(@imageHostingSites, @domain)) { @userFlags[] = 's-img'; }
			}
		}
		# Message contains: Many non-word & repeated characters
			# scenario: spammer added | character border to an entire message
		@nonWords = reg_match_all('[^\\w. ]', @discord['message']);
		if(array_index_exists(@config, 'AS_Non_Words_Limit')) {
			if(array_size(@nonWords) > @config['AS_Non_Words_Limit']) {
				@nwc = array();
				foreach(@i: @c in @nonWords) {
					if(!array_index_exists(@nwc, @c[0])) { @nwc[@c[0]] = 0; }
					@nwc[@c[0]]++;
				}
				_db_msg_Console('AS: nonwords: '.@nwc, @discord['serverid'], 'debug');
				@userFlags[] = 's-rpchar';
				@flagDesc['s-rpchar'] = replace(@flagDesc['s-rpchar'], '%count%', array_size(@nonWords));
				@flagDesc['s-rpchar'] = replace(@flagDesc['s-rpchar'], '%list%', @nwc);
			}
		}
	}
	# Message contains: image attachment
	if(array_index_exists(@discord, 'attachments', 0)) {
		foreach(@at in @discord['attachments']) {
			@fileExt = reg_match('[.](?<ext>[\\w]{0,5})(?:\\?|$)', @at['filename']);
			if(array_index_exists(@fileExt, 'ext')) {
				if(array_contains(array('png', 'jpg', 'jpeg', 'webp', 'gif', 'webm'), @fileExt['ext'])) { @userFlags[] = 's-img'; }
			}
		}
	}


##### -------------------
#Flag setup (requires sub url or image flag)
	@chanArr = array(@discord['channelid']);
	@fastCount = 0;
	foreach(@i: @d in @lastUserMsgs) {
		if(@i > 15) { break(); }
		# Check count of channels posted to in last 60 seconds period.
		@checkTimeout = if(array_contains(@userFlags, 's-img') || array_contains(@userFlags, 's-url'), @time60, @time123);
		if(@d['time'] > @checkTimeout) { @chanArr[] = @d['channelid']; }
		# Check if last message's timestamps were posted within the past few seconds
		if(@d['time'] > @time4) { @fastCount++; }
	}
	@cidCount = array_size(array_unique(@chanArr));
	
	
##### -------------------
#Checks
#Main Flags checks

# Check if URL is whitelisted on a safe Channel
	if(@safeURLChan === true && array_contains(@userFlags, 's-url')) {
		foreach(@i: @url in @messageURLs) {
			@domain = if(is_null(@url[2]), @url[3], @url[2].@url[3]);
			if(!array_contains(@config['AS_Safe_URL_Sites'], @domain)) {
				@adduser = true;
				@userFlags[] = 'chansafe';
				@flagDesc['chansafe'] = replace(@flagDesc['chansafe'], '%channel%', @discord['channel']);
				@flagDesc['chansafe'] = replace(@flagDesc['chansafe'], '%d%', @domain);
				break();
			}
		}
	}

# Unusual message activity: Duplicates, send too quickly, etc. (More than 3-4 is typically indicative of spam)
	@cidu3 = false;
	# Do not count if at least 3 previous message data not available.
	# message is blank check no longer present due to spam moving to posting only screenshots.
	if(array_index_exists(@lastUserMsgs, 2)) {
		if(@lastUserMsgs[0]['channelid'] !== @discord['channelid'] && @lastUserMsgs[1]['channelid'] !== @discord['channelid'] && @lastUserMsgs[0]['channelid'] !== @lastUserMsgs[1]['channelid']) { 
			@cidu3 = true;
		}
		@dcount = import('DiscordBot.'.@discord['serverid'].'.antispam.dupecount');
		if(!is_array(@dcount)) { @dcount = array(); }
		if(!array_index_exists(@dcount, @discord['userid'])) { @dcount[@discord['userid']] = array('f': 0, 'c': 0); }
		# Set a new rolling 12 second period:
		if(@dcount[@discord['userid']]['f'] < @time) {
			# Sending messages with image only attachments are taking over 12 seconds, skipping normal dupe timeout. Extend timeout for image posts.
			@dcount[@discord['userid']]['f'] = if(array_contains(@userFlags, 's-img') || array_contains(@userFlags, 's-url'), @time + 60000, @time + 12345);
			if(@dcount[@discord['userid']]['c'] < 6) {
				@dcount[@discord['userid']]['c'] = 0;
			}
		}
	#Duplicated Messages:
	# Last message is the same as current:
		# Split on < to avoid checking a cache's addition of "<Sent a file> <Also attached file:>": # if(split('<', @lastUserMsgs[0]['message'])[0] === split('<', @discord['message'])[0]) {
		if(@lastUserMsgs[0]['message'] === @discord['message']) {
			## <<Add extra count>>: Current message is same yet posted on different channel. Can be indicative of spam same message on all available channels.
			if(@lastUserMsgs[0]['channelid'] !== @discord['channelid']) { @dcount[@discord['userid']]['c']++; }
			## <<Add extra count>>: Message contains a URL link. Can be indicative of spam same message on all available channels.
			# if(reg_count('([\\w+]+\\:\\/\\/)?([\\w\\d-]+\\.)*[\\w-]+[\\.\\:]\\w+([\\/\\?\\=\\&\\#.]?[\\w-]+)*\\/?', @discord['message']) > 0) {
			if(array_contains(@userFlags, 's-url')) {
				@dcount[@discord['userid']]['c']++;
				@userFlags[] = 'dupe';
			}
			# Last 2 messages is ... also the same as current:
			if(@lastUserMsgs[1]['message'] === @discord['message']) {
				# Previous 2 messages match, highly likely spam event. Increment counter.
				@dcount[@discord['userid']]['c']++;
				## <<Add extra count>>: Current message posted on channel that isn't either of the previous 2 channels. Highly likely spam event! (or someone legitly replying "lol" to everything)
				if(@cidu3) {
					@dcount[@discord['userid']]['c']++;
					@userFlags[] = 'dupe';
					@userFlags[] = 's-chan'.@cidCount;
				}
			}
		}		
	# Messages across multiple channels were sent too quickly
		if(@cidu3 || @cidCount > 2) {
		#If past 3 messages spanning 3 channels are sent in the last few seconds, too fast - likely scripted spam.
			if(@fastCount > 2) {
				@adduser = true;
				@userFlags[] = 'fastmsg';
			}
		}
		#If past few messages were on 5 channels in a short amount of time, too fast. might be "lol" to everything, maybe not.
		if(@cidCount > 4) {
			@adduser = true;
			@userFlags[] = 'fastchannel';
			@userFlags[] = 's-chan'.@cidCount;
		}
	### If the counter reaches 5, trigger anti spam
		if(@dcount[@discord['userid']]['c'] > 5) {
			@adduser = true;
			if(array_size(@userFlags) < 1) { @userFlags[] = 'dupe'; }
		}
		export('DiscordBot.'.@discord['serverid'].'.antispam.dupecount', @dcount);
	}	
# Checks for New Users:
	# --- Returning users bypass new user checks, as new member reports false. ---
	if(@newuser === true) {
	# New user has talked on most channels - unlikely unless spamming. **Set limit to around number of channels @everyone can talk on.**
		if(array_size(@userchannels[@discord['userid']]) >= @config['AS_New_User_Channel_Limit']) {
			@adduser = true;
			@userFlags[] = 'newlimit'.@config['AS_New_User_Channel_Limit'];
		}
	# New user pinged @here or @everyone
		@checkmsg = parse_args(@discord['message']);
		foreach(@word in @checkmsg) {
			if(to_lower(@word) === '@here' || to_lower(@word) === '@everyone') {
				@adduser = true;
				@userFlags[] = 'newglobalping';
				@flagDesc['newglobalping'] = replace(@flagDesc['newglobalping'], '%word%', @word);
			}
		}
	#Check if link sent includes a domain not allowed for posting by a new user.
		if(array_index_exists(@config, 'AS_New_User_Domain_Blacklist') && array_contains(@userFlags, 's-url')) {
			foreach(@i: @url in @messageURLs) {
				@domain = if(is_null(@url[2]), @url[3], @url[2].@url[3]);
				if(array_contains(@config['AS_New_User_Domain_Blacklist'], @domain)) {
					@adduser = true;
					@userFlags[] = 'newdomain';
					@flagDesc['newdomain'] = replace(@flagDesc['newdomain'], '%domain%', @domain);
					break();
				}
			}
		}
	}
# Ignore Checks:
	# Message sent in a No XP (ignored) channel
	if(array_index_exists(@config, 'AS_Ignore_NoXP')) {
		if(@config['AS_Ignore_NoXP'] === true) {
			if(array_contains(@config['LB_Options']['NoXP_Channels'], @discord['channel']) || array_contains(@config['LB_Options']['NoXP_Channels'], @discord['channelid'])) {
				@adduser = false;
			}
		}
	}
	# Message of user project sent in the Showcase channel
	if(array_index_exists(@config, 'Channels', 'Showcase') && array_contains(@userFlags, 's-img')) {
		if(@discord['channelid'] === @config['Channels']['Showcase']) { @adduser = false; }
	}
	
##### -------------------
# Add user to Triggered state:

	if(@adduser === true) {
		@userFlags = array_unique(@userFlags);
		if(!array_index_exists(@asmembers, @discord['userid'])) {
			@asmembers[@discord['userid']] = array('flags': @userFlags, 'log': false, 'rtime': @time, 'time': @time, 'username': @discord['username'], 'notes': '', 'triggercount': 0);
		}
		_db_msg_Console('AS: adduser: '.@asmembers[@discord['userid']], @discord['serverid'], 'debug');
		#Debug: save json of messages received from user
		if(array_index_exists(@cacheMsgs, 'user', @discord['userid'])) {
			@saveMsgs = array('User :'.@discord['username'].'  ID: '.@discord['userid'], 'Message IDs:', @cacheMsgs['user'][@discord['userid']], 'Messages:');
			foreach(@msgID in @cacheMsgs['user'][@discord['userid']]) {
				@saveMsgs[] = @msgID.':  '.@cacheMsgs['messages'][@msgID];
			}
			_write_file(import('DiscordBot.logs.dir').'/'.@discord['serverid'].'/debug/AntiSpam_User_Message_'.@discord['userid'].'.txt', array_implode(@saveMsgs, '\n'), 'overwrite');
		}
	}
	
##### -------------------
# !!! User is in Triggered state: !!!

	if(array_index_exists(@asmembers, @discord['userid'])) {
		consume();
		@actiontaken = '\n- *Actions taken:*';
	# Record total server triggers
		@count = import('DiscordBot.bot.antispam.triggers');
		if(!is_array(@count)) { 
			@count = get_value('DiscordBot.bot.antispam.triggers');
			if(!is_array(@count)) { @count = array('lastedit': 0, 'total': 0); }
			if(!array_index_exists(@count, 'msgs')) { @count['msgs'] = array(); }
			if(!array_index_exists(@count, 'active')) { @count['active'] = array(); }
		}
		if(!array_index_exists(@count, @discord['serverid'])) { @count[@discord['serverid']] = 0; }
		@count[@discord['serverid']]++;
		@count['total']++;
	# Record User message hash (for DMs to verify if same spam was DM'ed to bot)
		if(!array_index_exists(@count, 'msgs', @discord['userid'])) { @count['msgs'][@discord['userid']] = array(); }
		if(!array_contains(@count['msgs'][@discord['userid']], sha1(@discord['message']))) {
			@count['msgs'][@discord['userid']][] = sha1(@discord['message']);
		}
	# Record user is active under Anti Spam
		if(!array_index_exists(@count, 'active', @discord['userid'])) {
			@count['active'][@discord['userid']] = @discord['serverid'];
		}
		@count['lastedit'] = @time;
		export('DiscordBot.bot.antispam.triggers', @count);
	# If user's first trigger:
		if(@asmembers[@discord['userid']]['triggercount'] < 2) {
			@msgcount = 0;
		# Delete messages recorded in the user's cached messages?
			if(@config['AS_Remove_Messages'] === true) {
				# if(array_contains(@userFlags, 'newlimit'.@config['AS_New_User_Channel_Limit']) || array_contains(@userFlags, 'newglobalping')) {
				if(@newuser === true) {
				# New User: Remove last 5 mins of messages
					@dmtimeout = 300000;
				}
				#more messages option: remove last 30 mins
				if(array_index_exists(@config, 'AS_Remove_User_Messages')) {
					if(@config['AS_Remove_User_Messages'] === true) {
						@dmtimeout = 1800000;
					}
				}
				@rmIDs = array();
				foreach(@message in @lastUserMsgs) {
					if(!array_index_exists(@message, 'message')) { @message['message'] = ''; }
					# Action either upon messages within timeout, or messages that match the content of trigger message
					if(@message['time'] > (@time - @dmtimeout) || array_contains(@count['msgs'][@discord['userid']], sha1(@message['message']))) {
						@rmIDs[] = @message['id']; 
						@return = _db_as_dm(@message, true);
						if(@return != false) { @msgcount++; }
					}
				}
			#Remove CS relayed messages
				foreach(@server in import('DiscordBot.Servers')) {
					@s_cfg = import('DiscordBot.config.'.@server);
					if(@s_cfg['Cross_Server_Messages'] != true) { continue(); }
					@returnC = _db_as_dm(array('serverid': @server, 'username': @discord['username'], 'userid': @discord['userid']), true, true);
					if(@returnC != false) {
						@msgcount++;
						@rmIDs[] = 'cs.'.@returnC;
					}
				}
				_db_msg_Console('AntiSpam: Removed Message IDs: '.array_implode(@rmIDs, ', '), @discord['serverid'], 'debug');
			}
			if(@msgcount > 0) {
				@actiontaken .= ' <Deleted '.@msgcount.' of user\'s recent messages>';
			}
		# Timeout user
			if(@config['AS_Timeout_User'] === true) {
				@actiontaken .= ' <24 Hour Timeout set for user>';
				discord_request('PATCH', 'guilds/'.@discord['serverid'].'/members/'.@discord['userid'], array('communication_disabled_until': simple_date('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'000+00:00\'', (time() + 86400000), 'UTC')), 
				# closure(@ex) { _discordBot_broadcast(@discord['serverid'], '--admin', 'Successfully set timeout on user `'.@discord['nickname'].'` for the next 24 hours.') }, 
				closure(@ex) { _db_msg_Console('Successfully set timeout on user `'.@discord['nickname'].'` for the next 24 hours.', @discord['serverid']) }, 
				closure(@ex) { _db_msg_Console('AntiSpam: Set Timeout failed for '.@discord['username'].'\n'.@ex, @discord['serverid'], 'error'); }
				);
			}
		#Brand user?
			if(@config['AS_Brand_User'] === true) {
				try {
					discord_member_set_nickname(@discord['serverid'], @discord['userid'], 'SPAMMER: '.@discord['nickname']);
					@actiontaken .= ' <Set Nickname to spammer>';
				} catch(InsufficientPermissionException @ex) {
					_db_msg_Console('AntiSpam: Not allowed to set spam nickname for '.@discord['username'], @discord['serverid'], 'error');
				} catch(Exception @ex) {
					_db_msg_Console('AntiSpam: nickname:\n'.@ex, @discord['serverid'], 'error');
				}
			}
		# Message Admins, and DM user.
			if(@actiontaken == '\n- *Actions taken:*') { @actiontaken = ''; }
			@prDisA = array();
			@prDisB = array();
			@flagDesc['s-chan'] = replace(@flagDesc['s-chan'], '%count%', @cidCount);
			@flagDesc['fastchannel'] = replace(@flagDesc['fastchannel'], '%count%', @cidCount);
			@flagDesc['newlimit'] = replace(@flagDesc['newlimit'], '%count%', @config['AS_New_User_Channel_Limit']);
			foreach(@r in @userFlags) {
				@f = @r;
				if(reg_count('[0-9]', @r) > 0) {
					@f = substr(@r, 0, (length(@r) - reg_count('[0-9]', @r)));
				}
				if(string_starts_with(@f, 's-')) {
					@prDisB[] = @flagDesc[@f];
				} else {
					@prDisA[] = @flagDesc[@f];
				}
			}
			@prDis = if(array_size(@prDisA) > 0, array_implode(@prDisA, ', '), '');
			@s = if(array_size(@prDisA) > 1, 's', '');
			if(array_size(@prDisB) > 0) { @prDis .= '\n*Messages '.array_implode(@prDisB, ', ').'.*'; }
			@logMsg = array('content': '__**Anti Spam alert**__\nUser <@'.@discord['userid'].'> [`'.@discord['username'].'`  `'.@discord['userid'].'`] triggered Anti Spam protection!\n- *Protection Reason'.@s.':* '.@prDis.@actiontaken);
			@userinfo = array();
			try {
				@userinfo = discord_member_info(@discord['serverid'], @discord['userid']);
			} catch(NotFoundException @ex) {
				export('DiscordBot.debug.user.not.found.'.@discord['userid'], @discord['serverid']);
			}
			if(@config['AS_Log_ShowUserInfo'] === true && array_index_exists(@userinfo, 'userid')) {
				@userRoles = discord_member_get_roles(@discord['serverid'], @discord['userid']);
				@displayUR = if(array_size(@userRoles) > 0, '<@&'.array_implode(@userRoles, '> <@&').'>', 'None');
				@logMsg['embeds'] = array();
			#Get Avatar and embed color info
				if(!array_index_exists(@userinfo, 'avatar')) { @userinfo['avatar'] = 'https://cdn.discordapp.com/embed/avatars/0.png'; }
				@newuserD = if(@newuser, 'Yes', 'No');
				@logMsg['embeds'][] = array(
				'author': array('icon_url': @userinfo['avatar'].'?size=40', 'name': @discord['username'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @discord['username'])),
				'color': array('r': 109, 'g': 109, 'b': 109),
				'thumbnail': @userinfo['avatar'].'?size=48',
				'fields': array(
					array('name': 'Join: Server', 'value': '<t:'.substr(@userinfo['joined_at'], 0, 10).':f>', 'inline': true),
					array('name': 'Is New to the Server?', 'value': @newuserD, 'inline': true),
					array('name': 'Join: Discord', 'value': '<t:'.substr(rshift(@discord['userid'], 22) + 1420070400000, 0, 10).':f>', 'inline': true)
				),
				'footer': array('text': 'ID: '.@discord['userid']),
				'timestamp': time()
				);
				if(array_index_exists(@userinfo, 'color')) {
					if(@userinfo['color'] != null) {
						@logMsg['embeds'][0]['color'] = @userinfo['color'];
					}
				}
				@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard');
				if(is_array(@leaderboard)) {
					if(array_index_exists(@leaderboard, 'members', @discord['userid'])) { 
						if(@leaderboard['members'][@discord['userid']]['level'] > 0) {
							@logMsg['embeds'][0]['fields'][] = array('name': 'Leaderboard Level', 'value': @leaderboard['members'][@discord['userid']]['level'], 'inline': true);
						}	
					}
				}
				@joininfo = get_value('DiscordBot.'.@discord['serverid'].'.Join.info');
				if(!is_array(@joininfo)) { @joininfo = array(); }
				if(!array_index_exists(@joininfo, @discord['userid'])) {
					@inv = import('DiscordBot.'.@discord['serverid'].'.Welcome.inv', array())	
					if(array_index_exists(@inv, @discord['userid'], 'code')) {
						@joininfo[@discord['userid']] = array('code': @inv[@discord['userid']]['code']);
					}
				}
				if(array_index_exists(@joininfo, @discord['userid'], 'code')) {
					@code = @joininfo[@discord['userid']]['code'];
					if(is_array(@joininfo[@discord['userid']]['code'])) { @code = array_implode(@joininfo[@discord['userid']]['code'], ', '); }
					if(@code != '') { @logMsg['embeds'][0]['fields'][] = array('name': 'Invite', 'value': @code, 'inline': true); }
				}
				@logMsg['embeds'][0]['fields'][] = array('name': 'Roles ['.array_size(@userRoles).']', 'value': @displayUR, 'inline': false);
			}
			if(@asmembers[@discord['userid']]['log'] === false) {
				_db_msg_Console(color(14).@discord['username'].color(8).' <@'.@discord['userid'].'>'.color(7).' triggered Anti Spam protection. Reason'.@s.': '.color(9).@prDis, @discord['serverid']);
				_discordBot_broadcast(@discord['serverid'], '--admin', @logMsg);
				@announceMsg = @botconfig['AS_General_Announcement'];
				if(array_index_exists(@config, 'AS_General_Announcement')) { @announceMsg = @config['AS_General_Announcement']; }
				foreach(@r in @userFlags) {
					if(array_index_exists(@config, 'AS_Announcement_'.@r)) {
						@announceMsg = replace(@config['AS_Announcement_'.@r], '%UserID%', '<@'.@discord['userid'].'>');
					}
				}
				if(@announceMsg != '') { _discordBot_broadcast(@discord['serverid'], '--announce', @announceMsg); }
				@subMsg = '';
				if(@newuser === true) {
					@logJointimes = get_value('DiscordBot.'.@discord['serverid'].'.log.users.Join.Times');
					if(!is_array(@logJointimes)) { @logJointimes = array(); }
					if(!array_index_exists(@logJointimes, @discord['userid'], 1)) { @subMsg = '\n\nIf you have recently rejoined the server with a new account, ask the moderators to use my `transferroles` command to bypass this AntiSpam protection.'; }
				}
				_discordBot_broadcast(@discord['serverid'], @discord['userid'], array('prefix': 'death', 'dm': true, 'content': 'Your recent activity at the server "'.@guildInfo['name'].'" has triggered their Anti Spam protection. You will need to message the moderators to reinstate access.'.@subMsg));
				@asmembers[@discord['userid']]['log'] = true;
			}
		}
	#Actions for each trigger:
		if(@config['AS_Remove_Messages'] === true) {
			_db_as_dm(@discord);
		}
		@asmembers['lastedit'] = @time;
		@asmembers[@discord['userid']]['rtime'] = @time;
		@asmembers[@discord['userid']]['triggercount']++
		export('DiscordBot.'.@discord['serverid'].'.antispam.members', @asmembers);
### DEBUG -------
		@asMsgs = get_value('DiscordBot.'.@discord['serverid'].'.debug.ASTrigger.Messages');
		if(!is_array(@asMsgs)) { @asMsgs = array(); }
		if(!array_index_exists(@asMsgs, @discord['userid'])) { @asMsgs[@discord['userid']] = array(); }
		array_insert(@asMsgs[@discord['userid']], @discord, 0);
		store_value('DiscordBot.'.@discord['serverid'].'.debug.ASTrigger.Messages', @asMsgs);
#### -------
	}
	# } else {
	#User OK 
}