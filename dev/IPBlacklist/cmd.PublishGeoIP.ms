# Generate reports about which ASNs and countries are listed in the IP Blacklist file, using the GeoIP shell command lookup.
proc _geoip_report_send_msg(@msg, @player, @msgConsole) {
	if(!@player) { @player = '~console'; }
	@s = '';
	if(@msgConsole) { @s = ' '; }
	console(@msg.@s.@msgConsole, false);
	if(@player != '~console' && function_exists('msg')) { msg(@msg); }
}
proc _geoip_asn_report(boolean @scan = true, boolean @consoleReport = false, boolean @gencfg = true) {
x_new_thread('GeoIPASNReport'.time(), closure(){
#threaded due to shell call for single IP would process ~25 IPs/second
	@prefix = color(8).'['.color(1).'GeoIP Report'.color(8).']'.color('r').' '
	@prefixError = color(12).'['.color(7).'GeoIP Report'.color(12).']'.color('r').' '
	@player = '~console'
	@reportmsg = array();
	if(function_exists('player')) { @player = player(); }
	@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()));
	@extFileList = array('Source1.txt');
	if(function_exists('list_files')) { @extFileList = list_files(import('ipbl.config.dir')) }
	@checkIP = @blacklistIP['IP_Blacklist'][];
	@sourceCount = 1;
	foreach(@num: @filename in @extFileList) {
		if(reg_count('^[Ss]ource[0-9][.]txt$', @filename) < 1) { continue() }
		@extSource = array();
		try {
			@extSource = parse_args(replace(replace(read(import('ipbl.config.dir').'/'.@filename), '\r', ''), '\n', ' '));
		} catch(IOException @ex) {
			_geoip_report_send_msg(@prefixError.color(12).'ext source file "'.@filename.'" could not be read. ', @player, @ex['message']);
			@extSource = array();
		} catch(FormatException @ex) {
			_geoip_report_send_msg(@prefixError.color(12).'ext source file "'.@filename.'" is improperly formatted.', @player, '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']));
			@extSource = array();
		} catch(Exception @ex) {
			_geoip_report_send_msg(@prefixError.color(12).'ext source file "'.@filename.'" has an error. ', @player, @ex['message']);
			@extSource = array();
		}
		if(array_size(@extSource) > 1) {
			foreach(@e in @extSource) {
				if(string_starts_with(@e, '#')) { array_remove_values(@extSource, @e) }
			}
			@checkIP = array_merge(@checkIP, @extSource);
			@sourceCount++;
		}
	}
	@checkIP = array_sort(array_unique(@checkIP, false), 'REGULAR');
	@serverConfig = import('ipbl.config.Server');
	@writeDir = import('ipbl.logs.dir');
	@gitpublish = true
	if(array_index_exists(@serverConfig, 'Git_Dir')) { @writeDir = @serverConfig['Git_Dir'];} else { @gitpublish = false }
	@time = time();
	@raw = false
	@ipdb = array()
	@asnlist = array()
	@asnc = array()
	@asnrc = array()
	@asnip = array()
	@ipcount = 0
	@asnnicks = array()
	@asnipover10 = array()
	@ablasnList = array()
	@v6ip = array()
	try {
		@asnnicks = yml_decode(read(import('ipbl.config.dir').'/ASN_ISP_Names.yml'))
	} catch(IOException @ex) {
		_geoip_report_send_msg(@prefixError.color(12).'ASN ISP Nicknames file could not be read. ', @player, @ex['message']);
	} catch(FormatException @ex) {
		_geoip_report_send_msg(@prefixError.color(12).'ASN ISP Nicknames file is improperly formatted.', @player, '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']));
	} catch(Exception @ex) {
		_geoip_report_send_msg(@prefixError.color(12).'There was an error with the ASN ISP Nicknames file. ', @player, @ex['message']);
	}
	@mancfg = ''
	@mancfgArray = array('Spam_Player_Names': array());
	try {
		@mancfg = read(import('ipbl.config.dir').'/Template-IP.yml');
		@mancfgArray = yml_decode(@mancfg);
	} catch(IOException @ex) {
		_geoip_report_send_msg(@prefixError.color(12).'Template-IP Config file could not be read. ', @player, @ex['message']);
		die();
	} catch(FormatException @ex) {
		_geoip_report_send_msg(@prefixError.color(12).'Template-IP Config file is improperly formatted.', @player, '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']));
		die();
	} catch(Exception @ex) {
		_geoip_report_send_msg(@prefixError.color(12).'There was an error with the Template-IP Config file. ', @player, @ex['message']);
		die();
	}
	@spnList = array();
	@spasnList = array();
	foreach(@spname: @spIPs in @mancfgArray['Spam_Player_Names']) {
		if(is_array(@spIPs)) {
			array_push_all(@spnList, @spIPs);
		} else {
			@spnList[] = @spIPs;
		}
	}
	@prevcount = get_value('ipbl.Publish.count')
	if(array_size(@checkIP) == @prevcount && @scan == true) { 
		_geoip_report_send_msg(@prefix.'Count of blacklisted IPs is the same as the last run, stopping.', @player);
		return(false);
	}
	if(@scan == true) {
		# _write_file(@writeDir.'/checkip.json', json_encode(@checkIP), 'Overwrite');
		_geoip_report_send_msg(@prefix.color(8).'Processing GeoIP report data:', @player);
		@ipdb = _geoip_lookup(@checkIP);
		if(!is_array(@ipdb)) { 
			_geoip_report_send_msg(@prefixError.color(8).'An error occured with the Geo IP scanner, see logs.', @player, 'Data received:\n'.@ipdb);
			die();
		}
		@scReport = integer(array_size(@checkIP) * .10);
console(@scReport.'   /   '.array_size(@checkIP))
		foreach(@i: @ip in @checkIP) {
			if(@i % @scReport == 0) { _geoip_report_send_msg(@prefix.color(8).'Checked '.color(5).@i.color(8).' of '.color(1).array_size(@checkIP).color(8).' IPs.', @player); }
			if(@ip == 'raw') { continue() }
			if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
				_geoip_report_send_msg(@prefixError.color(12).'Not a valid IP: '.@ip, @player);
				continue();
			}
			@listIPData = color(14).'['.@ip.'] '.color(3)
			@nomsg = array()
			if(@ipdb[@ip]['c'] == '') { 
				@nomsg[] = 'country';
				@ipdb[@ip]['c'] = '?';
			}
			if(@ipdb[@ip]['asn'] == '') { 
				@nomsg[] = 'ASN';
				@ipdb[@ip]['asn'] = 'None';
				@ipdb[@ip]['aso'] = 'Unknown: No Data Given';
			}
			if(array_size(@nomsg) > 0) { _geoip_report_send_msg(@prefix.color(9).@ip.color(7).': no '.array_implode(@nomsg, ', ').'!', @player) }
			if(!array_index_exists(@asnc, @ipdb[@ip]['asn'])) { @asnc[@ipdb[@ip]['asn']] = array(); }
			if(!array_index_exists(@asnrc, @ipdb[@ip]['asn'])) { @asnrc[@ipdb[@ip]['asn']] = array(); }
			if(!array_index_exists(@asnip, @ipdb[@ip]['asn'])) { @asnip[@ipdb[@ip]['asn']] = array(); }
			#List ASN under mc spam.
			if(array_contains(@spnList, @ip)) { @spasnList[] = @ipdb[@ip]['asn'] }
			#Auto blacklist ASNs if an IP is deemed obnoxious.
			if(array_contains(array_keys(@mancfgArray['Obnoxious']), @ip)) { @ablasnList[] = @ipdb[@ip]['asn'] }
			#Add IP
			@asnip[@ipdb[@ip]['asn']][] = @ip;
			#List all given country codes, in case one entry differs in review
			if(@ipdb[@ip]['c'] == '' || @ipdb[@ip]['c'] == '?') { @asnc[@ipdb[@ip]['asn']][] = 'Unknown' } else { @asnc[@ipdb[@ip]['asn']][] = @ipdb[@ip]['cn'] }
			if(@ipdb[@ip]['rc'] != '') { 
				@asnrc[@ipdb[@ip]['asn']][] = @ipdb[@ip]['rcn']
			}
			@asnlist[@ipdb[@ip]['asn']] = @ipdb[@ip]['aso'];
			@ipcount++
			if(string_contains(@ip, ':')) { @v6ip[] = @ip; }
		}
	} else {
		@data = get_value('ipbl.scan.results')
		if(!is_array(@data)) { die(color(12).'No previous scan results.') }
		@reportmsg[] = 'Using Previous Scan Data! May not be current'
		@ipcount = @data[0]
		@asnlist = @data[1]
		@asnc = @data[2]
		@asnrc = @data[3]
		@asnip = @data[4]
		@spasnList = @data[7]
	}
	store_value('ipbl.Publish.count', array_size(@checkIP))
	@countries = array()
	@asncnlist = array()
	@asnrcnlist = array()
