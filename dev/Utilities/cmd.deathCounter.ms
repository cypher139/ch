# Version 2 - requires ScriptLibraries - getplayerID and UUID database
proc _msg_count(@count, @player, @pos) {
	@name = 'DeathCount';
	@prefix = color(14).'['.color(6).@name.color(14).'] ';
	@posmsg = ' ('.color(4).'#'.@pos.' on leaderboard'.color(7).')';
	@dcmsg = '';
	if(@pos == '' || @pos == null) { @posmsg = ''}
	switch(@count) {
		case '':
		case null:
			@dcmsg = 'Reaper reports '.@player.' never died, you lucky bastard.';
		case 0:
			@dcmsg = 'Reaper says his memory was wiped!?';
		case 'ni':
			@prefix = color(9).'['.color(0).@name.color(9).'] ';
			@dcmsg = 'Reaper is currently suffering memory loss.';
			console(@prefix.color(8).' Player UUID not found for '.@player, false);
		case 'nn':
			@prefix = color(9).'['.color(0).@name.color(9).'] ';
			@dcmsg = 'Reaper is currently suffering memory loss..';
			console(@prefix.color(8).' Player name not found for '.@player, false);
		case 'd':
			@prefix = color(9).'['.color(0).@name.color(9).'] ';
			@dcmsg = 'Reaper is currently suffering memory loss...';
			console(@prefix.color(8).' Requested Player named "'.@player.'" has not logged on here before!', false);
		default:
			@dcmsg = @player.' died a total of '.color(12).@count.color(7).' times!';
	}
	return(@prefix.color(7).@dcmsg.@posmsg);
}

proc _msg_leaderboard(@board, @max) {
	@name = 'DeathCount';
	@prefix = color(14).'['.color(6).@name.color(14).'] ';
	@results = array(@prefix.color(7).' Top '.color(12).@max.color(7).' Deaths Leaderboard:');
	@numColors = array(12, 6, 7, '#ba3e39', 4);
	for(@i = 0, @i < @max, @i++){
		if(array_index_exists(@board, @i)) {
			@nc = 4
			if(array_index_exists(@numColors, @i)) { @nc = @numColors[@i]; }
			@results[] = color(@nc).'# '.(@i + 1).color(7).':  '.color(@nc).@board[@i][0].color(7).' -- '.color(12).@board[@i][1].color(7).' deaths';
		} else {
			@results[] = @prefix.color(9).' ------ End of Leaderboard ------';
			break();
		}
	}
	return(array_implode(@results, '\n'));
}

#------------------------------

register_command('deathcounter', array(
	'description': 'See who has died the most times on this server.',
	'usage': color(8).'Examples: /deathcounter, /deathcounter leaderboard, /deathcounter all, /deathcounter <playername(s)>',
	'permission': 'commandhelper.alias.deathcounter',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actsub = array('all', 'leaderboard');
			@actsubAdmin = array('console');
			@actplayers = all_players();
			if(has_permission(@sender, 'commandhelper.alias.admin')) { 
				array_push_all(@actplayers, get_offline_players());
				@actplayers = array_sort(array_unique(@actplayers, false), 'REGULAR');
			}
			@actplayers = array_merge(all_players(), get_offline_players());
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
				@usetabs = @actsub;
				if(has_permission(@sender, 'commandhelper.alias.admin')) { @usetabs = array_merge(@actsub, @actsubAdmin); }
				array_push_all(@usetabs, @actplayers);
			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
				@usetabs = @actplayers;
			}
		#Return tabs
			@areturn = array_filter(@usetabs, closure(@key, @value) {
			return(length(@arg) <= length(@value)
					&& equals_ic(@arg, substr(@value, 0, length(@arg))));
			});
			# console(@atype);
			return(@areturn);
		},
	'aliases': array('dc'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@player = @sender;
			@uuid = puuid(@player, 'dashless');
			@id = 0;
			@returnMsg = array(12, '?');
			@name = 'DeathCount';
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
		# puuid does not find offline bedrock players, does find any java even if never played
			@countdata = get_value('DeathCount.players.death.counter');
			@oplayer = get_offline_players();
			@prefix = color(14).'['.color(6).@name.color(14).'] ';
			@boardpos = 'Unlisted';
		# Default command only
			if(array_size(@args) <= 0) {
				#Console's stats
				if(player() == '~console') {
					msg(_msg_count(get_value('DeathCount.console.death.counter'), 'Console'));
					return(true);
				} else {
				#Your Own Stats
					msg(_msg_count(@countdata[_getplayerID(player())['id']], 'You'));
					return(true);
				}
			}
		# Setup Leaderboard
			@leaderboard = array();
			foreach(@k: @v in @countdata) {
				@pName = _getplayerName(@k)['name']
				if(@pName == null) { continue(); }
				array_push(@leaderboard, array(@pName, @v));
			}
			array_sort(@leaderboard, closure(@left, @right) {
				return(@left[1] < @right[1]);
			});
			@results = array();
		# Sub Actions:
			switch(@args[0]) {
			case 'c':
			case 'console':
			if(has_permission('commandhelper.alias.deathcounter.console')) {
				@results[] = _msg_count(get_value('DeathCount.console.death.counter'), 'Console');
			} else {
				@results[] = @prefix.color(12).'You do not have permission to view Console stats.';
			}
			case 'moo':
				@word = 'Unexpected action.';
				if(array_index_exists(@args, 1)) { @word = @args[1]; }
				@results[] = color('r').moo(color(3).@word.color('r'));
			case 'leader':
			case 'leaderboard':
			case 'l':
				if(!array_index_exists(@args, 1)) { @args[] = 10; }
				if(!is_numeric(@args[1])) { @args[1] = 10 } 
				@results[] = _msg_leaderboard(@leaderboard, @args[1]);
			case 'all':
			case 'players':
				foreach(@k: @v in @countdata) {
					@pName = _getplayerName(@k)['name']
					if(@pName == null) {
						@results[] = _msg_count('nn', @k);
						continue();
					}
					if(@v == 0) {continue(); }
					array_remove_values(@oplayer, @pName);
					@results[] = color(9).@pName.color(7).' -- '.color(12).@v.color(7).' deaths';
				}
				if(array_size(@oplayer) > 0) {
					@results[] = @prefix.color(9).'Reaper'.color(7).' forgot about '.color(12).array_size(@oplayer).color(7).' players!';
				}
			default:
				foreach(@k: @v in @args) {
					#catches valid Minecraft player but never played here.
					if(!array_contains_ic(get_offline_players(), @v)) {
						msg(_msg_count('d', @v));
						return(true);
					}
					@playerID = _getplayerID(@v);
					#catches no UUID - offline Bedrock players may have this issue if not in internal database
					if(@playerID['id'] == null) { die(_msg_count('ni', @v)); }
					foreach(@index: @p in @leaderboard) {
						if(array_contains(@p, @playerID['name'])) { 
							@boardpos = @index + 1
							break();
						}
					}
					@results[] = _msg_count(@countdata[@playerID['id']], @playerID['name'], @boardpos);
				}
			}
			msg(array_implode(@results, '\n'));
			return(true);
		}
));