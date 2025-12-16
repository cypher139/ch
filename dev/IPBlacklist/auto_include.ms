### Functions

proc _ipbl_save_config(array @blacklistIP = array(), string @savetype = 'all') {
	@direct = true;
	@serverConfig = import('IPBlacklist.config.Server');
	if(array_size(@blacklistIP) < 3 || !array_index_exists(@blacklistIP, 'IP_Blacklist')) {
		@blacklistIP = import('IPBlacklist.config.IPBlacklist');
		@direct = false;
	}
	if(!is_array(@blacklistIP)) { _msg_Admins('IP Blacklist', 'error', color(14).'No data given to save.'); return(false); }
#Export, if directly given
	if(@direct === true && @savetype === 'all') {
		export('IPBlacklist.config.IPBlacklist', @blacklistIP);
	}
#Save to persistance
	if(@savetype === 'all' || @savetype === 'store') {
		store_value('IPBlacklist.config.IPBlacklist', @blacklistIP);
	}
#Publish list of blacklisted IPs to a file for use by your firewall.
	if(@savetype === 'all' || @savetype === 'block') {
		if(@serverConfig['Write_Blacklist_IP_File'] === true) {
			@ipFileList = array();
			try {
				@ipFileList = parse_args(replace(read(@serverConfig['Write_Blacklist_IP_File_Path']), '\n', ' '));
			} catch(Exception @ex) {
				console('[IP Blacklist] Blacklist IP file: '.@ex['classType'].' '.@ex['message'], false);
			}
			if(sha1(@blacklistIP['IP_Blacklist']) != sha1(@ipFileList)) {
				@ipSizeOld = array_size(@ipFileList);
				@ipSizeNew = array_size(@blacklistIP['IP_Blacklist']);
				_write_file(@serverConfig['Write_Blacklist_IP_File_Path'], array_implode(@blacklistIP['IP_Blacklist'], '\n'), 'OVERWRITE');
				@ipSizePrefix = '';
				if(@ipSizeNew > @ipSizeOld) { @ipSizePrefix = 'Added '.(@ipSizeNew - @ipSizeOld).' IPs to'; }
				if(@ipSizeNew < @ipSizeOld) {
					@ipSizePrefix = 'Removed '.(@ipSizeOld - @ipSizeNew).' IPs from';
					_write_file('^lp/IPBlacklist/Logs/ipold.yml', yml_encode(@ipFileList, true), 'OVERWRITE');
					_write_file('^lp/IPBlacklist/Logs/ipnew.yml', yml_encode(@blacklistIP['IP_Blacklist'], true), 'OVERWRITE');
				}
				if(@ipSizePrefix != '') { console('[IP Blacklist] '.@ipSizePrefix.' firewall blacklist.', false); }
			}
		}
	}
# write ipbl yml
	if(@savetype === 'all' || @savetype === 'cfg') {
		_write_file('^lp/IPBlacklist/Configs/IPBlacklist.yml', yml_encode(@blacklistIP, true), 'OVERWRITE');
	}
	return(true);
}

proc _ipbl_pings_write_log(array @ping = array(), string @type = 'ignore', boolean @superignore = false, string @ISP = 'Unknown') {
	@time = time();
	if(array_size(@ping) <= 0) { return('no data'); }
	if(@superignore === true) { return('ignored'); }
	@serverConfig = import('IPBlacklist.config.Server');
	@ip = reg_replace('[%][0]$', '', @ping['ip']);
	@ignoredIPPings = get_value('Server.pings.log.'.@type.'.IP');
	if(!is_array(@ignoredIPPings)) { @ignoredIPPings = array(); }
	if(!array_index_exists(@ignoredIPPings, 'isp')) { @ignoredIPPings['isp'] = array(); }
	if(!array_index_exists(@ignoredIPPings, @ip)) { @ignoredIPPings[@ip] = array(); }
	array_push(@ignoredIPPings[@ip], @time);
	if(@ISP != 'Unknown') { @ignoredIPPings['isp'][@ip] = @ISP; }
	store_value('Server.pings.log.'.@type.'.IP', @ignoredIPPings);
	_write_file('^lp/IPBlacklist/Logs/Ping-Log-'.@type.'-IPs.csv', simple_date('MM-dd-yy HH:mm:ss', @time).','.@ping['ip'].'\n', 'append');
	#Optional: publish IP block list to server HTML
	if(@type == 'blacklist' && @serverConfig['Write_Blacklist_IP_File'] === true) {
		@blacklistIP = import('IPBlacklist.config.IPBlacklist', array('IP_Blacklist': array()));
		array_remove(@ignoredIPPings, 'isp');
		@ipList = array_merge(@blacklistIP['IP_Blacklist'], array_keys(@ignoredIPPings));
		@ipList = array_sort(@ipList, 'REGULAR');
		# @ipList = array_unique(@ipList, false);
		@previp = '';
		foreach(@k: @v in @ipList) {
			if(@v == @previp) {
				array_remove(@ipList, @k);
			} else {
				@previp = @v;
			}
		}	
		_write_file(@serverConfig['Write_Blacklist_IP_File_Path'], array_implode(@ipList, '\n'), 'overwrite');
	}
	return(true);
}