# Compute master list of all countries presented, and which ASNs register with a country.
	foreach(@asn: @cnarray in @asnc) {
		if(@asn == 'None') { continue() }
		foreach(@cn in @cnarray) {
			if(!array_index_exists(@asncnlist, @cn)) { @asncnlist[@cn] = array(); }
			@countries[] = @cn
			if(!array_contains(@asncnlist[@cn], @asn)) { @asncnlist[@cn][] = @asn }
		}
	}
	@countries = array_unique(@countries)
	array_sort(@countries, 'REGULAR')
	@rcountries = array()
# Same list for registered country, differs a lot from normal country depending on cloud platform server locations, etc.
	foreach(@asn: @cnarray in @asnrc) {
		if(@asn == 'None') { continue() }
		foreach(@cn in @cnarray) {
			if(!array_index_exists(@asnrcnlist, @cn)) { @asnrcnlist[@cn] = array(); }
			@rcountries[] = @cn
			if(!array_contains(@asnrcnlist[@cn], @asn)) { @asnrcnlist[@cn][] = @asn }
		}
	}
	@rcountries = array_unique(@rcountries)
	array_sort(@rcountries, 'REGULAR')
# Messages: asn found list IP occurences and aso/ISP
	foreach(@asn: @aso in @asnlist) {
		@msg = ''
		@ipcolor = 7
		if(array_size(@asnc[@asn]) != array_size(@asnip[@asn])) { @ipcolor = 12 }
		@space = ''
		if(length(@asn) < 6) { @space = string_multiply(' ', (6 - length(@asn))) }
		@asnnick = ''
		if(array_index_exists(@asnnicks, 'ASN_ISP_Names', @asn)) { @asnnick = '\n'.color(14).'      : '.color(8).' [AKA: '.@asnnicks['ASN_ISP_Names'][@asn].']' }
		@msg = color(14).@asn.@space.': '.color(3).@aso.color(7).color(@ipcolor).' <IPs: '.color(10).array_size(@asnip[@asn]).color(7).'>'.@asnnick
		@rmsg = ''
		if(array_size(array_unique(@asnrc[@asn])) > 0) { @rmsg = color(14).' Reg Country Codes: '.array_size(array_unique(@asnrc[@asn])) }
		@msg .= '\n'.color(14).'      : '.color(8).' Country codes: '.array_size(array_unique(@asnc[@asn])).@rmsg
		@reportmsg[] = @msg;
	}
