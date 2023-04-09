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
		@pid['display'] = reg_replace('^[\\.]','', @pid['name'])
	)
	return(@pid)
}

proc _reloader_check_perm(@player, @option, @option2) {
	@permmsg = ''
	@e = false
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
				@option2 = data_name(@option2)
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
	@name = string(import('dispenserreloader.name'))
	#Script defaults, used to reset server defaults if requested
	@sdi = 'ARROW'
	@sdq = 64
	@sdf = 'COAL'
	@sdfee = array(tool: 5, area: 35)
	@return = array()
	switch(@option) {
	case 'start':
	case 'startup':
		#load defaults into RAM
		### What is the default item to use? (Note: this value can use ID or name. Default: arrows)
		@defaultitem = get_value(@name.'.default.item.type')
		if(@defaultitem == '' || @defaultitem == null) { @defaultitem = @sdi }
		#For other parts of the script, we'll export this value.
		export(@name.'.default.item.type', @defaultitem)

		### What is the default item to use for fuel mode? (Note: this value uses a ID, not a name. Default: coal)
		@fueldefaultitem = get_value(@name.'.default.item.type.fuel')
		if(@fueldefaultitem == '' || @fueldefaultitem == null) { @fueldefaultitem = @sdf }
		export(@name.'.default.item.type.fuel', @fueldefaultitem)

		### What is the default item quantity to use? (Note: this value uses a number. Default: full stack (64))
		@defaultitemqty = get_value(@name.'.default.item.qty')
		if(@defaultitemqty == '' || @defaultitemqty == null) { @defaultitemqty = @sdq }
		export(@name.'.default.item.qty', @defaultitemqty)
		
		### What is the default fees to charge? (Note: this value uses a number. Default: tool: $5, area $35)
		@defaultfees = get_value(@name.'.default.fees')
		if(!is_array(@defaultfees)) { @defaultfees = @sdfee }
		export(@name.'.default.fees', @defaultfees)
		@return = array('type': @defaultitem, 'item': @defaultitem, 'fuel': @fueldefaultitem, 'qty': @defaultitemqty, 'fee': @defaultfees)
	case 'clearitem':
		export(@name.'.default.item.type', @sdi)
		export(@name.'.default.item.type.fuel', @sdf)
		@return = array('type': @sdi, 'item': @sdi, 'fuel': @sdf, 'qty': import(@name.'.default.item.qty'), 'fee': import(@name.'.default.fees'))
	case 'clearqty':
		export(@name.'.default.item.qty', @sdq)
		@item = import(@name.'.default.item.type')
		@return = array('type': @item, 'item': @item, 'fuel': import(@name.'.default.item.type.fuel'), 'qty': @sdq, 'fee': @sdfee)
	default:
		@item = import(@name.'.default.item.type')
		@return = array('type': @item, 'item': @item, 'fuel': import(@name.'.default.item.type.fuel'), 'qty': import(@name.'.default.item.qty'), 'fee': import(@name.'.default.fees'))
	}
	return(@return)
}

proc _reloader_item_name(@item) {
	@id = ''
	@display = ''
	switch(@item) {
	case '':
	case null:
		return(array('name': null, 'id': 0, 'display': 'Invalid item name or ID given'))
	default:
	#Get rid of a 0 data value
	if(reg_count('[0-9]+:0', @item) == 1) {
			@item = reg_split(':', @item)[0]
	}
	# Legacy Item data support: This checks for one : in the middle of the given item ID. A match means the ID has extra data to it to denote the item.
	# This argument syntax is not supported internally anymore, translated here
	@name = ''
	if(reg_count('[0-9]+:[0-9]+', @item) == 1) {
		@ids = reg_split(':', @item)
		@name = data_name(array('name': data_name(@ids[0]), 'data': integer(trim(@ids[1]))))
		@display = to_lower(@name)
		@id = @item
	} else {
		if(is_numeric(@item)) {
		#legacy ID given
			@name = data_name(@item)
			@display = to_lower(@name)
			@id = @item
		} else {
		#newer named ID given
			@name = to_upper(@item)
			@display = to_lower(@item)
			if(is_proc('_get_data_values')) {
				@id = _get_data_values(@item)
			} else { 
				@id = null
				console('Cannot get data_values info, proc is missing!')
			}
			if(!array_contains(all_materials(), @name)) {
				@name = 0
				@display = 'Invalid item name given'
			}
		}
	}
	if(reg_count('[a-zA-Z]+_[a-zA-Z]+', @name) == 1) {
		@display = to_lower(reg_replace('_', ' ', @name))
	}
	# Check: Is this air?
	if(@name == '0' || string_contains_ic(@name, 'air')) { @name = null }
	
	return(array('name': @name, 'id': @id, 'display': @display))
	}
}
 
