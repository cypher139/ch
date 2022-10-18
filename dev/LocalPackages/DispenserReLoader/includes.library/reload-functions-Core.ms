######################################################
#
#   ReLoad: Fill blocks that have inventories in one click!
#   Core Functions: Fill block inventory, record stats, and other shared functions.
#   version 1.2-tmc
#
######################################################
proc _is_even_number(@number) {return(mod(@number, 2) == 0)}

proc _reloader_getplayerID(@option1) {
	@pid = array()
	if(@option1 == '~console'){
		@pid = array(display: 'Console', name: '~console', id: 'console', nick: 'Server Console')
	} else {
	if(ponline(@option1) == true) {
		@pid['display'] = pinfo(@option1)[0];
		@pid['name'] = pinfo(@option1)[0];
		@pid['nick'] = pinfo(@option1)[4];
	} else {
		@pid['display'] = @option1
		@pid['name'] = @option1
		@pid['nick'] = 'Player Offline'		
	}
	@pid['id'] = puuid(@option1, 'dashless');
	}
	#Bedrock to Java players come in with name ".NAME", remove dot
	if(reg_count('^[\\.].*', @pid['name']) == 1, 
		assign(@pid['display'], reg_replace('^[\\.]','', @pid['name']))
	)
	return(@pid)
}

proc _reloader_check_perm(@player, @option, @option2) {
	switch(@option) {
	case 'item':
	#item
	#Any item
	#start with nope, only change to true on match
		@permmsg = 'You do not have permissions to use this item type.'
		@e = false
		if(has_permission(@player, 'commandhelper.alias.reloader.any.item.use')) {
			@permmsg = 'Using any item perm'
			@e = true
		}
		#item NAME (use.COAL), also use.263 if old id used
		if(has_permission(@player, 'commandhelper.alias.reloader.use.'.@option2)) {
			if(is_numeric(@option2)) {
				@permmsg = 'Using item ID perm'
			} else {
				@permmsg = 'Using item name perm'
			}
			@e = true
		} else {
		#extra check for item ID, one final translate check to "use.NAME"
			if(is_numeric(@option2)) {
				assign(@option2, data_name(@option2))
				if(has_permission(@player, 'commandhelper.alias.reloader.use.'.@option2) && @option2 != null) {
					@permmsg = 'Using item ID to name perm'
					@e = true
				}
			}
		}
	case 'istack':
		if(has_permission(@player, 'commandhelper.alias.reloader.stack.illegitimate')) {
			@permmsg = color(7).'[DEV] stack: '.color('f').'Using illegitimate stack perm'
		} else {
			@permmsg = color(7).'[DEV] stack: '.color('f').'stack legit'
		}
	}	

	if(import('ch.player.'._reloader_getplayerID(@player)['id'].'.developer') == true) {
		tmsg(@player, color(7).'[DEV]: '.color('f').@permmsg)
	}
	return(@e)
}


proc _reloader_get_server_defaults(@option) {
	assign(@name, string(import('dispenserreloader.name')))
	#Script defaults, used to reset server defaults if requested
	@sdi = 'ARROW'
	@sdq = 64
	@sdf = 'COAL'
	@sdfee = array(tool: 5, area: 35)
	switch(@option) {
	case 'start':
	case 'startup':
		#load defaults into RAM
		### What is the default item to use? (Note: this value can use ID or name. Default: arrows)
		assign(@defaultitem, get_value(@name.'.default.item.type'))
		if(@defaultitem == '' || @defaultitem == null,
				assign(@defaultitem, @sdi)
		)
		#For other parts of the script, we'll export this value.
		export(@name.'.default.item.type', @defaultitem)

		### What is the default item to use for fuel mode? (Note: this value uses a ID, not a name. Default: coal)
		assign(@fueldefaultitem, get_value(@name.'.default.item.type.fuel'))
		if(@fueldefaultitem == '' || @fueldefaultitem == null,
			assign(@fueldefaultitem, @sdf)
		)
		export(@name.'.default.item.type.fuel', @fueldefaultitem)

		### What is the default item quantity to use? (Note: this value uses a number. Default: full stack (64))
		assign(@defaultitemqty, get_value(@name.'.default.item.qty'))
		if(@defaultitemqty == '' || @defaultitemqty == null,
				assign(@defaultitemqty, @sdq)
		)
		export(@name.'.default.item.qty', @defaultitemqty)
		
		### What is the default fees to charge? (Note: this value uses a number. Default: tool: $5, area $35)
		assign(@defaultfees, get_value(@name.'.default.fees'))
		if(is_array(@defaultfees), null,
				assign(@defaultfees, @sdfee)
		)
		export(@name.'.default.fees', @defaultfees)
		@return = array(type: @defaultitem, item: @defaultitem, fuel: @fueldefaultitem, qty: @defaultitemqty, fee: @defaultfees)
	case 'clearitem':
		export(@name.'.default.item.type', @sdi)
		export(@name.'.default.item.type.fuel', @sdf)
		@return = array(type: @sdi, item: @sdi, fuel: @sdf, qty: import(@name.'.default.item.qty'), fee: import(@name.'.default.fees'))
	case 'clearqty':
		export(@name.'.default.item.qty', @sdq)
		@item = import(@name.'.default.item.type')
		@return = array(type: @item, item: @item, fuel: import(@name.'.default.item.type.fuel'), qty: @sdq, fee: @sdfee)
	default:
		@item = import(@name.'.default.item.type')
		@return = array(type: @item, item: @item, fuel: import(@name.'.default.item.type.fuel'), qty: import(@name.'.default.item.qty'), fee: import(@name.'.default.fees'))
	}
	return(@return)
}

