######################################################
#
#   Main.ms file. This file is run when the server
#   starts up, or the plugin is reloaded. It can be used
#   as an opportunity to register events or do other things
#   when the server initially starts.
#
######################################################

bind(plugin_message_received, array(id: 'new.test'), null, @event,
	console(@event)
)

#binds
#-------
bind(player_join, array(id: 'login'), null, @login,
	#event playername may return null for some unknown reason
	assign(@player, _getplayerID(player()))

#Get player group
	assign(@group, pgroup(@player[name])[0])
	store_value('player.'.@player[id].'.group', @group)

#Are you a dev? Lets export the dev value!!!!!
	assign(@dev, get_value('ch.player.'.@player[id].'.developer'))
	export('ch.player.'.@player[id].'.developer', @dev)

#Console info
 	set_timeout(2000,closure(console(color(3).player().color(r).' connected with'.color(7).' IP: '.color(a).pinfo(player())[3].color(7).' hostname: '.pinfo(player())[10], false)))

#Rei's minimap: Enable radar for everything, and cavemapping.
#	msg(color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color(e).color(f))
	modify_event('join_message', color(0).color(0).color(1).color(2).color(3).color(4).color(5).color(6).color(7).color(e).color(f).color(a).'+ join'.color(7).': '.@player[display])
	
)

#-----


#ploc returns new world position, so not going to work
#bind(world_changed, array(id: 'world'), null, @world,
#        assign(@player, player())
#        if(@world[to] == @world[from]) { return() }
#
#        if(@world[to] == 'adventure',
#                assign(@sp, get_value(@player.'.adventure.savepoint'))
#                if(@sp == null || @sp == '', die())
#                set_timeout(5000, closure(
#					set_ploc(@player, @sp)
#				))
#				msg(color(7).'Returning to your previous savepoint in 5 seconds.')
#       )
#        if(@world[from] == 'adventure',
#				assign(@ploc, ploc(@player))
#                store_value(@player.'.adventure.savepoint', @ploc)
#                msg(@ploc)
#        )
#)


bind(player_quit, array(id: 'quit'), null, @quit,
	assign(@player, player())
	assign(@playerID, _getplayerID(player()))
	modify_event('message', color(c).'- part'.color(7).': '.@playerID[display])
)


bind(server_ping, array(id: 'ping'), null, @ping,
	console(color(6).'['.color(9).'Notification'.color(6).'] '.color(7).'Received ping from '.@ping[ip], false)
	modify_event('motd', _rainbow(@ping[motd], doubles))
)