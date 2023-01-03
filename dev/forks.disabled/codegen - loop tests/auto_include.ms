proc _codegen2(@codelength, @codetype, @codetype2, @looptype) {
#--- User Input Checks
	@string = array()
	if(is_numeric(@codelength) == true) {
		@codelength = integer(@codelength)
	} else if(@codelength == '') { 
		@codelength = 7
	}
	if(@codetype == '') { @codetype = 'full' }
/*	if(x_get_current_thread() != '(CommandHelper) CodeGenerator') {
		if(@codelength > 512) {
			@codelength = '512'
		}
	}
*/
#--- List of Characters
	assign(@lower, array('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'))
	assign(@upper, array('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'))
	assign(@number, array('1','2','3','4','5','6','7','8','9'))
	assign(@full, array_merge(@lower, @upper, @number))
	assign(@symbol, array('!', '@', '#', '$', '%', '^', '&', '*', '+', '-', '/', '\\', '~', '?'))
	assign(@all, array_merge(@full, @symbol))

	if(!is_numeric(@codetype)) { @codetype = to_lower(@codetype) }
	if(!is_numeric(@codetype2)) { @codetype2 = to_lower(@codetype2) }
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
	default:
		return('Invalid code type given (1)')
	}

#--- Character Set 2
	if(@codetype2 !== '') {
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
		default:
			return('Invalid code type given (2)')
		}
		@chars = array_merge(@chars, @chars2)
	}
#--- Generate code
int @starttime = time()

switch(@looptype){
	case 1:
	case 'for':
	default:
		for(@i = 0, @i < @codelength, @i++,
			@string[@i] = @chars[rand(array_size(@chars))]
		)
		@string = array_implode(@string, '')
		return(@string)
	case 2:	
	case 'foreach':
		array_resize(@string, @codelength)
		foreach(@i: @char in @string) {
			@string[@i] = @chars[rand(array_size(@chars))]
		}
		@string = array_implode(@string, '')
		return(@string)
	case 3:
	case 'array_iterate':
	case 'ai':
		array_resize(@string, @codelength)
		array_iterate(@string, closure(@i, @char) {
			@string[@i] = @chars[rand(array_size(@chars))]
		})
		@string = array_implode(@string, '')
		return(@string)
	case 4:
	case 'while':
		array_resize(@string, @codelength)
		@i = 1234567;
		while(@i--) {
		  @string[@i] = @chars[rand(array_size(@chars))]
		}
		@string = array_implode(@string, '')
		return(@string)
	case 5:
	case 'typed_while':
		array_resize(@string, @codelength)
		int @i = 1234567;
		while(@i--) {
		  @string[@i] = @chars[rand(array_size(@chars))]
		}
		@string = array_implode(@string, '')
		return(@string)
	}
}