proc _download_file(@file, @path, @url, @mode = 'update') {
	@write = false;
	@prefix = 'File ';
	if(!@url) {
		switch(@file) {
		case 'GeoLite2-ASN.mmdb':
		case 'GeoLite2-City.mmdb':
			@url = 'https://github.com/P3TERX/GeoLite.mmdb/raw/download/';
			@prefix = 'GeoIP database file ';
		case 'geoip.py': 
			@url = 'https://raw.githubusercontent.com/cypher139/ch/release/dev/IPBlacklist/';
		default:
			return('NoURL');
		}
	}
	if(!@file || !@path) { return('NoFile'); }
	switch(@mode) {
	case 'update':
		if(function_exists('file_last_modified')) {
			@fm = file_last_modified(@path.'/'.@file);
			if(@fm > 0 && @fm > (time() - 604800000)) { @write = false; } else { @write = true; }
		} else { return('NoExt') }
	case 'create':
		if(function_exists('file_exists')) {
			if(!file_exists(@path.'/'.@file)) { @write = true; }
		} else { return('NoExt') }
	}	
	if(@write) {	
		http_request(@url.@file, array('binary': true, 'blocking': true, 'success': closure(@data) {
			# export('ipbl.dl.update.check.'.@file, time());
			if(@data['error'] === true) {
				if(@data['responseCode'] == 404) { console('URL '.@url.@file.' was not found!'); }
				export('ipbl.debug.http.error', @data);
				return(false);
			} else {
				@writeReturn = _write_file(@path.'/'.@file, @data['data'], 'OVERWRITE');
				@suffix = color(10).'updated: ';
				if(!@writeReturn) { @suffix = color(4).'could not be written: '; }
				console(color(14).@prefix.@suffix.color(9).@file, false);
			}
		}));
	}
	return(true);
}

proc _geoip_lookup(@args, boolean @raw = false) {
	@serverConfig = import('IPBlacklist.config.Server');
	@checkIPs = array();
	if(!is_array(@args)) { @args = array(@args); }
	#Setup Check array, validate addresses
	foreach(@arg in @args) {
		@ip = reg_replace('[%][0]$', '', @arg);
		@noip = false;
		#Validate v4 or v6 octet dividers
		if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) === false) { @noip = true; }
		#v4:
		if(string_contains(@ip, '.') && !string_contains(@ip, ':')) {
			if(!is_numeric(replace(@ip, '.', ''))) { @noip = true; }
		} else {
		#v6:
			if(reg_count('[G-Zg-z]+', @ip) > 0) { @noip = true; }
		}
		if(@noip === true) {
			_msg_Admins('GeoIP Lookup', 'error', 'Invalid IP given', color(12).':  '.@ip);
			continue();
		}
		@checkIPs[] = @ip;
	}
	if(array_size(@checkIPs) < 1) {	return('NoIP'); }
	#Setup GeoIP Databases and shell call
	@geoipData = array();
	try {
		@call = array('python3', 'geoip.py');
		array_push_all(@call, @checkIPs);
		@geoipData = json_decode(shell(@call, array('workingDir': @serverConfig['LookupIP_DB_Dir'])));
	} catch(InsufficientPermissionException @ex) {
		console(color(12).'GeoIP shell cannot start, make sure you have turned on the allow-shell setting in preferences.ini. \n'.@ex);
		return('NoPerms');
	} catch(ShellException @ex) {
		if(string_starts_with(@ex['message'], 'python3: can\'t open file')) {
			_download_file('geoip.py', @serverConfig['LookupIP_DB_Dir']);
			console(color(14).'Downloading geoip.py');
			return('DBUpdate');
		} else {
			console(color(12).'GeoIP: Shell command had an exception:\n'.@ex['message']);
		}
		return('Error');
	} catch(Exception @ex) {
		console('GeoIP shell: '.@ex);
		return(false);
	}
	#File Update Check:
	if(array_size(@geoipData['updateFile']) > 0) {
		foreach(@file in @geoipData['updateFile']) {
			_download_file('GeoLite2-'.@file.'.mmdb', @serverConfig['LookupIP_DB_Dir']);
		}
		console(color(14).'Downloading '.array_implode(@geoipData['updateFile'], ', ').' database files.', false);
		return('DBUpdate');
	}
	#Parse returned Data
	@return = array();
	foreach(@ip in @checkIPs) {
		@ipData = array();
		if(array_index_exists(@geoipData, @ip)) {
			if(array_size(@geoipData[@ip]) > 0) { @ipData = @geoipData[@ip]; }
		}
		if(array_size(@ipData) < 1) {
			_msg_Admins('GeoIP Lookup', 'info', 'No IP data returned for'.color(12).':  '.@ip);
		}
###DEBUG: console(color(9).'GeoIP: '.color(14).@ip.' '.color(7).@ipData, false);
		@ipreturn = array('cn': '', 'c': '', 'asn': '', 'aso': '', 'rc': '', 'rcn': '');
		if(array_index_exists(@ipData, 'country')) { 
			@ipreturn['cn'] = @ipData['country']['iso_code'];
			@ipreturn['c'] = @ipData['country']['names']['en'];
		}
		if(array_index_exists(@ipData, 'country') && array_index_exists(@ipData, 'registered_country')) {
			if(@ipData['registered_country']['iso_code'] != @ipData['country']['iso_code']) {
				@ipreturn['rcn'] = @ipData['registered_country']['iso_code'];
				@ipreturn['rc'] = @ipData['registered_country']['names']['en'];
			}
		}
		if(array_index_exists(@ipData, 'autonomous_system_number')) { 
			@ipreturn['asn'] = @ipData['autonomous_system_number'];
		}
		if(array_index_exists(@ipData, 'autonomous_system_organization')) { 
			@ipreturn['aso'] = @ipData['autonomous_system_organization'];
		}
		if(@raw === true) {
			@ipreturn['raw'] = @ipData;
		}
		@return[@ip] = @ipreturn;
	}
	return(@return);
}