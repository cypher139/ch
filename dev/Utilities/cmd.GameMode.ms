try(unregister_command('mode'))
try(unregister_command('gamemode'))
try(unregister_command('gm'))

#Per Game Mode Inventories / Game Mode Lock Enforcement
bind('gamemode_change', array('id': 'gamemode.listener', 'priority': 'HIGH'), null, @event) {
	@name = 'gameMode';
	@uuid = puuid(@event['player'], 'dashless');
	@dev = import('ch.player.'.@uuid.'.dev.scripts.gamemode');
	if(@dev == true) { msg(@event['player'].': Old mode: '.pmode(@event['player']).' | New mode: '.@event['newmode']); }
# -- Game Mode Lock Enforcement
	@userlock = import(@name.'.player.'.@uuid.'.lock');
	if(@userlock == true) {
		tmsg(@event['player'], color(13).'['.color(9).@name.color(13).'] '.color(5).'Someone just tried to change your gamemode to '.to_lower(@event['newmode']).'!');
		cancel();
		die();
	}	
# -- Per Game Mode Inventories
	@gmpinv = get_value(@name.'.player.'.@uuid.'.mode.inv');
	if(!is_array(@gmpinv)) { @gmpinv = array('use': false, 'SURVIVAL': array(), 'CREATIVE': array(), 'ADVENTURE': array(), 'SPECTATOR': array()) }
	if(@gmpinv['use'] == true) {
	# Save Current Mode's Inventory
		@gmpinv[pmode(@event['player'])] = pinv(@event['player']);
	# Load New Mode's previous inventory
		clear_pinv(@event['player']);
		set_pinv(@event['player'], @gmpinv[@event['newmode']]);
		store_value(@name.'.player.'.@uuid.'.mode.inv', @gmpinv);
	}
}


# Game mode command
register_command('gamemode', array(
	'description': 'Change your gamemode, and enable per-mode inventories.',
	'usage': color(8).'Examples: /gamemode, /gm creative, /mode lock',
	'permission': 'commandhelper.alias.shiftmode',
	'noPermMsg': color(12).'['.color(8).'gameMode'.color(12).'] '.color('f').'You don\'t have permission to change your gamemode.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actplayers = all_players();
			@atype = 0;
			@actoptions = array('Lock', 'Unlock', 'Adventure', 'Survival', 'Creative', 'Spectator', 'Per-Mode-Inventory');
			@usetabs = array('<No further arguments>');
		#Compute Tabs for each arg position
			switch(@argPos) {
			case 0:
		#Options
				@usetabs = @actoptions;
				@atype = 'a0';
			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
		#Change Other Player's modes
				if(has_permission('commandhelper.alias.shiftmode.others')) { @usetabs = @actplayers; }
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
	'aliases': array('gm', 'mode'),
	'executor':
		closure(@alias, @sender, @args, @info) {
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
			#Arguments nag message
			if(array_index_exists(@args, 0) && !has_permission(@sender, 'commandhelper.alias.shiftmode.notip') && array_size(@args) < 2) {
				msg(color(3).'Tip: '.color(7).'Switch between '.color(12).'Survival'.color(7).' and '.color(11).'Creative'.color(7).' mode by just using '.color(10).'/mode');
			}
			@return = _cmd_gamemode(@sender, @args, @sender);
			msg(@return);
			return(true);
		}
));