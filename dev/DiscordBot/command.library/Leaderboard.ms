proc _discordBot_cmd_viewlb(@discord, @cmdargs) {
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@discord['serverid'])
	if(@config['LB_Enable'] != true) { return('NotEnabled') }
	@leaderboard = import('DiscordBot.'.@discord['serverid'].'.Leaderboard');
	@levelxp = import('DiscordBot.'.@discord['serverid'].'.Leaderboard.levelXP')
	@serverInfo = import('DiscordBot.Guilds.Info.'.@discord['serverid'])
	@showExtraInfo = false
	@userIDs = array()
	if(@leaderboard == null) { 
		_db_msg_Console('Leaderboard data not initialized, exiting', @discord['serverid']) 
		return(false)
	}
	if(!is_array(@discord)) {
		_db_msg_Console('No data given to Leaderboard system, exiting', @discord['serverid'])
		return(false)
	}
	if(@levelxp == null) { 
		@levelxp = _discordBot_lb_levelXP(@discord['serverid'], @config['LB_Options']['XP_Type']);
	}
	if(@serverInfo == null) { 
		_discordBot_get_server_info(@discord['serverid'])
		@serverInfo = import('DiscordBot.Guilds.Info.'.@discord['serverid'])
		# @serverIcon = 'https://cdn.discordapp.com/embed/avatars/0.png'
	}
	# Calculate Top ranks
	@lbTop = array()
	foreach(@id: @data in @leaderboard['members']) {
		@lbTop[] = array('username': @data['username'], 'xp': @data['xp'], 'id': @id)
	}
	array_sort(@lbTop, closure(@left, @right){
		return(@left['xp'] < @right['xp']);
	});
	#options
	@usercheckargs = array()
	#apply all options
	foreach(@arg in @cmdargs) {
		switch(@arg) {
		case 'extra':
			@showExtraInfo = true
		case 'all':
			@Placeholder = true
		case 'top':
		case 'first':
			@userIDs[] = @lbTop[0]['id']
		case 'second':
			@userIDs[] = @lbTop[1]['id']
		case 1..9:
			@userIDs[] = @lbTop[(@arg - 1)]['id']
		default:
			@usercheckargs[] = @arg
		}
	}
		
		
	# Check remaining options for user IDs, add to list of IDs to display
	#Note: Skipped if an ID was already provided
#maybe foreach results to show multiple embeds (limit to 3 results)
	if(!array_index_exists(@userIDs, 0) && array_index_exists(@usercheckargs, 0)) {
		foreach(@arg in @usercheckargs) {
			if(is_numeric(@arg) && length(@arg) < 17) { continue() }
			@checkuser = _discordBot_cmd_proc_finduserID(@arg, @discord)
			console('arg: '.@arg.'     cu: '.@checkuser)
			switch(string(@checkuser)) {
			case 'bot':
				# @checkuser = @config['Bot_ID']
				return('Sorry, I can\'t just track myself on the leaderboards, as it\'s not for us bots!')
			case 'self':
				@checkuser = @discord['userid']
			case 'notfound':
				continue()
			case 'multiple':
				continue()
			default:
				if(!is_numeric(@checkuser)) {
					@checkuser = @discord['userid']
				}
			}
			if(!is_numeric(@checkuser)) {
				_db_msg_Console('view lb: non-numeric target! '.@userID, @discord['serverid'], 'debug')
				@checkuser = @discord['userid']
			}
			if(array_index_exists(@leaderboard, 'members', @checkuser)) {
				@userIDs[] = @checkuser
			}
		}
	}
#No IDs found: view yourself
	if(!array_index_exists(@userIDs, 0)) {
		if(array_index_exists(@usercheckargs, 0)) {
			#All checked users did not have an lb entry.
			return('Leaderboard entry not found for this User.')
		} else {
			#No arguments, view yourself
			@userIDs[] = @discord['userid']
		}
	}

