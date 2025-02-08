# Generate reports about which ASNs and countries are listed in Chat's IP Blacklist file, using the GeoIP shell command lookup.
# Auto-Generate Blacklist config file for new IPs, for publish to Git
set_cron('@daily', closure(){
x_new_thread('ChatGitPublish'.time(), closure(){
#threaded due to shell call processing ~25 IPs/second
	@blacklistIP = import('Chat.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
	@checkIP = array_sort(array_unique(@blacklistIP['IP_Blacklist'], false), 'REGULAR');
	@serverConfig = import('Chat.config.Server')
	if(!array_index_exists(@serverConfig, 'Git_Dir')) { die() }
	@time = time();
	@raw = false
	@scan = true
	@consoleReport = false
	@ipdb = array()
	@asnlist = array()
	@asnc = array()
	@asnrc = array()
	@asnip = array()
	@ipcount = 0
	@asnnicks = array()
	@asnipover10 = array()
	@v6ip = array()
	try {
		@asnnicks = yml_decode(read(import('Chat.config.dir').'/ASN_ISP_Names.yml'))
	} catch(IOException @ex) {
		_chat_msg_Admins(color(12).'[Chat] ASN ISP Nicknames file could not be read. ', @ex['message'], true)
	} catch(FormatException @ex) {
		_chat_msg_Admins(color(12).'[Chat] ASN ISP Nicknames file is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']), true) 
	} catch(Exception @ex) {
		_chat_msg_Admins(color(12).'[Chat] There was an error with the ASN ISP Nicknames file. ', @ex['message'], true) 
	}
	@prevcount = get_value('Chat.IPBlacklist.Publish.count')
	if(array_size(@checkIP) == @prevcount) { return(false) }
	if(@scan == true) {
		foreach(@i: @ip in @checkIP) {
			if(@i % 100 == 0) { console(color(8).'[Chat] Processed '.@i.' of '.array_size(@checkIP).' IPs.', false); }
			if(@ip == 'raw') { continue() }
			if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
				console(color(12).'[Chat] Not a valid IP: '.@ip)
				continue()
			}
			@listIPData = color(14).'['.@ip.'] '.color(3)
			@ipdb = _chat_lookup_ip_db(@ip);
			if(!is_array(@ipdb)) { die(color(12).'An error occured with the Geo IP scanner, see logs.') }
			if(@ipdb['asn'] == '') { 
				console(color(12).@ip.': no ASN!', false)
				array_set(@ipdb, 'asn', 'None')
				array_set(@ipdb, 'aso', 'Unknown: No Data Given')
				array_set(@ipdb, 'c', '?')
			}
			if(@ipdb['c'] == '') { console(color(12).@ip.': no country!', false) }
			if(!array_index_exists(@asnc, @ipdb['asn'])) { array_set(@asnc, @ipdb['asn'], array()) }
			if(!array_index_exists(@asnrc, @ipdb['asn'])) { array_set(@asnrc, @ipdb['asn'], array()) }
			if(!array_index_exists(@asnip, @ipdb['asn'])) { array_set(@asnip, @ipdb['asn'], array()) }
			
			@asnip[@ipdb['asn']][] = @ip;
			#List all given country codes, in case one entry differs in review
			if(@ipdb['c'] == '' || @ipdb['c'] == '?') { @asnc[@ipdb['asn']][] = 'Unknown' } else { @asnc[@ipdb['asn']][] = @ipdb['cn'] }
			if(@ipdb['rc'] != '') { 
				@asnrc[@ipdb['asn']][] = @ipdb['rcn']
			}
			array_set(@asnlist, @ipdb['asn'], @ipdb['aso'])
			@ipcount++
			if(string_contains(@ip, ':')) { @v6ip[] = @ip; }
		}
	} else {
		@data = get_value('Chat.debug.results.asn')
		if(!is_array(@data)) { die(color(12).'No previous scan results.') }
		@ipcount = @data[0]
		@asnlist = @data[1]
		@asnc = @data[2]
		@asnrc = @data[3]
		@asnip = @data[4]
	}
	store_value('Chat.IPBlacklist.Publish.count', array_size(@checkIP))
	@countries = array()
	@asncnlist = array()
	@asnrcnlist = array()
# Computer master list of all countries presented, and which ASNs register with a country.
	foreach(@asn: @cnarray in @asnc) {
		if(@asn == 'None') { continue() }
		foreach(@cn in @cnarray) {
			if(!array_index_exists(@asncnlist, @cn)) { array_set(@asncnlist, @cn, array()) }
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
			if(!array_index_exists(@asnrcnlist, @cn)) { array_set(@asnrcnlist, @cn, array()) }
			@rcountries[] = @cn
			if(!array_contains(@asnrcnlist[@cn], @asn)) { @asnrcnlist[@cn][] = @asn }
		}
	}
	@rcountries = array_unique(@rcountries)
	array_sort(@rcountries, 'REGULAR')
# Messages: asn found list IP occurences and aso/ISP
	@reportmsg = array()
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

#List all country Codes
	@reportmsg[] = color(2).'List of Country Codes: '.array_implode(@countries, ' ')
	@reportmsg[] = color(5).'List of Registered Country Codes: '.array_implode(@rcountries, ' ')
#General Stats
	@ipsizecolor = 3
	if(array_size(@checkIP) != @ipcount) { @ipsizecolor = 12 }
	@reportmsg[] = color(3).'IPs: '.color(@ipsizecolor).@ipcount.color(3).', ASNs: '.array_size(@asnlist).','.color(6).' Countries: '.array_size(@countries).','.color(13).' Reg Countries: '.array_size(@rcountries)
	store_value('Chat.debug.results.asn', array(@ipcount, @asnlist, @asnc, @asnrc, @asnip, @countries, @rcountries))
	if(@consoleReport) { console(array_implode(@reportmsg, '\n'), false) }
# More Detail CSV reports:
	@asnipreport = 'ASN, IP Addresses'
	@asncnreport = 'Country Code, ASNs'
	@asnrcnreport = 'Registerd Country Code, ASNs'
	@newcfg = 'IP_Blacklist:'
	@kASN = get_value('Chat.server.bl.known.ASNs');
	if(!is_array(@kASN)) { @kASN = array() }
	array_push_all(@kASN, array_keys(@asnip));
	@kASN = array_unique(@kASN, false);
	array_sort(@kASN, 'REGULAR');
	@dASN = array()
	foreach(@asn in @kASN) {
		array_set(@dASN, @asn, 0);
		if(array_index_exists(@asnip, @asn)) {
			array_set(@dASN, @asn, array_size(@asnip[@asn]));
		}
	}
	@jsoncfg = array('Discovered_ASNs': @dASN, 'IP_Blacklist': array())
	foreach(@asn: @iplist in @asnip) {
		@asnnick = ''
		if(array_index_exists(@asnnicks, 'ASN_ISP_Names', @asn)) { @asnnick = ' <'.@asnnicks['ASN_ISP_Names'][@asn].'>' }
		@asnipreport .= '\n'.@asn.@asnnick.','.array_implode(@iplist, ',')
		@newcfg .= '\n# ('.@asn.') '.@asnlist[@asn].@asnnick.'\n- '.array_implode(@iplist, '\n- ')
		array_push_all(@jsoncfg['IP_Blacklist'], @iplist);
		if(array_size(@iplist) > 9) { @asnipover10[] = @asn; }
	}
	foreach(@cn: @asns in @asncnlist) {
		@asncnreport .= '\n'.@cn.','.array_implode(@asns, ',')
	}
	foreach(@cn: @asns in @asnrcnlist) {
		@asnrcnreport .= '\n'.@cn.','.array_implode(@asns, ',')
	}
	array_sort(@jsoncfg['IP_Blacklist'], 'REGULAR');
#Auto_Generate new blacklist for IP_Blacklist config file
	@prevhash = get_value('Chat.IPBlacklist.Publish.hash')
	if(sha1(@jsoncfg['IP_Blacklist']) != @prevhash) {
		@writeDir = @serverConfig['Git_Dir']
		_write_file(@writeDir.'/Report.txt', strip_colors(array_implode(@reportmsg, '\n')), 'overwrite');
		_write_file(@writeDir.'/Reports/ASN-IP.csv', @asnipreport, 'overwrite');
		_write_file(@writeDir.'/Reports/ASN-IP-10.csv', 'Known ASNs with over 10 IPs blacklisted\n'.array_implode(@asnipover10, '\n'), 'overwrite');
		_write_file(@writeDir.'/Reports/ASN-CN.csv', @asncnreport, 'overwrite');
		_write_file(@writeDir.'/Reports/ASN-RCN.csv', @asnrcnreport, 'overwrite');
		_write_file(@writeDir.'/Reports/Current-ASNs.csv', 'Current ASNs\n'.array_implode(array_keys(@asnip), '\n'), 'overwrite');
		store_value('Chat.server.bl.known.ASNs', @kASN);
		_write_file(@writeDir.'/Reports/Known-ASNs.csv', 'Known ASNs\n'.array_implode(@kASN, '\n'), 'overwrite');
		@mancfg = ''
		try {
			@mancfg = read(import('Chat.config.dir').'/Template-IP.yml')
		} catch(IOException @ex) {
			_chat_msg_Admins(color(12).'[Chat] Template-IP Config file could not be read. ', @ex['message'], true)
			die()
		} catch(FormatException @ex) {
			_chat_msg_Admins(color(12).'[Chat] Template-IP Config file is improperly formatted.', '\n'.reg_replace('Improperly formatted YML[:]?', '', @ex['message']), true) 
			die()
		} catch(Exception @ex) {
			_chat_msg_Admins(color(12).'[Chat] There was an error with the Template-IP Config file. ', @ex['message'], true) 
			die()
		}
		_write_file(@writeDir.'/Reports/Obnoxious_IPs.yml', yml_encode(yml_decode(@mancfg)['Obnoxious'], true), 'overwrite');
		_write_file(@writeDir.'/Reports/IP_Block_Blacklist.yml', yml_encode(yml_decode(@mancfg)['IP_Block_Blacklist'], true), 'overwrite');
		@extracfg = array('Discovered_ASNs': @dASN, 'Auto_Blacklist_ASNs': @asnipover10)
		if(array_index_exists(@asnip, 'None')) { array_set(@extracfg, 'Unknown_ASN_IPs', @asnip['None']) }
		@jsoncfg = array_merge(@jsoncfg, yml_decode(@mancfg), @extracfg)
		_write_file(@writeDir.'/IPBlacklist.yml', @mancfg.'\n'.@newcfg.'\n'.yml_encode(@extracfg, true), 'overwrite');
		_write_file(import('Chat.config.dir').'/IPBlacklist.yml', @mancfg.'\n'.@newcfg.'\n'.yml_encode(@extracfg, true), 'overwrite');
		_write_file(@writeDir.'/IPBlacklist.json', json_encode(@jsoncfg), 'overwrite');
		_write_file(@writeDir.'/block.txt', array_implode(@jsoncfg['IP_Blacklist'], '\n'), 'Overwrite');
		_write_file(@writeDir.'/Reports/v6.txt', array_implode(@v6ip, '\n'), 'Overwrite');
		console(color(8).'[Chat] Wrote report files to Git folder.', false)
		try {
			@shellreturn = shell(array('./gitupload.sh'), array('workingDir': @writeDir))
			console(color(3).'[Chat] Git push results: '.color('r').@shellreturn, false)
			store_value('Chat.IPBlacklist.Publish.hash', sha1(@jsoncfg['IP_Blacklist']))
		} catch(InsufficientPermissionException @ex) {
			console(color(12).'Chat: GeoIP Git shell cannot start, make sure you have turned on the allow-shell setting in preferences.ini. \n'.@ex)
			return('NoPerms')
		} catch(ShellException @ex) {
			console(color(12).'Chat: GeoIP Git Shell command had an exception:\n'.@ex['message'])
			return('Error')
		} catch(IOException @ex) {
			console('Chat: GeoIP Git shell: '.@ex)
			return(false)
		} catch(Exception @ex) {
			console('Chat: GeoIP Git shell: '.@ex)
			return(false)
		}
	}
});
});