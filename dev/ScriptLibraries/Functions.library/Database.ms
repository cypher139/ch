######################################################
#
#   CH: Developer debug tools for making CommandHelper scripts..
#   These functions allow for data reading and editing in CH's internal persistance.
#
######################################################

proc _chdb(@action, @option1, @option2) {
@name = 'db'
if(array_size(@arguments) < 2) { msg('[Database] Not enough arguments provided') return(false) }
@args = @arguments[1..]

# @option1 = ''
# @option2 = ''
if(array_index_exists(@args, 0)) { @option1 = @args[0] } 
if(array_index_exists(@args, 1)) { @option2 = @args[1] } 

#action list help
proc _ch_help() {
	msg(color(6).'CommandHelper Database help:  '.color('c').'FOR DEBUG USE ONLY.')
	msg(color('a').'Command usage: <required> [optional]')
	msg(color('a').'/chdb <action> [option1] [option2]')
	msg(color(6).'Actions:')
	msg(color(7).'/chdb clearvalue <player> <value>'.color(4).' - '.color('f').'Clears the specified value in ch\'s persistance file. FOR DEBUG USE ONLY.')
	msg(color(7).'/chdb getvalue <value>'.color(4).' - '.color('f').'Gets the specified value from ch\'s persistance file.')
	msg(color(7).'/chdb hasvalue <player> <value>'.color(4).' - '.color('f').'Returns if the specified value exists.')
	msg(color(7).'/chdb storevalue <value> <data>'.color(4).' - '.color('f').'Stores the data into the specified value in ch\'s persistance file. FOR DEBUG USE ONLY.')
	msg(color(7).'/chdb getvalues <player> [value]'.color(4).' - '.color('f').'Gets the values from the specified key. If none is provided, tries the current player.')
	msg(color(7).'/chdb export <value> <data>'.color(4).' - '.color('f').'Stores the data into the specified value into ch\'s memory persistance, that will be lost on server reboot. FOR DEBUG USE ONLY.')
	msg(color(7).'/chdb import <value>'.color(4).' - '.color('f').'Gets the specified value from ch\'s memory persistance.')
}

@prefix = color(7).'['.color(6).@name.color(7).'] '

switch(@action){
case 'export':
# TODO port store value
	if(@args[0] == 'undo') {
		@undo = import('ch.export.undo', array())
		if(array_size(@undo) == 0) {
			msg(@prefix.color(6).'There is no data to restore.')
		} else {
			export(@key, @data)
			msg(@prefix.color(6).'Restored '.@undo[0].' to :'.@undo[1])
		}
		die()
	}
	export('ch.export.undo', array(@args[0], @args[1..]))
	
	msg(@prefix.color(6).'Export: '.color('d').@args[0])
	export(@args[0], @args[1..])
	@v = import(@args[0])
	msg(@prefix.color(6).'Value '.@args[0].' exported to: '.color(7).@v)

case 'import':
	@v = import(@args[0])
	@arraymsg = ''
	@as = 0
	@color = 7
	if(is_array(@v)) {
		@as = array_size(@v)
		@arraymsg = color(3).' Array size: '.@as
		if(array_index_exists(@args, 1)) {
			if(array_index_exists(@v, @args[1])) {
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
		}
	}
	msg(@prefix.color(6).'Import: '.color('d').@args[0].@arraymsg.color('f').' returned:')
	msg(color(@color).@v)
	if(@as > 9) { msg(@prefix.@arraymsg) }
	
	
case 'clearvalue':
case 'cv':
	if(array_size(@args) == 0) { array_push(@args, player()) }
	msg(@prefix.color(6).'Clear value: '.color('d').@args[0])
	
	if(has_value(@args[0]) == true) {
		clear_value(@args[0])
		if(has_value(@args[0]) == false) { msg(@prefix.color(10).'Successfully cleared value.') }
	} else {
		msg(@prefix.color(12).'That value does not exist.')
	}

case 'getvalue':
case 'gv':
	if(array_size(@args) == 0) { array_push(@args, player()) }
	@v = get_value(@args[0])
	@type = reg_replace('[:]?ms[.]lang[.]', '', typeof(@v))
	@arraymsg = ''
	@as = 0
	@color = 7
	if(is_array(@v)) {
		@as = array_size(@v)
		@arraymsg = color(3).' Array size: '.@as
		if(array_index_exists(@args, 1)) {
			if(array_index_exists(@v, @args[1])) {
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
	msg(@prefix.color(6).'Value: '.color('d').@args[0].color(7).' is_'.@type.@arraymsg)
	msg(color(@color).@v)
	if(@as > 9) { msg(@prefix.@arraymsg) }
	
case 'clearindex':
case 'ci':
	if(array_size(@args) == 0) { array_push(@args, player()) }
	if(!array_index_exists(@args, 0)) { die(@prefix.'Specify a value with an array!') }
	if(!array_index_exists(@args, 1)) { die(@prefix.'Specify index to remove!') }
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
		die(@prefix.color(12).'Value is Not an Array!')
	}
	msg(@prefix.color(6).'Clear Index: '.color(3).@args[1].color('r').' from '.color('d').@args[0])
	msg(@msg)
	

case 'hasvalue':
case 'hv':
	@hv = ''
	if(array_size(@args) == 0) { 
		@hv = color('e').'eh, what value?!'
	} else if(has_value(@args[0]) == true) {
		@hv = color('a').'That value exists!'
	} else {
		@hv = color('c').'That value does not exist.'
	}
	msg(@prefix.@hv)

case 'storevalue':
case 'sv':
# BUGS

# stores t/f as string
	@old = get_value(@args[0])
	if(@args[0] == 'undo') {
		@undo = import('ch.sv.undo', array())
		if(array_size(@undo) == 0) {
			msg(@prefix.color(6).'There is no data to restore.')
		} else {
			store_value(@undo[0], @undo[1])
			msg(@prefix.color(6).'Restored '.color('d').@undo[0].color(6).' to: '.color(7).@undo[1])
		}
		die()
	}
	if(array_size(@args) < 2) { die(@prefix.color('c').'Not enough arguments provided.') }
	@new = @args[1..]
	msg(@prefix.color(6).'Store value: '.color('d').@args[0])
	msg(@prefix.color(6).'Previous: '.color(7).@old)
	export('ch.sv.undo', array(@args[0], @old))
	switch(@args[1]) {
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
		if(!array_index_exists(@args, 2)) { die(@prefix.color('c').'Not enough arguments provided.') }
		if(!is_numeric(@args[2])) { die(@prefix.color('c').'Value is not a number.') }
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
	msg(@prefix.color(6).'Saved '.color(3).@type.color(6).': '.color(7).@v)

case 'getvalues':
case 'gvs':
	if(array_size(@args) == 0) { array_push(@args, player()) }
	@v = get_values(@args[0])
	msg(@prefix.color(6).'Get values: '.color('d').@args[0])
	foreach(@key: @data in @v) {
		msg(color(2).@key.': '.color(7).@data)
	}
	msg(@prefix.color(3).'Total values found: '.array_size(@v))

case 'hasvalues':
case 'hvs':
	if(array_size(@args) == 0) { array_push(@args, player()) }
	@v = get_values(@args[0])
	msg(@prefix.color(6).'Has values: '.color('d').@args[0])
	foreach(@key: @data in @v) {
		msg(color(2).@key)
	}
	msg(@prefix.color(3).'Total values found: '.array_size(@v))
	
case 'clearvalues':
case 'cvs':
	if(array_size(@args) == 0) { die(@prefix.color('c').'Not enough arguments provided.') }
	if(@args[0] == 'undo') {
		@undo = import('ch.cvs.undo', array())
		if(array_size(@undo) == 0) {
			msg(@prefix.color(6).'There is no data to restore.')
		} else {
			foreach(@key: @data in @undo) {
				store_value(@key, @data)
			}
			msg(@prefix.color(6).'Restored '.array_size(@undo).' values.')
		}
		die()
	}
	@v = get_values(@args[0])
	export('ch.cvs.undo', @v)
	msg(@prefix.color(6).'Clear all values: '.color('d').@args[0])
	foreach(@key: @data in @v) {
		clear_value(@key)
		if(has_value(@key) == false) { msg(@prefix.color(6).'Cleared value: '.@key) }
	}
	msg(@prefix.color(1).'Total values cleared: '.array_size(@v))

case 'hasexport':
case 'he':
	@truecount = 0
	@changedcount = 0
	@truemsg = color(8).'None Found'
	@changedmsg = ''
	@falsemsg = ''
	@falsecount = 0
	@v = get_values(@args[0])
	msg(@prefix.color(6).'Has export copy: '.color('d').@args[0])
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
		msg(@key.@result)
	}
	if(@truecount > 0) { @truemsg = color(2).'True: '.@truecount } else if(@changedcount > 0 || @falsecount > 0) { @truemsg = '' }
	if(@changedcount > 0) { @changedmsg = color(14).' Changed: '.@changedcount }
	if(@falsecount > 0) { @falsemsg = color(12).' False: '.@falsecount }
	msg(@prefix.color(7).'Totals: '.@truemsg.@changedmsg.@falsemsg)	
	

default:
	msg(color('red').'['.color(6).@name.color('red').'] '.color('red').'Action not recognized.')
}
}