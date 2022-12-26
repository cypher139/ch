#version 1.1-tmc
set_uncaught_exception_handler(closure(@ex){
	@name = 'CH'
	@dev = import('ch.player.'._getplayerID(player())['id'].'.developer')
	msg(color('c').'['.color(6).@name.color('c').'] '.color(7).'An error has occured! Error ID: '.color(9).@ex['stackTrace'][0]['line'].'.'.@ex['stackTrace'][0]['col'])
	msg(color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['message'])
	assign(@msg1, color('c').'['.color(6).@name.color('c').'] '.color('c').@ex['classType'].'! '.color(7).@ex['message'])
	if(@dev == true) {msg(@msg1)}
	console(@msg1, false)
	array_iterate(@ex['stackTrace'], closure(@k, @v) {
		assign(@pathdisplay, reg_split('\\/CommandHelper\\/', @v['file'])[1])
		if(reg_count('/(.[^/]+)\\.library', @pathdisplay) > 0) {
			@pathdisplay = reg_match('/(.[^/]+)\\.library', @pathdisplay)[1].'.library/'.reg_split('\\.library\\/', @pathdisplay)[1]
		}		
		assign(@msg2, color(9).'../'.@pathdisplay.color(7).' Line: '.color('a').@v['line'].'.'.@v['col'])
		console(color('c').'['.color(6).@name.color('c').'] '.@msg2, false)
		if(@dev == true) {msg(@msg2)}
	})
	return(true)
});