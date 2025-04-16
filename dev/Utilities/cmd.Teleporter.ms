# Turn pressure plates (or redstone and farm land) into your own personal teleporter!
bind('pressure_plate_activated', array('id': 'triangle.teleporter', 'priority': 'MONITOR'), null, @event) {
	@uuid = puuid(player(), 'dashless')
	@dev = import('ch.player.'.@uuid.'.dev.scripts.tp')
	@prefix = color('#ffcc00').'['.color(7).'Teleporter'.color('#ffcc00').'] '
	# 2 modes: mode 1: teleport on press. mode 2: on press say warpname on hotbar, warp on release
	if(@event['macrotype'] != 'player') { console('whut?') }
	@useBlock = false
	@supportedBlocks = array('REDSTONE_ORE', 'FARMLAND', 'PRESSURE_PLATE')
	foreach(@i: @block in @supportedBlocks) {
		if(string_ends_with(get_block(@event['location']), @block) == true) { @useBlock = true }
	}
	if(@useBlock == false) {
# Debug: collecting event data
		@otherblocks = get_value('ch.dev.data.event.pressure_plate.types')
		if(!is_array(@otherblocks)) { @otherblocks = array() }
		if(!array_contains(@otherblocks, get_block(@event['location']))) { 
			@otherblocks[] = get_block(@event['location'])
			store_value('ch.dev.data.event.pressure_plate.types', @otherblocks)
			console(color(12).'New: '.color(8).' pressure_plate_activated event occured on a '.get_block(@event['location']))
			console(color(8).'Current types found:  '.array_implode(@otherblocks, ', '))
		}
		if(@dev == true) { msg(color(12).'Note: '.color(8).'pressure_plate_activated event occured on a '.get_block(@event['location'])) }
		die()
	}
	#msg(@event)

	@allteleporters = get_value('server.Teleporters.registered')
	if(!is_array(@allteleporters)) { @allteleporters = array() }

	#location array: key is x.y.z all whole numbers
	@implodeloc = integer(@event['location']['x']).'.'.integer(@event['location']['y']).'.'.integer(@event['location']['z'])

# Save command
	if(import('player.'.@uuid.'.command.teleporter.set') == true) {
		@setargs = import('player.'.@uuid.'.command.teleporter.set.args')
		store_value('server.Teleporters.registered.undo', @allteleporters)

		@newtpInfo = array('type': get_block(@event['location']), 'location': @setargs['location'], 'registrar': player(), 'name': @setargs['name'], 'activetime': @setargs['time'], 'allowedGroups': null, 'uses': 0);
		if(array_index_exists(@allteleporters, pworld(), @implodeloc)) {
			@allteleporters[pworld()][@implodeloc] = @newtpInfo;
		} else {
			array_set(@allteleporters[pworld()], @implodeloc, @newtpInfo);
		}
		store_value('server.Teleporters.registered', @allteleporters)
		export('player.'.@uuid.'.command.teleporter.set', null)
		export('player.'.@uuid.'.command.teleporter.set.args', null)
		msg(@prefix.color(6).'Teleporter Bound and Online!')
		die()
	}

# Info command
	if(import('player.'.@uuid.'.command.teleporter.info') == true) {
		@return = _cmd_teleporter_info(player(), @event['location']);
		export('player.'.@uuid.'.command.teleporter.info', null)
		die(@return);
	}

# Teleport
	#if stepped on plate registered in array, teleport to location given
	if(array_index_exists(@allteleporters, pworld(), @implodeloc, 'location')) {
		#time check
		if(reg_count(':', @allteleporters[pworld()][@implodeloc]['activetime']) > 0) {
			@tptime = split(':', @allteleporters[pworld()][@implodeloc]['activetime'])
			if(get_world_time(pworld()) < @tptime[0] || get_world_time(pworld()) > @tptime[1]) {
				die(color(6).'Teleporter is out of order. Come back another time!')
			}
		}
		set_ploc(@allteleporters[pworld()][@implodeloc]['location'])
		@allteleporters[pworld()][@implodeloc]['uses'] = @allteleporters[pworld()][@implodeloc]['uses'] + 1
		store_value('server.Teleporters.registered', @allteleporters)

		@tpmsg = color(6).'You have been Teleported!'
		if(@allteleporters[pworld()][@implodeloc]['name'] != null) {
			@tpmsg = color(6).'You have used the "'.color(9).@allteleporters[pworld()][@implodeloc]['name'].color(6).'" Teleporter!'
		}
		msg(@tpmsg)
	}

}



register_command('teleporter', array(
	'description': 'Setup and obtain info about various in-world teleporters.',
	'usage': color(8).'Examples: /teleporter, /teleporter info 1,2,-34, /teleporter set',
	'permission': 'commandhelper.alias.teleporter',
	'noPermMsg': color(6).'Teleporter is out of order. Come back another time!',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actplayers = all_players();
			@atype = 0;
			@actoptions = array('Lock', 'Unlock', 'Adventure', 'Survival', 'Creative', 'Spectator', 'Per-Mode-Inventory');
			@actcmds = array('Set', 'Info')
			@usetabs = array('<No further arguments>');
		#Compute Tabs for each arg position
			switch(@argPos) {
			case 0:
		#Options
				@usetabs = @actcmds;
				@atype = 'a0';
			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
		#Change Other Player's modes
				if(has_permission('commandhelper.alias.teleporter.info')) { @usetabs = @actplayers; }
				@atype = 'a1';
			}
		#Return tabs
			@areturn = array_filter(@usetabs, closure(@key, @value) {
			return(length(@arg) <= length(@value)
					&& equals_ic(@arg, substr(@value, 0, length(@arg))));
			});
			# console(@atype);
			return(@areturn);
		},
	'aliases': array('tper', 'triangle', '/\\'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@name = 'Teleporter'
			@cmd = 'info'
			if(array_index_exists(@args, 0)) {
				if(@args[-1] == 'arguments>') {
					@back = array_size(@args) - 4;
					if(@back < 0) {
						@args = array();
					} else {
						@args = @args[cslice(0, @back)];
					}
				}
			}
			if(array_index_exists(@args, 0)) {
				@cmd = @args[0]
				array_remove(@args, 0)
			}
		#Sub Commands
			if(!has_permission(@sender, 'commandhelper.alias.teleporter.'.@cmd)) { 
				msg(color(12).'['.color(7).@name.color(12).'] '.color(7).'You do not have permission to use this command.'); 
				return(true);
			}	
			switch(@cmd) {
			case 'info':		
				@return = _cmd_teleporter_info(@sender, @args, @sender);
				msg(@return);
				return(true);
			default:
				msg(color(12).'['.color(7).@name.color(12).'] '.color(7).'Action not recognized.');
				return(false);
			}
		}
));