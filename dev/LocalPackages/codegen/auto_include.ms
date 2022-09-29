#Random Code Generation
#version 2.1
proc _codegen(@codelength, @codetype, @codetype2) {
#How to use:
# call _codegen(NUMBER, character type 1, character type 2)
# The number determines how long the code is, and the 2 types determine which types of characters you want. 
# Character types: lowercase ("lower"), uppercase ("upper"), number ("num"), or all.

#--- User Input Checks
	@string = array()
	if(@codelength == '' || is_numeric(@codelength) == false){ 
		assign(@codelength, 7)
	}
	if(@codetype == ''){ 
		@codetype = 'full'
	}

#--- List of Characters
	assign(@lower, array(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z))
	assign(@upper, array(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z))
	assign(@number, array(1,2,3,4,5,6,7,8,9))
	assign(@full, array(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,1,2,3,4,5,6,7,8,9))

#--- Character Set 1
	switch(to_lower(@codetype)){
	case 'lower':
	case 'l':
	case 'low':
		@chars = array_get(@lower)
	case 'upper':
	case 'u':
	case 'up':
		@chars = array_get(@upper)
	case 'number':
	case 'n':
	case '#':
	case 'num':
		@chars = array_get(@number)
	case 'full':
	case 'all':
		@chars = array_get(@full)
	default:
		die(color(3).' - '.color(4).'Fail:'.color(3).' Invalid code type given (1)')
	}

#--- Character Set 2
	if(@codetype2 !== '',
		switch(to_lower(@codetype2)){
		case 'lower':
		case 'l':
		case 'low':
			@chars2 = array_get(@lower)
		case 'upper':
		case 'u':
		case 'up':
			@chars2 = array_get(@upper)
		case 'number':
		case 'n':
		case '#':
		case 'num':
			@chars2 = array_get(@number)
		case 'full':
		case 'all':
			@chars2 = array_get(@full)
		default:
			die(color(3).' - '.color(4).'Fail:'.color(3).' Invalid code type given (2)')
		}
		foreach(@chars2, @i,
			array_push(@chars, @i)
		)
	)
#--- Generate code
	for(@i = 0, @i < @codelength, @i++,
		@string[@i] = @chars[rand(array_size(@chars))]
	)
	@string = array_implode(@string, '')

	return(@string)
}