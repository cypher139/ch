 
proc(_reloader_msgAdmins, @msg, @consolemsg, @consoleconcat,
        if(@consolemsg == '' || @consolemsg == null, assign(@consolemsg, @msg))
	if(@consoleconcat == true,
		assign(@consolemsg, @msg.@consolemsg)
	)
        console(@consolemsg, false)
        foreach(all_players(), @p,
                if(has_permission(@p, 'commandhelper.alias.admin.message'),
                        tmsg(@p, @msg)
                )
        )
)
 
proc(_number_commaize, @number,
        #catch numbers with decimal points, and only commaize the whole numbers.
        if(reg_match('[0-9]\\.[0-9]', @number),
                assign(@n1, reg_split('\\.', @number))
                assign(@n, @n1[0])
                assign(@n2, @n1[1])
        ,
                assign(@n, @number)
        )
        #add the commas
        assign(@n, reg_replace('(\\d)(?=(\\d{3})+$)', '$1,', @n))
        if(reg_match('[0-9]\\.[0-9]', @number),
                return(@n.'.'.@n2)
        ,
                return(@n)
        )
)
 
 
proc(_reloader_fill, @x, @y, @z, @world, @item, @player, @qty, @fuel, @verbose,
	assign(@name, import('dispenserreloader.name'))
        assign(@dev, import(@player.'.script.developer'))
        assign(@chmaxstacksize, 64)
 
# We need a real array
	assign(@xyz, array())
        assign(@xyz[0], @x)
        assign(@xyz[1], @y)
        assign(@xyz[2], @z)
        assign(@xyz[3], @world)
        if(@dev == true,
                tmsg(@player, color(7).'[DEV] _reloader_fill: '.color(f).'Evaluating block: '.@xyz)
        )
# Check: null/air
        assign(@itemname, data_name(@item))
        if(@itemname == null || @item == 0,
                return(array(msg: color(c).'['.color(6).@name.color(c).'] '.color(7).'You cannot use air!', size: 0, fail: true))
        )
# Get the inventory size
        try(
                assign(@size, get_inventory_size(@xyz))
        ,@fail,
                return(array(msg: color(c).'['.color(6).@name.color(c).'] '.color(7).'This location isn\'t capable of having a inventory!', size: 0, fail: true))
        )
        assign(@filltype, get_inventory_type(@xyz))
        assign(@maxstacksize, max_stack_size(@item))
        if(@verbose == 'yes',
                tmsg(@player, color(3).'['.color(6).@name.color(3).'] '.color(9).'A fillable item was found at: '.@xyz)
        )
# Check for fuel mode: If enabled ignore chest/dispenser
	if(@filltype != 'FURNACE' && @fuel == true,
		return(array(msg: color(c).'['.color(6).@name.color(c).'] '.color(7).'You cannot use a Chest or Dispenser while in Fuel mode!', size: 0, fail: true))
	) 
# Check: limit what you can fill
        assign(@acceptfilltypes, array(CHEST, DISPENSER, FURNACE))
        if(array_contains(@acceptfilltypes, @filltype), null,
                return(array(msg: color(c).'['.color(6).@name.color(c).'] '.color(7).'You cannot fill this item type!', size: 0, fail: true))
        )
# Get specified item quantity
        if(@qty == '' || @qty == null,
                assign(@qty, import(@name.'.player.'.@player.'.set.item.qty'))
        )
        if(@qty == '' || @qty == null,
                assign(@qty, @maxstacksize)
        )      
# Set array of item
        assign(@itema, array(type: @item, qty: @qty))
 
# Check: illegitimate stack perm
        if(has_permission(@player, 'commandhelper.alias.reloader.stack.illegitimate'),
                assign(@istack, true)
        ,
                assign(@istack, false)
        )


# Set the items in the block.
        assign(@fqty, 0)
	assign(@re, '')
        for(assign(@i, 0), @i < @size, @i++,
                if(@filltype == 'FURNACE',
                        if(@fuel == true,
                                #this sets the fuel in the bottom of the furnace.
                                assign(@i, 1)
                        ,
                                #this sets the top of the furnace.
                                assign(@i, 0)
                        )
                )
                #item already filled check
                assign(@af, get_inventory_item(@xyz, @i))
                if(@af == '' || @af == null, assign(@af, array(type: 0, qty: 0, data: 0)))
                assign(@mqty, 0)
                #if block types match
                if(reg_count('[0-9]:[0-9]', @item) == 1,
                        assign(@checktype, @af[type].':'.@af[data])
                ,
                        assign(@checktype, @af[type])
                )
                if(@item == @checktype,
                        assign(@re, 're-')
                        #quantity greater than current (eg qty 64, filled 23)
                        if(@qty > @af[qty],
                                #set_inventory_item needs what's already there plus the new items, as anything previously in there gets overwritten.
                                assign(@nqty, @af[qty] + @qty)
                                #set_inventory_item has a max limit of 64
                                if(@nqty > @chmaxstacksize,
                                        assign(@mqty, @nqty - @chmaxstacksize)
                                        assign(@nqty, @chmaxstacksize)
                                )
                                #Check: illegitimate stack
                                if(@nqty > @maxstacksize,
                                        if(@istack == true, null,
                                                #no perm, so we will bump down the qty to the max stack size minus what's filled.
                                                assign(@qty, @maxstacksize - @af[qty])
                                                if(0 > @qty, assign(@qty, 0))
                                                assign(@mqty, @qty)
                                                assign(@nqty, @qty)
                                        )
                                )
                                assign(@itema[qty], @nqty)
                                #stats: quantity actually filled
                                assign(@fqty1, @qty - @mqty)
                        )
                        #quantity is less than or equals filled
                        if(@qty < @af[qty] || @qty == @af[qty],
                                if(@filltype == 'FURNACE',
                                        break()
                                ,
                                        continue()
                                )
                        )
                ,
                #item does not match whats being filled.
                        #Check: illegitimate stack
                        if(@qty > @maxstacksize,
                                if(@istack == true, null,
                                        #no perm, so we will bump down the qty to the max stack size.
                                        assign(@qty, @maxstacksize)
                                        if(0 > @qty, assign(@qty, 0))
                                        assign(@fqty1, @qty)
                                )
                        )
                        assign(@itema[qty], @qty)
                        assign(@fqty1, @qty)
                )
                if(@dev == true, msg('slot'.@i.': '.get_inventory_item(@xyz, @i)))
        # Set the items
                set_inventory_item(@xyz, @i, @itema)
        # Stats: record amount of items used.
                assign(@fqty, @fqty + @fqty1)
        # If this is a furnace, there isn't anything left to fill, so stop the loop!
                if(@filltype == 'FURNACE', break())
        )
       
 
        assign(@donemsg, color(7).'['.color(6).@name.color(7).'] '.color(3).'Success! This '.to_lower(@filltype).' was '.@re.'filled, using a total of '.@fqty.' '.@itemname.'.')      
 
        if(@fqty == 0, assign(@donemsg, '0'))
        return(array(msg: @donemsg, size: @size, type: @filltype, filledqty: @fqty, fail: false))
)
 
 
       
