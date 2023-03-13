#version 1.3-tmc

# Command Line Prerequisites
if(in_cmdline_mode()) {
	# Libraries
	@pathparent = reg_replace('Chat', '', pwd())
    if(array_contains(ls(@pathparent), 'ScriptLibraries')) {
		include(@pathparent.'/ScriptLibraries/UncaughtException.ms')
        include(@pathparent.'/ScriptLibraries/auto_include.ms')
    }
	# Chat Core Functions
	include('auto_include.ms')
} else {
# Load Server Configs for Minecraft usage
	@return8239 = _chat_load_config('Server')
	if(!is_array(@return8239)) { die() }

	#Format Addon Startup
	export('Chat.format.groups', get_value('Chat.format.groups'))
	export('Chat.format.options', get_value('Chat.format.options'))
	# chf_write('Format_Options_config.yml', yml_encode(get_value('Chat.format.options'), true), OVERWRITE)
	# chf_write('Format_Group_Options_config.yml', yml_encode(get_value('Chat.format.groups'), true), OVERWRITE)
}

		
# Startup Discord Functions
if(function_exists('discord_connect')) {
# Databases Startup
	export('server.Discord.members.ID', get_value('server.Discord.members.ID'))
	export('server.Discord.members.names', get_value('server.Discord.members.names'))
	export('server.Discord.members.leaderboard', get_value('server.Discord.members.leaderboard'))
# Load Discord Configs
	@return8762 =_chat_load_config('Discord')
	if(!is_array(@return8762)) { die() }		
# Connect
	try {
		discord_connect(@return8762['Profile_Name'], closure(){
			_chat_mc_broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color('a').'Connected'.color(8).' to Discord');
			if(get_value('Chat.Discord.Console.receive') == true) {
				export('Chat.Discord.Console.receive', true)
				console('[Chat - Discord] Console receives Chat from Discord Users.', false)
			} else {
				export('Chat.Discord.Console.receive', false)
			}
# Set Bot Activity
			@acttypes8901 = reg_split('of\\s|[,.]\\s(?:or\\s)*', reflect_docs('discord_set_activity', 'description'))[2..]
			foreach(@k: @v in @acttypes8901) {
				if(to_upper(@v) != @v) { array_remove(@acttypes8901, @k) }
			}
			if(array_contains(@acttypes8901, to_upper(@return8762['Activity_Type']))) {
				try {
					discord_set_activity(to_upper(@return8762['Activity_Type']), string(@return8762['Activity_Message']));
				} catch(Exception @ex) {
					_chat_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Bot Activity Message: '.color('r').@ex['message'])
					console(color(4).'['.color(9).'Server'.color(4).'] Bot Activity Message: '.color(12).@ex['classType'].': '.@ex['message'], false)
				}
			} else {
				_chat_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] Selected Bot Activity Type is not supported!')
			}	
		});
	} catch(Exception @ex) {
		console(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord: '.color('r').@ex['message'])
#		console(@ex)
	}
# Second server Connect
	if(@return8762['Use_Second_Server'] == true) {
		try {
			discord_connect('discordCredentials2', closure(){
				_chat_mc_broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord #2');
			})
		} catch(Exception @ex) {
			console(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord #2: '.color('r').@ex['message'])
		}
	}
	
# Command Line: Start rest of script
	if(in_cmdline_mode() == true) {
		# External Scripts
		if(array_contains(ls(@pathparent), 'codegen')) {
			include(@pathparent.'/codegen/auto_include.ms')
		}
		# Load Addons
		#Note: DOES include .disabled
		include_dir('Addons', true)
	}

