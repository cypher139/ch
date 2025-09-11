<!
	strict: on;
	author: CypherNova139;
	created: 1/5/2016;
	description: Create randomly generated codes, useful for secondary authentications;
>
export('codegen.version', '3.0');
proc _codegen_help() {
	@return = array(
	color(6).'CodeGen!     Version: '.import('codegen.version'),
	color(7).'/codegen'.color(3).' - '.color(15).'Prints a randomly generated code. Defaults to a code 7 characters in length using uppercase, lowercase, and numbers.',
	color(10).'Command usage: <required> [optional]',
	color(3).'/codegen [length] [Character type 1] [Character type 2]',
	color(3).' - '.color(15).' You can specify how many characters the code should be, and specify the types of characters.',
	color(3).' - '.color(15).' Character types: lowercase ("lower"), uppercase ("upper"), number ("num"), symbol ("sym"), full (all alphanumeric characters) or all (full + symbols).',
	color(3).' - '.color(15).' Extra character types: 8bit or 16bit for their respective numbers.',
	);
	return(array_implode(@return, color('r').'\n'));
}

register_command('codegen', array(
	'description': 'Create and print randomly generated codes.',
	'usage': color(8).'Examples: /codegen, /codegen lower number, /codegen 100 number',
	'permission': 'commandhelper.alias.codegen',
	'noPermMsg': color(6).'New Codes are not available yet. Come back another time!',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actplayers = all_players();
			@atype = 0;
			@actqty = array('help');
			for(@i = 1, @i <= 100, @i++) {
				@actqty[] = @i;
			}
			@actcmds = array('Lower', 'Upper', 'Number', 'Symbol', 'All', '8bit', '16bit');
			@usetabs = array('<No further arguments>');
		#Compute Tabs for each arg position
			switch(@argPos) {
			case 0:
		#Length
				@usetabs = @actqty;
				@atype = 'a0';
			case 1:
		#Options
				@usetabs = @actcmds;
				@atype = 'a1';
			case 2:
			case 3:
			case 4:
			case 5:
				array_remove_values(@actcmds, '8bit');
				array_remove_values(@actcmds, '16bit');
				@usetabs = @actcmds;
				switch(@arg[-1]){
				case 'n8':
				case '8bit':
				case 'n16':
				case '16bit':
					@usetabs = array('<Selected type does not support further arguments>');
				}
				@atype = 'a2';
			}
		#Return tabs
			@areturn = array_filter(@usetabs, closure(@key, @value) {
			return(length(@arg) <= length(@value)
					&& equals_ic(@arg, substr(@value, 0, length(@arg))));
			});
			# console(@atype);
			return(@areturn);
		},
	'aliases': array('code'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@name = 'CodeGen';
			@cmd = '';
			if(@sender == 'CONSOLE') { @sender = '~console'; }
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
			if(array_index_exists(@args, 0)) { @cmd = @args[0]; }
		#Sub Commands
			if(!has_permission(@sender, 'commandhelper.alias.codegen')) { 
				msg(color(12).'['.color(7).@name.color(12).'] '.color(7).'You do not have permission to use this command.'); 
				return(true);
			}	
			switch(@cmd) {
			case 'help':
			case 'info':
			case '?':
				msg(_codegen_help());
				return(true);
			default:
				@length = 7;
				@slice = 0;
				if(array_index_exists(@args, 0)) {
					if(is_numeric(@args[0])) { 
						@length = @args[0];
						@slice = 1;
					}
				}
				x_new_thread('CodeGenerator', closure(){
					@code = _codegen(@length, @args[cslice(@slice, array_size(@args) - 1)]);
					msg(color(7).'['.color(6).'CodeGen'.color(7).'] '.color(7).'Random generated code at '.simple_date('HH:mm:ss.S z').':');
					msg(@code);
				});
				return(true);
			}
		}
));