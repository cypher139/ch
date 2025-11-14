proc _discordBot_cmd_viewlb(@discord, @cmdargs) {
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	if(@config['LB_Enable'] != true) { return('NotEnabled'); }
	@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard');
	@levelxp = import('DiscordBot.'.@discord['serverid'].'.Leaderboard.levelXP');
	@serverInfo = import('DiscordBot.Servers.Info.'.@discord['serverid']);
	@serverIconType = 'png';
	if(string_starts_with(@serverInfo['icon'], 'a_')) { @serverIconType = 'gif'; }
	@lbURL = if(array_index_exists(@config, 'LB_Options', 'URL'), @config['LB_Options']['URL'], 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @leaderboard['Guild_Name']));
	@groupLB = false;
	@isLastPage = false;
	@showExtraInfo = false;
	@showRoles = false;
	@userIDs = array();
	@return = array('embeds': array());
	if(@leaderboard == null) {
		_db_msg_Console('Leaderboard data not initialized, exiting', @discord['serverid']);
		return(false);
	}
	if(!is_array(@discord)) {
		_db_msg_Console('No data given to Leaderboard system, exiting', @discord['serverid']);
		return(false);
	}
	if(@levelxp == null) {
		@levelxp = _discordBot_lb_levelXP(@discord['serverid'], @config['LB_Options']['XP_Type']);
	}
	if(@serverInfo == null) {
		_discordBot_cache_server_info(@discord['serverid']);
		@serverInfo = import('DiscordBot.Servers.Info.'.@discord['serverid']);
		# @serverIcon = 'https://cdn.discordapp.com/embed/avatars/0.png';
	}
	# Calculate Top ranks
	@lbTop = array();
	foreach(@id: @data in @leaderboard['members']) {
		@lbTop[] = array('username': @data['username'], 'xp': @data['xp'], 'id': @id);
	}
	array_sort(@lbTop, closure(@left, @right){
		return(@left['xp'] < @right['xp']);
	});
	#options
	@usercheckargs = array();
	#apply all options
	foreach(@arg in @cmdargs) {
		switch(@arg) {
		case 'extra':
			@showExtraInfo = true;
		case 'roles':
		case 'levels':
			if(@showRoles || @config['LB_Options']['Use_Role_Rewards'] === false) { continue(); }
			@index = array_keys(@config['LB_Options']['Role_Rewards']);
			array_sort(@index, 'NUMERIC');
			@uInfo = discord_member_info(@discord['serverid'], @discord['userid']);
			@uDisplay = _db_get_user_nick(@discord['userid'], @discord['serverid'], @uInfo['username']);
			@uLevel = if(array_index_exists(@leaderboard['members'], @discord['userid']), @leaderboard['members'][@discord['userid']]['level'], 0);
			@roles = array(
			'author': array('icon_url': @uInfo['avatar'].'?size=40', 'name': @uDisplay, 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @uDisplay.' '.@leaderboard['Guild_Name'])),
			'title': @leaderboard['Guild_Name'].' Level Roles',
			'color': @uInfo['color'],
			'thumbnail':'https://cdn.discordapp.com/icons/'.@discord['serverid'].'/'.@serverInfo['icon'].'.'.@serverIconType.'?size=48',
			'description': '<@'.@discord['userid'].'>\'s Level:‎ ‎ ‎ ‎ ‎ ‎‎‎‎‎**'.@leaderboard['members'][@discord['userid']]['level'].'**',
			'fields': array(),
			'footer': array('text': '')
			);
			@unlockCount = 0;
			foreach(@i: @num in @index) {
				@unlocked = '';
				@uF = '';
				if(@uLevel >= @num) { @unlocked = 'UN'; @unlockCount++; @uF = '*';}
				@roleIDindex = if(@discord['UseDM'] === true, array('', 'RoleName', ''), array('<@&', 'RoleID', '>'));
				@roles['fields'][] = array('name': 'Level '.@num, 'value': '**'.@uF.@unlocked.'LOCKED'.@uF.'**\n**|** '.@roleIDindex[0].@config['LB_Options']['Role_Rewards'][@num][@roleIDindex[1]].@roleIDindex[2], 'inline': true);
			}
			@roles['footer']['text'] = if(@unlockCount < array_size(@index), @unlockCount.' Unlocked Roles | '.array_size(@index).' Total', 'All '.@unlockCount.' Roles Unlocked!');
			@return['embeds'][] = @roles;
			@showRoles = true;
			return(@return);
		case 'top':
		case 'all':
			@groupLB = true;
		case 'first':
			@userIDs[] = @lbTop[0]['id'];
		case 'second':
			@userIDs[] = @lbTop[1]['id'];
		case 'third':
			@userIDs[] = @lbTop[2]['id'];
		case 'fourth':
			@userIDs[] = @lbTop[3]['id'];
		case 'fifth':
			@userIDs[] = @lbTop[4]['id'];
		case '.':
		case '..':
		case 'i':
		case 'me':
		case 'self':
			@userIDs[] = @discord['userid'];
		default:
			if(is_numeric(@arg) && length(@arg) < 6) {
				if(array_index_exists(@lbTop, (@arg - 1))) {
					@userIDs[] = @lbTop[(@arg - 1)]['id'];
				}
			} else {
				@usercheckargs[] = @arg;
			}
		}
	} else {
	# No args: Use command defaults.
		switch(@discord['cmd']) {
		case 'rank':
			@userIDs[] = @discord['userid'];
		default:
			@groupLB = true;
		}
	}
		
	# Check remaining options for user IDs, add to list of IDs to display
	#Note: Skipped if an ID was already provided
	if(!array_index_exists(@userIDs, 0) && array_index_exists(@usercheckargs, 0)) {
		foreach(@arg in @usercheckargs) {
			if(is_numeric(@arg) && length(@arg) < 17) { continue(); }
			@checkuser = _discordBot_cmd_proc_finduserID(@arg, @discord);
			switch(string(@checkuser)) {
			case 'bot':
				# @checkuser = @config['Bot_ID'];
				return('Sorry, I can\'t just track myself on the leaderboards, as it\'s not for us bots!');
			case 'self':
				@checkuser = @discord['userid'];
			case 'notfound':
				continue();
			case 'multiple':
				continue();
			default:
				if(!is_numeric(@checkuser)) {
					@checkuser = @discord['userid'];
				}
			}
			if(!is_numeric(@checkuser)) {
				_db_msg_Console('view lb: non-numeric target! '.@checkuser, @discord['serverid'], 'debug');
				@checkuser = @discord['userid'];
			}
			if(array_index_exists(@leaderboard, 'members', @checkuser)) {
				@userIDs[] = @checkuser;
			}
		}
	}
