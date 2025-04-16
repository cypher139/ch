try(unregister_command('back'))
#Console Deaths = amount of times server started / alias reloads
store_value('DeathCount.console.death.counter', get_value('DeathCount.console.death.counter')++);

#Player Teleports: Save Location infos.
bind('player_teleport', array('id': 'cmd.back.tp'), null, @tp) {
	@uuid = puuid(@tp['player'], 'dashless');
	@lastloc = get_value('player.'.@uuid.'.last.location');
	# Flag last teleport type
	export('player.'.@uuid.'.cmd.back.default', 'tp');
	#Set a return location for /back return, if last command isn't the backtp functions.
	@lastcmd = import('player.'.@uuid.'.last.command')
	if(!is_array(@lastcmd)) { @lastcmd = array('--') }
	@lastreturn = import('player.'.@uuid.'.last.return.location')
	if(!is_array(@lastreturn)) { @lastreturn = array() }
	if(!string_starts_with(@lastcmd[0], '/back') || !array_index_exists(@lastreturn, 'world')) {
		export('player.'.@uuid.'.last.return.location', @tp['from']);
	}
	#Don't save locations if the BackTP commands are running - prevents overwriting current location with previous when revisiting
	if(import('player.'.@uuid.'.cmd.back.active') == true) { 
		export('player.'.@uuid.'.cmd.back.active', null); 
		die();
	}
	#Record previous location
	@mode = string(pmode(@tp['player']))[0];
	if(!is_array(@lastloc)) { @lastloc = array(@tp['from']) }
	if(!array_index_exists(@lastloc, @mode)) { array_set(@lastloc, @mode, array()) }
	array_insert(@lastloc[@mode], @tp['from'], 0);
	if(array_index_exists(@lastloc, @mode, 10)) { array_remove(@lastloc[@mode], 10) }
	store_value('player.'.@uuid.'.last.location', @lastloc);
}

#Player Deaths: Save Location and Drops infos.
bind('player_death', array('id': 'cmd.back.deathtp', 'priority': 'MONITOR'), null, @death) {
	x_new_thread('DeathStats.'.@death['player'], closure(@player = @death['player'], @drops = @death['drops']){
		@uuid = puuid(@player, 'dashless');
		@dev = import('ch.player.'.@uuid.'.developer');
		@mode = string(pmode(@player))[0]
	# Flag last teleport type
		export('player.'.@uuid.'.cmd.back.default', 'deathtp');
	# Save death point for /back [per mode] [mode key is first letter of mode name]
		@here = ploc(@player);
		@pdloc = get_value('player.'.@uuid.'.last.death.location');
		if(!is_array(@pdloc)) { @pdloc = array() }
		if(!array_index_exists(@pdloc, @mode)) { array_set(@pdloc, @mode, array(@here)) }
		array_insert(@pdloc[@mode], @here, 0);
		if(array_index_exists(@pdloc, @mode, 10)) { array_remove(@pdloc[@mode], 10) }
		store_value('player.'.@uuid.'.last.death.location', @pdloc);
		tmsg(@player, color(7).'Use the '.color(12).'/back'.color(7).' command to return to your death point.')
		
	# Save inventory [per mode]
		@pddrops = get_value('player.'.@uuid.'.last.death.drops');
		if(!is_array(@pddrops)) { @pddrops = array() }
		if(!array_index_exists(@pddrops, @mode)) { array_set(@pddrops, @mode, array(@drops)) }
		array_insert(@pddrops[@mode], @drops, 0);
		if(array_index_exists(@pddrops, @mode, 10)) { array_remove(@pddrops[@mode], 10) }
		store_value('player.'.@uuid.'.last.death.drops', @pddrops);
		
	# Save number of times died
		@dc = get_value('DeathCount.players.death.counter')
		if(!is_array(@dc)) { @dc = array() }
		if(array_index_exists(@dc, @uuid)) {
			@dc[@uuid] = @dc[@uuid] + 1
		} else {
			#if array key not set, @array[key] does not work
			array_set(@dc, @uuid, 1);
		}
		store_value('DeathCount.players.death.counter', @dc);
	});
}

#------------------------------