proc _reloader_msgAdmins(@msg, @consolemsg, @consoleconcat) {
	if(@consolemsg == '' || @consolemsg == null, @consolemsg = @msg)
	if(@consoleconcat == true, @consolemsg = @msg.@consolemsg)
	console(@consolemsg, false)
	foreach(all_players(), @p,
		if(has_permission(@p, 'commandhelper.alias.admin.message'),
				tmsg(@p, @msg)
		)
	)
}
 
proc _reloader_number_commaize(@number) {
	@n = ''
	@n2 = ''
	#catch numbers with decimal points, and only commaize the whole numbers.
	if(reg_match('[0-9]\\.[0-9]', @number)) {
		@n1 = reg_split('\\.', @number)
		@n = @n1[0]
		@n2 = @n1[1]
	} else {
		@n = @number
	}
	#add the commas
	@n = reg_replace('(\\d)(?=(\\d{3})+$)', '$1,', @n)
	if(reg_match('[0-9]\\.[0-9]', @number)) {
		return(@n.'.'.@n2)
	} else {
		return(@n)
	}
}

proc _reloader_capitalize(@string, @lower, @u) {
	if(@lower == '' || @lower == null) { @string = to_lower(@string) }
	@l1 = to_upper(@string[0])
	@length = length(@string) - 1
	@newstring = @l1.@string[cslice(1, @length)]
	if(@u == '' || @u == null) {
		if(reg_count('[_]', @newstring) > 0) {
			@newstring = reg_replace('_', ' ', @newstring)
		}
	}
	return(@newstring)
}

proc _reloader_get_fuel_items(@option) {
#no stairs, catches too many stone stairs
#more are possible, intentional left out some types that have low usage times.
	@allfuelitems = array('AZALEA', 'BAMBOO', 'BARREL', 'BLAZE_POWDER', 'BLAZE_ROD', 'COAL_BLOCK', 'BOOKSHELF', 'BOW', 'BOWL', 'CARTOGRAPHY_TABLE', 'CHARCOAL', 'CHEST', 
	'COAL', 'COMPOSTER', 'CRAFTING_TABLE', 'CROSSBOW', 'DAYLIGHT_DETECTOR', 'DRIED_KELP_BLOCK', 'FISHING_ROD', 'FLETCHING_TABLE', 'JUKEBOX', 'LADDER', 'LAVA_BUCKET', 
	'LECTERN', 'LOOM', 'MANGROVE_ROOTS', 'NOTE_BLOCK', 'SMITHING_TABLE', 'STICK', 'TRAPPED_CHEST', 'WOODEN_AXE', 'WOODEN_HOE', 'WOODEN_PICKAXE', 'WOODEN_SHOVEL', 'WOODEN_SWORD')

	foreach(@k: @v in all_materials()) {
	#3 and 4 letter words separated so as to not catch generic blocks that aren't usable. 'block' 'leaves' 'cake' 'fan' etc
	# Overworld Log or Stripped Log 	15 - 300 ticks
		if(reg_count('^.+[-_][L][O][G]', @v) > 0) {
			array_push(@allfuelitems, @v)
			continue()
		}
	# Any Wool 	5 - 100 ticks
	# Overworld Wood or Stripped Wood 	15 - 300 ticks 	
		if(reg_count('^.+[-_]WOO[DL]', @v) > 0) {
			array_push(@allfuelitems, @v)
			continue()
		}
	# Any Boat 	60 - 1200 ticks 
	# Any Boat with Chest 
	# Any Carpet 	3.35 - 67 ticks 
	# Any Sapling  5 - 100 ticks 
	# Overworld Fence Or Fence Gate 	15 - 300 ticks 	
	# Overworld Planks 	15 - 300 ticks
	# Overworld Pressure Plate 	15 - 300 ticks
	# Overworld Sign 	10 - 200 ticks 	
	# Overworld Wooden Trapdoor 	15 - 300 ticks
		if(reg_count('^.+[-_][BCSFPT][OAELIR][ARPNG][TPLCND](?:[EIKD]|$)(?:[TNOS_]|$)(?:[GSO]|$)[RA]?', @v) > 0) {
		# still catches 'fern' 'sand' 'iron', 'blackstone' 'stone'
			if(reg_count('^.+STONE_', @v) > 0 || reg_count('^.+_BRICK', @v) > 0 || reg_count('^.*IRON_', @v) > 0 || reg_count('^.+_FER', @v) > 0 || reg_count('^.+_SAND', @v) > 0) { continue() } 
			array_push(@allfuelitems, @v)
			continue()
		}
	}
	return(@allfuelitems)
}
 
