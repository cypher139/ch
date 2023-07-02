#!/usr/bin/env /usr/local/bin/mscript
<!
	strict: off;
	name: DiscordBot.ms;
	author: cypher139;
	created: 2023-03-14;
	description: Provides functionality to a connected Discord Bot.;
	requiredExtensions: Core, CHDiscord;
>
#version 1.3-tmc

# Command Line Prerequisites
if(in_cmdline_mode()) {
	@pathparent = reg_replace('[^/]+$', '', pwd())
	# Shared Libraries
    if(array_contains(ls(@pathparent), 'ScriptLibraries')) {
		include(@pathparent.'/ScriptLibraries/UncaughtException.ms')
		include(@pathparent.'/ScriptLibraries/Functions.library/Database.ms')
        include(@pathparent.'/ScriptLibraries/auto_include.ms')
    }
	# External Scripts
	if(array_contains(ls(@pathparent), 'codegen')) {
		include(@pathparent.'/codegen/auto_include.ms')
	}
	# Core Functions
	include('auto_include.ms')
} else {
#Minecraft Prerequisites
	if(!function_exists('write_file') && !function_exists('chf_write')) {
		console(color('c').'[DiscordBot] File writing extensions are not installed! Features such as logs and leaderboard export will not function!', false)
	}
}

# Startup Discord Functions
if(function_exists('discord_connect')) {
# Version Check
	@version = reg_replace('[^0-9]+', '', extension_info()['CHDiscord']['version'])
	if(@version < 290) {
		console(color(12).'[DiscordBot] Installed CHDiscord version is too low, please update!', false);
		die();
	}
# Load DiscordBot Configs
	@return8762 = _db_load_config('Discord');
	if(!is_array(@return8762)) { die() }
	@connectmsg = color(6).'['.color(9).'Server'.color(6).'] '.color('a').'Connected'.color(8).' to Discord'
# Connect
	try {
		discord_connect(@return8762['Profile_Name'], closure(){
			export('DiscordBot.server.ID', xml_read(read(sys_properties()['user.dir'].'/plugins/CommandHelper/prefs/profiles.xml'), '/profiles/profile[@id="'.@return8762['Profile_Name'].'"]/serverId'))
			# Setup Each guild's config
			@ret8901 = _db_load_guilds(discord_get_servers());
			# If successful: Setup initial tasks
			if(@ret8901 == true) {
				set_cron('0 1 * * 0', closure(){ _discordBot_update_members() });
				set_cron('7 0 * * 0', closure(){ _discordBot_backup_members() });
				_write_file(import('DiscordBot.logs.dir').'/Bot-Started.txt', simple_date('MM-dd-yy_HHmm', time()).'\n', 'append');
				_discordBot_set_activity();
				_db_mc_broadcast(@connectmsg, '', true);
			} else {
				discord_disconnect();
				_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] '.color('e').'Guild Configurations were not found.'.color(8).'Disconnected from Discord')
				die()
			}
		});
	} catch(Exception @ex) {
		_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord: '.color('r').@ex['message'])
		die()
#		console(@ex)
	}
# Command Line: Start rest of script
	if(in_cmdline_mode()) {
		#Note: DOES include .disabled
		include_dir('Functions', true)
	}
}