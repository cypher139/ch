proc _cmd_teleporter_info(@player, @args, @giver) {
	if(!@args) {
		@args = array()
	}
	if(!is_array(@args)) { @args = parse_args(@args) }
	if(!@player) { @player = player() }
	@dev = false
	@uuid = 1
	@world = ''
	@coordsList = array();
	if(is_associative(@args)) { @coordsList[] = array('x': @args['x'], 'y': @args['y'], 'z': @args['z'], 'world': @args['world']) }
	@results = array();
	@prefix = color('#ffcc00').'['.color(7).'Teleporter'.color('#ffcc00').'] ';
	@allteleporters = get_value('server.Teleporters.registered');
	if(!is_array(@allteleporters)) { @allteleporters = array(); }
	if(@player == '~console') {
		@dev = true
		@world = ini_decode(read(file_resolve(sys_properties()['user.dir'].'/server.properties')))['level-name']
	} else {
		@uuid = puuid(@player,'dashless')
		@dev = import('ch.player.'.@uuid.'.dev.scripts.tp')
		@world = pworld()
	}
	#-- Get World definition (only 1 supported)
	foreach(@i: @v in @args) {
		if(array_contains_ic(get_worlds(), @v)) { @world = @v }
	}
	#-- Get all coordinates
	@build1 = array();
	if(!is_associative(@args)) {
		foreach(@arg in reg_match_all('(?<![a-zA-Z0-9])(?<c>[-]*[0-9]+)[,]*(?<w>[0-9]*[a-zA-Z]+[0-9]*)*(?=[, ]|$)(?![a-zA-Z])', array_implode(@args, ' '))) {
			@build1[] = @arg['c']
			if(array_size(@build1) == 3) {
				@build1['x'] = integer(@build1[0])
				@build1['y'] = integer(@build1[1])
				@build1['z'] = integer(@build1[2])
				if(@arg['w'] != '') { 
					if(array_contains_ic(get_worlds(), @arg['w'])) { @world = @arg['w'] }
				}
				@build1['world'] = @world
				@coordsList[] = @build1;
				@build1 = array();
			}
		}
	}
	if(@dev){msg(@coordsList.@world);}
	# if(@dev){msg(get_worlds())}
	#-- Look at teleporter check
	@useBlock = false
	@supportedBlocks = array('REDSTONE_ORE', 'FARMLAND', 'PRESSURE_PLATE')
	foreach(@i: @block in @supportedBlocks) {
		if(@player == '~console') { break() }
		if(string_ends_with(get_block(pcursor()), @block) == true) { @useBlock = true }
	}
	if(@useBlock) { @coordsList[] = pcursor(); }
	#-- Named teleporters
	if(array_size(@args) > 0 && !is_associative(@args)) {
		@dp = 0
		@dp1 = 0
		@updatename = ''
		@samemsg = 'Teleporters were discovered in the same '
		foreach(@i: @v in @args) {
			@dp = 0
			if(reg_count('[.,]', @v) > 0) { continue() }
			if(is_numeric(@v)) { continue() }
			if(@dev) {msg(@i.@v)}
			foreach(@tpworld: @worldtplist in @allteleporters) {
				@dp1 = 0
				if(!array_contains(get_worlds(), @v)) { @world = @v }
				foreach(@ic: @tpData in @worldtplist) {
					if(array_contains_ic(@tpData, @v)) {
						@split = split('.', @ic)
						@build2 = array('world': @tpworld)
						@build2['x'] = @split[0]
						@build2['y'] = @split[1]
						@build2['z'] = @split[2]
						@coordsList[] = @build2
						@dp++
						@dp1++
						@updatename = @tpData['name']
					}
				}
				if(@dp1 > 1) {
					if(array_contains_ic(all_players(), @v)) {
						@results[] = @prefix.'Showing '.color(12).@dp1.color('#ffcc00').' Teleporters registered to '.color(5).@v;
					} else {	
						@results[] = @prefix.color(12).@dp1.color(6).' "'.@updatename.'" '.@samemsg.'world!';
					}
				}
			}
			if(@dp == 0) { @results[] = @prefix.color('f').'Location "'.color(9).@v.color('f').'"'.color('f').' is not Registered.'; }
			# if(@dp > 1) { msg(@prefix.color(12).@dp.color(6).' "'.@updatename.'" '.@samemsg.'server!') }
		}
	}
	#-- Validate location check
	foreach(@coord in @coordsList) {
		try{
			@check = get_block(@coord)
		} catch(Exception @ex) {
			console(@ex);
			return(@prefix.color(12).'Coordinates "'.@coord['x'].', '.@coord['y'].', '.@coord['z'].', '.@coord['world'].'" given is not valid.');
		}
	}
	#-- Results
	if(array_size(@coordsList) <= 0) {
		export('player.'.@uuid.'.command.teleporter.info', true)
		@results[] = @prefix.color(6).'No coordinates given! '.color(7).' Step on any pressure plate to obtain info about the related Teleporter.';
	} else {
		foreach(@coord in @coordsList) {
			@implodeloc = integer(@coord['x']).'.'.integer(@coord['y']).'.'.integer(@coord['z']);
			@post = array();
			if(array_index_exists(@allteleporters, @coord['world'], @implodeloc)) {
				@post = @allteleporters[@coord['world']][@implodeloc];
			} else {
				@tplocmsg = 'Location '.color(9).integer(@coord['x']).', '.integer(@coord['y']).', '.integer(@coord['z']).': '.@coord['world'];
				if(import('player.'.@uuid.'.command.teleporter.info') == true) { @tplocmsg = 'Teleporter' }
				@results[] = @prefix.color('f').@tplocmsg.color('f').' not Registered.';
				continue()
			}
			@tpName = 'Unnamed Teleporter'
			if(@post['name'] != null) { @tpName = @post['name']; }
			@tpType = 'Pressure Plate'
			if(array_index_exists(@post, 'type')) { @tpType = _capitalize(@post['type'], true); }
			@return = array(
				@prefix.color('f').'"'.color(11).@tpName.color('f').'" Info:',
				color(9).' Type: '.color(3).@tpType.color(0).'  |  '.color(9).'Uses: '.color(10).@post['uses'],
				color(9).' Location: '.color(5).integer(@coord['x']).', '.integer(@coord['y']).', '.integer(@coord['z']).': '.@coord['world'],
				color(9).' Warps to: '.color(10).array_implode(@post['location'], ', '),
				color(9).' Registered by: '.color(8).@post['registrar']
			)
			if(@post['activetime'] != null) {
				@timeColor = 10	
				if(reg_count(':', @post['activetime']) > 0) {
					@tptime = split(':', @post['activetime'])
					if(get_world_time(@coord['world']) < @tptime[0] || get_world_time(@coord['world']) > @tptime[1]) { @timeColor = 12; }
				}
				@return[] = color(8).' Active times: '.color(@timeColor).@post['activetime'];
			}
			if(is_array(@post['allowedGroups'])) {
				if(array_size(@post['allowedGroups']) > 0) { @return[] = color(8).' Allowed Groups: '.array_implode(@post['allowedGroups'], ', '); }
			}
			@results[] = array_implode(@return, '\n');
		}
	}
	return(array_implode(@results, '\n'));
}



