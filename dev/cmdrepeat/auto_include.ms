#version 1.2-tmc
export('cmdrepeat.console.command.show', get_value('cmdrepeat.console.command.show'))

# get_commands() is a huge array. sort into a single array:
@allcmds = array()
foreach(@v in get_commands()) {
	array_push(@allcmds, @v['name'])
	array_push_all(@allcmds, @v['aliases'])
}
export('cmdrepeat.all.commands', @allcmds)

if(!is_proc('_getplayerID')) {
	proc _getplayerID(@option1) {
		@pid = array()
		@uuiddata = import('primus.database.UUID')
		if(!is_array(@uuiddata)) { @uuiddata = array() }
		if(reg_count('^~?console$', @option1) > 0) {
			@pid = array('display': 'Console', 'name': '~console', 'id': 'console', 'nick': 'Server Console')
		} else {
			try(
				@pid['id'] = puuid(@option1, 'dashless');
			,@fail,
				#puuid throws exception if not found.
				#if ID not found: search uuid for playername
				foreach(@k: @v in @uuiddata) {
					if(equals_ic(@option1, @v[0])) { 
						@pid['id'] = @k
						break()
					}
				}
			)
			#not sure what to return yet
			if(!array_index_exists(@pid, 'id')) {
				@pid['id'] = null
			}
			#if found in database
			if(array_index_exists(@uuiddata, @pid['id'])) {
				@pid['name'] = @uuiddata[@pid['id']][0]
				@pid['display'] = @uuiddata[@pid['id']][0]
				if(ponline(@pid['name']) == true) {
					@pid['nick'] = pinfo(@pid['name'])[4];
				} else {
					@pid['nick'] = @uuiddata[@pid['id']][2]	
				}
			} else {
			#not found in database
				if(ponline(@option1) == true) {
					@pid['display'] = pinfo(@option1)[0];
					@pid['name'] = pinfo(@option1)[0];
					@pid['nick'] = pinfo(@option1)[4];
				} else {
					@pid['display'] = @option1
					@pid['name'] = @option1
					@pid['nick'] = 'Player Offline'		
				}
			}
		}
		#Bedrock to Java players come in with name ".NAME", remove dot
		if(reg_count('^[\\.].*', @pid['name']) == 1) {
			@pid['display'] = reg_replace('^[\\.]', '', @pid['name'])
		}
		return(@pid)
	}
}