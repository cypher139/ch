# Certain code portions credit to PseudoKnight
# https://github.com/PseudoKnight/FinalScoreMC

proc _cmd_giveitem(@player, @args, @giver) {
	if(!@args) {
		@args = array('fill')
	}
	if(!@player) { @player = player() }
	if(!@giver) { @giver = player() }
	@transparent = array('water', 'lava', 'air');
	@slot = null
	@itemID = null
	@itemName = array_implode(@args, ' ');
	@amount = 1;
	@meta = associative_array();
#Quantity Check - always last index.
	if(array_size(@args) > 1) {
		@index = -1;
		if(is_integral(@args[-1]) && @args[-1] > 0) {
			@amount = integer(@args[-1]);
			@index = -2;
		} else if(reg_count('^[Mm][Aa]?[Xx]?$', @args[-1]) > 0) {
			#Get Max Stack Quantity
			@amount = 'max'
			@index = -2;
		}
		if(@index == -2) { @itemName = array_implode(@args[cslice(0, @index)], '_'); }
	}
# Meta check
	@bracePos = string_position(@itemName, '{')
	@barPos = string_position(@itemName, '|')
	if(@barPos > -1 && (@bracePos == -1 || @bracePos > @barPos)) {
		try {
			@meta = yml_decode(@itemName[cslice(@barPos + 1, length(@itemName) - 1)]);
		} catch(FormatException @ex) {
			return(color(12).'Invalid YAML for item meta: '.@itemName[cslice(@barPos + 1, length(@itemName) - 1)]);
		}
		@itemName = @itemName[cslice(0, @barPos - 1)];
	} else if(@bracePos > -1) {
		try {
			@meta = json_decode(@itemName[cslice(@bracePos, length(@itemName) - 1)]);
		} catch(FormatException @ex) {
			return(color(12).'Invalid JSON for item meta: '.@itemName[cslice(@bracePos, length(@itemName) - 1)]);
		}
		@itemName = @itemName[cslice(0, @bracePos - 1)];
	}
#Special Actions
	switch(@args[0]) {
#gib me that block I'm looking at
	case 'that':
	case 'look':
	case 'looks':
	case 'want':
		if(@player == 'CONSOLE' || string_contains_ic(get_block(pcursor(@player, @transparent)), 'air')) {
			return(color(12).'No block was in sight!');
		} else {
			@itemName = get_block(pcursor(@player, @transparent));
		}
#gib me more of item I'm holding
	case 'max':
	case 'refill':
	case 'fill':
	case 'more':
		if(@giver == 'CONSOLE') {
			@slot = null;
		} else {	
			@slot = pinv(@player, null);
		}
		if(@slot == null) {
		#cant give you a hand, sorry.
			return(color(12).@player.' did not have an item equipped in that slot!')
		} else {
			@itemName = @slot['name'];
		}		
# overrides for some Legacy IDs that are not being picked up by CH / minecraft data values
# or seemingly obvious names that don't actually match to anything as too generic
	case '50':
	case 'wall_torch':
		@itemName = 'TORCH';
	case 'sign':
	case 'wooden_sign':
	case 'wood_sign':
		@itemName = 'OAK_SIGN';
	case 'door':
		@itemName = 'OAK_DOOR';
	}
### Item Type
# Get rid of a 0 data value
	if(reg_count('[0-9]+:0', @itemName) == 1) {
		@itemName = reg_split(':', @itemName)[0];
		console(color(7).'[giveitem]: :0 removed');
	}
# Legacy ID Item:Subitem argument syntax is no longer supported internally, translated here.
	if(reg_count('^[0-9]+:[0-9]+$', @itemName) == 1) {
		@legacyNames = reg_split(':', @itemName);
		@itemID = @itemName;
		@itemName = data_name(array('name': data_name(@legacyNames[0]), 'data': @legacyNames[1]));
	} else {
# Legacy or Normal IDs:
		if(is_numeric(@itemName)) {
		// Using Legacy IDs
			@itemID = @itemName;
			@itemName = data_name(@itemName);
			if(@itemName == null) {
				return(color(12).'Item ID "'.@itemID.'" Not Recognized.');
			}
		} else {
		// Using normal name
			@itemName = to_upper(@itemName);
			if(!array_contains_ic(all_materials(), @itemName)) {
				return(color(12).'Item "'.@itemName.'" not recognized.');
			}
			if(is_proc('_get_data_values')) {
				@itemID = _get_data_values(@itemName);
			} else { 
				@itemID = null;
				console('Cannot get data_values info, proc is missing!');
			}
			if(@itemID == null) {
				@itemID = 'No ID';
			}
		}
	}
### Quantity checks that require set item
# Get Max Stack Quantity
	if(@amount == 'max') { @amount = max_stack_size(array('name': to_upper(@itemName), 'meta': null)); }
# Fill mode: Quantity is the missing amount
	switch(@args[0]) {
	case 'max':
	case 'refill':
	case 'more':
	case 'fill':
		@stack = max_stack_size(array('name': to_upper(@itemName), 'meta': null));
		# Give only 1 more of tool
		if(@stack == 1) { @stack++; }
		@amount = @stack - @slot['qty'];
		if(@amount < 1) {
			return(color(12).'This slot already has a full stack!');
		}	
	}
	if(@amount < 1) { @amount = 1; }
	# console(color(7).'[giveitem dev]: '.@itemName.' ('.@itemID.') [qty:'.@amount.']', false);
# Let console get Item IDs
	if(@player == 'CONSOLE') {	return(color(7).'Item IDs returned: '.color(3).@itemName.color(8).' ('.color(10).@itemID.color(8).') '.color(8).'[max:'.max_stack_size(array('name': to_upper(@itemName), 'meta': null)).']') }
# Give Items
	if(!has_permission(@player, 'commandhelper.alias.creative') && @player != @giver) {
		if(!has_permission(@giver, 'commandhelper.alias.admin')) { return(color(12).@player.' does not have permission to use the /give command.'); }
	}
	try {
		pgive_item(@player, array('meta': @meta, 'name': to_upper(@itemName), 'qty': @amount));
	} catch(Exception @ex) {
		console('[giveitem]: '.color(12).@ex['message'], false);
		return(color(12).'Could not complete giving the item.');
	}
#Return messages
	@msgid = ''
	if(has_permission(@giver, 'commandhelper.alias.creative.see.id')) {	@msgid = color(8).' ('.@itemID.')'; }
	@display = to_lower(replace(@itemName, '_', ' '));
	@dp = '';
	if(@player != @giver) { 
		@dp = color(5).@player.' ';
		tmsg(@player, color(5).@giver.color(6).'Gave you '.color(3).@amount.color(6).' of '.color(10).@display);
	}
	return(color(6).'Giving '.@dp.color(3).@amount.color(6).' of '.color(10).@display.@msgid)
}