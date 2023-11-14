#Random Code Generation
#version 2.4.1
proc _codegen(@codelength, @codetype, @codetype2) {
#How to use:
# call _codegen(NUMBER, character type 1, character type 2)
# The number determines how long the code is, and the 2 types determine which types of characters you want. 
# Character types: lowercase ("lower"), uppercase ("upper"), number ("num"), symbol ('sym'), full (all alphanumeric characters) or all (Full + symbols).
# Extra character types: 8bit or 16bit for their respective numbers.

#--- User Input Checks
	@string = array()
	@chars = array()
	@chars2 = array()
	if(is_numeric(@codelength) == true) {
		@codelength = integer(@codelength)
	} else if(@codelength == '') { 
		@codelength = 7
	}
	if(@codetype == '') { @codetype = 'full' }
	# Thread limit: Using main server thread may produce slowdowns for large code numbers.
	if(x_get_current_thread() == 'Server thread') {
		if(@codelength > 512) {
			@codelength = 512
		}
	}
	if(!is_numeric(@codetype)) { @codetype = to_lower(@codetype) }
	if(!is_numeric(@codetype2)) { @codetype2 = to_lower(@codetype2) }
	@numlimit = ''
	
#--- List of Characters
	@lower = array('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
	@upper = array('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
	@number = array('1','2','3','4','5','6','7','8','9')
	@full = array_merge(@lower, @upper, @number)
	@symbol = array('!', '@', '#', '$', '%', '^', '&', '*', '+', '-', '/', '\\', '~', '?')
	@all = array_merge(@full, @symbol)
	
#--- Character Set 1
	switch(@codetype){
	case 'lower':
	case 'l':
	case 'low':
	case 0:
		@chars = array_get(@lower)
	case 'upper':
	case 'u':
	case 'up':
	case 1:
		@chars = array_get(@upper)
	case 'number':
	case 'n':
	case '#':
	case 'num':
	case 2:
		@chars = array_get(@number)
	case 'full':
	case 'f':
	case 3:
		@chars = array_get(@full)
	case 'swear':
	case 'symbol':
	case 'sym':
	case 's':
	case 4:
		@chars = array_get(@symbol)
	case 'all':
	case 'a':
	case 5:
		@chars = array_get(@all)
	case 'n8':
	case '8bit':
		array_push(@number, 0)
		@chars = @number
		@codelength = 3
		@numlimit = array(2,5,5)
	case 'n16':
	case '16bit':
		array_push(@number, 0)
		@chars = @number
		@codelength = 5
		@numlimit = array(6,5,5,3,5)
	default:
		return('Invalid code type given (1)')
	}

#--- Character Set 2
	if(@codetype2 != '' && !is_array(@numlimit)) {
		switch(@codetype2){
		case 'lower':
		case 'l':
		case 'low':
		case 0:
			@chars2 = array_get(@lower)
		case 'upper':
		case 'u':
		case 'up':
		case 1:
			@chars2 = array_get(@upper)
		case 'number':
		case 'n':
		case '#':
		case 'num':
		case 2:
			@chars2 = array_get(@number)
		case 'full':
		case 'f':
		case 3:
			@chars2 = array_get(@full)
		case 'swear':
		case 'symbol':
		case 'sym':
		case 's':
		case 4:
			@chars2 = array_get(@symbol)
		case 'all':
		case 'a':
		case 5:
			@chars2 = array_get(@all)
		case 'n8':
		case '8bit':
		case 'n16':
		case '16bit':
			@chars2 = 'Not supported as type #2'
		default:
			return('Invalid code type given (2)')
		}
		if(is_array(@chars2)) { @chars = array_merge(@chars, @chars2) }
	}
	
#--- Generate code
	array_resize(@string, @codelength)
	foreach(@i: @char in @string) {
		if(is_array(@numlimit)) {
			@string[@i] = @chars[rand(@numlimit[@i])]
		} else {
			@string[@i] = @chars[rand(array_size(@chars))]
		}
	}
	@string = array_implode(@string, '')
	return(@string)
}