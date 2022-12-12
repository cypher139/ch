#version 1.0-tmc
bind('player_chat', array('id': 'Chat.formatter'), null, @chat) {
	@name = import('chatmodifier.name', 'Chat')
	@player = _getplayerID(player())
	@group = pgroup(@player['name'])[0]
	@dev = import('ch.player.'.@player['id'].'.developer')
	@say = @chat['message']
	set_uncaught_exception_handler(closure(@ex) {
		@dev = import('ch.player.'.puuid(player(), 'dashless').'.developer')
		msg(color('c').'['.color(6).@name.color('c').'] '.color(7).'An error has occured! Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'])
		msg(color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['message'])
		@msg1 = color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['classType'].'! '.color(7).@ex['message']
		if(@dev == true) {msg(@msg1)}
		console(@msg1, false)
		array_iterate(@ex['stackTrace'], closure(@k, @v) {
			@pathdisplay = reg_split('\\/CommandHelper\\/', @v['file'])[1]
			if(reg_count('(includes.library)', @pathdisplay) > 0) {
				@pathdisplay = 'includes.library/'.reg_split('\\/includes.library\\/', @pathdisplay)[1]
			}		
			@msg2 = color(9).'../'.@pathdisplay.color(7).' Line: '.color('a').@v['line'].'.'.@v['col']
			console(color('c').'['.color(6).@name.color('c').'] '.@msg2, false)
			if(@dev == true) {msg(@msg2)}
		})
		return(true)
	});



