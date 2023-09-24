#version 1.0-tmc

proc _discordBot_cmd_wrf(@discord, @cmdargs) {
	if(is_proc('_discordBot_WelcomeRolesFinder')) {
		if(!array_index_exists(@cmdargs, 0)) { @cmdargs = array('welcome') }
		@return = _discordBot_WelcomeRolesFinder(@cmdargs[0])
		if(reg_count('^[WwNn0]', @cmdargs[0]) > 0) {	
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
			# _discordBot_send_message(@return['amount'].' '.@return['msg'], @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
			return(array('embeds': array(array('title': 'Welcome Roles Finder', 'description': @return['amount'].' '.@return['msg'], 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'])))))
			
		} else {
			return('Specify the type you want: WelcomeRoles for members with just welcome roles, None for those with no roles.')
		}
	} else {
		return('NoCmd')
	}
}


#Add Commands to list
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'welcomerolesfinder': array('alias': array('wrf'), 'admin': true, 'category': 'Admin', 'cmd': closure(@discord, @args) { 
		if(!array_index_exists(@args, 0)) { @args = array('arg') }
		return(_discordBot_cmd_wrf(@discord, @args));
	})
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)