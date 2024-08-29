#!/usr/bin/env /usr/local/bin/mscript
<!
	strict: off;
	name: StartApp.ms;
	author: cypher139;
	created: 2023-03-14;
	description: Provides functionality to a connected Discord App.;
	requiredExtensions: Core, CHDiscord;
>
# ---------------------
### App Version Numbers
#App, Server configs:
@cfgVersion = array(10,12)
# CHDiscord extension
@requiredVersion = array(2, 15, 0)
# Types
@dev = '-dev'
@envtype = ''
# ---------------------
### Startup Prerequisites
# Path Setup
@pf = '/'
if(get_os() == 'WINDOWS') { @pf = '\\' }
@path = ''
if(in_cmdline_mode()) {
	@envtype = 'cmd'
	@path = pwd()
} else {
	@envtype = 'mc'
	@path = sys_properties()['user.dir'].@pf.'plugins'.@pf.'CommandHelper'.@pf.'LocalPackages'.@pf.'DiscordBot'
}
export('DiscordBot.version', '1.0.'.array_implode(@cfgVersion, '').array_implode(@requiredVersion, '').'-'.@envtype.@dev)
export('DiscordBot.config.dir', file_resolve(@path.@pf.'Configs'))
export('DiscordBot.logs.dir', file_resolve(@path.@pf.'Logs'))
export('DiscordBot.test.dir', time())
export('DiscordBot.cfg.version', @cfgVersion);
# export('DiscordBot.cmd.dir', file_resolve(@path.@pf.'command.library'))
# Version Check
if(extension_exists('CHDiscord')) {
	@version = reg_replace('[^0-9.]+', '', extension_info()['CHDiscord']['version'])
		foreach(@place: @num in split('.', @version)) {
		if(@num < @requiredVersion[@place]) {
			console(color(12).'[DiscordBot] Installed CHDiscord version is too low. Update to '.array_implode(@requiredVersion, '.'), false);
			die();
		}
	}
}
# Command Line specific
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
#Minecraft specific
	if(!function_exists('write_file') && !function_exists('chf_write')) {
		console(color(12).'[DiscordBot] File writing extensions are not installed! Features such as logs and leaderboard export will not function!', false)
	}
}
# ---------------------
### Startup Discord Functions
if(function_exists('discord_connect') && function_exists('discord_member_info') && function_exists('discord_get_servers') && function_exists('discord_set_allowed_mentions')) {
# Load DiscordBot Configs
	@return8762 = _db_load_config('Bot', true);
	if(!is_array(@return8762)) { die() }
	@connectmsg = color(6).'['.color(9).'Server'.color(6).'] '.color(10).'Connected'.color(8).' to Discord'
# Connect
	try {
		discord_connect(@return8762['Profile_Name'], closure(){
			# Setup Each guild's config
			@ret8901 = _db_load_guilds(discord_get_servers());
			# If successful: Setup initial tasks
			if(@ret8901 == true) {
				set_cron('0 1 * * 0,3', closure(){ _discordBot_update_members() });
				set_cron('7 0 * * 0', closure(){ _discordBot_backup_guild_data() });
				set_cron('1 0 * * *', closure(){ _discordBot_clean_cache() });
				@ret8902 = discord_member_info(@return8762['Bot_ID'])
				export('DiscordBot.Bot.Info', @ret8902)
				_write_file(import('DiscordBot.logs.dir').'/Bot-Started.txt', simple_date('MM-dd-yy_HHmm', time()).'\n', 'append');
				_discordBot_set_activity();
				foreach(@k: @v in @return8762['Allowed_Mentions']) {
					@w = to_upper(@v)
					if(array_contains(array('USER', 'ROLE', 'EVERYONE'), @w)) {
						@return8762['Allowed_Mentions'][@k] = @w
					} else {
						array_remove(@return8762['Allowed_Mentions'], @k)
					}
				}
				if(array_index_exists(@return8762['Allowed_Mentions'], 0)) {
					discord_set_allowed_mentions(@return8762['Allowed_Mentions']);
				}
				#AutoSave: store changes to certain database keys in RAM to the database every few minutes. ex. Leaderboard data.
				# - Leaderboard: Also publishes json to logs. A webserver can pull from this for an online leaderboard display.
				set_interval(@return8762['AutoSave_Wait'], 100000, closure(){ _discordBot_db_autosave() });
				_db_mc_broadcast(@connectmsg, '', true);
			} else {
				discord_disconnect();
				_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] '.color(14).'Guild Configurations were not found.'.color(8).'Disconnected from Discord')
				die();
			}
		});
	} catch(Exception @ex) {
		_db_msg_Admins(color(4).'['.color(9).'Server'.color(4).'] '.color(4).'NOT Connected to Discord: '.color('r').@ex['message'])
		die();
	}
# Command Line: Start rest of script
	if(in_cmdline_mode()) {
		#Note: DOES include .disabled
		include_dir('Functions', true)
	}
}