#Chat layout formatting: finalization
	@groupinfo = import(@name.'.format.groups')
	if(@groupinfo == '' || @groupinfo == null || is_array(@groupinfo) == false,
		@groupinfo = array()
	)
	@groupinfokeys = array_keys(@groupinfo)
	if(!array_contains_ic(@groupinfokeys, @group),
		@groupinfo[@group] = array('namecolor': '', 'showhealth': '', 'usercolor': '', 'chatcolor': '', 'nickname': '')
	)
	@chatoptions = import(@name.'.format.options')
	if(@chatoptions == '' || @chatoptions == null || is_array(@chatoptions) == false,
		@chatoptions = array('colorize': '', 'randcolor': '', 'capitalizechat': '', 'capitalizegroupname': '')
	)
    #Defaults
	if(@groupinfo[@group]['showhealth'] == '' || @groupinfo[@group]['showhealth'] == null, @groupinfo[@group]['showhealth'] = true)
	if(@groupinfo[@group]['namecolor'] == '' || @groupinfo[@group]['namecolor'] == null, @groupinfo[@group]['namecolor'] = 'e')
	if(@groupinfo[@group]['usercolor'] == '' || @groupinfo[@group]['usercolor'] == null, @groupinfo[@group]['usercolor'] = 3)
	if(@groupinfo[@group]['chatcolor'] == '' || @groupinfo[@group]['chatcolor'] == null, @groupinfo[@group]['chatcolor'] = 'f')

	if(@chatoptions['colorize'] == '' || @chatoptions['colorize'] == null, @chatoptions['colorize'] = true)
    #Health
	if(@groupinfo[@group]['showhealth'] == true,
		@hb = color(0).'('._healthbar(@player['name']).color(0).')'
	)
	
	#Group options
	# Set nickname
	if(@groupinfo[@group]['nickname'] == '' || @groupinfo[@group]['nickname'] == null,
		@groupname = @group
	,
		@groupname = @groupinfo[@group]['nickname']
	)
	#Capitalize the group name?
	if(@chatoptions['capitalizegroupname'] == '' || @chatoptions['capitalizegroupname'] == null || @chatoptions['capitalizegroupname'] == true,
		@groupname = _capitalize(@groupname)
	)
	
	#User options
    #User's name color
	@namecolor = import(@name.'.player.'.@player['id'].'.chat.format.colors.username')
	if(@namecolor == '' || @namecolor == null,
		#first chat, values not loaded
		@namecolor = get_value(@name.'.player.'.@player['id'].'.chat.format.colors.username')
		export(@name.'.player.'.@player['id'].'.chat.format.colors.username', @namecolor)
	)
	#if no value set, this will set the group's color.
	if(@namecolor == '' || @namecolor == null,
		@namecolor = @groupinfo[@group]['usercolor']
	)
    #User's chat color
	@chatcolor = import(@name.'.player.'.@player['id'].'.chat.format.colors.chat')
	if(@chatcolor == '' || @chatcolor == null,
		#first chat, values not loaded
		@chatcolor = get_value(@name.'.player.'.@player['id'].'.chat.format.colors.chat')
		export(@name.'.player.'.@player['id'].'.chat.format.colors.chat', @chatcolor)
	)
	#if no value set, this will set the group's color.
	if(@chatcolor == '' || @chatcolor == null,
		@chatcolor = @groupinfo[@group]['chatcolor']
	)
    #Colorize user chat?
	@colorize = import(@name.'.player.'.@player['id'].'.chat.format.colorize')
	if(@colorize == '' || @colorize == null,
		#first chat, values not loaded
		@colorize = get_value(@name.'.player.'.@player['id'].'.chat.format.colorize')
		export(@name.'.player.'.@player['id'].'.chat.format.colorize', @colorize)
	)
	#if no value set, this will load the global default.
	if(@colorize == '' || @colorize == null,
		@colorize = @chatoptions['colorize']
	)
    #Capitalize user chat?
	@capitalizechat = import(@name.'.player.'.@player['id'].'.chat.format.capitalize')
	if(@capitalizechat == '' || @capitalizechat == null,
		#first chat, values not loaded
		@capitalizechat = get_value(@name.'.player.'.@player['id'].'.chat.format.capitalize')
		export(@name.'.player.'.@player['id'].'.chat.format.capitalize', @capitalizechat)
	)
	#if no value set, this will load the global default.
	if(@capitalizechat == '' || @capitalizechat == null,
		@capitalizechat = @chatoptions['capitalizechat']
	)
	
	
    #Toggle Rainbow chat
	@rtoggle = import(@name.'.player.'.@player['id'].'.chat.rainbow.toggle')
	if(@rtoggle == '' || @rtoggle == null) {
		#first chat, values not loaded
		@rtoggle = get_value(@name.'.player.'.@player['id'].'.chat.rainbow.toggle')
		export(@name.'.player.'.@player['id'].'.chat.rainbow.toggle', @rtoggle)
	}
	if(!has_permission(@player['name'], 'commandhelper.alias.chat.use.rainbow')) { @rtoggle = false }
	@rtype = import(@name.'.player.'.@player['id'].'.chat.rainbow.type')
	if(@rtype == '' || @rtype == null,
		#first chat, values not loaded
		@rtype = get_value(@name.'.player.'.@player['id'].'.chat.rainbow.type')
		export(@name.'.player.'.@player['id'].'.chat.rainbow.type', @rtype)
	)
	@rcmd = import(@name.'.player.'.@player['id'].'.chat.rainbow.cmd', false)
	if(@rtype == '' || @rtype == null, @rtype = 'normal')
	if(@rtoggle == true) {
		if(@rcmd == true) {	
			@say = @chat['message']
			export(@name.'.player.'.@player['id'].'.chat.rainbow.cmd', false)
		} else {
			@colorize = false
			@say = _rainbow(@chat['message'], @rtype)
		}
	}

    #Translate color codes into actual colors?
	if(@colorize == true) { @say = colorize(@say) }

    #Capitalize the first letter in chat?
	if(@capitalizechat == true) { @say = _capitalize(@say) }
	
	#Bug: ms.lang.FormatException! The "format" key in modify_event for the player_chat event only accepts %1$s and %2$s as format specifiers. Use a "%%" to display a single "%".
	@say = reg_replace('\\%', '%%', @say)

    #Finalize formatting
	modify_event('format', @hb.color(7).'('.color(@groupinfo[@group]['namecolor']).@groupname.color(7).') '.color(7).'<'.color(@namecolor).pinfo(@player['name'])[4].color(7).'> '.color(@chatcolor).@say)
}