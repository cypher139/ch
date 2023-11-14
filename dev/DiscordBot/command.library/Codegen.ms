proc _discordBot_cmd_codegen(@discord, @args) {	
	switch(rand(1,11)){
	case 4:
		return(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/password_strength.png'))))
	default:
		if(is_proc('_codegen')) {
			@time = time()
			@id = _codegen(7, 0, 1)
			@dmCode = @discord['UseDM']
			@type1 = ''
			@type2 = ''
			@length = null
			@prefix = ''
			if(array_index_exists(@args, 0)) {
				foreach(@i: @arg in @args) {
					if(reg_count('^[-]?[PpDd]', @arg) > 0) {
						@dmCode = 'dm'
						continue()
					}
					#if arg more than 5: set length
					if(is_numeric(@arg)) {
						if(@arg < 0) { continue() }
						if(@arg > 5) {
							if(@arg > 512) { @length = 512 } else { @length = @arg }
							continue()
						}
					}
					if(@type1 == '') {
						@type1 = @arg
					} else if(@type2 == '') {
						@type2 = @arg
					} else if(@length != null) {
						break()
					}
				}
			}
			if(@length == null) { @length = 8 }
			if(@type1 == '') { @type1 = 'full' }			
			x_new_thread(@id.@time, closure(){
				@code = _codegen(@length, @type1, @type2)
				export(@id.@time, @code)
			});
			x_thread_join(@id.@time, 7000)
			@code = import(@id.@time)
			if(@code == null) { return('Error') }
			if(@dmCode == 'dm') {
				@prefix = 'Randomly Generated code: \n'
			}
			export(@id.@time, null)
			return(array('content': @prefix.'`'.@code.'`', 'dm': @dmCode))
		} else { return('NoCmd') }
	}
}

proc _discordBot_cmd_codegen_pl(@discord, @args) {	
	switch(rand(1,4)) {
		case 2:
		if(is_proc('_codegen')) {
			@time = time()
			@id = _codegen(7, 0, 1)
			x_new_thread(@id.@time, closure(){
				@results = array()		
				array_resize(@results, rand(5, 15)) 
				foreach(@k: @v in @results) {
					@results[@k] = _codegen(rand(6, 21), rand(0, 5), rand(0, 5))
				}
				export(@id.@time, @results)
			});	
			x_thread_join(@id.@time, 7000)
			@results = import(@id.@time)
			if(!is_array(@results)) { return('Error') }
			_db_msg_Console(@results, @discord['serverid'], 'debug')
			@service = array_get_rand(array('your mom', '<redacted>', 'FTP'))
			export(@id.@time, null)
			return('Passwords for '.@service.': \n --: '.array_implode(@results, '\n --: '))
		} else {
			return('NoCmd')
		}
		case 3:
			return(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/security.png'))))
		default:
			return(array('embeds': array(array('image': 'https://media.tenor.com/KDm053TyIgEAAAAC/portal.gif'))))
	}
}

#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'codegen': array('alias': array('code', 'gibberish', 'generatecode', 'password'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_codegen(@discord, @args)); }),
	'listpasswords': array('alias': array('passwords', 'lp', 'passwordlist'), 'admin': false, 'category': 'Fun', 'cmd': closure(@discord) { return(_discordBot_cmd_codegen_pl(@discord)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)