# Format display
	@return = array('embeds': array())
	foreach(@userID in @userIDs) {
		if(!array_index_exists(@leaderboard['members'], @userID)) { continue() }
		@userInfo = discord_member_info(@discord['serverid'], @userID);
		@userDisplay = @userInfo['username']
		if(nequals_ic(@userInfo['username'], @userInfo['displayname'])) { @userDisplay = @userInfo['displayname'] }
		if(nequals_ic(@userInfo['username'], @userInfo['nickname']) && @userInfo['nickname'] != '' ) { @userDisplay = @userInfo['nickname'] }
		@userRank = 0
		foreach(@index: @data in @lbTop) {
			if(@data['id'] == @userID) {
				@userRank = (@index + 1)
				break()
			}
		}
		@userLevel = @leaderboard['members'][@userID]['level']
		@earnedXP = 0
		@remainXP = 0
		@totalXP = 0
		if(array_index_exists(@levelxp, (@userLevel + 1))) {
			@remainXP = @levelxp[(@userLevel + 1)] - @leaderboard['members'][@userID]['xp']
			@earnedXP = @leaderboard['members'][@userID]['xp'] - @levelxp[@userLevel]
			@totalXP = @levelxp[(@userLevel + 1)] - @levelxp[@userLevel]
		} else {
			@earnedXP = @leaderboard['members'][@userID]['xp']
			@remainXP = 'Max'
			@totalXP = @leaderboard['members'][@userID]['xp']
		}
		@serverIconType = 'png'
		if(string_starts_with(@serverInfo['icon'], 'a_')) { @serverIconType = 'gif' }
		@lbURL = 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @leaderboard['Guild_Name'])
		if(array_index_exists(@config, 'LB_Options', 'URL')) { @lbURL = @config['LB_Options']['URL'] }
		@embed = array(
		# https://cdn.discordapp.com/icons/'.@discord['serverid'].'/'guild_icon.'.png'
		'author': array('icon_url': 'https://cdn.discordapp.com/icons/'.@discord['serverid'].'/'.@serverInfo['icon'].'.'.@serverIconType, 'name': @leaderboard['Guild_Name'], 'url': 'https://www.google.com/search?q='.reg_replace('\\W+', '+', @leaderboard['Guild_Name'])),
		'title': 'Leaderboard',
		'url': @lbURL,
		'color': @userInfo['color'],
		'thumbnail': @userInfo['avatar'],
		'description': '<@'.@userID.'> ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎ ‎‎‎‎‎Rank #**'.@userRank.'** ‎ ‎ ‎ ‎ ‎ ‎ ‎Level **'.@leaderboard['members'][@userID]['level'].'**',
		'fields': array(
			array('name': 'XP', 'value': @leaderboard['members'][@userID]['xp'].' xp', 'inline': true),
			array('name': 'Messages', 'value': @leaderboard['members'][@userID]['msg_count'], 'inline': true),
			array('name': 'Level Up', 'value': @earnedXP.' / '.@totalXP.' xp\n'.'[progress]', 'inline': false),
		),
		'footer': array('text': 'Retrieved'),
		'timestamp': time()
		)
		if(@showExtraInfo == true) {
			if(@leaderboard['members'][@userID]['last_msg'] == 0) {	@lbLM = '`-`' } else { @lbLM = '<t:'.substr(@leaderboard['members'][@userID]['last_msg'], 0, 10).':f>' }
			@embed['fields'][] = array('name': 'Last Message', 'value': @lbLM, 'inline': true)
			if(array_index_exists(@leaderboard, 'members', @userID, 'words')) {
				@embed['fields'][] = array('name': 'Number of Words', 'value': @leaderboard['members'][@userID]['words'], 'inline': true)
			}
			@embed['fields'][] = array('name': 'All XP', 'value': '*Bot Spam:* '.@leaderboard['members'][@userID]['all_xp'][0].'\n  *Multiple Messages in 1 Min:* '.@leaderboard['members'][@userID]['all_xp'][1].'\n Normal XP: '.@leaderboard['members'][@userID]['all_xp'][2], 'inline': true)
			if(@discord['admin'] == true) {
				@embed['fields'][] = array('name': 'Avatar', 'value': '[Avatar]('.@userInfo['avatar'].')', 'inline': true)
				@embed['fields'][] = array('name': 'HTML Color', 'value': @leaderboard['members'][@userID]['color'], 'inline': true)
				if(array_index_exists(@leaderboard, 'members', @userID, 'tag')) {
					@embed['fields'][] = array('name': 'User Tag', 'value': @leaderboard['members'][@userID]['tag'].'\n note: feature deprecated', 'inline': true)
				}
				if(array_index_exists(@leaderboard, 'members', @userID, 'mee6_xp')) {
					@embed['fields'][] = array('name': 'XP at Mee6 conversion:', 'value': @leaderboard['members'][@userID]['mee6_xp'], 'inline': true)
				}
			}
		}
		#format embed setup, send to return
		@return['embeds'][] = @embed
	}
	if(!array_index_exists(@return, 'embeds', 0)) { @return = 'Um, yea i didn\'t find a matching Leaderboard entry!' }
	console(@return)
	return(@return)
}


#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'viewleaderboard': array('alias': array('viewlb', 'lb'), 'admin': false, 'category': 'Leaderboard', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_viewlb(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)