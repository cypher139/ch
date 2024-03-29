/*
######################################################
#
#   ReLoad: Fill blocks that have inventories in one click!
#   includes for Area mode, to be included if the extension SKCompat is installed.
#   version 1.2-tmc
#
######################################################
*/
proc _reloader_iterate_cuboid(@proc_name, @world, @item, @playergiven, @qty, @fuel, @verbose) {
	@name = import('dispenserreloader.name')
	@player = _reloader_getplayerID(@playergiven)
	@playerconfig = import(@name.'.player.'.@player['id'].'.config', 'new')
	if(!is_array(@playerconfig)) { @playerconfig = array('area': 'All', 'fuel_type': '', 'item_type': '', 'item_qty': '', 'verbose': false) }
	# CH requires an extension to access WorldEdit selection data.
	include('../ext.library/ext-SKCompat.ms')
	@pos1 = _reloader_get_pos1(@player['name'])
	@pos2 = _reloader_get_pos2(@player['name'])
	if(@pos1 == null || @pos2 == null) {
		return(array('fail': true, 'failmsg': color('c').'['.color(6).@name.color('c').'] '.color(7).'What area? You need to make a selection with WorldEdit first!'))
	}
	if(!is_array(@pos1) || !is_array(@pos2)) {
		return(array('fail': true, 'failmsg': 'SKCompat extension not installed! '.color('r').@name.' is unable to determine WorldEdit selection data for Area Mode.'))
	}
	#Start counting how many blocks were filled
	@n = 0
	@nq = 0
	@eb = 0
	# "ALL" filltypes list here
	@acceptfilltypes = array('BARREL', 'BLAST_FURNACE', 'BREWING', 'CHEST', 'DISPENSER', 'FURNACE', 'SHULKER_BOX', 'SMOKER', 'TRAPPED_CHEST')
	@blocktypes = array()
	# Get the player's area mode
	@areamode = @playerconfig['area']
	if(@areamode == '' || @areamode == null) { @areamode = 'ALL' }
	@areamode = to_upper(@areamode)
	# Force furnace mode if "/reloader area fuel" is used.
	if(@fuel == true) {@areamode = 'GROUP_FURNACE'}
	
#Loop through all blocks in area
	for(@x = min(@pos1[0], @pos2[0]), @x <= max(@pos1[0], @pos2[0]), @x++) {
		for(@y = min(@pos1[1], @pos2[1]), @y <= max(@pos1[1], @pos2[1]), @y++) {
			for(@z = min(@pos1[2], @pos2[2]), @z <= max(@pos1[2], @pos2[2]), @z++) {
				@xyz = array(@x, @y, @z, @world)
				#If this block isn't capable of having a inventory, continue to next block.
				try {
					@size = get_inventory_size(@xyz)
				} catch(Exception @ex) {
					continue()
				}
				#Area Modes: Setup which block types are accepted to fill.
				@filltype = get_inventory_type(@xyz)
				@getblock = get_block(@xyz)
				switch(@areamode) {
				case 'ALL':
					@acceptfilltypes = array('BARREL', 'BLAST_FURNACE', 'BREWING', 'CHEST', 'DISPENSER', 'FURNACE', 'SHULKER_BOX', 'SMOKER', 'TRAPPED_CHEST')
					#accounting for dyed boxes
					if(reg_count('(_SHULKER_BOX)', @getblock) == 1) {
						@filltype = 'SHULKER_BOX'
					}
				case 'GROUP_CHEST':
				case 'CHESTS':
					@acceptfilltypes = array('BARREL', 'CHEST', 'SHULKER_BOX', 'TRAPPED_CHEST')
					#accounting for dyed boxes
					if(reg_count('(_SHULKER_BOX)', @filltype) == 1) {
						@filltype = 'SHULKER_BOX'
					}
				case 'GROUP_FURNACE':
				case 'FURNACES':
					@acceptfilltypes = array('BLAST_FURNACE', 'BREWING', 'FURNACE', 'SMOKER')
				default:
					# one block type only: 
					# As of 1.19 the filltype for trapped chest is still 'CHEST', hence using getblock check
					if(reg_count('(_CHEST)', @areamode) == 1) { 
						if(@areamode != @getblock) { continue() }
					} else {
						# If this is a Dyed shulker box: only matches if exact match.
						# As of 1.19 the filltype for any dyed shulker box is still 'SHULKER_BOX', hence using getblock check
						if(reg_count('(_SHULKER_BOX)', @areamode) == 1) {				
							if(@areamode != @getblock) { continue() }
						} else {
						# - all other block types
						if(@areamode != @filltype) { continue() }
						}
					}
				}

				#Groups: check if block is part of group types
				if(!array_contains(@acceptfilltypes, @filltype)) {continue()}
				
				#Fuel: Item check:
				#Brewing stand only supports Blaze Powder, continue to next block if this is not the fuel in use.
				if(@fuel == true && @filltype == 'BREWING' && @item != 'BLAZE_POWDER') {continue()}
				# Vice Versa, Furnaces don't support Blaze Powder
				if(@filltype != 'BREWING' && @item == 'BLAZE_POWDER') {continue()}

				#Run the fill operation.
				inc(@eb)
				@return = call_proc(@proc_name, @x, @y, @z, @world, @item, @player['name'], @qty, @fuel, @verbose)
				#stats: count blocks filled and items used.
				@ft = to_lower(get_block(@xyz))
				#Report how many of each block type was filled, but only if it was filled!
				if(@return['filledqty'] != 0) {
					if(array_index_exists(@blocktypes, @ft)) {
						@blocktypes[@ft] = @blocktypes[@ft] + 1
					} else {
						#if array key not set, @array[key] does not work
						array_set(@blocktypes, @ft, 1)
					}
					inc(@n)
					inc(@nq, @return['filledqty'])
				}
			}
		}
	}
#record stats, only if you actually filled a block.
	if(@nq != 0) { _reloader_record_stats(@player['name'], 'area', @n, @nq, @item, @qty) }

#return
	return(array('blocks': @n, 'items': @nq, 'type': @blocktypes, 'fail': false, 'failmsg': false, 'found': @eb))
}