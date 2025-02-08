try(unregister_command('give'))
try(unregister_command('i'))
register_command('give', array(
	'description': 'Gives the specified player a new item.',
	'usage': color(8).'Examples: /give Player dirt 64, /i refill, /i dirt 3, /i stick|display: "Mighty Stick", or /i stick{"display":"Mighty Stick"}',
	'permission': 'commandhelper.alias.creative',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actmaterials = array_map(all_materials(), closure(@value) {
				return(to_lower(string(@value)));
			});
			@actplayers = all_players();
			@actqty = array('max');
			for(@i = 1, @i <= 64, @i++) {
				@actqty[] = @i;
			}
			@atype = 0
			array_push(@actmaterials, '{<JSON Item Meta data>}', '|<YAML Item Meta data>', 'that', 'fill', 'refill', 'max', 'more')
			@usetabs = array('<No further arguments>');
		#Compute Tabs for each arg position
			switch(@argPos) {
			case 0:
		#1st arg:
		#give: player, i: material
				@usetabs = @actplayers;
				if(@alias == 'i') { @usetabs = @actmaterials; }				
			case 1:
		#give: material, i: qty
				@usetabs = @actmaterials;
				if(@alias == 'i') { @usetabs = @actqty; }
			case 2:
		#give: qty, i: ---
				if(@alias == 'give') { @usetabs = @actqty; }
			}
		#Return tabs
			@areturn = array_filter(@usetabs, closure(@key, @value) {
			return(length(@arg) <= length(@value)
					&& equals_ic(@arg, substr(@value, 0, length(@arg))));
			});
			return(@areturn);
		},
	'aliases': array('i'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@player = @sender;
			if(@args[-1] == 'arguments>') {
				@back = array_size(@args) - 4;
				if(@back < 0) {
					@args = array();
				} else {
					@args = @args[cslice(0, @back)]
				}
			}
			# Give: Get other player name:
			if(@alias == 'give') {
				if(array_size(@args) < 2) { 
					msg(color(12).'You must specify a player and item.') 
					return(false);
				}
				if(array_contains_ic(all_players(), @args[0])) {
					@player = @args[0];
				} else {
					msg(color(12).'That player was not found.');
					return(true);
				}
			}
			if(@alias == 'i') { @player = @sender; }
			@return = _cmd_giveitem(@player, @args, @sender);
			msg(@return);
			return(true);
		}
));