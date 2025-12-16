### Core Startup
@name = 'Chat';
export('chatmodifier.name', @name);
@cfgVersion = array('Server': 13);
export('Chat.cfg.version', @cfgVersion);
# ---------------------
### Version
@dev = import('cypher139.version.dev', '-dev');
@envtype = if(in_cmdline_mode(), 'cmd', 'mc');
@7y6s = import('cypher139.version', array());
@7y6s[@name] = '1.0.'.array_implode(@cfgVersion, '').'-'.@envtype.@dev;
export('cypher139.version', @7y6s);
# ---------------------
# Load Chat configs on server start
_load_yml_config(@name, 'Server', @cfgVersion['Server']);
