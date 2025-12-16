### Core Startup
@name = 'IPBlacklist';
@cfgVersion = array('Server': 12);
# Types
@dev = import('cypher139.version.dev', '-dev');
@envtype = if(in_cmdline_mode(), 'cmd', 'mc');
# Path Setup
@pf = if(get_os() === 'WINDOWS', '\\', '/');
@path = if(in_cmdline_mode(), pwd(), sys_properties()['user.dir'].@pf.'plugins'.@pf.'CommandHelper'.@pf.'LocalPackages'.@pf.@name);
# ---------------------
### Version
@7y6s = import('cypher139.version', array());
@7y6s[@name] = '1.0.'.array_implode(@cfgVersion, '').'-'.@envtype.@dev;
export('cypher139.version', @7y6s);
# ---------------------
export('IPBlacklist.cfg.version', @cfgVersion);
# ---------------------
# Load configs on server start
@getipblCheck = iclosure(@loadcfg) {
	@serverConfig = import('IPBlacklist.config.Server', array('Write_Blacklist_IP_File': false));
	@kh = import('IPBlacklist.config.IPBlacklist.load.hash', array());
	@update = false;
	if(array_index_exists(@loadcfg, 'Obnoxious')) {
		if(!array_index_exists(@kh, 'o')) { @kh['o'] = sha1(array_keys(@loadcfg['Obnoxious'])); }
		if(sha1(array_keys(@loadcfg['Obnoxious'])) !== @kh['o']) {
			@loadcfg['IP_Blacklist'] = array_merge(@loadcfg['IP_Blacklist'], array_keys(@loadcfg['Obnoxious']));
			@update = true;
			@kh['o'] = sha1(array_keys(@loadcfg['Obnoxious']));
		}
		array_remove(@loadcfg, 'Obnoxious');
	}
	if(array_index_exists(@loadcfg, 'Spam_Player_Names')) {
		if(!array_index_exists(@kh, 's')) { @kh['s'] = sha1(@loadcfg['Spam_Player_Names']); }
		if(sha1(@loadcfg['Spam_Player_Names']) !== @kh['s']) {
			@update = true;
			foreach(@name: @IP in @loadcfg['Spam_Player_Names']) {
				if(is_array(@IP)) {
					@loadcfg['IP_Blacklist'] = array_merge(@loadcfg['IP_Blacklist'], @IP);
				} else {
					@loadcfg['IP_Blacklist'][] = @IP;
				}
			}
			@kh['s'] = sha1(@loadcfg['Spam_Player_Names']);
		}
		array_remove(@loadcfg, 'Spam_Player_Names');
	}
	foreach(@index: @ip in @loadcfg['IP_Blacklist']) {
		if(is_array(@ip)) {
			if(array_size(@ip) > 1) { throw(FormatException, 'Please re-check your IP Blacklist config, as IP entries are misaligned.'); }
			@ip = array_implode(array_keys(@ip), '');
			if(string_ends_with(@ip, ':')) { 
				@ip .= ':';
				# @ip .= 0;
			}
			_msg_Admins('IP Blacklist', 'warning', color(5).'Correcting '.color(9).'array'.color(5).' in IP: '.color(3).@ip, ' ('.@loadcfg['IP_Blacklist'][@index].')');
			@loadcfg['IP_Blacklist'][@index] = @ip;
			@update = true;
		}
	}
	if(@update) {
		export('IPBlacklist.config.IPBlacklist.load.hash',	@kh);
		@loadcfg['IP_Blacklist'] = array_unique(@loadcfg['IP_Blacklist']);
	}
	_ipbl_save_config(@loadcfg, 'block');
	return(@loadcfg);
}
###
_load_yml_config(@name, 'Server', 1);
_load_yml_config(@name, 'IPBlacklist', 0, @getipblCheck);
_load_yml_config(@name, 'UUIDBlacklist');
# ---------------------
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