proc _reloader_item_name(@item) {
	switch(@item) {
	case '':
	case null:
		return(array(name: null, id: 0, display: 'Invalid item name or ID given'))
	default:
	#Get rid of a 0 data value
	if(reg_count('[0-9]+:0', @item) == 1) {
			assign(@item, reg_split(':', @item)[0])
	}
	# Legacy Item data support: This checks for one : in the middle of the given item ID. A match means the ID has extra data to it to denote the item.
	# This argument syntax is not supported internally anymore, translated here
	if(reg_count('[0-9]+:[0-9]+', @item) == 1) {
		@ids = reg_split(':', @item)
		@name = data_name(array(name: data_name(@ids[0]), data: integer(trim(@ids[1]))))
		@display = to_lower(@name)
		@id = @item
	} else {
		if(is_numeric(@item)) {
		#legacy ID given
			assign(@name, data_name(@item))
			assign(@display, to_lower(@name))
			assign(@id, @item)
		} else {
		#newer named ID given
			assign(@name, to_upper(@item))
			assign(@display, to_lower(@item))
			assign(@id, data_values(@item))
			if(!array_contains(all_materials(), @name)) {
				assign(@name, 0)
				assign(@display, 'Invalid item name given')
			}
		}
	}
	if(reg_count('[a-zA-Z]+_[a-zA-Z]+', @name) == 1) {
		assign(@display, to_lower(reg_replace('_', ' ', @name)))
	}
	# Check: Is this air?
	if(@name == '0' || string_contains_ic(@name, 'air')) { @name = null }
	
	return(array(name: @name, id: @id, display: @display))
	}
}
 
proc _reloader_msgAdmins(@msg, @consolemsg, @consoleconcat) {
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
}
 
proc _reloader_number_commaize(@number) {
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
}

proc _reloader_capitalize(@string, @lower, @u) {
	if(@lower == '' || @lower == null) { @string = to_lower(@string) }
	assign(@l1, to_upper(@string[0]))
	assign(@length, length(@string) - 1)
	assign(@newstring, @l1.@string[cslice(1, @length)])
	if(@u == '' || @u == null) {
		if(reg_count('[_]', @newstring) > 0) {
			@newstring = reg_replace('_', ' ', @newstring)
		}
	}
	return(@newstring)
}
 
