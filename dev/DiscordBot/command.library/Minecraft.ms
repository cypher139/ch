#minecraft centric commands

proc _discordBot_cmd_mcwhitelist(@discord, @args) {
	@config = import('DiscordBot.config.'.@discord['serverid'])	
	@wllog = get_value('DiscordBot.server.whitelist.info')	
	@stats = array('NoUsesRemain': array(), 'AlreadyListed': array(), 'UserNotFound': array(), 'Success': array());
	if(!is_array(@wllog)) { @wllog = array('Whitelisted': array(), 'log': array(), 'uses': array()); }
	if(!array_index_exists(@wllog, 'uses', @discord['userid'])) { @wllog['uses'][@discord['userid']] = 0; }
	@useList = false;
	@return = '';
	# User Must be an admin or have the required role to proceed.
	if(@discord['admin'] === true) { 
		@useList = true;
	} else {	
		try (
			@userRoles = discord_member_get_roles(@discord['serverid'], @discord['username']);
			foreach(@rolename: @roleid in @userRoles) {
				if(equals_ic(@config['Whitelist_Role'], @rolename) || @config['Whitelist_Role'] == @roleid) {
					@useList = true;
					break();
				}
			}
		);
	}
	if(@useList === false) {
		return('This keycard has expired: please check The Coffee Shop for a new keycard.');
	}
	foreach(@user in @args) {
	# Limit how many whitelists a Discord user can use unless they are an admin.
		if(@wllog['uses'][@discord['userid']] >= @config['Whitelist_Allowed_Uses'] && @discord['admin'] === false) { 
			array_push(@stats['NoUsesRemain'], @user);
			continue();
		}
		if(pwhitelisted(@user)) {
			array_push(@stats['AlreadyListed'], @user);
			continue();
		} else {
			try {
				set_pwhitelisted(@user, true);
			} catch(NotFoundException @ex) {
				array_push(@stats['UserNotFound'], @user);
				continue();
			}
			array_push(@wllog['Whitelisted'], @user);
			@wllog['log'][time()] = array('user': @user, 'from': @discord['userid'], 'fromuser': @discord['username']);
			@wllog['uses'][@discord['userid']]++
			array_push(@stats['Success'], @user);
		}
	}
	store_value('DiscordBot.server.whitelist.info', @wllog);

	#Send log Messages to User and server logs.
	if(array_size(@stats['Success']) > 0) {
		@s = '';
		if(array_size(@stats['Success']) > 1) { @s = 's'; }
		@return = ' Whitelisted User'.@s.': `'.array_implode(@stats['Success'], '` `').'`';
		@adminmsg = '\n(Total whitelistings from '.@discord['username'].': '.@wllog['uses'][@discord['userid']].')';
		_discordBot_broadcast(@discord['serverid'], '--admin', '**'.@discord['username'].'**'.@return.@adminmsg);
		_db_msg_Console(color(9).@discord['username'].color(10).@return.color('r').@adminmsg, @discord['serverid']);
		@return = ':white_check_mark: '.@return
	}
	if(array_size(@stats['AlreadyListed']) > 0) {
		@s = '';
		if(array_size(@stats['AlreadyListed']) > 1) { @s = 's'; }
		@return .= '\n:information_source: User'.@s.' `'.array_implode(@stats['AlreadyListed'], '` `').'` were already Whitelisted!';
	}
	if(array_size(@stats['NoUsesRemain']) > 0) {
		@s = '';
		if(array_size(@stats['NoUsesRemain']) > 1) { @s = 's'; }
		@return .= '\n :warning: *You do not have enough remaining whitelist uses!* Contact the admins for assistance in whitelisting User'.@s.': `'.array_implode(@stats['NoUsesRemain'], '` `').'`';
		@adminmsg = @discord['username'].' does not have any more remaining uses to whitelist User'.@s.' `'.array_implode(@stats['NoUsesRemain'], '`  `').'`';
		_discordBot_broadcast(@discord['serverid'], '--admin', @adminmsg);
		_db_msg_Console(color(14).@adminmsg, @discord['serverid']);
	}
	if(array_size(@stats['UserNotFound']) > 0) {
		@s = '';
		if(array_size(@stats['UserNotFound']) > 1) { @s = 's'; }
		@return .= '\n:information_source: User'.@s.': `'.array_implode(@stats['UserNotFound'], '` `').'` were not found!';
	}
	return(@return);
}

proc _discordBot_cmd_mcgive(@discord, @args) {

if(!array_index_exists(@args, 0)) {return('Error'); }
if(!array_contains(all_players(), @args[0])) {return('NoUserFound'); }
if(!array_index_exists(@args, 1)) {return('Error'); }
#index: 0 - -2: item name, -1: qty
@array = @args[1..-1];
@mcreturn = _cmd_giveitem(@args[0], @args[1..-1], @discord['nickname']);

#index: 0 - -2: item name, -1: qty
@array = @args[1..-1];

@mcreturn = _cmd_giveitem(@args[0], @args[1..-1], @discord['nickname']);
return(@mcreturn);
}
#Add Commands to list
@c3lx = import('DiscordBot.Command.List', array());
@mIu7 = array(	
	'whitelist': array('alias': array('mc-whitelist'), 'admin': false, 'category': 'Minecraft', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_mcwhitelist(@discord, @args)); }),
	'give': array('alias': array('mc-give'), 'admin': false, 'category': 'Minecraft', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_mcgive(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7);
export('DiscordBot.Command.List', @c3lx);