# MC centric spam List
	@spasnList = array_unique(@spasnList);
	array_sort(@spasnList, 'REGULAR');
#List all country Codes
	@reportmsg[] = color(2).'List of Country Codes: '.array_implode(@countries, ' ')
	@reportmsg[] = color(5).'List of Registered Country Codes: '.array_implode(@rcountries, ' ')
#General Stats
	@ipsizecolor = 3
	if(array_size(@checkIP) != @ipcount) { @ipsizecolor = 12 }
	@reportmsg[] = color(3).'IPs: '.color(@ipsizecolor).@ipcount.color(3).', ASNs: '.array_size(@asnlist).','.color(6).' Countries: '.array_size(@countries).','.color(13).' Reg Countries: '.array_size(@rcountries)
	store_value('ipbl.scan.results', array(@ipcount, @asnlist, @asnc, @asnrc, @asnip, @countries, @rcountries, @spasnList))
	if(@consoleReport) { console(array_implode(@reportmsg, '\n'), false) }
# More Detail CSV reports:
	@asnipreport = 'ASN, IP Addresses'
	@asncnreport = 'Country Code, ASNs'
	@asnrcnreport = 'Registerd Country Code, ASNs'
	@newcfg = 'IP_Blacklist:'
	@kASN = get_value('Server.ipbl.known.ASNs');
	if(!is_array(@kASN)) { @kASN = array() }
	array_push_all(@kASN, array_keys(@asnip));
	@kASN = array_unique(@kASN, false);
	array_sort(@kASN, 'REGULAR');
	@dASN = array()
	foreach(@asn in @kASN) {
		if(is_numeric(@asn)) { @asn = integer(@asn); }
		@dASN[@asn] = 0;
		if(array_index_exists(@asnip, @asn)) {
			@dASN[@asn] = array_size(@asnip[@asn]);
		}
	}
	@jsoncfg = array('IP_Blacklist': array())
	foreach(@asn: @iplist in @asnip) {
		@asnnick = ''
		if(array_index_exists(@asnnicks, 'ASN_ISP_Names', @asn)) { @asnnick = ' <'.@asnnicks['ASN_ISP_Names'][@asn].'>' }
		@asnipreport .= '\n'.@asn.@asnnick.','.array_implode(@iplist, ',')
		@newcfg .= '\n# ('.@asn.') '.@asnlist[@asn].@asnnick.'\n- '.array_implode(@iplist, '\n- ')
		array_push_all(@jsoncfg['IP_Blacklist'], @iplist);
		if(array_size(@iplist) > 9) {
			if(is_numeric(@asn)) { @asn = integer(@asn); }
			@asnipover10[] = @asn;
		}
	}
	foreach(@cn: @asns in @asncnlist) {
		@asncnreport .= '\n'.@cn.','.array_implode(@asns, ',')
	}
	foreach(@cn: @asns in @asnrcnlist) {
		@asnrcnreport .= '\n'.@cn.','.array_implode(@asns, ',')
	}
	array_sort(@jsoncfg['IP_Blacklist'], 'REGULAR');
	# Final array setup
	array_push_all(@ablasnList, @asnipover10);
	@ablasnList = array_sort(array_unique(@ablasnList), 'REGULAR');
	@extracfg = array('Spam_Player_ASNs': @spasnList, 'Discovered_ASNs': @dASN, 'Auto_Blacklist_ASNs': @ablasnList)
	if(array_index_exists(@asnip, 'None')) { @extracfg['Unknown_ASN_IPs'] = @asnip['None']; }
	@jsoncfg = array_merge(@jsoncfg, @mancfgArray, @extracfg)
	store_value('Server.ipbl.known.ASNs', @kASN);
	store_value('Server.ipbl.known.mc.ASNs', @spasnList);
