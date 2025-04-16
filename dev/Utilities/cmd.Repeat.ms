# on Server startup:
export('console.cmd.repeat.show', get_value('console.cmd.repeat.show'))
# get_commands() is a huge array. sort into a single array:
@allcmds = array()
foreach(@v in get_commands()) {
	@allcmds[] = @v['name'];
	array_push_all(@allcmds, @v['aliases']);
}
export('ch.all.commands', @allcmds);

# Monitor player commands and offer a simple repeat command
bind('player_command', array('id': 'cmd.Repeat', 'priority': 'HIGH'), null, @event) {
	@player = _getplayerID(player());
	@cmd = split(' ', @event['command']);
	@dev = import('ch.player.'.@player['id'].'.dev.scripts.cmdrepeat');
	@logtoConsole = import('console.cmd.repeat.show');
	
	#Show command back to the player who issued the command, if permitted to do so.
	@sendcmd = import('player.'.@player['id'].'.cmd.repeat.show')
	if(@sendcmd == null) {
		@sendcmd = get_value('player.'.@player['id'].'.cmd.repeat.show')
		export('player.'.@player['id'].'.cmd.repeat.show', @sendcmd)
	}
	
	#Automatically remove extra slashes not recognized by CH Aliases or Registered Commands.
	@allcmds = import('ch.all.commands')
	#Remove extra slashes and beginning spaces
	if(!is_alias(@cmd[0])) {
		if(!array_contains(@allcmds, reg_replace('^\\/', '', @cmd[0]))) {
			if(@dev == true) { msg('r') }
		# Remove empty command slash
			if(@cmd[0] == '/' && !array_index_exists(@cmd, 1)) {
				if(@dev == true) { msg('r - "/"') }
				cancel()
				die()
			}
		# Space after slash check
			if(reg_count('^\\/*$', @cmd[0]) > 0 && array_index_exists(@cmd, 1)) {
			# Added @cmd[1] check to allow for not calling WorldEdit's "//" command with extra arguments
			# Remove space after slash
				array_remove(@cmd, 0)
				@cmd[0] = '/'.@cmd[0]
				if(@dev == true) { msg('r "/ "') }
				modify_event('command', array_implode(@cmd, ' '))
			}
		# Extra Slashes
			if(reg_count('^\\/\\/+', @cmd[0]) > 0) {
				#Remove extra slash
				@cmd[0] = reg_replace('^\\/\\/+', '\\/', @cmd[0])
				if(@dev == true) {
					msg('now: '.@cmd[0])
					msg('a:  <'.array_implode(@cmd, ' ').'>')
				}
				modify_event('command', array_implode(@cmd, ' '))
			}
		} else {
			# Remove invalid arguments from WorldEdit's "//"
			if(reg_count('^\\/\\/$', @cmd[0]) > 0 && array_index_exists(@cmd, 1)) {
				array_remove(@cmd, 0)
				@cmd[0] = '/'.@cmd[0]
				if(@dev == true) { msg('r-we "/ "') }
				modify_event('command', array_implode(@cmd, ' '))
			}
		}
	}
	@cmdDisplay = array_implode(@cmd, ' ')
	if(@dev == true) { msg('o: '.@event['command'].'    n:'.@cmdDisplay) }
	
	#List cmd used, with CH aliases showing as a different color.
	@ac = 7
	if(is_alias(@cmd[0])) { @ac = 3 } else { @ac = 6 }
	
	@pData = import('player.'.@player['id'].'.last.command')
	if(!is_array(@pData)) { @pData = array() }

	# Convert Number start at 1 to 0
	if(array_index_exists(@cmd, 1)) {
		if(is_numeric(@cmd[1]) && @cmd[1] < 10 && @cmd[1] > 0) { @cmd[1] = @cmd[1] - 1 }
	}
	# Is this a new command or repeat command?
	switch(@cmd[0]){
		case '/.':
		case '/..':
		case '/...':
		case '//.':	
		case '/repeat':
		case '/\'':
			if(@logtoConsole == true) {
				if(array_index_exists(@cmd, 1)) {
					if(is_numeric(@cmd[1]) && @cmd[1] < 9) {
						# Repeat Command
						if(array_index_exists(@pData, @cmd[1])) {
							if(is_alias(@pData[@cmd[1]])) { @ac = 3 } else { @ac = 6 }
							console(color(7).@player['display'].' repeated '.color(@ac).@pData[@cmd[1]], false)
						}
					} else {
					# Repeat options
						console(color(7).@player['display'].' used '.color(@ac).@cmdDisplay, false)
					}
				} else {
				# Find ID from alias
				@cmdID = 0
				@hasdot = reg_count('[.]', @cmd[0])
				if(@hasdot > 0) { @cmdID = @hasdot - 1; }
				if(@cmd[0] == '//.') { @cmdID = 1 }
				# Repeat Last command
					if(array_index_exists(@pData, @cmdID)) {
						if(is_alias(@pData[@cmdID])) { @ac = 3 } else { @ac = 6 }
						console(color(7).@player['display'].' repeated '.color(@ac).@pData[@cmdID], false)
					}
				}
			}			
		default:
		# Save the last command this player used.
			if(@logtoConsole == true) {
				console(color(7).@player['display'].' used '.color(@ac).@cmdDisplay, false)
			}
			if(@sendcmd == 1) { #all cmds
				if(!has_permission(@player['name'], 'commandhelper.alias.see.is.alias')) { @ac = 7 }
				msg('> '.color(@ac).@cmdDisplay)
			}			
			array_insert(@pData, @cmdDisplay, 0)
			if(array_index_exists(@pData, 10)) { array_remove(@pData, 10) }
			export('player.'.@player['id'].'.last.command', @pData)	
	}
}

