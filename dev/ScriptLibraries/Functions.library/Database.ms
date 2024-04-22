######################################################
#
#   CH: Developer debug tools for making CommandHelper scripts.
#   These functions allow for data reading and editing in CH's internal persistance.
#
######################################################

proc _chdb(@action, @args) {
@name = 'db'
if(!is_array(@args)) {
	@args = parse_args(@args)
}

msg(@action.', a: '.@args)
@option1 = ''
@option2 = ''
if(array_size(@args) == 0) {
	if(function_exists('player')) {
		@args[] = player()
	} else {
		return('[Database] Not enough arguments provided')
	}
}
if(array_index_exists(@args, 0)) { @option1 = @args[0] } 
if(array_index_exists(@args, 1)) { @option2 = @args[1] } 

@prefix = color(7).'['.color(6).@name.color(7).'] '

@player = ''
@otherplayer = ''
if(function_exists('player')) {
	@player = player()
	# Get other player name  
	foreach(@v in @args) {
		if(array_contains_ic(all_players(), @v)) {
			@otherplayer = player(@v)
		}
	}
	@playerID = _getplayerID(@player)
} else {
	@player = 'cmdline'
}
@returnmsg = ''
	
switch(@action){
	case 'export':
	# TODO port store value
		@returnmsg = @prefix.color(6).'Export: '.color(13).@args[0]
		if(@args[0] == 'undo') {
			@undo = import('ch.export.undo', array())
			if(array_size(@undo) == 0) {
				msg(@prefix.color(6).'There is no data to restore.')
			} else {
				export(@undo[0], @undo[1])
				@returnmsg = @prefix.color(6).'Restored '.color(13).@undo[0].color(6).' to: '.color(7).@undo[1]
				return(@returnmsg)
			}
		}
		export('ch.export.undo', array(@args[0], @args[1..]))
		export(@args[0], @args[1..])
		@v = import(@args[0])
		@type = reg_replace('[:]?ms[.]lang[.]', '', typeof(@v))
		@returnmsg = @returnmsg.'\n'.@prefix.color(6).'Saved '.color(3).@type.color(6).': '.color(7).@v
		return(@returnmsg)

	case 'import':
		@v = import(@args[0])
		@arraymsg = ''
		@as = 0
		@as2 = 0
		@color = 7
		if(is_array(@v)) {
			@as = array_size(@v)
			@arraymsg = color(3).' size: '.@as
			if(array_index_exists(@args, 1)) {
				if(@args[1] == '-keys') {
					@v = color(3).'Keys Only: \n'.color(@color).array_keys(@v)
				} else if(array_index_exists(@v, @args[1])) {
					if(is_array(@v[@args[1]])) {
						@as2 = array_size(@v[@args[1]]);
						@arraymsg = @arraymsg.color(3).' index size: '.@as2
					}
					@v = color(3).'Index: '.@args[1].'\n'.color(@color).@v[@args[1]]
				} else {
					@v = color(12).'Index '.@args[1].' was not found!'
				}
			}
		} else {
			switch(@v) {
			case true:
				@color = 10
			case false:
				@color = 12
			case null:
				@color = 8
			default:
				if(is_numeric(@v)) { @color = 9 }
			}
		}
		@type = reg_replace('[:]?ms[.]lang[.]', '', typeof(@v))
		@return = @prefix.color(6).'Import: '.color(13).@args[0].color(7).' is_'.@type.@arraymsg.'\n'.color(@color).@v
		if(@as > 9 || @as2 > 9) { @return = @return.'\n'.@arraymsg }
		return(@return)

	case 'clearvalue':
	case 'cv':
		if(array_size(@args) == 0) { @args[] = @player }
		@returnmsg = @prefix.color(6).'Clear value: '.color(13).@args[0]
		if(has_value(@args[0]) == true) {
			clear_value(@args[0])
			if(has_value(@args[0]) == false) { @returnmsg = @returnmsg.'\n'.@prefix.color(10).'Successfully cleared value.' }
		} else {
			@returnmsg = @returnmsg.'\n'.@prefix.color(12).'That value does not exist.'
		}
		return(@returnmsg)
		
	case 'getvalue':
	case 'gv':
		@v = get_value(@args[0])
		@type = reg_replace('[:]?ms[.]lang[.]', '', typeof(@v))
		@arraymsg = ''
		@as = 0
		@color = 7
		if(is_array(@v)) {
			@as = array_size(@v)
			@arraymsg = color(3).'size: '.@as
			if(array_index_exists(@args, 1)) {
				if(@args[1] == '-keys') {
					@v = color(3).'Keys Only: \n'.color(@color).array_keys(@v)
				} else if(array_index_exists(@v, @args[1])) {
					@v = color(3).'Index: '.@args[1].'\n'.color(@color).@v[@args[1]]
				} else {
					@v = color(12).'Index '.@args[1].' was not found!'
				}
			}
		} else {
			switch(@v) {
			case true:
				@color = 10
			case false:
				@color = 12
			case null:
				@color = 8
			default:
				if(is_numeric(@v)) { @color = 9 }
			}
		}
		@return = @prefix.color(6).'Value: '.color(13).@args[0].color(7).' is_'.@type.@arraymsg.'\n'.color(@color).@v
		if(@as > 9) { @return = @return.'\n'.@arraymsg }
		return(@return)
		
	case 'clearindex':
	case 'ci':
		if(array_size(@args) == 0) { @args[] = @player }
		if(!array_index_exists(@args, 0)) { return(@prefix.'Specify a value with an array!') }
		if(!array_index_exists(@args, 1)) { return(@prefix.'Specify index to remove!') }
		@v = get_value(@args[0])
		@arraymsg = ''
		@msg = ''
		@as = 0
		@color = 7
		if(is_array(@v)) {
			@as = array_size(@v)
			@arraymsg = color(3).' Array size: '.@as
			if(array_index_exists(@v, @args[1])) {
				@msg = color('a').'Removed!'
				array_remove(@v, @args[1])
				store_value(@args[0], @v)
			} else {
				@msg = color(12).'Index was not found!'
			}
		} else {
			return(@prefix.color(12).'Value is Not an Array!')
		}
		return(@prefix.color(6).'Clear Index: '.color(3).@args[1].color('r').' from '.color(13).@args[0].'\n'.@msg)

	case 'exportvalue':
	case 'ex':
		@time = time()
		if(array_size(@args) == 0) { @args[] = @player }
		@v = get_value(@args[0])
		@type = reg_replace('[:]?ms[.]lang[.]', '', typeof(@v))
		if(!array_index_exists(@args, 1)) { @args[] = 'yml' }
		@fileext = ''
		switch(string(@args[1])) {
		case 'raw':
			@nc = 1
		case 'json':
		case 'j':
			@fileext = 'json'
			@v = json_encode(@v)
		case 'yml':
		case 'y':
		default:
			@fileext = 'yml'
			@v = yml_encode(@v, true)
		}
		@return = _write_file('Export_'.@args[0].'_'simple_date('MM-dd-yy_HHmm_', @time).'.'.@fileext, @v, 'Overwrite')
		if(@return == true) {
			@returnmsg = color(10).' was exported'
		} else {
			@returnmsg = color(12).' was not exported'
		}
		return(@prefix.color(6).'Value '.color(13).@args[0].@returnmsg.color(7).' to a file!')
		

	case 'hasvalue':
	case 'hv':
		@hv = ''
		if(array_size(@args) == 0) { 
			@hv = color(14).'eh, what value?!'
		} else if(has_value(@args[0]) == true) {
			@hv = color(10).'That value exists!'
		} else {
			@hv = color(12).'That value does not exist.'
		}
		return(@prefix.@hv)

	case 'storevalue':
	case 'sv':
	# BUGS
	# stores t/f as string
		@old = get_value(@args[0])
		if(@args[0] == 'undo') {
			@undo = import('ch.sv.undo', array())
			if(array_size(@undo) == 0) {
				@returnmsg = @prefix.color(6).'There is no data to restore.'
			} else {
				store_value(@undo[0], @undo[1])
				@returnmsg = @prefix.color(6).'Restored '.color(13).@undo[0].color(6).' to: '.color(7).@undo[1]
			}
			return(@returnmsg)
		}
		if(array_size(@args) < 2) { die(@prefix.color('c').'Not enough arguments provided.') }
		@new = @args[1..]
		@returnmsg = @prefix.color(6).'Store value: '.color(13).@args[0]
		@returnmsg = @returnmsg.'\n'.@prefix.color(6).'Previous: '.color(7).@old
		export('ch.sv.undo', array(@args[0], @old))
		switch(@args[1]) {
		case 'aa':
		case 'aarray':
		case 'associative':
			if(array_index_exists(@args, 2)) {
				if((array_size(@args) - 2) % 2 == 0) {
					@new = array()
					#is Even
					foreach(@index: @v in @args) {
						if(@index % 2 == 1 || @index < 2) { continue() }
						array_set(@new, @v, @args[(@index + 1)])
					}
				} else {
					return(@prefix.color('c').'Not enough array arguments provided.')	
				}
			}
		case 'array':
			if(array_index_exists(@args, 2)) {
				@new = @args[2..]
			} else {
				@new = array()
			}
		case 'string':
			if(array_index_exists(@args, 2)) {
				@new = string(array_implode(@args[2..], ' '))	
			} else {
				@new = string('')
			}
		case 'int':
		case 'integer':
			if(!array_index_exists(@args, 2)) { return(@prefix.color('c').'Not enough arguments provided.') }
			if(!is_numeric(@args[2])) { return(@prefix.color('c').'Value is not a number.') }
			@new = integer(@args[2])
		case 'not':
			@new = !@old
		case 'null':
			@new = null
		default:
			@new = string(array_implode(@args[1..], ' '))
		}
		store_value(@args[0], @new)
		@v = get_value(@args[0])
		@type = reg_replace('[:]?ms[.]lang[.]', '', typeof(@v))
		@returnmsg = @returnmsg.'\n'.@prefix.color(6).'Saved '.color(3).@type.color(6).': '.color(7).@v
		return(@returnmsg)

	case 'getvalues':
	case 'gvs':
		if(array_size(@args) == 0) { @args[] = @player }
		@v = get_values(@args[0])
		@returnmsg = @prefix.color(6).'Get values: '.color(13).@args[0]
		foreach(@key: @data in @v) {
			@returnmsg = @returnmsg.'\n'.color(2).@key.': '.color(7).@data
		}
		@returnmsg = @returnmsg.'\n'.@prefix.color(3).'Total values found: '.array_size(@v)
		return(@returnmsg)

	case 'hasvalues':
	case 'hvs':
		if(array_size(@args) == 0) { @args[] = @player }
		@v = get_values(@args[0])
		@returnmsg = @prefix.color(6).'Has values: '.color(13).@args[0]
		foreach(@key: @data in @v) {
			@returnmsg = @returnmsg.'\n'.color(2).@key
		}
		@returnmsg = @returnmsg.'\n'.@prefix.color(3).'Total values found: '.array_size(@v)
		return(@returnmsg)
		
	case 'clearvalues':
	case 'cvs':
		if(array_size(@args) == 0) { die(@prefix.color('c').'Not enough arguments provided.') }
		if(@args[0] == 'undo') {
			@undo = import('ch.cvs.undo', array())
			if(array_size(@undo) == 0) {
				@returnmsg = @prefix.color(6).'There is no data to restore.'
			} else {
				foreach(@key: @data in @undo) {
					store_value(@key, @data)
				}
				@returnmsg = @prefix.color(6).'Restored '.array_size(@undo).' values.'
			}
			return(@returnmsg)
		}
		@v = get_values(@args[0])
		export('ch.cvs.undo', @v)
		@returnmsg = @prefix.color(6).'Clear all values: '.color(13).@args[0]
		foreach(@key: @data in @v) {
			clear_value(@key)
			if(has_value(@key) == false) { @returnmsg = @returnmsg.'\n'.@prefix.color(6).'Cleared value: '.@key }
		}
		@returnmsg = @returnmsg.'\n'.@prefix.color(1).'Total values cleared: '.array_size(@v)
		return(@returnmsg)

	case 'hasexport':
	case 'he':
		@truecount = 0
		@changedcount = 0
		@truemsg = color(8).'None Found'
		@changedmsg = ''
		@falsemsg = ''
		@falsecount = 0
		@v = get_values(@args[0])
		@returnmsg = @prefix.color(6).'Has export copy: '.color(13).@args[0]
		foreach(@key: @data in @v) {
			@result = ''
			@import = import(@key, '~~~~~~')	
			if(@import == @data) {
				@result = color(2).' true'
				@truecount++
			} else if(@import == '~~~~~~') {
				@falsecount++
				@result = color(12).' false'
			} else { 
				@changedcount++
				@result = color(14).' changed'
			}
			@returnmsg = @returnmsg.'\n'.@key.@result
		}
		if(@truecount > 0) { @truemsg = color(2).'True: '.@truecount }
		if(@changedcount > 0) { @changedmsg = color(14).' Changed: '.@changedcount }
		if(@falsecount > 0) { @falsemsg = color(12).' False: '.@falsecount }
		@returnmsg = @returnmsg.'\n'.@prefix.color(7).'Totals: '.@truemsg.@changedmsg.@falsemsg
		return(@returnmsg)

	case 'copy':
	case 'cp':
		if(!array_index_exists(@args, 1)) { return(@prefix.color(12).'Not enough arguments provided.') }
		@v = get_value(@args[0])
		if(@v == '' || @v == null) {
			return(@prefix.color(14).'Source value is blank.')
		}
		@w = get_value(@args[1])
		if(@w != null) {
			if(!array_index_exists(@args, 2)) {
				@check = import('ch.copy.confirm.'.@args[1])
				if(@check == 'await') {
					export('ch.copy.confirm.'.@args[1], null)
				} else {
					export('ch.copy.confirm.'.@args[1], 'await')
					return(@prefix.color(14).'There is existing data in the destination! Run this command again to confirm the copy operation.')
				}
			}
		}	
		store_value(@args[1], @v)
		return(@prefix.color(7).'Copied '.@args[0].' to '.@args[1])

	default:
		return(color(12).'['.color(6).@name.color(12).'] '.color(12).'Action not recognized.')
	}
}