#Auto_Generate new blacklist for IP_Blacklist config file. Does not run for previous scan replays.
	@prevhash = get_value('ipbl.Publish.hash')
	if(sha1(@jsoncfg['IP_Blacklist']) != @prevhash && @gencfg == true && @scan == true) {
		_write_file(@writeDir.'/Report.txt', strip_colors(array_implode(@reportmsg, '\n')), 'overwrite');
		_write_file(@writeDir.'/Reports/v6.txt', array_implode(@v6ip, '\n'), 'Overwrite');
		_write_file(@writeDir.'/Reports/ASN-IP.csv', @asnipreport, 'overwrite');
		_write_file(@writeDir.'/Reports/ASN-IP-10.csv', 'Known ASNs with over 10 IPs blacklisted\n'.array_implode(@asnipover10, '\n'), 'overwrite');
		_write_file(@writeDir.'/Reports/ASN-CN.csv', @asncnreport, 'overwrite');
		_write_file(@writeDir.'/Reports/ASN-RCN.csv', @asnrcnreport, 'overwrite');
		_write_file(@writeDir.'/Reports/Current-ASNs.csv', 'Current ASNs\n'.array_implode(array_keys(@asnip), '\n'), 'overwrite');
		_write_file(@writeDir.'/Reports/Known-ASNs.csv', 'Known ASNs\n'.array_implode(@kASN, '\n'), 'overwrite');
		_write_file(@writeDir.'/Reports/Known-MC-ASNs.csv', 'Known Minecraft centric spam ASNs\n'.array_implode(@spasnList, '\n'), 'overwrite');
		_write_file(@writeDir.'/Reports/Obnoxious_IPs.yml', yml_encode(@mancfgArray['Obnoxious'], true), 'overwrite');
		_write_file(@writeDir.'/Reports/IP_Block_Blacklist.yml', yml_encode(@mancfgArray['IP_Block_Blacklist'], true), 'overwrite');
		_write_file(@writeDir.'/IPBlacklist.yml', @mancfg.'\n'.@newcfg.'\n'.yml_encode(@extracfg, true), 'overwrite');
		_write_file(@writeDir.'/IPBlacklist.json', json_encode(@jsoncfg), 'overwrite');
		_write_file(@writeDir.'/block.txt', array_implode(@jsoncfg['IP_Blacklist'], '\n'), 'Overwrite');
		@addMsg = @prefix.'Wrote report files to Git folder.'
		if(@sourceCount > 1) { @addMsg .= ' Total Sources Used: '.@sourceCount }
		export('ipbl.config.IPBlacklist', @jsoncfg);
		_ipbl_save_config(@jsoncfg);
		# _write_file(import('ipbl.config.dir').'/IPBlacklist.yml', @mancfg.'\n'.@newcfg.'\n'.yml_encode(@extracfg, true), 'overwrite');
		console(color(8).@addMsg, false);
		@reportmsg[] = color(2).@addMsg;
		if(@gitpublish) {
			@addMsg2 = ''
			try {
				@shellreturn = shell(array('./gitupload.sh'), array('workingDir': @writeDir));
				@addMsg = @prefix.color(3).'Git push results: '.color('r').@shellreturn;
				store_value('ipbl.Publish.hash', sha1(@jsoncfg['IP_Blacklist']));
			} catch(InsufficientPermissionException @ex) {
				@addMsg = @prefixError.color(12).'GeoIP Git shell cannot start, make sure you have turned on the allow-shell setting.'
				@addMsg2 = color(12).' (in preferences.ini) \n'.@ex;
			} catch(ShellException @ex) {
				@addMsg = @prefixError.color(12).'GeoIP Git Shell command had an exception.';
				@addMsg2 = color(4).'\n'.@ex['message'];
			} catch(Exception @ex) {
				@addMsg = @prefixError.color(12).'GeoIP Git shell had an exception: ';
				@addMsg2 = color(4).@ex;
			}
			console(@addMsg.@addMsg2, false)
			@reportmsg[] = @addMsg;
		}
	}
	if(@player != '~console') { msg(array_implode(@reportmsg, '\n'), false) }
	return(true);
});
}

