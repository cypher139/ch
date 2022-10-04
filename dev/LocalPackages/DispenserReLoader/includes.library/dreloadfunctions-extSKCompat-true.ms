######################################################
#
#   ReLoad: Fill chests or dispensers, or furnaces in one click!
#   includes for Area mode, to be included if the extension SKCompat is installed.
#   version 1.1-tmc
#
######################################################
proc(_reloader_iterate_cuboid, @proc_name, @world, @item, @playergiven, @qty, @fuel, @verbose,
	assign(@name, import('dispenserreloader.name'))
	assign(@player, _reloader_getplayerID(@playergiven))
	assign(@pos1, sk_pos1(@player[name]))
	assign(@pos2, sk_pos2(@player[name]))
        if(@pos1 == null || @pos2 == null,
                return(array(fail: true, failmsg: color(c).'['.color(6).@name.color(c).'] '.color(7).'What area? You need to make a selection with WorldEdit first!'))
        )
        #Start counting how many blocks were filled
        assign(@n, 0)
        assign(@nq, 0)
        assign(@blocktypes, array(chest: 0, dispenser: 0, furnace: 0))
        # Get the player's area mode
        assign(@areamode, get_value(@name.'.player.'.@player.'.area.mode'))
        if(@areamode == '' || @areamode == null,
                assign(@areamode, ALL)
        )
        # Area mode, part 2: Force furnace mode if "/reloader area fuel" is used.
        if(@fuel == true,
                assign(@areamode, FURNACE)
        )
        assign(@areamode, to_upper(@areamode))
        assign(@acceptfilltypes, array(CHEST, DISPENSER, FURNACE))     
 
        for(assign(@x, min(@pos1[0], @pos2[0])), @x <= max(@pos1[0], @pos2[0]), @x++,
                for(assign(@y, min(@pos1[1], @pos2[1])), @y <= max(@pos1[1], @pos2[1]), @y++,
                        for(assign(@z, min(@pos1[2], @pos2[2])), @z <= max(@pos1[2], @pos2[2]), @z++,
				assign(@xyz, array())
                                assign(@xyz[0], @x)
                                assign(@xyz[1], @y)
                                assign(@xyz[2], @z)
                                assign(@xyz[3], @world)
                                #This stops the script if this block isn't capable of having a inventory.
                                try(
                                        assign(@size, get_inventory_size(@xyz))
                                ,@fail,
                                        continue()
                                )
                                #Check: limit what you can fill
                                assign(@filltype, get_inventory_type(@xyz))
                                if(array_contains(@acceptfilltypes, @filltype), null, continue())
                                #Area mode: Continue if the block type doesn't match the set mode.
                                if(@areamode != 'ALL',
                                        if(@areamode != @filltype, continue())
                                )      
                                #Run the fill operation.
                                assign(@return, call_proc(@proc_name, @x, @y, @z, @world, @item, @player[name], @qty, @fuel, @verbose))
                                #stats: count blocks filled and items used.
                                assign(@ft, to_lower(@filltype))
                                #Report how many of each block type was filled, but only if it was filled!
                                if(@return[filledqty] != 0,
                                        assign(@blocktypes[@ft], @blocktypes[@ft] + 1)
                                        inc(@n)
                                        inc(@nq, @return[filledqty])
                                )
                        )
                )
        )
#record stats, only if you actually filled a block.
        if(@nq != 0,
                _reloader_record_stats(@player[name], area, @n, @nq, @item, @qty)
        )
 
#return
        return(array(blocks: @n, items: @nq, type: @blocktypes, fail: false, failmsg: false))
)
