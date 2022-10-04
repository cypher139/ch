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
