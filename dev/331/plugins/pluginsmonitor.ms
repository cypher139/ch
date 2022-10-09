bind(player_command, array(id: 'pl'), null, @cmdevent,
	assign(@name, Plugins)
	assign(@player, player())
	assign(@cmd, reg_split(' ', @cmdevent[command]))


	assign(@pluginscmds, get_value(@name.'.plugins.checklist.cmds'))
	assign(@pluginsperm, get_value(@name.'.plugins.checklist'))

	assign(@pluginschecks, array_keys(@pluginscmds))
	assign(@j, 0)
	foreach(@pluginscmds, @currentvar,
		assign(@plugin, @pluginschecks[@j])
		if(array_contains_ic(@currentvar, @cmd[0]),
			assign(@pluginl, to_lower(@plugin))
			#don't assume the plugin is still being checked!
			try(
				assign(@permcheck, @pluginsperm[@pluginl])
			,@fail,
				_msgAdmins(color(c).'['.color(6).@name.color(c).'] NAG NAG NAG '.color(7).@player.' just tried to use a command that is registered to a plugin that isn\'t being checked! Please add the "'.@plugin.'" to the permission check, or remove the plugin\'s commands from the check!', 'msg', 'no', @player)
				die()
			)
			if(has_permission(@player, @permcheck), null,
				tmsg(@player, color(f).'Unknown command. Type "help" for help.')
				assign(@serverplugins, get_server_info(9))
				foreach(@serverplugins, @currentplugin,
					assign(@checkcurrentplugin, to_lower(@currentplugin))
					if(@plugin == @checkcurrentplugin,
						assign(@plname, @currentplugin)
					,
						assign(@plname, '-')
					)
				)
				if(@plname == '-', assign(@plname, @plugin))
				_msgAdmins(color(c).'['.color(6).@name.color(c).'] '.color(7).@player.' just tried to use a command he does not have permission for!'.color(e).' Command used: '.@cmd[0], color(3).' (which is registered to the plugin: '.@plname.')', 'yes', @player)
				cancel()
			)
			break()
		)
		assign(@j, @j + 1)
	)
)