#------------------------------

register_command('repeat', array(
	'description': 'Repeat your previously used commands.',
	'usage': color(8).'Examples: /repeat, /repeat 2, /., /repeat print, /repeat list',
	'permission': 'commandhelper.alias.repeat',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actsub = array('recent', 'list', 'print');
			@actsubAdmin = array('console', 'allcmds', 'moo');
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
			# Show no options if alias has no a-z characters. At least at first.
				if(reg_count('[A-Za-z]', @alias) <= 0 && length(@arg) <= 0) {
					@usetabs = array('--');
				} else {
				#one option at a time, combine id and commands, cmds first
					@usetabs = @actsub;
					if(has_permission(@sender, 'commandhelper.alias.admin')) { @usetabs = array_merge(@actsub, @actsubAdmin); }
					array_push_all(@usetabs, @actqty);
				}
			}
		#Return tabs
			@areturn = array_filter(@usetabs, closure(@key, @value) {
			return(length(@arg) <= length(@value)
					&& equals_ic(@arg, substr(@value, 0, length(@arg))));
			});
			# console(@atype)
			return(@areturn);
		},
	'aliases': array('.', '\'', '/.', '..', '...'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@player = @sender;
			@uuid = puuid(@player, 'dashless');
			@id = 0;
			@returnMsg = array(12, '?');
			@name = 'Command'
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
		# Select Sub command, or command ID.
			if(array_index_exists(@args, 0)) {
			#Select ID
				if(is_numeric(@args[0])) {
					if(integer(@args[0]) < 0) {
						@id = 0;
					} else if(@args[0] - 1 > 9) {
						msg(color(8).'['.color(9).@name.color(8).'] '.color(7).'Sorry, I don\'t remember that far back!')
						return(false);
					} else { @id = @args[0] - 1 }
					if(@id > 9) { @id = 9; }
				} else {
			#Sub Commands
					switch(to_lower(@args[0])) {
					case 'allcmds':
						if(has_permission(@player, 'commandhelper.alias.admin')) {
							@returnMsg = array(6, 'All Commands and CH Aliases: \n'.color(9).array_implode(import('ch.all.commands', array()), ', '));
						} else {
							@returnMsg = array(12, color(12).'You do not have permission to view that.');
						}
					case 'print':
					case 'show':
					case 'hide':
					case 'pr':
					# Show command printed back in chat?
						@set = get_value('player.'.@uuid.'.cmd.repeat.show');
						if(!is_numeric(@set)) { @set = 0; } 
						if(array_index_exists(@args, 1)) {
							switch(string(to_lower(@args[1])[0])) {
							case 'e':
							case 't':
								@set = 1
							case 'r':
							case 'o':
								@set = 2
							case 'd':
							case 'f':
								@set = 0
							default:
								msg(color(8).'['.color(9).@name.color(8).'] '.color(7).'What option is that!? Use Enable, Disable, or Repeat Only.');
								return(false);
							}
						} else {
							if(@set > 1) { @set = 0 } else {
								@set = !@set;
						# console(@set)
							}
						}
						#alias specific
						switch(string(to_lower(@args[0])[0])) {
						case 's':
							@set = 1;
						case 'h':
							@set = 0;
						}
						store_value('player.'.@uuid.'.cmd.repeat.show', @set);
						export('player.'.@uuid.'.cmd.repeat.show', @set);
						@msgs = array('Any command you run will be '.color(9).'hidden'.color('r').' and not printed back to you in the chat.', 'Any command you run will be '.color(10).'shown'.color('r').' only to you in the chat.', ' The command re-run will be '.color(10).'shown'.color('r').' only to you in the chat.');
						@returnMsg = array(6, @msgs[@set])
					case 'console':
					case 'cc':
						if(has_permission(@player, 'commandhelper.alias.admin')) {
							@set = get_value('console.cmd.repeat.show')
							if(!is_boolean(@set)) { @set = false }
							@set = !@set;
							store_value('console.cmd.repeat.show', @set)
							export('console.cmd.repeat.show', @set)
							@msgs = array('Commands will '.color(12).'NOT broadcast'.color('r').' to the console via /repeat. This does not affect any command broadcast messages other plugins or the vanilla server may provide.', 'All commands will '.color(10).'be broadcast'.color('r').' to the console. This does not affect any command broadcast messages other plugins or the vanilla server may provide.');
							@returnMsg = array(6, @msgs[@set])
						} else {
							@returnMsg = array(12, color(3).'You do not have permissions to use this command option.')
						}
					case 'moo':
						@word = 'Unexpected action.'
						if(array_index_exists(@args, 1)) { @word = @args[1]; }
						@returnMsg = array(9, '\n'.color('r').moo(color(3).@word.color('r')));
					case 'recent':
					case 'r':
					case 'last':
					case 'list':
						@pData = import('player.'.@uuid.'.last.command');
						if(!is_array(@pData)) { 
							@returnMsg = array(12, color('r').'Any Recent Commands were '.color(12).'not found.');
						} else {
							@results = array(color(3).'Your '.array_size(@pData).' most recent Commands:');
							@ac = 7
							@useac = false
							if(has_permission(@player, 'commandhelper.alias.see.is.alias')) { @useac = true; }
							foreach(@k: @v in @pData) {
								if(@useac) {
									if(is_alias(split(' ', @v)[0])) { @ac = 3 } else { @ac = 6 }
								}
								@results[] = color(9).(@k + 1).' > '.color(@ac).@v;
							}	
							@returnMsg = array(6, array_implode(@results, '\n'))
						}
					default:
						@returnMsg = array(12, color(5).'Action specified not recognized.')
					}
					msg(color(8).'['.color(@returnMsg[0]).@name.color(8).'] '.color(7).@returnMsg[1]);
					return(true);
				}
			} else {
				#No Args: Check if count in alias
				@hasdot = reg_count('[.]', @alias)
				if(@hasdot > 0) { @id = @hasdot - 1; }
				if(@alias == '/.') { @id = 1 }
			}
		#Common Args
			@displayid = @id + 1;		
		#Repeat command
			if(@player == 'CONSOLE') { msg(color(8).'['.color(12).@name.color(8).'] '.color(3).'Console cannot repeat commands. Use the Up arrow to repeat a command.'); return(true); }
			@pData = import('player.'.@uuid.'.last.command');
			@showcmd = import('player.'.@uuid.'.cmd.repeat.show');
			if(@showcmd == null) {
				@showcmd = get_value('player.'.@uuid.'.cmd.repeat.show');
				export('player.'.@uuid.'.cmd.repeat.show', @showcmd);
			}
			if(!is_array(@pData)) { msg(color(8).'['.color(12).@name.color(8).'] '.color(12).'Any Recent Commands were not found.'.color('r').' Did you just login? ('.@displayid.')'); return(true); }
			if(!array_index_exists(@pData, @id)) { msg(color(8).'['.color(12).@name.color(8).'] '.color(12).'Recent Command #'.@displayid.' not found.'); return(true); }
			#List cmd used, with CH aliases showing as a different color.
			@ac = 6
			if(is_alias(reg_split(' ', @pData[@id])[0])) { @ac = 3 }
			if(!has_permission(@player, 'commandhelper.alias.see.is.alias')) { @ac = 7 }
			#msg(@pData)
			msg(color(3).'Re-ran your last command. (#: '.@displayid.')');
			if(@showcmd > 0) { msg('> '.color(@ac).@pData[@id]); }
			run_cmd(@pData[@id]);
		}
));