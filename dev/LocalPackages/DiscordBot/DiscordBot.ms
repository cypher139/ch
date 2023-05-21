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
# Databases Startup
	export('DiscordBot.members.ID', get_value('DiscordBot.members.ID'))
	export('DiscordBot.members.names', get_value('DiscordBot.members.names'))
	export('DiscordBot.Leaderboard', get_value('DiscordBot.Leaderboard'))
# Load Discord Configs
	@return8762 = _db_load_config('Discord')
	if(!is_array(@return8762)) { die() }
	@connectmsg = color(6).'['.color(9).'Server'.color(6).'] '.color('a').'Connected'.color(8).' to Discord'
# Connect
	try {
		discord_connect(@return8762['Profile_Name'], closure(){
			#Setup: on every Config Load
			_db_setup(@return8762);
			# Setup: on Initial Start
			set_cron('@daily', closure(){ _discordBot_update_members() });
			set_cron('@weekly', closure(){ _discordBot_backup_members() });
			_db_mc_broadcast(@connectmsg);
		});
	} catch(Exception @ex) {
		console(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord: '.color('r').@ex['message'])
		die()
#		console(@ex)
	}
# Command Line: Start rest of script
	if(in_cmdline_mode()) {
		#Note: DOES include .disabled
		include_dir('Functions', true)
	}
}