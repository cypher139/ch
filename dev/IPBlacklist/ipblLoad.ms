### Core Startup
@cfgVersion = array(12,0,0);
# Types
@dev = '-dev';
@envtype = '';
# Path Setup
@pf = '/';
if(get_os() === 'WINDOWS') { @pf = '\\'; }
@path = '';
if(in_cmdline_mode()) {
	@envtype = 'cmd';
	@path = pwd();
} else {
	@envtype = 'mc';
	@path = sys_properties()['user.dir'].@pf.'plugins'.@pf.'CommandHelper'.@pf.'LocalPackages'.@pf.'IPBlacklist';
}
export('ipbl.version', '1.0.'.array_implode(@cfgVersion, '').'-'.@envtype.@dev);
export('ipbl.cfg.version', @cfgVersion);
export('ipbl.config.dir', file_resolve(@path.@pf.'Configs'));
export('ipbl.logs.dir', file_resolve(@path.@pf.'Logs'));
####
# Load configs on server start
_ipbl_load_config('Server');
_ipbl_load_config('IPBlacklist');
_ipbl_load_config('UUIDBlacklist');

# Conversions:
if(has_value('Chat.server.bl.known.ASNs')) {
	store_value('Server.ipbl.known.ASNs', get_value('Chat.server.bl.known.ASNs'));
	store_value('Server.ipbl.known.mc.ASNs', get_value('Chat.server.bl.known.mc.ASNs'));
	clear_value('Chat.server.bl.known.ASNs');
	clear_value('Chat.server.bl.known.mc.ASNs');
	clear_value('Chat.IPBlacklist.scan.results');
	clear_value('Chat.IPBlacklist.Publish.count');
	clear_value('Chat.IPBlacklist.Publish.hash');
	clear_value('Chat.debug.results.asn');
}