proc(_reloader_record_stats, @player, @action, @filledblocks, @totalitems, @item, @qty,
	assign(@name, import('dispenserreloader.name'))
#Start the Stats recording.
        #total blocks filled
        assign(@fb, get_value(@name.'.stats.alltime.filled.blocks'))
        if(@fb == '' || @fb == null, assign(@fb, 0))
        assign(@nfb, @fb + @filledblocks)
        store_value(@name.'.stats.alltime.filled.blocks', @nfb)
        #total blocks filled - player
        assign(@pfb, get_value(@name.'.player.'.@player.'.stats.alltime.filled.blocks'))
        if(@pfb == '' || @pfb == null, assign(@pfb, 0))
        assign(@npfb, @pfb + @filledblocks)
        store_value(@name.'.player.'.@player.'.stats.alltime.filled.blocks', @npfb)
        #total action runs
        assign(@atr, get_value(@name.'.stats.alltime.runs.'.@action))
        if(@atr == '' || @atr == null, assign(@atr, 0))
        assign(@antr, @atr + 1)
        store_value(@name.'.stats.alltime.runs.'.@action, @antr)
        #total action runs - player
        assign(@ptr, get_value(@name.'.player.'.@player.'.stats.alltime.runs.'.@action))
        if(@ptr == '' || @ptr == null, assign(@ptr, 0))
        assign(@pntr, @ptr + 1)
        store_value(@name.'.player.'.@player.'.stats.alltime.runs.'.@action, @pntr)
        #total items filled
        assign(@items, get_value(@name.'.stats.alltime.items'))
        if(@items == '' || @items == null, assign(@items, array()))
        if(array_index_exists(@items, @item) == false,
                assign(@items[@item], 0)
        )
        assign(@items[@item], @totalitems + @items[@item])
        store_value(@name.'.stats.alltime.items', @items)
        #total items filled - player
        assign(@playeritems, get_value(@name.'.player.'.@player.'.stats.alltime.items'))
        if(@playeritems == '' || @playeritems == null, assign(@playeritems, array()))
        if(array_index_exists(@playeritems, @item) == false,
                assign(@playeritems[@item], 0)
        )
        assign(@playeritems[@item], @totalitems + @playeritems[@item])
        store_value(@name.'.player.'.@player.'.stats.alltime.items', @playeritems)
        #Last run
        assign(@olr1, get_value(@name.'.stats.last.run.1'))
        assign(@olr2, get_value(@name.'.stats.last.run.2'))
        assign(@olr3, get_value(@name.'.stats.last.run.3'))
        store_value(@name.'.stats.last.run.1', array(action: @action, player: @player, qty: @qty, filledqty: @totalitems, blocks: @filledblocks, item: @item))
        store_value(@name.'.stats.last.run.2', @olr1)
        store_value(@name.'.stats.last.run.3', @olr2)
        #last run - player
        store_value(@name.'.player.'.@player.'.stats.last.run', array(action: @action, qty: @qty, filledqty: @totalitems, blocks: @filledblocks, item: @item))
 
)

#reload random
#meant to be called once per block, for area needs re called for each successful block - _iterate_cuboid can manage this
#acts as wrapper for fill, managing random - whether or not it calls it.
#first get block types that can be used array
#2: assign action, yes or no. 50/50.
#if nothing, return(nofilled
#if yes continues
#3: assign choices, high percentage of nothing! each block/item to fill gets a weight. highest weight goes to nothing.
#if block, iterate inventory slots. send _reloader_fill the needed information to fill the slot if something was chosen. - must retrofit to not fill entire slots, only a specific slot.
#for stats you must return what / how much was filled.
