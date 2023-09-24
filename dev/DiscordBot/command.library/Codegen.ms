#version 1.0-tmc

proc _discordBot_cmd_codegen(@discord, @args) {	
	switch(rand(1,11)){
	case 4:
		return(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/password_strength.png'))))
	default:
		if(is_proc('_codegen')) {	
			@dmCode = @discord['UseDM']
			@channel = @discord['SendChannel']
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
			x_new_thread('CodeGenerator', closure(){
				@code = _codegen(@length, @type1, @type2)
				if(@dmCode == 'dm') {
					@prefix = 'Randomly Generated code: \n'
					@channel = @discord['userid']
				}
				_discordBot_send_message(@prefix.@code, @discord['serverid'], 'discord', @channel, @dmCode)
			});
			return(true)
		} else { return('NoCmd') }
	}
}

proc _discordBot_cmd_codegen_pl(@discord, @args) {	
	switch(rand(1,4)) {
		case 2:
		if(is_proc('_codegen')) {	
			@results = array()		
			array_resize(@results, rand(5, 15)) 
			x_new_thread('CodeGenerator', closure(){
				foreach(@k: @v in @results) {
					@results[@k] = _codegen(rand(6, 21), rand(0, 5), rand(0, 5))
				}
				_db_msg_Console(@results, @discord['serverid'], 'debug')
				@service = array_get_rand(array('your mom', '<redacted>', 'FTP'))
				_discordBot_send_message('Passwords for '.@service.': '.array_implode(@results, '\n --: '), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
			});	
		} else {
			return('NoCmd')
		}
		case 3:
			_discordBot_send_message(array('embeds': array(array('image': 'https://imgs.xkcd.com/comics/security.png'))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
		default:
			_discordBot_send_message(array('embeds': array(array('image': 'https://media.tenor.com/KDm053TyIgEAAAAC/portal.gif'))), @discord['serverid'], 'discord', @discord['SendChannel'], @discord['UseDM'])
	}
}

#Add Commands to List
@c3lx = import('DiscordBot.Command.List', array())
@mIu7 = array(	
	'codegen': array('alias': array('code', 'gibberish', 'gibberishgenerator', 'password'), 'admin': false, 'category': 'Utility', 'cmd': closure(@discord, @args) { return(_discordBot_cmd_codegen(@discord, @args)); }),
	'listpasswords': array('alias': array('passwords', 'lp', 'passwordlist'), 'admin': false, 'category': 'Fun', 'cmd': closure(@discord) { return(_discordBot_cmd_codegen_pl(@discord)); })
);
@c3lx = array_merge(@c3lx, @mIu7)
export('DiscordBot.Command.List', @c3lx)