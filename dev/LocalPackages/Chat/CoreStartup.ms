#version 1.3-tmc


#Core Startup
export('chatmodifier.name', 'Chat')
export('chatmodifier.version', '1.0-tmc')

#Format Addon Startup
export('Chat.format.groups', get_value('Chat.format.groups'))
export('Chat.format.options', get_value('Chat.format.options'))

#Configurable options
export('Chat.Discord.Channels.receive', array('general', 'news', 'minecraft', 'MC server', 'voice-chat', 'other', 'cross-server-chat', 'cross-server', 'mctest'))
export('Chat.Discord.Channels.send', array('general', 'minecraft', 'suggestions', 'MC server', 'voice-chat', 'other', 'botspam', 'cross-server-chat', 'cross-server', 'mctest'))
export('Chat.Discord.Roles.colors', array('DiscordPurple': '8a00ff', 'Owner': 'fbff00', 'Modding Extraordinare': 'ff0000', 'Co-Owner': '1bae93', 'Server Admin': 'ba3e39', 'Most Active': 'f1c40f', 'Active Level 3': 'f1c40f', 'Active Level 2': 'f1c40f', 'Active Level 1': 'f1c40f', 'Member': '7289da'))
export('Chat.Discord.Roles.admins', array('DiscordPurple', 'Owner', 'Modding Extraordinare', 'Co-Owner', 'Server Admin'))
export('Chat.Discord.Broadcast.URLs', false)
export('Chat.Discord.Enable.Server2', false)

#		msg(file_resolve('Server.library'))
		
#Prerequisites for Discord functions: Connect to Server!
if(function_exists('discord_connect')) {
	try(
		discord_connect('discordCredentials', closure(){
			broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color('a').'Connected'.color(8).' to Discord');
			if(get_value('Chat.Discord.Console.receive') == true) {
				export('Chat.Discord.Console.receive', true)
				console('[Chat] Console will now receive chat Messages from Discord Users.', false)
			} else {
				export('Chat.Discord.Console.receive', false)
				console('[Chat] Console no longer receives chat Messages from Discord Users.', false)
			}
		#	discord_set_activity('DEFAULT', string('Minecraft'));
		})
		if(import('Chat.Discord.Enable.Server2') == true) {
			discord_connect('discordCredentials2', closure(){
				broadcast(color(6).'['.color(9).'Server'.color(6).'] '.color(7).'Now Connected to Discord #2');
			#	discord_set_activity('DEFAULT', string('Minecraft'));
		})
	}
	,@fail,
		console(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord: '.@fail['message'])
#		console(@fail)
	)
}

#todo:
#discord_set_activity(DEFAULT, 'Minecraft')
#discord_member_get_roles(member) - make name colors somewhat match discord versions
#color() Additionally, any RGB colour can be used in the hex format '#rrggbb'. 