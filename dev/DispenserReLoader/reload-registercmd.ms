######################################################
#
#   ReLoad: Fill blocks that have inventories in one click!
#   This provides tab completion for the ReLoad commands.
#   version 1.2-tmc
#
######################################################


#   Server Reload protections:
#   This provides protection from players inadvertently
#   reloading the server while trying to access ReLoad.
try(unregister_command('reload'))
try(unregister_command('rl'))

#   Register all ReLoad commands
register_command('reloader', array(
	'description': 'ReLoad: Fill blocks that have inventories in one click!',
	'usage': color(7).'/reloader help'.color(4).' - '.color('f').'Shows the help screen.',
	'permission': 'commandhelper.alias.reloader',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args) {
			@input = @args[-1];
			/*
			console(@input)
			console(@args)
			console('c: '.(array_size(@args) - 1))
			try(console('-2: '.@args[-2]))
			*/
			@tabs = array('help', 'info', 'stats', 'verbose', 'set', 'area', 'fuel', 'mode', 'bind', 'unbind', 'this', 'that', 'clear')
			#get item name
			if((array_size(@args) - 1) > 0)  {
			@tabs = array('There are no further arguments', 'Note:')
				if(array_contains_ic(array('set', 'area', 'fuel', 'mode'), @args[-2])) {
					@usetabs = array()
					if(equals_ic('mode', @args[-2])) {
						@usetabs = array('All', 'Barrel', 'Blast_Furnace', 'Brewing', 'Chest', 'Dispenser', 'Furnace', 'Shulker_Box', 'Smoker', 'Trapped_Chest', 'Group_Chest', 'Chests', 'Group_Furnace', 'Furnaces', 'Black_Shulker_Box', 'Blue_Shulker_Box', 'Brown_Shulker_Box', 'Cyan_Shulker_Box', 'Gray_Shulker_Box', 'Green_Shulker_Box', 'Light_Blue_Shulker_Box', 'Light_Gray_Shulker_Box', 'Lime_Shulker_Box', 'Magenta_Shulker_Box', 'Orange_Shulker_Box', 'Pink_Shulker_Box', 'Purple_Shulker_Box', 'Red_Shulker_Box', 'White_Shulker_Box', 'Yellow_Shulker_Box')
					} else if(equals_ic('fuel', @args[-2])) {
						@usetabs = import('dispenserreloader.fuel.items')			 
					} else {
						@usetabs = all_materials()
						array_push(@usetabs, 'clear', 'default', 'this', 'fuel')
					}
					@areturn = array_filter(@usetabs, closure(@key, @value) {
					return(length(@input) <= length(@value)
							&& equals_ic(@input, substr(@value, 0, length(@input))));
					});						
				#	console('a2: '.@areturn)
					return(@areturn)
				}
			}
			#getting qty
			if((array_size(@args) - 1) > 1)  {
				if(array_contains_ic(all_materials(), @args[-2])) {
					@usetabs = array('clear', 'default')
					for(@i = 1, @i <= 64, @i++) {
						array_push(@usetabs, @i)
					}
					@areturn = array_filter(@usetabs, closure(@key, @value) {
					return(length(@input) <= length(@value)
							&& equals_ic(@input, substr(@value, 0, length(@input))));
					});						
				#	console('a3: '.@areturn)
					return(@areturn)
				}
			}

			#normal commands:		
			@areturn = array_filter(@tabs, closure(@key, @value) {
				return(length(@input) <= length(@value)
						&& equals_ic(@input, substr(@value, 0, length(@input))));
			});
		#	console('a: '.@areturn)
		#	console(@alias.'  '.@sender)
			return(@areturn)
		},
	'aliases': array('reload', 'rl'),
	'executor':
		closure(@alias, @sender, @args) {
		#	console(@alias.'  '.@sender)
			if(@alias == 'reload') {
				if(@sender == 'CONSOLE') {
					msg(color('c').'Are you sure you wish to reload your server? Reloading causes bugs and memory leaks. It is highly recommended to restart instead of using /reload. To start a server restart, please type '.color('e').'/reload confirm')
					if(array_index_exists(@args, 0)) {
						if(@args[0] == 'confirm') { shutdown_server() }
						die()
					}
				}
			}
			call_alias('/reloader '.array_implode(@args, ' '))
			return(true);
		}
));


register_command('reloaderadmin', array(
	'description': 'ReLoad Administration: Manage settings for Reloader.',
	'usage': color(7).'/reloaderadmin help'.color(4).' - '.color('f').'Shows the help screen.',
	'permission': 'commandhelper.alias.admin',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args) {
			@input = @args[-1];
/*		
			console(@input)
			console(@args)
			console('c: '.(array_size(@args) - 1))
			try(console('-2: '.@args[-2]))
		*/	
			@tabs = array('help', 'info', 'stats', 'version', 'set', 'default', 'settings', 'view')
			#get item name
			if((array_size(@args) - 1) > 0)  {
				@tabs = array('There are no further arguments', 'Note:')			
				if(array_contains_ic(array('item', 'name', 'type', 'fuel'), @args[-2])) {
					@usetabs = all_materials()
					array_push(@usetabs, 'clear', 'default', 'this', 'fuel')
					@areturn = array_filter(@usetabs, closure(@key, @value) {
					return(length(@input) <= length(@value)
							&& equals_ic(@input, substr(@value, 0, length(@input))));
					});						
				#	console('a2: '.@areturn)
					return(@areturn)
				}
				# Set: action [item/qty/fuel]
				if(array_contains_ic(array('set', 'default'), @args[-2])) {
					@tabs = array('item', 'name', 'type', 'fuel', 'qty') 
				}
				#Stats: player name
				if(equals_ic(@args[-2], 'stats')) {
					@areturn = array_filter(get_offline_players(), closure(@key, @value) {
					return(length(@input) <= length(@value)
							&& equals_ic(@input, substr(@value, 0, length(@input))));
					});						
				#	console('ap: '.@areturn)
					return(@areturn)
				}
			}
			#getting qty
			if((array_size(@args) - 1) > 1)  {
				if(equals_ic(@args[-2], 'qty') || array_contains_ic(all_materials(), @args[-2])) {
					@usetabs = array('clear', 'default')
					for(@i = 1, @i <= 64, @i++) {
						array_push(@usetabs, @i)
					}
					@areturn = array_filter(@usetabs, closure(@key, @value) {
						return(length(@input) <= length(@value)
							&& equals_ic(@input, substr(@value, 0, length(@input))));
					});						
				#	console('a3: '.@areturn)
					return(@areturn)
				}
			}
			#normal commands:
			@areturn = array_filter(@tabs, closure(@key, @value) {
				return(length(@input) <= length(@value)
						&& equals_ic(@input, substr(@value, 0, length(@input))));
			});
		#	console('a: '.@areturn)
		#	console(@alias.'  '.@sender)
			return(@areturn)
		},
	'aliases': array('reloadadmin', 'rladmin'),
	'executor':
		closure(@alias, @sender, @args) {
		#	console(@alias.'  '.@sender)
			call_alias('/reloaderadmin '.array_implode(@args, ' '));
			return(true);
		}
));