proc _cmd_gamemode(@player, @args, @giver) {
	if(!@args) {
		@args = array()
	}
	if(!@player) { @player = player() }
	if(!@giver) { @giver = player() }
	@name = 'gameMode'
	if(!has_permission(@player, 'commandhelper.alias.shiftmode')) {
		return(color(12).'['.color(8).@name.color(12).'] '.color('f').'You don\'t have permission to change your gamemode.')
	}
	@modeColors = array('survival': 12, 'spectator': 14, 'creative': 11, 'adventure': 10);
	# @user = @player
	@setUsers = array();
	@newmode = 'Unset'
	# Get other player's name if provided
	@otherperm = false
	@multiperm = false
	if(has_permission('commandhelper.alias.shiftmode.others')) { @otherperm = true }
	if(has_permission('commandhelper.alias.shiftmode.others.multi')) { @multiperm = true }
	foreach(@k: @v in @args) {
		# Set mode if numeric argument given
		if(is_numeric(@v)) {
			if(length(@v) == 1) {
				switch(@v) {
				case 0:
					@newmode = 'Survival'
				case 1:
					@newmode = 'Creative'
				case 2:
					@newmode = 'Spectator'
				case 3:
					@newmode = 'Adventure'
				}
			} else { continue() }
		}
		# Get other player's name if provided
		if(array_contains_ic(all_players(), @v)) {
			if(@otherperm == false) { return(color(12).'['.color(8).@name.color(12).'] '.color(12).'You do not have permission to change other player\'s gamemodes!') }
			if(array_size(@setUsers) > 1 && !@multiperm) { return(color(12).'['.color(8).@name.color(12).'] '.color(12).'You do not have permission to change *many* player\'s gamemodes simultaneously!') }
			@setUsers[] = @v;
			array_remove(@args, @k);
			#No break, so finds all players and picks last mentioned.
		}
	}
	if(!array_index_exists(@setUsers, 0)) { @setUsers[] = @player; }
	@userResults = array();
	foreach(@i: @username in @setUsers) {
		@user = _getplayerID(@username)
		@fc = 0
		if(array_size(@args) > 0) {
		# Non-Player Arguments provided
			foreach(@k: @v in @args) {
				#Options for individual players only
				if(@user['name'] == @player) {
					if(reg_count('^[GgIiPp]', @v) > 0) {
						@gmpinv = get_value(@name.'player.'.puuid(@user['name'], 'dashless').'.mode.inv')
						if(!is_array(@gmpinv)) { @gmpinv = array('use': false, 'SURVIVAL': array(), 'CREATIVE': array(), 'ADVENTURE': array(), 'SPECTATOR': array()) }
						if(@gmpinv['use'] == true) {
							@gmpinv['use'] = false
							tmsg(@player, color(13).'['.color(9).@name.color(13).'] '.color(5).'Your inventory will not be reset upon game mode change.')
						} else {
							@gmpinv['use'] = true
							tmsg(@player, color(13).'['.color(9).@name.color(13).'] '.color(5).'Upon game mode change your inventory will be set to the inventory for that game mode.')
						}
						store_value(@name.'player.'.puuid(@user['name'], 'dashless').'.mode.inv', @gmpinv)
						@fc++
						continue()
					}
					if(reg_count('^[Ll][Oo]', @v) > 0 && @user['name'] == @player) {
						export(@name.'.player.'.puuid(@user['name'], 'dashless').'.lock', true)
						tmsg(@player, color(13).'['.color(9).@name.color(13).'] '.color(5).'Your game mode setting is now locked to '.pmode(@user['name']).'.')
						@fc++
						continue()
					}
					if(reg_count('^[Uu][Nn]', @v) > 0 && @user['name'] == @player) {
						export(@name.'.player.'.puuid(@user['name'], 'dashless').'.lock', false)
						tmsg(@player, color(13).'['.color(9).@name.color(13).'] '.color(5).'Your game mode setting is now unlocked.')
						@fc++
						continue()
					}
				}
				#Options for any player
				if(reg_count('^[Aa]', @v) > 0) { @newmode = 'Adventure' }
				if(reg_count('^[Cc]', @v) > 0) { @newmode = 'Creative' }
				if(reg_count('^[Ss][Uu]', @v) > 0) { @newmode = 'Survival' }
				if(reg_count('^[Ss][Pp]', @v) > 0) { @newmode = 'Spectator' }	
			}
			if(@newmode == 'Unset') {
				if(@fc == 0) { return(color(12).'['.color(8).@name.color(12).'] '.color(12).'Please specify a valid game mode!') } else { return(color(13).'['.color(9).@name.color(13).'] '.color(3).'Settings Saved.') }
			}
		} else {
		# /mode - No Arguments
			if(@newmode == 'Unset') {
				switch(pmode(@user['name'])) {
				case 'CREATIVE':
					@newmode = 'Survival'
				case 'SURVIVAL':
					@newmode = 'Creative'
				case 'SPECTATOR':
					@newmode = 'Survival'
				case 'ADVENTURE':
					@newmode = 'Survival'
				}
			}
		}
	# Gamemode lock/unlock - lock out other players and yourself from changing your game mode. Does not survive reboots by design for now.
		@adminbypass = false
		if(import(@name.'.player.'.puuid(@user['name'], 'dashless').'.lock') == true) {
			if(has_permission(@player, 'commandhelper.alias.shiftmode.lock.bypass')) {
				@adminbypass = true
				tmsg(@player, color(13).'['.color(9).@name.color(13).'] '.color(5).@user['name'].' has locked their gamemode, using admin bypass.')
			} else {
				tmsg(@player, color(13).'['.color(9).@name.color(13).'] '.color(5).@user['name'].' has requested to not change their gamemode.')
				continue()
			}
		}
	#World based permission
		# Mode Allowed in any world
		if(!has_permission(@player, 'commandhelper.alias.shiftmode.any.world.'.to_lower(@newmode))) {
			# Mode Allowed in Specific world
			if(!has_permission(@player, 'commandhelper.alias.shiftmode.world.'.to_lower(pworld(@user['name'])).'.'.to_lower(@newmode))) {
				return(color(12).'['.color(8).@name.color(12).'] '.color('f').'You don\'t have permission to change the gamemode to '.@newmode.' on world: '.pworld(@user['name']))
			}
		}
	#Set and Return
		if(@adminbypass) { export(@name.'.player.'.puuid(@user['name'], 'dashless').'.lock', false) }
		set_pmode(@user['name'], to_upper(@newmode));
		if(@adminbypass) { export(@name.'.player.'.puuid(@user['name'], 'dashless').'.lock', true) }

		if(@user['name'] == @player) {
			@userResults[] = color(7).'['.color(9).@name.color(7).'] '.color('f').'Changed to '.color(@modeColors[to_lower(@newmode)]).@newmode.color('f').' gamemode.';
		} else {
			tmsg(@user['name'], color(7).'['.color(9).@name.color(7).'] '.color(9).@player.color('f').' has changed your gamemode to '.color(@modeColors[to_lower(@newmode)]).@newmode.color('f').'.')
			@userResults[] = color(7).'['.color(9).@name.color(7).'] '.color('f').'Changed '.@user['name'].' to '.color(@modeColors[to_lower(@newmode)]).@newmode.color('f').' gamemode.';
		}
	}
return(array_implode(@userResults, '\n'));
}


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