proc _reloader_fill(@x, @y, @z, @world, @item, @playergiven, @qty, @fuel, @verbose) {
	@name = import('dispenserreloader.name')
	@chmaxstacksize = 64
	@player = _reloader_getplayerID(@playergiven)
	@dev = import('ch.player.'.@player['id'].'.developer')
	@acceptfilltypes = array('BARREL', 'BLAST_FURNACE', 'BREWING', 'CHEST', 'DISPENSER', 'DROPPER', 'FURNACE', 'HOPPER', 'SHULKER_BOX', 'SMOKER', 'TRAPPED_CHEST')
# We need a real array
	@xyz = array()
	@xyz[0] = @x
	@xyz[1] = @y
	@xyz[2] = @z
	@xyz[3] = @world
	if(@dev == true) {tmsg(@player['name'], color(7).'[DEV] _reloader_fill: '.color('f').'Evaluate: '.@xyz)}
# Check: null/air
	if(@item == null || @item == 0) {
		return(array('msg': color('c').'['.color(6).@name.color('c').'] '.color(7).'You cannot use air!', 'size': 0, 'fail': true))
	}
# Get the inventory size
	@size = 0
	try(
		@size = get_inventory_size(@xyz)
	,@fail,
		return(array('msg': color('c').'['.color(6).@name.color('c').'] '.color(7).'This location isn\'t capable of having a inventory!', 'size': 0, 'fail': true))
	)
	@filltype = get_inventory_type(@xyz)
	@maxstacksize = max_stack_size(array('name': @item, 'meta': null))
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
				return(array('msg': color('c').'['.color(6).@name.color('c').'] '.color(7).'A Brewing Stand does not support any fuel other than Blaze Powder!', 'size': 0, 'fail': true))
			}
		default:
			return(array('msg': color('c').'['.color(6).@name.color('c').'] '.color(7).'Fuel mode does not support Chest or Dispenser block types!', 'size': 0, 'fail': true))
		}
	}
# Check: limit what you can fill
	if(!array_contains(@acceptfilltypes, @filltype)) {
		return(array('msg': color('c').'['.color(6).@name.color('c').'] '.color(7).'You cannot fill this item type!', 'size': 0, 'fail': true))
	}
# Get specified item quantity
	if(@qty == '' || @qty == null) { @qty = @maxstacksize }     
# Set array of item
	@itema = array('name': @item, 'qty': @qty)
 
# Check: illegitimate stack perm
	@istack = has_permission(@player['name'], 'commandhelper.alias.reloader.stack.illegitimate')

