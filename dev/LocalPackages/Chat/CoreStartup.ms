#version 1.3-tmc

#Format Addon Startup
export('Chat.format.groups', get_value('Chat.format.groups'))
export('Chat.format.options', get_value('Chat.format.options'))

#console(reflect_docs('discord_set_activity', 'description'))
# PLAYING, STREAMING, LISTENING, WATCHING, CUSTOM_STATUS, or COMPETING.

# chf_write('Format_Options_config.yml', yml_encode(get_value('Chat.format.options'), true), OVERWRITE)
# chf_write('Format_Group_Options_config.yml', yml_encode(get_value('Chat.format.groups'), true), OVERWRITE)
		
#Prerequisites for Discord functions: Connect to Server!
if(function_exists('discord_connect')) {
# Load Discord Configs
	@zrp1mg6 = ''
	try {
		@zrp1mg6 = yml_decode(read(import('Chat.config.dir').'/Discord_config.yml'))
	} catch(IOException @ex) {
		_msgAdmins('[Chat - Discord] Config file could not be read. '.@ex['message'])
		die()
	} catch(FormatException @ex) {
		_msgAdmins('[Chat - Discord] Config file is improperly formatted.') 
		die()
	} catch(Exception @ex) {
		_msgAdmins('[Chat - Discord] There was an error with the Config file. '.@ex['message']) 
		die()
	}
	if(array_contains(@zrp1mg6['Channels_Receive'], 'default')) {
		_msgAdmins('[Chat - Discord] Config file is still using default values. Please configure it in order to use various Discord features.') 
		die()
	}
	export('Chat.config.Discord', @zrp1mg6)
	try {
		discord_connect('discordCredentials', closure(){
			broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color('a').'Connected'.color(8).' to Discord');
			if(get_value('Chat.Discord.Console.receive') == true) {
				export('Chat.Discord.Console.receive', true)
				console('[Chat - Discord] Console receives Chat from Discord Users.', false)
			} else {
				export('Chat.Discord.Console.receive', false)
			}
			discord_set_activity('LISTENING', string('Minecraft'));
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
				broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord #2');
			})
		} catch(Exception @ex) {
			console(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord #2: '.color('r').@ex['message'])
		}
	}
}