#minecraft centric commands

proc _discordBot_cmd_mcwhitelist(@discord, @args) {
	@config = import('DiscordBot.config.'.@discord['serverid'])	
	@wllog = get_value('DiscordBot.server.whitelist.info')	
	@stats = array('NoUsesRemain': array(), 'AlreadyListed': array(), 'UserNotFound': array(), 'Success': array())
	if(!is_array(@wllog)) { @wllog = array('Whitelisted': array(), 'log': array(), 'uses': array()) }
	if(!array_index_exists(@wllog, 'uses', @discord['userid'])) { array_set(@wllog['uses'], @discord['userid'], 0) }
	@useList = false
	@return = ''
	# User Must be an admin or have the required role to proceed.
	if(@discord['admin'] == true) { 
		@useList = true	
	} else {	
		try (
			@userRoles = discord_member_get_roles(@discord['serverid'], @discord['username'])
			foreach(@rolename: @roleid in @userRoles) {
				if(equals_ic(@config['Whitelist_Role'], @rolename) || @config['Whitelist_Role'] == @roleid) {
					@useList = true
					break()
				}
			}
		)
	}
	if(@useList == false) {
		return('This keycard has expired: please check The Coffee Shop for a new keycard.')
	}
	foreach(@user in @args) {
	# Limit how many whitelists a Discord user can use unless they are an admin.
		if(@wllog['uses'][@discord['userid']] >= @config['Whitelist_Allowed_Uses'] && @discord['admin'] == false) { 
			array_push(@stats['NoUsesRemain'], @user)
			continue()
		}
		if(pwhitelisted(@user)) {
			array_push(@stats['AlreadyListed'], @user)
			continue()
		} else {
			try {
				set_pwhitelisted(@user, true);
			} catch(NotFoundException @ex) {
				array_push(@stats['UserNotFound'], @user)
				continue()
			}
			array_push(@wllog['Whitelisted'], @user)
			array_set(@wllog['log'], time(), array('user': @user, 'from': @discord['userid'], 'fromuser': @discord['username']))
			@wllog['uses'][@discord['userid']]++
			array_push(@stats['Success'], @user)
		}
	}
	store_value('DiscordBot.server.whitelist.info', @wllog)

	#Send log Messages to User and server logs.
	if(array_size(@stats['Success']) > 0) {
		@s = ''
		if(array_size(@stats['Success']) > 1) { @s = 's' }
		@return = ' Whitelisted User'.@s.': `'.array_implode(@stats['Success'], '` `').'`'
		@adminmsg = '\n(Total whitelistings from '.@discord['username'].': '.@wllog['uses'][@discord['userid']].')'
		_discordBot_send_message('**'.@discord['username'].'**'.@return.@adminmsg, @discord['serverid'], 'admin');
		_db_msg_Console(color(9).@discord['username'].color(10).@return.color('r').@adminmsg, @discord['serverid']);
		@return = ':white_check_mark: '.@return
	}
	if(array_size(@stats['AlreadyListed']) > 0) {
		@s = ''
		if(array_size(@stats['AlreadyListed']) > 1) { @s = 's' }
		@return = @return.'\n:information_source: User'.@s.' `'.array_implode(@stats['AlreadyListed'], '` `').'` were already Whitelisted!'
	}
	if(array_size(@stats['NoUsesRemain']) > 0) {
		@s = ''
		if(array_size(@stats['NoUsesRemain']) > 1) { @s = 's' }
		@return = @return.'\n :warning: *You do not have enough remaining whitelist uses!* Contact the admins for assistance in whitelisting User'.@s.': `'.array_implode(@stats['NoUsesRemain'], '` `').'`'
		@adminmsg = @discord['username'].' does not have any more remaining uses to whitelist User'.@s.' `'.array_implode(@stats['NoUsesRemain'], '`  `').'`'
		_discordBot_send_message(@adminmsg, @discord['serverid'], 'admin')
		_db_msg_Console(color(14).@adminmsg, @discord['serverid'])
	}
	if(array_size(@stats['UserNotFound']) > 0) {
		@s = ''
		if(array_size(@stats['UserNotFound']) > 1) { @s = 's' }
		@return = @return.'\n:information_source: User'.@s.': `'.array_implode(@stats['UserNotFound'], '` `').'` were not found!'
	}
	return(@return)
}


#Add Commands to list
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'whitelist': array('alias': array('mc-whitelist'), 'admin': false, 'category': 'Minecraft', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_mcwhitelist(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)