proc _reloader_fill(@x, @y, @z, @world, @item, @playergiven, @qty, @fuel, @verbose) {
#throw('ms.lang.CastException', 'testing throwfill')
	assign(@name, import('dispenserreloader.name'))
	assign(@chmaxstacksize, 64)
	assign(@player, _reloader_getplayerID(@playergiven))
	assign(@dev, import('ch.player.'.@player['id'].'.developer'))
	assign(@acceptfilltypes, array('BARREL', 'BLAST_FURNACE', 'BREWING', 'CHEST', 'DISPENSER', 'DROPPER', 'FURNACE', 'HOPPER', 'SHULKER_BOX', 'SMOKER', 'TRAPPED_CHEST'))
# We need a real array
	assign(@xyz, array())
	assign(@xyz[0], @x)
	assign(@xyz[1], @y)
	assign(@xyz[2], @z)
	assign(@xyz[3], @world)
	if(@dev == true) {tmsg(@player['name'], color(7).'[DEV] _reloader_fill: '.color('f').'Evaluate: '.@xyz)}
# Check: null/air
	if(@item == null || @item == 0) {
		return(array(msg: color('c').'['.color(6).@name.color('c').'] '.color(7).'You cannot use air!', size: 0, fail: true))
	}
# Get the inventory size
	try(
		assign(@size, get_inventory_size(@xyz))
	,@fail,
		return(array(msg: color('c').'['.color(6).@name.color('c').'] '.color(7).'This location isn\'t capable of having a inventory!', size: 0, fail: true))
	)
	assign(@filltype, get_inventory_type(@xyz))
	assign(@maxstacksize, max_stack_size(array(name: @item, 'meta': null)))
	if(@verbose == true && @fuel == false) {
		tmsg(@player['name'], color(3).'['.color(6).@name.color(3).'] '.color(9).'A fillable item was found at '.integer(@xyz[0]).', '.integer(@xyz[1]).', '.integer(@xyz[2]))
	}
# Fuel mode: If enabled ignore chest/dispenser types of blocks
	if(@fuel == true) {
		switch(@filltype) {
		case 'FURNACE':
		case 'BREWING':
		case 'SMOKER':
		case 'BLAST_FURNACE':
			if(@verbose == true) {
				tmsg(@player['name'], color(3).'['.color(6).@name.color(3).'] '.color(9).'A fillable furnace was found at '.integer(@xyz[0]).', '.integer(@xyz[1]).', '.integer(@xyz[2]))
			}
			if(@filltype == 'BREWING' && @item != 'BLAZE_POWDER') {
				return(array(msg: color('c').'['.color(6).@name.color('c').'] '.color(7).'A Brewing Stand does not support any fuel other than Blaze Powder!', size: 0, fail: true))
			}
		default:
			return(array(msg: color('c').'['.color(6).@name.color('c').'] '.color(7).'Fuel mode does not support Chest or Dispenser block types!', size: 0, fail: true))
		}
	}
# Check: limit what you can fill
	if(!array_contains(@acceptfilltypes, @filltype)) {
		return(array(msg: color('c').'['.color(6).@name.color('c').'] '.color(7).'You cannot fill this item type!', size: 0, fail: true))
	}
# Get specified item quantity
	if(@qty == '' || @qty == null) {
		assign(@qty, @maxstacksize)
	}     
# Set array of item
	assign(@itema, array(name: @item, qty: @qty))
 
# Check: illegitimate stack perm
	if(has_permission(@player['name'], 'commandhelper.alias.reloader.stack.illegitimate'),
			assign(@istack, true)
	,
			assign(@istack, false)
	)


# Set the items in the block.
	assign(@fqty, 0)
	assign(@re, '')
	for(assign(@i, 0), @i < @size, @i++) {
		switch(@filltype) {
		case 'FURNACE':
		case 'SMOKER':
		case 'BLAST_FURNACE':
			if(@fuel == true) {
				#this sets the fuel in the bottom of the furnace.
				@i = 1
			} else {
				#this sets the item to cook in the top of furnace.
				@i = 0
			}
		case 'BREWING':
			if(@fuel == true) {
				#this sets the fuel in the stand
				@i = 4
			} else {
				#this sets the item to distill.
				@i = 3
			}
		}
		#item already filled check
		assign(@af, get_inventory_item(@xyz, @i))
		if(@af == '' || @af == null, assign(@af, array(name: null, qty: 0, meta: null)))
		assign(@mqty, 0)

		if(@item == @af['name']) {
			assign(@re, 're-')
			#quantity greater than current (eg qty 64, filled 23)
			if(@qty > @af['qty']) {
				#set_inventory_item needs what's already there plus the new items, as anything previously in there gets overwritten.
				assign(@nqty, @af['qty'] + @qty)
				#set_inventory_item has a max limit of 64
				if(@nqty > @chmaxstacksize) {
					assign(@mqty, @nqty - @chmaxstacksize)
					assign(@nqty, @chmaxstacksize)
				}
				#Check: illegitimate stack
				if(@nqty > @maxstacksize) {
					if(@istack == false) {
						#no perm, so we will bump down the qty to the max stack size minus what's filled.
						assign(@qty, @maxstacksize - @af['qty'])
						if(0 > @qty, assign(@qty, 0))
						assign(@mqty, @qty)
						assign(@nqty, @qty)
					}
				}
			assign(@itema['qty'], @nqty)
			#stats: quantity actually filled
			assign(@fqty1, @qty - @mqty)
			}
			#quantity is less than or equals filled
			if(@qty < @af['qty'] || @qty == @af['qty']) {
				switch(@filltype) {
				case 'FURNACE':
				case 'BREWING':
				case 'SMOKER':
				case 'BLAST_FURNACE':
					break(2)
				default:
					continue()
				}
			}
		} else {
		#item does not match whats being filled.
				#Check: illegitimate stack
				if(@qty > @maxstacksize) {
					if(@istack == false) {
						#no perm, so we will bump down the qty to the max stack size.
						assign(@qty, @maxstacksize)
						if(0 > @qty, assign(@qty, 0))
						assign(@fqty1, @qty)
					}
				}
				assign(@itema['qty'], @qty)
				assign(@fqty1, @qty)
		}
#		if(@dev == true, msg('slot'.@i.': '.get_inventory_item(@xyz, @i)))
# Set the items
		set_inventory_item(@xyz, @i, @itema)
# Stats: record amount of items used.
		assign(@fqty, @fqty + @fqty1)
# If this is a furnace, there isn't anything left to fill, so stop the loop!
		switch(@filltype) {
		case 'FURNACE':
		case 'BREWING':
		case 'SMOKER':
		case 'BLAST_FURNACE':
			break(2)
		}
	}
#return stats
	assign(@donemsg, color('a').'['.color(6).@name.color('a').'] '.color(3).'Success! This '._reloader_capitalize(@filltype).' was '.@re.'filled, using a total of '.@fqty.' '.to_lower(@item).'.')      
	if(@fqty == 0, assign(@donemsg, '0'))
	return(array(msg: @donemsg, size: @size, type: @filltype, filledqty: @fqty, fail: false))
}
 
       
proc _reloader_record_stats(@playergiven, @action, @filledblocks, @totalitems, @item, @qty) {
	assign(@name, import('dispenserreloader.name'))
	assign(@player, _reloader_getplayerID(@playergiven))
#Start the Stats recording.
        #total blocks filled
        assign(@fb, get_value(@name.'.stats.alltime.filled.blocks'))
        if(@fb == '' || @fb == null, assign(@fb, 0))
        assign(@nfb, @fb + @filledblocks)
        store_value(@name.'.stats.alltime.filled.blocks', @nfb)
        #total blocks filled - player
        assign(@pfb, get_value(@name.'.player.'.@player['id'].'.stats.alltime.filled.blocks'))
        if(@pfb == '' || @pfb == null, assign(@pfb, 0))
        assign(@npfb, @pfb + @filledblocks)
        store_value(@name.'.player.'.@player['id'].'.stats.alltime.filled.blocks', @npfb)
        #total action runs
        assign(@atr, get_value(@name.'.stats.alltime.runs.'.@action))
        if(@atr == '' || @atr == null, assign(@atr, 0))
        assign(@antr, @atr + 1)
        store_value(@name.'.stats.alltime.runs.'.@action, @antr)
        #total action runs - player
        assign(@ptr, get_value(@name.'.player.'.@player['id'].'.stats.alltime.runs.'.@action))
        if(@ptr == '' || @ptr == null, assign(@ptr, 0))
        assign(@pntr, @ptr + 1)
        store_value(@name.'.player.'.@player['id'].'.stats.alltime.runs.'.@action, @pntr)
        #total items filled
        assign(@items, get_value(@name.'.stats.alltime.items'))
        if(@items == '' || @items == null, assign(@items, array()))
        if(array_index_exists(@items, @item) == false,
                assign(@items[@item], 0)
        )
        assign(@items[@item], @totalitems + @items[@item])
        store_value(@name.'.stats.alltime.items', @items)
        #total items filled - player
        assign(@playeritems, get_value(@name.'.player.'.@player['id'].'.stats.alltime.items'))
        if(@playeritems == '' || @playeritems == null, assign(@playeritems, array()))
        if(array_index_exists(@playeritems, @item) == false,
                assign(@playeritems[@item], 0)
        )
        assign(@playeritems[@item], @totalitems + @playeritems[@item])
        store_value(@name.'.player.'.@player['id'].'.stats.alltime.items', @playeritems)
        #Last run
        assign(@olr1, get_value(@name.'.stats.last.run.1'))
        assign(@olr2, get_value(@name.'.stats.last.run.2'))
        assign(@olr3, get_value(@name.'.stats.last.run.3'))
        store_value(@name.'.stats.last.run.1', array(action: @action, player: @player['display'], qty: @qty, filledqty: @totalitems, blocks: @filledblocks, item: @item))
        store_value(@name.'.stats.last.run.2', @olr1)
        store_value(@name.'.stats.last.run.3', @olr2)
		store_value(@name.'.stats.last.run.4', @olr3)
        #last run - player
        store_value(@name.'.player.'.@player['id'].'.stats.last.run', array(action: @action, qty: @qty, filledqty: @totalitems, blocks: @filledblocks, item: @item))
 
}

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
