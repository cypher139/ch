#version 1.3-tmc

#Command Line Prerequisites
if(in_cmdline_mode() == true) {
	#Libraries
	@pathparent = reg_replace('Chat', '', pwd())
    if(array_contains(ls(@pathparent), 'ScriptLibraries')) {
		include(@pathparent.'/ScriptLibraries/UncaughtException.ms')
        include(@pathparent.'/ScriptLibraries/auto_include.ms')
    }
	#Chat Core Functions
	include('auto_include.ms')
}

#Format Addon Startup
export('Chat.format.groups', get_value('Chat.format.groups'))
export('Chat.format.options', get_value('Chat.format.options'))

#console(reflect_docs('discord_set_activity', 'description'))
# PLAYING, STREAMING, LISTENING, WATCHING, CUSTOM_STATUS, or COMPETING.

# chf_write('Format_Options_config.yml', yml_encode(get_value('Chat.format.options'), true), OVERWRITE)
# chf_write('Format_Group_Options_config.yml', yml_encode(get_value('Chat.format.groups'), true), OVERWRITE)


# Load Server Configs
@b7xbc2t = ''
try {
	@b7xbc2t = yml_decode(read(import('Chat.config.dir').'/Server_config.yml'))
} catch(IOException @ex) {
	_chat_msg_Admins('[Chat - Server] Config file could not be read. '.@ex['message'])
	die()
} catch(FormatException @ex) {
	_chat_msg_Admins('[Chat - Server] Config file is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']), true) 
	die()
} catch(Exception @ex) {
	_chat_msg_Admins('[Chat - Server] There was an error with the Config file. '.@ex['message']) 
	die()
}
if(array_index_exists(@b7xbc2t, 'Not_Configured')) {
	_chat_msg_Admins('[Chat - Server] Server Config file is still using the default values. Please configure it to your needs!')
	die()
}
export('Chat.config.Server', @b7xbc2t)


		
#Prerequisites for Discord functions: Connect to Server!
if(function_exists('discord_connect')) {
# Database Startup
	export('server.Discord.members.ID', get_value('server.Discord.members.ID'))
	export('server.Discord.members.names', get_value('server.Discord.members.names'))
	export('server.Discord.members.leaderboard', get_value('server.Discord.members.leaderboard'))
# Load Discord Configs
	@zrp1mg6 = ''
	try {
		@zrp1mg6 = yml_decode(read(import('Chat.config.dir').'/Discord_config.yml'))
	} catch(IOException @ex) {
		_chat_msg_Admins('[Chat - Discord] Config file could not be read. '.@ex['message'])
		die()
	} catch(FormatException @ex) {
		_chat_msg_Admins('[Chat - Discord] Config file is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']), true)
		die()
	} catch(Exception @ex) {
		_chat_msg_Admins('[Chat - Discord] There was an error with the Config file. '.@ex['message']) 
		die()
	}
	if(array_contains(@zrp1mg6['Channels_Receive'], 'default')) {
		_chat_msg_Admins('[Chat - Discord] Config file is still using default values. Please configure it in order to use various Discord features.') 
		die()
	}
	if(@zrp1mg6['VC_Role_ID'] == 123) {
		_chat_msg_Admins('[Chat - Discord] Voice Chat Config is still using defaults. Please configure it in order to use the VC Role Ping feature.') 
	}
	if(@zrp1mg6['Welcome_Text_Channel_Name'] == 'default') {
		_chat_msg_Admins('[Chat - Discord] Member Config is still using defaults. Please configure it in order to use the Welcome Message feature.') 
	}
	if(array_contains(@zrp1mg6['CS_Server_1_Channels'], 'default')) {
		_chat_msg_Admins('[Chat - Discord] Cross server Config is still using default values. Please configure it in order to use Cross-Server chat features.') 
	}
	
	export('Chat.config.Discord', @zrp1mg6)
	try {
		discord_connect(@zrp1mg6['Profile_Name'], closure(){
			_chat_mc_broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color('a').'Connected'.color(8).' to Discord');
			if(get_value('Chat.Discord.Console.receive') == true) {
				export('Chat.Discord.Console.receive', true)
				console('[Chat - Discord] Console receives Chat from Discord Users.', false)
			} else {
				export('Chat.Discord.Console.receive', false)
			}
			discord_set_activity('PLAYING', string('Minecraft'));
		})
/*
		if(import('Chat.Discord.Has.Started') == false) {
			_send_discord_message('I\'m Alive once more, come join the Minecraft server!', 'Server')
			export('Chat.Discord.Has.Started', true)
		}
*/
	} catch(Exception @ex) {
		console(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord: '.color('r').@ex['message'])
#		console(@ex)
	}
	
	if(@zrp1mg6['Use_Second_Server'] == true) {
		try {
			discord_connect('discordCredentials2', closure(){
				_chat_mc_broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord #2');
			})
		} catch(Exception @ex) {
			console(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord #2: '.color('r').@ex['message'])
		}
	}
	
	#Command Line: Start rest of script
	if(in_cmdline_mode() == true) {
		# External Scripts
		if(array_contains(ls(@pathparent), 'codegen')) {
			include(@pathparent.'/codegen/auto_include.ms')
		}
		# Load Addons
		#Note: DOES include .disabled
		include_dir('Addons', true)
	}
}