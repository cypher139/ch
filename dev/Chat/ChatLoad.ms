### Core Startup
export('chatmodifier.name', 'Chat')
@cfgVersion = array(10,0)
# Types
@dev = '-dev'
@envtype = ''
# Path Setup
@pf = '/'
if(get_os() == 'WINDOWS') { @pf = '\\' }
@path = ''
if(in_cmdline_mode()) {
	@envtype = 'cmd'
	@path = pwd()
} else {
	@envtype = 'mc'
	@path = sys_properties()['user.dir'].@pf.'plugins'.@pf.'CommandHelper'.@pf.'LocalPackages'.@pf.import('chatmodifier.name')
}
export('chatmodifier.version', '1.0.'.array_implode(@cfgVersion, '').'-'.@envtype.@dev)
export('Chat.config.dir', file_resolve(@path.@pf.'Configs'))
export('Chat.logs.dir', file_resolve(@path.@pf.'Logs'))
####
# Load Chat configs on server start
_chat_load_config('Server');
_chat_load_config('IPBlacklist');
_register_poll_file('IPBlacklist', '_chat_load_config', import('Chat.config.dir').'/IPBlacklist.yml')