# Set the items in the block.
	@fqty = 0
	@re = ''
	for(@i = 0, @i < @size, @i++) {
		@fqty1 = 0
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
		@af = get_inventory_item(@xyz, @i)
		if(@af == '' || @af == null, @af = array('name': null, 'qty': 0, 'meta': null))
		@mqty = 0

		if(@item == @af['name']) {
			@re = 're-'
			#quantity greater than current (eg qty 64, filled 23)
			if(@qty > @af['qty']) {
				#set_inventory_item needs what's already there plus the new items, as anything previously in there gets overwritten.
				@nqty = @af['qty'] + @qty
				#set_inventory_item has a max limit of 64
				if(@nqty > @chmaxstacksize) {
					@mqty = @nqty - @chmaxstacksize
					@nqty = @chmaxstacksize
				}
				#Check: illegitimate stack
				if(@nqty > @maxstacksize) {
					if(@istack == false) {
						#no perm, so we will bump down the qty to the max stack size minus what's filled.
						@qty = @maxstacksize - @af['qty']
						if(0 > @qty) { @qty = 0 }
						@mqty = @qty
						@nqty = @qty
					}
				}
			@itema['qty'] = @nqty
			#stats: quantity actually filled
			@fqty1 = @qty - @mqty
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
					@qty = @maxstacksize
					if(0 > @qty) { @qty = 0 }
					@fqty1 = @qty
				}
			}
			@itema['qty'] = @qty
			@fqty1 = @qty
		}
#		if(@dev == true, msg('slot'.@i.': '.get_inventory_item(@xyz, @i)))
# Set the items
		set_inventory_item(@xyz, @i, @itema)
# Stats: record amount of items used.
		@fqty = @fqty + @fqty1
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
	@donemsg = color('a').'['.color(6).@name.color('a').'] '.color(3).'Success! This '._reloader_capitalize(@filltype).' was '.@re.'filled, using a total of '.@fqty.' '.to_lower(@item).'.'   
	if(@fqty == 0, @donemsg = '0')
	return(array('msg': @donemsg, 'size': @size, 'type': @filltype, 'filledqty': @fqty, 'fail': false))
}
 
       
proc _reloader_record_stats(@playergiven, @action, @filledblocks, @totalitems, @item, @qty) {
	@name = import('dispenserreloader.name')
	@player = _reloader_getplayerID(@playergiven)

	@globalstats = get_value(@name.'.stats')
	if(!is_array(@globalstats)) { @globalstats = array('filled_blocks': 0, 'items': array(), 'runs_area': 0, 'runs_tool': 0) }
	@playerstats = get_value(@name.'.player.'.@player['id'].'.stats')
	if(!is_array(@playerstats)) { @playerstats = array('filled_blocks': 0, 'items': array(), 'runs_area': 0, 'runs_tool': 0, 'last_run': array()) }
	
# Total blocks filled
	@globalstats['filled_blocks'] = @globalstats['filled_blocks'] + @filledblocks
	@playerstats['filled_blocks'] = @playerstats['filled_blocks'] + @filledblocks
	
# Total action runs
	@globalstats['runs_'.@action] = @globalstats['runs_'.@action] + 1
	#total action runs - player
	@playerstats['runs_'.@action] = @playerstats['runs_'.@action] + 1
	
# Total items filled
	@items = @globalstats['items']
	if(!is_array(@globalstats['items'])) { @globalstats['items'] = array() }
	if(!array_index_exists(@globalstats['items'], @item)) {
		array_set(@globalstats['items'], @item, 0)
	}
	@globalstats['items'][@item] = @globalstats['items'][@item] + @totalitems
	# total items filled - player
	if(!is_array(@playerstats['items'])) { @playerstats['items'] = array() }
	if(!array_index_exists(@playerstats['items'], @item)) {
		array_set(@playerstats['items'], @item, 0)
	}
	@playerstats['items'][@item] = @playerstats['items'][@item] + @totalitems
	
# Save Last run
	@stats = array('action': @action, 'player': @player['display'], 'qty': @qty, 'filledqty': @totalitems, 'blocks': @filledblocks, 'item': @item)
	@lastruns = get_value(@name.'.stats.last.runs')
	if(!is_array(@lastruns)) { @lastruns = array(@stats) }
	array_insert(@lastruns, @stats, 0)
	if(array_index_exists(@lastruns, 10)) { array_remove(@lastruns, 10) }
	store_value(@name.'.stats.last.runs', @lastruns)
	
	store_value(@name.'.stats', @globalstats)
	@playerstats['last_run'] = @stats
	store_value(@name.'.player.'.@player['id'].'.stats', @playerstats)
}