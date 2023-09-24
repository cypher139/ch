#version 1.0-tmc
proc _discordBot_cmd_dm(@discord, @cmdargs) {
	@config = import('DiscordBot.config.'.@discord['serverid'])
	@membernames = import('DiscordBot.'.@discord['serverid'].'.members.names')
	if(!is_array(@membernames)) { 
		@membernames = array()
		array_set(@membernames, @discord['username'], @discord['userid']) 
	}
	@userConfig = import('DiscordBot.DMs.user.settings', get_value('DiscordBot.DMs.user.settings'));
	if(is_array(@userConfig)) {
		if(!array_index_exists(@userConfig, @discord['userid'])) {
			array_set(@userConfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
		}	
	} else {
		@userConfig = array()
		array_set(@userConfig, @discord['userid'], array('NotifyContent': true, 'URLReadback': false))
	}
	
	if(!array_index_exists(@cmdargs, 0)) { @cmdargs = array('view') }
	switch(string(@cmdargs[0])) {
	case 'view':
		@userID = @discord['userid']
		@userSettings = @userConfig[@discord['userid']]
		if(array_index_exists(@cmdargs, 1)) {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord)
			if(!is_numeric(@userID)) {
				return('Cannot find settings for this user.')
			} else {
				@userSettings = @userConfig[@userID]
			}
		}
		@ret = 'DM settings for <@'.@userID.'>: '
		foreach(@set: @v in @userSettings) {
			@vd = '`'.@v.'`'
			if(is_boolean(@v)) {
				if(@v == true) {
					@vd = ':white_check_mark:'
				} else { 
					@vd = ':x:'
				}
			}
			@ret = @ret.'`'.@set.':` '.@vd.'  '
		}
		return(@ret)
		
	case 'notifycontent':
	case 'nc':
	case 'urlreadback':
	case 'url':
		@suffix = ' to the Minecraft server and Discord Admin log channel.'
		@ret = ''
		@userType = 'that user\'s'
		@userID = ''
		if(!array_index_exists(@cmdargs, 1)) {
			@userType = 'your'
			@userID = @discord['userid']
		} else if(@discord['admin'] == false) {
			return('NotAdmin')
		} else {
			@userID = _discordBot_cmd_proc_finduserID(@cmdargs[1], @discord)
			if(!is_numeric(@userID)) {
				switch(@userID) {
				case 'bot':
					return(array('embeds': array(array('footer': array('text': 'I don\'t know how to DM myself'), 'image': 'https://media.tenor.com/qfyuBx40-IAAAAAC/patrick-star-dumb.gif'))))
				case 'self':
					@userID = @discord['userid']
				case 'notfound':
					return('NoUserFound')
				case 'multiple':
					return(false)
				}
			}
			if(!array_index_exists(@userConfig, @userID)) {	array_set(@userConfig, @userID, array('NotifyContent': true, 'URLReadback': false))	}
		}
		switch(string(@cmdargs[0])) {
		case 'notifycontent':
		case 'nc':
			@userConfig[@userID]['NotifyContent'] = !@userConfig[@userID]['NotifyContent']
			if(@userConfig[@userID]['NotifyContent'] == true) {
				@ret = 'Content of '.@userType.' DMs with me shall be displayed'.@suffix
			} else {
				@ret = 'Content of '.@userType.' DMs with me *won\'t* be displayed'.@suffix	
			}
		case 'urlreadback':
		case 'url':
			@userConfig[@userID]['URLReadback'] = !@userConfig[@userID]['URLReadback']
			if(@userConfig[@userID]['URLReadback'] == true) {
				@ret = 'I\'ll message the URL of attachments in '.@userType.' DMs with me.'
			} else {
				@ret = 'Ok, no more useless URL messages in '.@userType.' DMs with me.'	
			}
		}
		export('DiscordBot.DMs.user.settings', @userConfig);
		store_value('DiscordBot.DMs.user.settings', @userConfig);
		return(@ret)
	default:
		return(false)
	}
	return('Last return')
}

#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'dm': array('alias': '', 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_dm(@discord, @args)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)