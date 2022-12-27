#version 1.0-tmc
bind('player_chat', array('id': 'Chat.formatter'), null, @chat) {
	@name = import('chatmodifier.name', 'Chat')
	@player = _getplayerID(player())
	@group = pgroup(@player['name'])[0]
	@dev = import('ch.player.'.@player['id'].'.developer')
	@say = @chat['message']


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
	if(@groupinfo[@group]['showhealth'] == true) {	@hb = color(0).'('._healthbar(@player['name']).color(0).')' }
	
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
	@userconfig = import(@name.'.format.users.'.@player['id'])
	if(@userconfig == '' || @namecolor == null) {
		# First chat, values not loaded in memory
		@userconfig = get_value(@name.'.format.users.'.@player['id'])
		export(@name.'.format.users.'.@player['id'], @userconfig)
	}
	if(!is_array(@userconfig)) { @userconfig = array('usernamecolor': '', 'chatcolor': '', 'colorize': '', 'capitalizechat': '', 'rainbow': false, 'rainbow_type': 'normal', 'randomcolor': false) }

	@namecolor = @userconfig['usernamecolor']
	@chatcolor = @userconfig['chatcolor']
	@colorize = @userconfig['colorize']
	@capitalizechat = @userconfig['capitalizechat']
	@randomcolor = @userconfig['randomcolor']
	#If no user value is set, this will redirect to the group or global setting.
	if(@namecolor == '' || @namecolor == null) { @namecolor = @groupinfo[@group]['usercolor'] }
	if(@chatcolor == '' || @chatcolor == null) { @chatcolor = @groupinfo[@group]['chatcolor'] }
	if(@colorize == '' || @colorize == null) { @colorize = @chatoptions['colorize'] }
	if(@capitalizechat == '' || @capitalizechat == null) { @capitalizechat = @chatoptions['capitalizechat'] }

		
    #Toggle Rainbow chat
	@rtoggle = @userconfig['rainbow']
	if(!has_permission(@player['name'], 'commandhelper.alias.chat.use.rainbow')) { @rtoggle = false }
	if(@rtoggle == true) {
		@rcmd = import(@name.'.player.'.@player['id'].'.chat.rainbow.cmd', false)
		if(@rcmd == true) {	
			@say = @chat['message']
			export(@name.'.player.'.@player['id'].'.chat.rainbow.cmd', false)
		} else {
			@colorize = false
			@say = _rainbow(@chat['message'], @userconfig['rainbow_type'])
		}
	}

    #Translate color codes into actual colors?
	if(@colorize == true) { @say = colorize(@say) }

    #Capitalize the first letter in chat?
	if(@capitalizechat == true) { @say = _capitalize(@say) }
	
	#Random start message color:
	if(@randomcolor == true) { @chatcolor = rand(0, 15) }
	
	#Bug: ms.lang.FormatException! The "format" key in modify_event for the player_chat event only accepts %1$s and %2$s as format specifiers. Use a "%%" to display a single "%".
	@say = reg_replace('\\%', '%%', @say)

    #Finalize formatting
	modify_event('format', @hb.color(7).'('.color(@groupinfo[@group]['namecolor']).@groupname.color(7).') '.color(7).'<'.color(@namecolor).pinfo(@player['name'])[4].color(7).'> '.color(@chatcolor).@say)
}