#No IDs found: view yourself
	if(!array_index_exists(@userIDs, 0)) {
		if(array_index_exists(@usercheckargs, 0)) {
		# All checked users did not have an lb entry.
			#Level roles requested
			if(array_size(@return['embeds']) !== 0 || @showRoles) {
				return(@return);
			} else {
				return('Leaderboard entry not found for this User.');
			}
		} else if(!@showRoles) {
			#Rank: No arguments, or no IDs found: view yourself
			if(@discord['cmd'] == 'rank') {
				@userIDs[] = @discord['userid'];
			} else {
		# leaderboard: No arguments, or no IDs found: view top 10
				@groupLB = true;
			}
		}
	}
#Top 10
	if(@groupLB) {
		# Get indexes from pagenum
		@noPage = false;
		@embedEntries = 10;
		@maxEntries = @embedEntries + (@discord['UsePage'] - 1) * @embedEntries;
		@groupIndexes = array(@maxEntries - @embedEntries, @maxEntries - 1);
		if(!array_index_exists(@lbTop, @groupIndexes[0])) { @noPage = true; }
		if(array_index_exists(@lbTop, @groupIndexes[0]) && !array_index_exists(@lbTop, @groupIndexes[1])) { @groupIndexes[1] = array_size(@lbTop) - 1; @isLastPage = true; }
		@maxPage = ceil((array_size(@lbTop) - 1) / @embedEntries);
		#setup embed common items
		@embed = array(
			'author': array('icon_url': 'https://cdn.discordapp.com/icons/'.@discord['serverid'].'/'.@serverInfo['icon'].'.'.@serverIconType, 'name': @leaderboard['Guild_Name'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @leaderboard['Guild_Name'])),
			'title': '❯ Leaderboard Top '.if(@discord['UsePage'] < 2, @embedEntries, (@maxEntries - @embedEntries).' - '.@maxEntries),
			'thumbnail':'https://i.imgur.com/mJ7zu6k.png',
			'footer': array('text': 'Page '.@discord['UsePage'].' of '.@maxPage),
			'timestamp': time(),
			'url': @lbURL
			);
		@embed['color'] = if(@noPage, array('r': 235, 'g': 0, 'b': 0), discord_member_info(@discord['serverid'], @lbTop[@groupIndexes[0]]['id'])['color']);
		if(!is_array(@embed['color'])) { @embed['color'] = array('r': 235, 'g': 0, 'b': 0); }
		@userRank = 0;
		if(array_index_exists(@leaderboard, 'members', @discord['userid'])) {
			foreach(@num: @data in @lbTop) {
				#!not strict for some reason!
				if(@data['id'] == @discord['userid']) {
					@userRank = @num + 1;
					break();
				}
			}
		}
		@embed['footer']['text'] .= ' | '.if(@userRank > 0, 'you are ranked #'.@userRank, 'you should chat some more to place on the Leaderboard!');
		#Add top 10 lb
		@fieldData = array();
		if(@noPage) {
			@fieldData[] = '• *There are no entries for Page #'.@discord['UsePage'].'*!';
		} else {
			for(@i = @groupIndexes[0], @i <= @groupIndexes[1], @i++) {
				@j = @i + 1;
			#format:
			# . **##**: <username ahref linked> :: Level <level> (<xp> XP)
				# @uInfo = discord_member_info(@discord['serverid'], @lbTop[@i]['id']);
				@uDisplay = _db_get_user_nick(@lbTop[@i]['id'], @discord['serverid'], @lbTop[@i]['username']);
				@fieldData[] = '•**'.@j.'**: ['.@uDisplay.']('.@lbURL.') :: Level **'.@leaderboard['members'][@lbTop[@i]['id']]['level'].'** *( '.@leaderboard['members'][@lbTop[@i]['id']]['xp'].' xp )*';
			}
		}
		@embed['description'] = array_implode(@fieldData, '\n');
		@return['embeds'][] = @embed;
		@return['AddPageReactions'] = true;
	} else {
	# Format Users displays
		foreach(@i: @userID in @userIDs) {
			if(@i > 3) {
				@return['content'] = 'Woah there, not so many requests at once! I can only show the first few usernames:';
				break();
			}
			if(!array_index_exists(@leaderboard, 'members', @userID)) { continue(); }
			@userInfo = discord_member_info(@discord['serverid'], @userID);
			@userDisplay = _db_get_user_nick(@userID, @discord['serverid'], @userInfo['username']);
			@userRank = 0
			foreach(@index: @data in @lbTop) {
				if(@data['id'] == @userID) {
					@userRank = (@index + 1);
					break();
				}
			}
			@userLevel = @leaderboard['members'][@userID]['level'];
			@earnedXP = 0;
			@remainXP = 0;
			@totalXP = 0;
			@earnedXPPercent = 0;
			if(array_index_exists(@levelxp, (@userLevel + 1))) {
				@remainXP = @levelxp[(@userLevel + 1)] - @leaderboard['members'][@userID]['xp'];
				@earnedXP = @leaderboard['members'][@userID]['xp'] - @levelxp[@userLevel];
				@totalXP = @levelxp[(@userLevel + 1)] - @levelxp[@userLevel];
				@earnedXPPercent = round(@earnedXP / @totalXP, 2);
				if(integer(@earnedXPPercent) > 0) { @earnedXPPercent = 0; }
				@earnedXPPercent = integer(@earnedXPPercent * 100);
			} else {
				@earnedXP = @leaderboard['members'][@userID]['xp'];
				@remainXP = 'Max';
				@totalXP = @leaderboard['members'][@userID]['xp'];
			}
			@embed = array(
			'author': array('icon_url': 'https://cdn.discordapp.com/icons/'.@discord['serverid'].'/'.@serverInfo['icon'].'.'.@serverIconType, 'name': @leaderboard['Guild_Name'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @leaderboard['Guild_Name'])),
			'title': '❯ Leaderboard',
			'color': @userInfo['color'],
			'thumbnail': @userInfo['avatar'],
			'description': '<@'.@userID.'> ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎‎‎‎‎Rank #**'.@userRank.'** ‎ ‎ ‎ ‎ ‎ ‎ ‎Level **'.@leaderboard['members'][@userID]['level'].'**',
			'fields': array(
				array('name': 'XP', 'value': @leaderboard['members'][@userID]['xp'].' xp', 'inline': true),
				array('name': 'Messages', 'value': @leaderboard['members'][@userID]['msg_count'], 'inline': true),
				array('name': 'Level Up', 'value': @earnedXP.' / '.@totalXP.' xp\n['.strip_colors(_progressbar(@earnedXP, array(0, @totalXP, 15), array('=', '>', '⠀'))).'] *'.@earnedXPPercent.'%*', 'inline': false),
			),
			'footer': array('text': 'Retrieved'),
			'timestamp': time()
			);
			if(@userInfo['color'] == null) { array_remove(@embed, 'color'); }
			if(@showExtraInfo === true) {
				@lbLM = '`-`';
				if(@leaderboard['members'][@userID]['last_msg'] != 0) { @lbLM = '<t:'.substr(@leaderboard['members'][@userID]['last_msg'], 0, 10).':f>'; }
				@embed['fields'][] = array('name': 'Last Message', 'value': @lbLM, 'inline': true);
				if(array_index_exists(@leaderboard, 'members', @userID, 'words')) {
					@embed['fields'][] = array('name': 'Number of Words', 'value': @leaderboard['members'][@userID]['words'], 'inline': true);
				}
				@embed['fields'][] = array('name': 'All XP', 'value': '*Bot Spam:* '.@leaderboard['members'][@userID]['all_xp'][0].'\n  *Multiple Messages in 1 Min:* '.@leaderboard['members'][@userID]['all_xp'][1].'\n Normal XP: '.@leaderboard['members'][@userID]['all_xp'][2], 'inline': true);
				if(@discord['admin'] === true) {
					@embed['fields'][] = array('name': 'Avatar', 'value': '[Avatar]('.@userInfo['avatar'].')', 'inline': true);
					@embed['fields'][] = array('name': 'RGB Color', 'value': array_implode(@leaderboard['members'][@userID]['color'], ', '), 'inline': true);
					if(array_index_exists(@leaderboard, 'members', @userID, 'tag')) {
						@embed['fields'][] = array('name': 'User Tag', 'value': @leaderboard['members'][@userID]['tag'].'\n note: feature deprecated', 'inline': true);
					}
					if(array_index_exists(@leaderboard, 'members', @userID, 'mee6_xp')) {
						@embed['fields'][] = array('name': 'XP at Mee6 conversion:', 'value': @leaderboard['members'][@userID]['mee6_xp'], 'inline': true);
					}
				}
			}
			# Format embed setup, send to return
			if(array_size(@return['embeds']) <= 0) {
			# from Discord: "Embeds are deduplicated by URL. If a message contains multiple embeds with the same URL, only the first is shown."
				@embed['url'] = @lbURL;
			}
			@return['embeds'][] = @embed;
		}
	}
	if(!array_index_exists(@return, 'embeds', 0)) { @return = 'Um, yea i didn\'t find a matching Leaderboard entry!'; }
	# dev: _db_msg_Console(@return, @discord['serverid'], 'debug');
	return(@return);
}


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array());
@mIu7 = array(	
	'viewleaderboard': array('alias': array('leaderboard', 'lb', 'rank'), 'admin': false, 'category': 'Leaderboard', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_viewlb(@discord, @args)); },
			'help': 'View your Leaderboard rankings for users on this server! Shows XP earned, level, rank number, and more!', 'usage': '<user name, or rank number> [2nd user, etc.] [top] [roles] [extra]',
			'usagenote': 'Type a rank number to see the info of the user in that rank.\n "extra" shows info such as last message time, ignored XP accrued, avatar, and more!\n"roles" shows the roles available via leveling up in the Leaderboard, and your current attainment status of the roles!\n"top" shows the #1 ranked user. use Second, Third, etc to see relevant ranks as well.'),
	'lbroles': array('alias': '', 'admin': false, 'category': 'Leaderboard', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_viewlb(@discord, array('roles'))); },
			'help': 'View your unlocked Rank roles via earned XP from the Leaderboard system, and see which ones are still yet to be obtained!')
);
@c3lx = array_merge(@c3lx, @mIu7);
export('DiscordBot.Command.List', @c3lx);