#------------------------------
# Auto-Generate Blacklist config file for new IPs, for publish to Git
set_cron('@daily', closure(){ _geoip_asn_report(); });
#------------------------------
# Update Check for GeoIP Database files
set_cron('0 23 * * *', closure(){ 
	@serverConfig = import('ipbl.config.Server');
	_download_file('GeoLite2-ASN.mmdb', @serverConfig['LookupIP_DB_Dir'])
	_download_file('GeoLite2-City.mmdb', @serverConfig['LookupIP_DB_Dir'])
	_download_file('geoip.py', @serverConfig['LookupIP_DB_Dir'], '', 'create')
});
#------------------------------
# Generate Blacklist config file for new IPs manually / view report in game or console.
if(function_exists('register_command')) {
	register_command('geoipasnreport', array(
		'description': 'Admin: Generate report of Blacklisted IP address ASNs.',
		'usage': color(8).'Examples: /geoipasnreport <true to scan, false to use previous result> <true to list report to console> <true to write config files and reports>',
		'permission': 'ipbl.Admin.cmd.geoIPasn',
		'noPermMsg': 'Unknown command. Type "/help" for help.',
		'tabcompleter':
			closure(@alias, @sender, @args, @info) {
				@arg = @args[-1];
				@argPos = array_size(@args) - 1;
				@actnp = array('<No permission>')
				@atype = 0
				@usetabs = array('<No further arguments>');		
			#Compute Tabs for each arg position
				switch(@argPos) {
				case 0:
			#1st arg:
					@usetabs = array('Run a new Scan?', 'true', 'false');
					if(!has_permission(@sender, 'ipbl.Admin.cmd.geoIPasn')) { @usetabs = @actnp; }
				case 1:
					@usetabs = array('Write report to Console?', 'true', 'false');
					if(!has_permission(@sender, 'ipbl.Admin.cmd.geoIPasn')) { @usetabs = @actnp; }
				case 2:
					@usetabs = array('Write config files to disk?', 'true', 'false');
					if(!has_permission(@sender, 'ipbl.Admin.cmd.geoIPasn')) { @usetabs = @actnp; }
				}
			#Return tabs
				@areturn = array_filter(@usetabs, closure(@key, @value) {
				return(length(@arg) <= length(@value)
						&& equals_ic(@arg, substr(@value, 0, length(@arg))));
				});
				return(@areturn);
			},
		'executor':
			closure(@alias, @sender, @args, @info) {
				@player = @sender;
				@uuid = puuid(@player, 'dashless');
				@id = 0;
				@returnMsg = array(12, '?');
				@useArgs = array(false, false, false)
				@name = 'IPBlacklist'
				if(array_index_exists(@args, 0)) {
					foreach(@i: @a in @args) {
						if(@a != 'true' && @a != 'false') { continue() }
						if(@i > 2) { break() }
						@b = true
						if(@a == 'false') { @b = !@b; }
						@useArgs[@i] = @b;
					}
				}
				if(!has_permission(player(), 'ipbl.Admin.cmd.geoIPasn')) {
					msg(color(12).'['.color(7).@name.color(12).'] '.color(12).'You do not have permission '.color(7).'to run the GeoIP ASN report.'); 
					return(true);
				}
				_geoip_asn_report(@useArgs[0], @useArgs[1], @useArgs[2]);
				return(true);
			}
	));
}