register_command('back', array(
	'description': 'Teleports a player back to their previous location(s) before a teleport or death, or gives a player their lost inventory.',
	'usage': color(8).'Examples: /back, /back 2, /back items 3, /back 2 adventure, /back death, /back tp',
	'permission': 'commandhelper.alias.back',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actmodes = array('Survival', 'Creative', 'Adventure');
			@actplayers = all_players();
			@actqty = array();
			for(@i = 1, @i <= 10, @i++) {
				@actqty[] = @i;
			}
			@atype = 0
			@usetabs = array('<No further arguments>');		
		#Compute Tabs for each arg position
			switch(@argPos) {
			case 0:
		#1st arg:
		#id
				if(@alias == 'back') { @actqty[] = 'tp'; @actqty[] = 'deathtp'; @actqty[] = 'items'; @actqty[] = 'return'; }
				@usetabs = @actqty;
				@atype = 'a0'
			case 1:
		#mode
				@usetabs = @actmodes;
				# if(@args[0][0] == 'i') { 
				if(@alias == 'back' && !is_numeric(@args[0])) { @usetabs = @actqty; }
				if(@args[0][0] == 'r') { @usetabs = array('--'); }
				@atype = 'a1'
			case 2:
				if(@alias == 'back' && !is_numeric(@args[0])) { @usetabs = @actmodes; }
				if(@args[0][0] == 'r') { @usetabs = array('--'); }
				@atype = 'a2'
			}
		#Return tabs
			@areturn = array_filter(@usetabs, closure(@key, @value) {
			return(length(@arg) <= length(@value)
					&& equals_ic(@arg, substr(@value, 0, length(@arg))));
			});
			# console(@atype)
			return(@areturn);
		},
	'aliases': array('backitems', 'backtp'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@player = @sender;
			@uuid = puuid(@player, 'dashless');
			@cmd = 'tp'
			@cmdkey = array('tp': 'location', 'deathtp': 'death.location', 'items': 'death.drops', 'return': 'return.location');
			@name = array('tp': 'BackTP', 'deathtp': 'DeathTP', 'items': 'DeathTP: ItemManagement', 'return': 'BackTP');
			if(@alias == 'backitems') { @cmd = 'items'; }
			if(@alias == 'backtp') { @cmd = 'tp'; }
			if(@alias == 'backdeath') { @cmd = 'deathtp'; }
			if(array_index_exists(@args, 0)) {
				if(@args[-1] == 'arguments>') {
					@back = array_size(@args) - 4;
					if(@back < 0) {
						@args = array();
					} else {
						@args = @args[cslice(0, @back)]
					}
				}
			}
		# Select Sub command
			if(array_index_exists(@args, 0)) {
				switch(to_lower(@args[0])[0]) {
				case 'b':
				case 't':
					@cmd = 'tp';
					array_remove(@args, 0);
				case 'd':
					@cmd = 'deathtp';
					array_remove(@args, 0);
				case 'i':
					@cmd = 'items';
					array_remove(@args, 0);
				case 'r':
					@cmd = 'return';
					array_remove(@args, 0);
				}
			} else if(@alias == 'back') {
				@flag = import('player.'.@uuid.'.cmd.back.default');
				if(array_index_exists(@cmdkey, @flag)) {
					@cmd = @flag;
				}
			}
		#Common Args
			if(!has_permission(@player, 'commandhelper.alias.back.'.@cmd)) {
				@cmdmsg = array('tp': 'to teleport back!?', 'deathtp': 'to teleport to your grave!?', 'items': 'to respawn items.', 'return': 'to return to your starting point.');
				msg(color(12).'['.color(7).@name[@cmd].color(12).'] '.color(12).'You do not have permission '.color(7).@cmdmsg[@cmd]); 
				return(true);
			}
			@id = 0
			@mode = string(pmode(@player))[0];
			if(array_index_exists(@args, 1)) { @mode = to_upper(@args[1])[0] }
			if(!string_starts_with(@mode, 'S') && !string_starts_with(@mode, 'C') && !string_starts_with(@mode, 'A')) {
				msg(color(12).'['.color(7).@name[@cmd].color(12).'] '.color(7).'What game mode is that?!');
				return(false);
			}
			if(array_index_exists(@args, 0)) {
				if(is_numeric(@args[0])) {
					if(integer(@args[0]) < 0) {
						@id = 0;
					} else if(@args[0] - 1 > 9) { 
						@id = 9;
					} else { @id = @args[0] - 1 }
				} else {
					msg(color(8).'['.color(9).@name[@cmd].color(8).'] '.color(7).'Sorry, I don\'t remember that far back!')
					return(false);
				}
			}
			@displayid = @id + 1;
			
			@pData = get_value('player.'._getplayerID(@player)['id'].'.last.'.@cmdkey[@cmd]);
			if(@cmd == 'return') { @pData = import('player.'._getplayerID(@player)['id'].'.last.'.@cmdkey[@cmd]) }
			if(!is_array(@pData)) { @pData = array() }
			@returnMsg = array(12, '?');
		#Commands
			switch(@cmd) {
			case 'tp':
			#Teleport - Back
				if(array_index_exists(@pData, @mode, @id, 'world')) {
					export('player.'.@uuid.'.cmd.back.active', true); 
					set_ploc(@pData[@mode][@id])
					@s = 'back to where you were before teleporting'
					if(@displayid > 1) { @s = 'to your previous teleport point #'.@displayid }
					@returnMsg = array(6, 'Teleported you '.@s.'.');
				} else {
					@returnMsg = array(12, 'You don\'t have a saved teleport point #'.@displayid.' to teleport to!');
				}
			case 'deathtp':
			#Teleport - Death
				if(array_index_exists(@pData, @mode, @id, 'world')) {
					export('player.'.@uuid.'.cmd.back.active', true); 
					set_ploc(@pData[@mode][@id])
					@s = 'last death point'
					if(@displayid > 1) { @s = 'previous death point #'.@displayid }
					@returnMsg = array(6, 'Teleported to your '.@s.'.');
				} else {
					@returnMsg = array(12, 'You don\'t have a saved death point #'.@displayid.' to teleport to!');
				}
			case 'return':
			#Teleport - Death
				if(array_index_exists(@pData, 'world')) {
					export('player.'.@uuid.'.cmd.back.active', true); 
					set_ploc(@pData)
					@returnMsg = array(6, 'Returned you to where you were before visiting previous teleport locations.');
				} else {
					@returnMsg = array(12, 'You don\'t have a return point to teleport to!');
				}
			case 'items':
				@s = 'the last death'
				if(@displayid > 1) { @s = 'previous death #'.@displayid }
			#Give Items
				if(array_index_exists(@pData, @mode, @id, 0, 'name')) {
					foreach(@item in @pData[@mode][@id]) {
					#array: meta, qty, name
						pgive_item(@player, @item)
					}
					@returnMsg = array(5, 'Respawning your items from '.@s.'.');
				} else {
					@returnMsg = array(12, @s.'\'s inventory was empty!');
				}
			}
			msg(color(8).'['.color(@returnMsg[0]).@name[@cmd].color(8).'] '.color(7).@returnMsg[1]);
			return(true);
		}
));