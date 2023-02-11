#version 1.0-tmc

proc _chat_cmd_codegen(@discord, @args) {	
	switch(rand(1,11)){
	case 4:
		return(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/password_strength.png'))))
	default:
		if(is_proc('_codegen')) {	
			@dmCode = @discord['UseDM']
			@channel = @discord['SendChannel']
			@type1 = ''
			@type2 = ''
			@length = null
			@prefix = ''
			if(array_index_exists(@args, 0)) {
				foreach(@i: @arg in @args) {
					if(reg_count('^[-]?[PpDd]', @arg) > 0) {
						@dmCode = 'dm'
						continue()
					}
					#if arg more than 5: set length
					if(is_numeric(@arg)) {
						if(@arg < 0) { continue() }
						if(@arg > 5) {
							if(@arg > 512) { @length = 512 } else { @length = @arg }
							continue()
						}
					}
					if(@type1 == '') {
						@type1 = @arg
					} else if(@type2 == '') {
						@type2 = @arg
					} else if(@length != null) {
						break()
					}
				}
			}
			if(@length == null) { @length = 8 }
			if(@type1 == '') { @type1 = 'full' }			
			x_new_thread('CodeGenerator', closure(){
				@code = _codegen(@length, @type1, @type2)
				if(@dmCode == 'dm') {
					@prefix = 'Randomly Generated code: \n'
					@channel = @discord['userid']
				}
				_send_discord_message(@prefix.@code, 'discord', @channel, @dmCode)
			});
			return(true)
		} else { return('NoCmd') }
	}
}

proc _chat_cmd_wrf(@discord, @cmdargs) {
	if(is_proc('_chat_WelcomeRolesFinder')) {
		if(!array_index_exists(@cmdargs, 0)) { @cmdargs = array('arg') }
		@return = _chat_WelcomeRolesFinder(@cmdargs[0])
		
		if(reg_count('^[WwNn]', @cmdargs[0]) > 0) {
			_send_discord_message(@return['amount'].' '.@return['msg'], 'discord', @discord['SendChannel'], @discord['UseDM'])
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
		} else {		
			if(array_index_exists(@return, 'zero')) {
				return(array('embeds': array(array('title': 'Welcome Roles Finder', 'description': @return['zero'].' members were detected as having 0 roles.', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'].'. Use "wrf noroles" to view IDs.')))))
				# discord_broadcast(@discord['SendChannel'], @return['zero'].' members were detected as having 0 roles. \n Use "wrf norole" to view IDs.')
			}
			if(array_index_exists(@return, 'welcome')) {
				return(array('embeds': array(array('title': 'Welcome Roles Finder', 'description': @return['welcome'].' members were detected as having only the Welcome Roles.', 'footer': array('icon_url': 'https://cdn.discordapp.com/emojis/511919340820627501.gif', 'text': ' requested by @'.@discord['username'].'. Use "wrf welcomeroles" to view IDs.')))))
			}
		}
	} else {
		return('NoCmd')
	}
}


proc _chat_cmd_codegen_pl(@discord, @args) {	
	switch(rand(1,4)) {
		case 2:
		if(is_proc('_codegen')) {	
			@results = array()		
			array_resize(@results, rand(5, 15)) 
			x_new_thread('CodeGenerator', closure(){
				foreach(@k: @v in @results) {
					@results[@k] = _codegen(rand(6, 21), rand(0, 5), rand(0, 5))
				}
				console(@results)
				@service = array_get_rand(array('your mom', '<redacted>', 'FTP'))
				_send_discord_message('Passwords for '.@service.': '.array_implode(@results, '\n --: '), 'discord', @discord['SendChannel'], @discord['UseDM'])
			});	
		} else {
			return('NoCmd')
		}
		case 3:
			_send_discord_message(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/security.png'))), 'discord', @discord['SendChannel'], @discord['UseDM'])
		default:
			_send_discord_message(array('embeds': array(array('image': 'https://media.tenor.com/KDm053TyIgEAAAAC/portal.gif'))), 'discord', @discord['SendChannel'], @discord['UseDM'])
	}
}


#Add Commands to list
@pnqx = import('Chat.Discord.Command.List.Admin', array())
@aqzy = import('Chat.Discord.Command.List.Alias', array())
@c3lx = import('Chat.Discord.Command.List', array())
@ow7q = import('Chat.Discord.Command.List.Categories', array('Utility': array('help')))

#External dependencies commands
if(is_proc('_codegen')) {
	@qn92 = array(	
		'code': closure(@discord, @args) { return(_chat_cmd_codegen(@discord, @args)); },
		'gibberish': closure(@discord, @args) { return(_chat_cmd_codegen(@discord, @args)); },
		'gibberishgenerator': closure(@discord, @args) { return(_chat_cmd_codegen(@discord, @args)); },
		'codegen': closure(@discord, @args) { return(_chat_cmd_codegen(@discord, @args)); },
		'password': closure(@discord, @args) { return(_chat_cmd_codegen(@discord, @args)); },
		####
		'listpasswords': closure(@discord) { return(_chat_cmd_codegen_pl(@discord)); },
		'passwords': closure(@discord) { return(_chat_cmd_codegen_pl(@discord)); },
		'lp': closure(@discord) { return(_chat_cmd_codegen_pl(@discord)); },
		'passwordlist': closure(@discord) { return(_chat_cmd_codegen_pl(@discord)); }
	)
	array_push(@aqzy, 'gibberish', 'gibberishgenerator', 'code', 'password', 'passwords', 'lp', 'passwordlist')
	@c3lx = array_merge(@c3lx, @qn92)
	@ow7qU = array('codegen')
	@ow7qF = array('listpasswords')
}
if(is_proc('_chat_WelcomeRolesFinder')) {
	@mIu7 = array(	
		'wrf': closure(@discord, @args) { 
			if(!array_index_exists(@args, 0)) { @args = array('arg') }
			return(_chat_cmd_wrf(@discord, @args));
		},
		'welcomerolesfinder': closure(@discord, @args) { 
			if(!array_index_exists(@args, 0)) { @args = array('arg') }
			return(_chat_cmd_wrf(@discord, @args));
		}
	)
	@c3lx = array_merge(@c3lx, @mIu7)
	array_push(@pnqx, 'wrf', 'welcomerolesfinder')
	array_push(@aqzy, 'wrf')
	@ow7qA = array('welcomerolesfinder')
}

# Categories. 
# Only name of main command.
if(!array_index_exists(@ow7q, 'Utility')) { array_set(@ow7q, 'Utility', array()) }
if(!array_index_exists(@ow7q, 'Fun')) { array_set(@ow7q, 'Fun', array()) }
if(!array_index_exists(@ow7q, 'Admin')) { array_set(@ow7q, 'Admin', array()) }
@ow7q['Utility'] = array_unique(array_merge(@ow7q['Utility'], @ow7qU))
@ow7q['Fun'] = array_unique(array_merge(@ow7q['Fun'], @ow7qF))
@ow7q['Admin'] = array_unique(array_merge(@ow7q['Admin'], @ow7qA))

export('Chat.Discord.Command.List', @c3lx)
export('Chat.Discord.Command.List.Admin', array_unique(@pnqx))
export('Chat.Discord.Command.List.Alias', array_unique(@aqzy))
export('Chat.Discord.Command.List.Categories', @ow7q)