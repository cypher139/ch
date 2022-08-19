#Export values, to allow for less database calls.
export('chat.format.groups', get_value('chat.format.groups'))
export('chat.format.options', get_value('chat.format.options'))


export('chatmodifier.name', 'Chat')
export('chatmodifier.version', '0.8-tza')


bind(player_chat, array(id: 'Chat.formatter'), null, @chat,
	assign(@name, import('chatmodifier.name'))
	assign(@player, player())
	assign(@group, pgroup(@player)[0])
	assign(@dev, import('ch.player.'.@chat[player].'.developer'))

	set_uncaught_exception_handler(closure(@ex){
		_msgAdmins(@player.'\'s chat caused an exception!: '.@ex)
		return(true)
	})


#test
	assign(@extok, '')
	if(extension_exists(CHPex),
		@extok = true
	,
		@extok = false
	)
	include('includes.library/chatfunctions-ext'.@extok.'.ms')
	
	if(@dev == true, msg(color(7).'[ChatDEV] chat perms return: '.color(f)._chat_perms_options(@player)))

#Chat layout formatting: finalization
	assign(@groupinfo, import(@name.'.format.groups'))
	if(@groupinfo == '' || @groupinfo == null || is_array(@groupinfo) == false,
		assign(@groupinfo, array())
	)
	assign(@groupinfokeys, array_keys(@groupinfo))
	if(!array_contains_ic(@groupinfokeys, @group),
		assign(@groupinfo[@group], array(namecolor: '', showhealth: '', usercolor: '', chatcolor: '', nickname: ''))
	)
	assign(@chatoptions, import(@name.'.format.options'))
	if(@chatoptions == '' || @chatoptions == null || is_array(@chatoptions) == false,
		assign(@chatoptions, array(colorize: '', randcolor: '', capitalizechat: '', capitalizegroupname: ''))
	)
    #Defaults
	if(@groupinfo[@group][showhealth] == '' || @groupinfo[@group][showhealth] == null, assign(@groupinfo[@group][showhealth], true))
	if(@groupinfo[@group][namecolor] == '' || @groupinfo[@group][namecolor] == null, assign(@groupinfo[@group][namecolor], e))
	if(@groupinfo[@group][usercolor] == '' || @groupinfo[@group][usercolor] == null, assign(@groupinfo[@group][usercolor], 3))
	if(@groupinfo[@group][chatcolor] == '' || @groupinfo[@group][chatcolor] == null, assign(@groupinfo[@group][chatcolor], f))

	if(@chatoptions[colorize] == '' || @chatoptions[colorize] == null, assign(@chatoptions[colorize], true))
    #Health
	if(@groupinfo[@group][showhealth] == true,
		assign(@hb, color(0).'('._healthbar(@player).color(0).')')
	)
	
	#Group options
	# Set nickname
	if(@groupinfo[@group][nickname] == '' || @groupinfo[@group][nickname] == null,
		assign(@groupname, @group)
	,
		assign(@groupname, @groupinfo[@group][nickname])
	)
	#Capitalize the group name?
	if(@chatoptions[capitalizegroupname] == '' || @chatoptions[capitalizegroupname] == null || @chatoptions[capitalizegroupname] == true,
		assign(@groupname, _capitalize(@groupname))
	)
	
	#User options
    #User's name color
	assign(@namecolor, import(@player.'.chat.format.colors.username'))
	if(@namecolor == '' || @namecolor == null,
		#first chat, values not loaded
		assign(@namecolor, get_value(@player.'.chat.format.colors.username'))
		export(@player.'.chat.format.colors.username', @namecolor)
	)
	#if no value set, this will set the group's color.
	if(@namecolor == '' || @namecolor == null,
		assign(@namecolor, @groupinfo[@group][usercolor])
	)
    #User's chat color
	assign(@chatcolor, import(@player.'.chat.format.colors.chat'))
	if(@chatcolor == '' || @chatcolor == null,
		#first chat, values not loaded
		assign(@chatcolor, get_value(@player.'.chat.format.colors.chat'))
		export(@player.'.chat.format.colors.chat', @chatcolor)
	)
	#if no value set, this will set the group's color.
	if(@chatcolor == '' || @chatcolor == null,
		assign(@chatcolor, @groupinfo[@group][chatcolor])
	)
    #Colorize user chat?
	assign(@colorize, import(@player.'.chat.format.colorize'))
	if(@colorize == '' || @colorize == null,
		#first chat, values not loaded
		assign(@colorize, get_value(@player.'.chat.format.colorize'))
		export(@player.'.chat.format.colorize', @colorize)
	)
	#if no value set, this will load the global default.
	if(@colorize == '' || @colorize == null,
		assign(@colorize, @chatoptions[colorize])
	)
    #Capitalize user chat?
	assign(@capitalizechat, import(@player.'.chat.format.capitalize'))
	if(@capitalizechat == '' || @capitalizechat == null,
		#first chat, values not loaded
		assign(@capitalizechat, get_value(@player.'.chat.format.capitalize'))
		export(@player.'.chat.format.capitalize', @capitalizechat)
	)
	#if no value set, this will load the global default.
	if(@capitalizechat == '' || @capitalizechat == null,
		assign(@capitalizechat, @chatoptions[capitalizechat])
	)
	
	
    #Toggle Rainbow chat
	assign(@rtoggle, import(@player.'.chat.rainbow.toggle'))
	if(@rtoggle == '' || @rtoggle == null,
		#first chat, values not loaded
		assign(@rtoggle, get_value(@player.'.chat.rainbow.toggle'))
		export(@player.'.chat.rainbow.toggle', @rtoggle)
	)
	if(has_permission(@player, 'commandhelper.alias.chat.use.rainbow'), null, assign(@rtoggle, false))
	assign(@rtype, import(@player.'.chat.rainbow.type'))
	if(@rtype == '' || @rtype == null,
		#first chat, values not loaded
		assign(@rtype, get_value(@player.'.chat.rainbow.type'))
		export(@player.'.chat.rainbow.type', @rtype)
	)
	assign(@rcmd, import(@player.'.chat.rainbow.cmd'))
	if(@rtype == '' || @rtype == null, assign(@rtype, 'normal'))
	if(@rcmd == '' || @rcmd == null, assign(@rcmd, false))
	if(@rtoggle == true && @rcmd == false, 
		assign(@colorize, false)
		assign(@say, _rainbow(@chat[message], @rtype))
	,
		assign(@say, @chat[message])
		export(@player.'.chat.rainbow.cmd', false)
	)

    #Translate color codes into actual colors?
	if(@colorize == true,
		assign(@say, colorize(@say))
	)
    #Capitalize the first letter in chat?
	if(@capitalizechat == true,
		assign(@say, _capitalize(@say))
	)

    #Finalize formatting
	modify_event('format', @hb.color(7).'('.color(@groupinfo[@group][namecolor]).@groupname.color(7).') '.color(7).'<'.color(@namecolor).pinfo(@player)[4].color(7).'> '.color(@chatcolor).@say)
)

