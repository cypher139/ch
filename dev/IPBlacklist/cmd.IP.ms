#Ignored & Blacklisted IP pings notification
set_cron('59 23 * * *', closure(){
	export('ipbl.cmd.IP.report', 'auto');
	run_cmd('/ip report');
});

#------------------------------
try(unregister_command('ip'))

register_command('ip', array(
	'description': 'Admin: IP address Blacklist management.',
	'usage': color(8).'Examples: /ip report, /ip avgtime <IP>, /ip check <IP>, /ip geo <IP>',
	'permission': 'ipbl.Admin.cmd.IP',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actsub = array('report', 'check', 'blacklist', 'whitelist', 'geoip', 'avgtime', 'notblock', 'pingmismatchignore');
			# @actsubAdmin = array('leaderboard');
			@actplayers = all_players();
			@actqty = array();
			for(@i = 1, @i <= 10, @i++) {
				@actqty[] = @i;
			}
			@atype = 0
			@usetabs = array('<No further arguments>');		
		#Compute Tabs for each arg position
			switch(@argPos) {
			case 0:
		#1st arg:
				@usetabs = @actsub;
			case 1:
				@usetabs = array('Type IP Address');
				if(@args[0][0] == 'r') { @usetabs = array('Post results to Console/Discord logs?', 'true', 'false'); }
				if(@args[0][0] == 'a' || @args[0][0] == 't') { @usetabs = array('raw', 'curate', 'ignore', 'blacklist', 'obnoxious', 'Type IP Address'); }
			case 2:
			case 3:
			case 4:
			case 5:
				@usetabs = array('Type IP Address');
				if(@args[0][0] == 'r') { @usetabs = array('--'); }
			}
		#Return tabs
			@areturn = array_filter(@usetabs, closure(@key, @value) {
			return(length(@arg) <= length(@value)
					&& equals_ic(@arg, substr(@value, 0, length(@arg))));
			});
			# console(@atype)
			return(@areturn);
		},
	'aliases': array('ipbl'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@player = @sender;
			@uuid = puuid(@player, 'dashless');
			@id = 0;
			@returnMsg = array(12, '?');
			@cmd = '';
			@name = 'IPBlacklist'
			if(array_index_exists(@args, 0)) {
				if(@args[-1] == 'arguments>') {
					@back = array_size(@args) - 4;
					if(@back < 0) {
						@args = array();
					} else {
						@args = @args[cslice(0, @back)]
					}
				}
			}
			# Select Sub command
			if(array_index_exists(@args, 0)) {
				switch(to_lower(@args[0])[0]) {
				case 'r':
				case 'e':
					@cmd = 'report';
				case 'c':
					@cmd = 'check';
				case 'b':
					@cmd = 'blacklist';
				case 'w':
					@cmd = 'whitelist';
				case 'g':
				case 'l':
					@cmd = 'geoip';
				case 'a':
				case 't':
					@cmd = 'avgtime';
				case 'n':
					@cmd = 'notblock';
				case 'p':
					@cmd = 'pingmismatchignore';
				}
				if(@cmd != '') { array_remove(@args, 0); }
			} 
			if(!@cmd) {
				msg(color(12).'['.color(7).@name.color(12).'] '.color(12).'You need to specify a command to run!'); 
				return(false);
			}
		#Common Args
			if(!has_permission(player(), 'ipbl.Admin.cmd.IP.'.@cmd)) {
				@cmdmsg = array('report': 'to view the Blackisted IP report.', 'check': 'to check if IP is blacklisted here.', 'avgtime': 'to check average IP ping times.', 'geoip': 'to lookup GeoIP information.', 'notblock': 'to view IPs not listed in a blacklisted IP Block.', 'blacklist': 'to manually blacklist IPs.');
				msg(color(12).'['.color(7).@name.color(12).'] '.color(12).'You do not have permission '.color(7).@cmdmsg[@cmd]); 
				return(true);
			}
			@time = time();
			@serverConfig = import('ipbl.config.Server');
			@results = array();
		# Sub Actions:
			switch(@cmd) {
			case 'blacklist':
		#Check if a given IP is already in IP Blacklist config
				@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				@results[] = color(14).'IPs to add to IP Blacklist: ';
				@listIPData = ''
				@ipuserdata = import('primus.database.IP');
				if(!is_array(@ipuserdata)) { @ipuserdata = array() }
			#Add
				@addip = array()
				@reviewip = array()
				@userdisplay = ''
				@showall = false
				if(array_contains(@args, 'show')) { @showall = true }
				foreach(@arg in @args) {
					if(@arg == 'show') { continue() }
					@listIPData = ''
					@upload = true
					@ip = reg_replace('[%][0]$', '', @arg);
					if(@ip == 'raw' || @ip == 'isp' || @ip == 'ip') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@listIPData = color(9).@ip.color(3)
					foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
						@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
						if(string_starts_with(string(@ip), @startBlock)) {
							@listIPData .= color(14).' Found On Block Blacklist: '.color(7).@block
						}
					}
					if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
						if(@showall) { @listIPData .= color(12).' Already In Blacklist' } else { continue(); }
						@upload = false
					}
					if(array_index_exists(@ipuserdata, @ip) && !array_contains(@args, 'confirm')) {
						array_set(@reviewip, @ip, @ipuserdata[@ip]);
						@listIPData .= color(9).' Player Names: '.color(8).array_implode(@ipuserdata[@ip], ', ')
						@userdisplay .= '\n'.@ip.': '.array_implode(@ipuserdata[@ip], ', ')
						@upload = false
					}
					if(@upload) { 
						@addip[] = @ip;
						@blacklistIP['IP_Blacklist'][] = @ip;
						@listIPData .= color(10).' - Added.'
					}
					@results[] = @listIPData;
				} else { @results[] = color(12).'No IPs were given to add?!?!'; }
				if(array_size(@addip) > 0) {
					export('ipbl.config.IPBlacklist', @blacklistIP);
					_ipbl_save_config(@blacklistIP);
					@results[] = color(10).array_size(@addip).' IPs were added.'; 
				}
				if(array_size(@reviewip) > 0) {
					@results[] = color(14).'These IPs have connected with a player name; If you wish to confirm blacklisting these IPs, '.color('r').'*type this command again and include the word "'.color(14).'confirm'.color('r').'".*'.@userdisplay;
				}
				case 'whitelist':
		#Check if a given IP is already in IP Blacklist config
				@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				@results[] = color(3).'IPs to remove from IP Blacklist: ';
				@listIPData = ''
				@ipuserdata = import('primus.database.IP');
				if(!is_array(@ipuserdata)) { @ipuserdata = array() }
			#Add
				@addip = array()
				@reviewip = array()
				@whitelist = get_value('ipbl.data.Whitelist')
				if(!@whitelist) { @whitelist = array() }
				@userdisplay = '';
				@showall = true
				if(array_contains(@args, 'show')) { @showall = true }
				foreach(@arg in @args) {
					if(@arg == 'show') { continue() }
					@listIPData = ''
					@upload = true
					@ip = reg_replace('[%][0]$', '', @arg);
					if(@ip == 'raw' || @ip == 'isp' || @ip == 'ip') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@listIPData = color(9).@ip.color(3)
					foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
						@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
						if(string_starts_with(string(@ip), @startBlock)) {
							@listIPData .= color(14).' Found On Block Blacklist: '.color(7).@block
						}
					}
					if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
						@upload = true;
					} else {
						@listIPData .= color(11).' Not Found In Blacklist';
						@upload = false
					}
					if(array_index_exists(@ipuserdata, @ip) && !array_contains(@args, 'confirm')) {
						array_set(@reviewip, @ip, @ipuserdata[@ip]);
						@listIPData .= color(9).' Player Names: '.color(8).array_implode(@ipuserdata[@ip], ', ')
						@userdisplay .= '\n'.@ip.': '.array_implode(@ipuserdata[@ip], ', ')
						@upload = false
					}
					if(@upload) { 
						@addip[] = @ip;
						array_remove_values(@blacklistIP['IP_Blacklist'], @ip);
						@listIPData .= color(10).' - Removed.'
					}
					@results[] = @listIPData;
				} else { @results[] = color(12).'No IPs were given to remove?!?!'; }
				if(array_size(@addip) > 0) {
					@whitelist = array_unique(array_merge(@whitelist, @addip));
					store_value('ipbl.data.Whitelist', @whitelist);
					export('ipbl.config.IPBlacklist', @blacklistIP);
					_ipbl_save_config(@blacklistIP);
					@results[] = color(10).array_size(@addip).' IPs were removed.'; 
				}
				if(array_size(@reviewip) > 0) {
					@results[] = color(14).'These IPs have connected with a player name; If you wish to confirm whitelisting these IPs, '.color('r').'*type this command again and include the word "'.color(14).'confirm'.color('r').'".*'.@userdisplay;
				}
			case 'pingmismatchignore':
		#Check if a given IP is already in IP Blacklist config
				@ignoreCheckob = get_value('ipbl.ignore.mismatch.pings');
				if(!is_array(@ignoreCheckob)) { @ignoreCheckob = array() } 
				@results[] = color(14).'IPs to add to ignore ping mismatch: ';
				@listIPData = ''
			#Add
				@addip = array()
				@reviewip = array()
				@userdisplay = ''
				@showall = false
				if(array_contains(@args, 'show')) { @showall = true }
				foreach(@arg in @args) {
					if(@arg == 'show') { continue() }
					@listIPData = ''
					@upload = true
					@ip = reg_replace('[%][0]$', '', @arg);
					if(@ip == 'raw' || @ip == 'isp' || @ip == 'ip') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@listIPData = color(9).@ip.color(3)
					if(array_contains(@ignoreCheckob, @ip)) {
						if(@showall) { @listIPData .= color(12).' Already In List' } else { continue(); }
						@upload = false
					}
					if(@upload) { 
						@addip[] = @ip;
						@ignoreCheckob[] = @ip;
						@listIPData .= color(10).' - Added.'
					}
					@results[] = @listIPData;
				} else { @results[] = color(12).'No IPs were given to add?!?!'; }
				if(array_size(@addip) > 0) {
					store_value('ipbl.ignore.mismatch.pings', @ignoreCheckob);
					@results[] = color(10).array_size(@addip).' IPs were added to ignore ping mismatch list.'; 
				}
			case 'check':
		#Check if a given IP is already in IP Blacklist config
				@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				@results[] = color(14).'is IPs on IP Blacklist: ';
				@listIPData = ''
				foreach(@arg in @args) {
					@listIPData = ''
					@ip = reg_replace('[%][0]$', '', @arg);
					if(@ip == 'raw' || @ip == 'isp' || @ip == 'ip') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@listIPData = color(8).'['.color(9).@ip.color(8).'] '.color(3)
					if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
						@listIPData .= color(12).'In Blacklist'
					} else {
						@listIPData .= color(10).'Not present'
					}
					foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
						@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
						if(string_starts_with(string(@ip), @startBlock)) {
							@listIPData .= color(8).', '.color(14).'Found On Block Blacklist: '.color(7).@block
							break()
						}
					}
					@results[] = @listIPData;
				} else { @results[] = color(12).'No IPs were given to check?!?!'; }
			case 'notblock':
		#Check all IPs for potential blocks to add to list
				@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				@results[] = color(14).'All IPs not on a Block Blacklist: ';
				@listIPData = ''
				@useLimit = false
				if(array_index_exists(@args, 0)) {
					if(string(@args[0]) == 'true') { @useLimit = true; }
				}
				@ipList = array()
				foreach(@arg in @blacklistIP['IP_Blacklist']) {
					@listIPData = ''
					@ip = reg_replace('[%][0]$', '', @arg);
					if(@ip == 'raw' || @ip == 'isp' || @ip == 'ip') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@listIPData = color(9).@ip.color(3)
					@onBlock = false
					foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
						@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
						if(string_starts_with(string(@ip), @startBlock)) {
							@listIPData .= color(8).', '.color(14).'Found On Block Blacklist: '.color(7).@block
							@onBlock = true
							break()
						}
					}
					if(@onBlock) { continue() } else {
						@type = '.';
						if(string_contains(@ip, ':')) { @type = ':' }
						@split = reg_split('[.:]', @ip);
						foreach(@i: @octet in @split) {
							@color = sha1(@octet)[0];
							# msg(@i.':  '.@color)
							@split[@i] = color(@color).@octet
						}
						# msg(array_implode(@split, color('r').@type))
						@ipList[] = array_implode(@split, color('r').@type);
					}
				} else { @results[] = color(12).'No IPs were given to check?!?!'; }
				@results[] = array_implode(@ipList, '\n');
				@results[] = color(3).'Total IPs not on a Block list: '.color(6).array_size(@ipList);
			# case 'leaderboard':
		# Setup Leaderboard of most pings
			case 'report':
		# Ignored & Blacklisted IP pings notification
				@useMsg = false
				@useReturn = true
				if(array_index_exists(@args, 0)) {
					if(string(@args[0]) == 'true') { @useMsg = true; }
				}
				if(import('ipbl.cmd.IP.report') == 'auto') { @useMsg = true; @useReturn = false; }
				export('ipbl.cmd.IP.report', null);
				@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				foreach(@type: @typeName in array('ignore': 'Ignored', 'blacklist': 'Blacklisted')) {
					@count = 0
					@iplog = get_value('Server.pings.log.'.@type.'.IP');
					if(!is_array(@iplog)) { continue(); }
					if(array_size(@iplog) <= 0) { continue(); }
					@msgStart = color(6).'['.color(9).'Server'.color(6).'] %fb%'.color(14).simple_date('[MM/dd]', time()).color(7).' '.@typeName.' IP ping report:%fb%\n';
					@msgNone = color(6).'['.color(9).'Server'.color(6).'] %fb%'.color(14).simple_date('[MM/dd]', time()).color(7).' No '.@typeName.' IP pings occured today.%fb%';
					@msgGroup1n = '\n'
					@msgStart2 = color(6).'['.color(9).'Server'.color(6).'] %fb%'.color(14).simple_date('[MM/dd]', time()).color(7).' '.@typeName.' IP blocks ping report:%fb%\n';
					@Message = array();
					@Message2 = array();
					@checktime = (time() - 86400000)
					@IPList = array()
					foreach(@ip: @times in @iplog) {
						if(@ip == 'ip' || @ip == 'isp') { continue(); }
						if(array_contains(@serverConfig['Ping_Message_Super_Ignore_IP'], @ip)) { continue(); }
						@count = 0
						foreach(@data in @times) {
							if(@checktime > @data) { continue(); }
							@count++			
						}
						# msg(@type.@count)
						if(@count > 0) {
							@IPList[] = @ip
							@blBlock = ''
							if(@type == 'blacklist') {
								foreach(@block: @ISP in @blacklistIP['IP_Block_Blacklist']) {
									@startBlock = string(reg_replace('[\\/][0-9]+', '', @block));
									if(string_starts_with(string(@ip), @startBlock)) {
										@blBlock = @block
										break()
									}
								}
							}
							@s = ''
							if(@count > 1) { @s = 's' }
							@isp = ''
							@addemoji = 0
							if(@serverConfig['Ping_Message_LookupIP_DB'] == true) {
								@ipdb = _geoip_lookup(@ip);
								if(is_array(@ipdb)) {
									@listIPData = ''
									@cnFlag = ''
									if(@ipdb[@ip]['cn'] != '') { @cnFlag = ':flag_'.to_lower(@ipdb[@ip]['cn']).':' }
									if(@ipdb[@ip]['rcn'] != '') { @cnFlag .= '(reg: :flag_'.to_lower(@ipdb[@ip]['rcn']).':)' }
									# if(@ipdb[@ip]['c'] != '') { @listIPData .= ' '.'Country: '.@ipdb[@ip]['c'] }
									if(@ipdb[@ip]['asn'] != '') {		
										@listIPData .= ' ASN: '.@ipdb[@ip]['asn']
										if(array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb[@ip]['asn'])) {
											if(@blacklistIP['Discovered_ASNs'][@ipdb[@ip]['asn']] > 0) {	@addemoji = 1 } else { @addemoji = 3 }
										}
										if(array_index_exists(@blacklistIP, 'Spam_Player_ASNs')) {
											if(array_contains(@blacklistIP['Spam_Player_ASNs'], @ipdb[@ip]['asn'])) { @addemoji = 4 }
										}
										if(array_index_exists(@blacklistIP, 'Auto_Blacklist_ASNs')) {
											if(array_contains(@blacklistIP['Auto_Blacklist_ASNs'], @ipdb[@ip]['asn'])) {
												@addemoji = 2
												@blacklistIP['IP_Blacklist'][] = @ip;
												export('ipbl.config.IPBlacklist', @blacklistIP);
											}
										}
										if(@addemoji > 0) { @listIPData .= ' %a'.@addemoji.'%' }
									}  else { @listIPData = 'No ASN Found' }
									if(@ipdb[@ip]['aso'] != '') { @listIPData .= ' ASO: '.@ipdb[@ip]['aso'] }
									if(@listIPData == '') { @isp = '' } else { @isp = '['.@cnFlag.to_lower(@listIPData).']' }
								}
							}
							if(@isp == '') {
								if(array_index_exists(@iplog, 'isp', @ip)) {
									@isp = '< '.@iplog['isp'][@ip].' >'
								}
							}
							@rp = ''
							if(@times[0] < @checktime) { @rp = ' %rp%' }
							if(@blBlock != '') { @blBlock = color(8).'(%bk%'.@blBlock.') ' }
							@newMsg = '%fs%'.color(9).@ip.color(7).'%fe%  %fb%'.color(12).@count.color(7).'%fb% ping'.@s.@rp.'   '.@blBlock.color(3).@isp;
							if(@type == 'blacklist' && @blBlock != '') {
								if(@addemoji == 2 || !array_contains(@blacklistIP['IP_Blacklist'], @ip)) { @Message2[] = @newMsg; } else { @Message[] = @newMsg; }
							}
						}
					}
					#Format Messages to Console and Discord
					@rMsg = ''
					if(array_size(@Message) <= 0 && array_size(@Message2) <= 0) {
						switch(@type) {
						case 'ignore':
							continue();
						case 'blacklist':
							@rMsg = @msgNone;
						}
					}
					if(array_size(@Message) <= 0) { @msgGroup1n = ''; } else { @rMsg = @msgStart.array_implode(@Message, '\n'); }
					if(array_size(@Message2) > 0) { @rMsg .= @msgGroup1n.@msgStart2.array_implode(@Message2, '\n'); }
					@cMsg = @rMsg;
					foreach(@key: @rep in array('bk': 'block=', 'rp': '!', 'fs': '', 'fe': '', 'fb': '', 'a1': ' <ASN Known>', 'a2': ' <Auto Added IP to Blacklist>', 'a3': ' <Past ASN>', 'a4': ' <ASN: Known MC Spam>')) {
						@cMsg = replace(@cMsg, '%'.@key.'%', @rep)
					}
					if(@useMsg == true) {
						if(@serverConfig['Ping_Message_Discord'] == true && @serverConfig['Ping_Message_Level'] > 1) {
							if(is_proc('_discordBot_broadcast')) { 
								@dMsg = @rMsg;
								foreach(@key: @rep in array('bk': ':white_medium_square:=', 'rp': ':repeat:', 'fs': '`', 'fe': '`', 'fb': '**', 'a1': ':exclamation:', 'a2': ':no_entry_sign:', 'a3': ':recycle:', 'a4': ':toilet:')) {
									@dMsg = replace(@dMsg, '%'.@key.'%', @rep)
								}
								_discordBot_broadcast('bot', '--ping', @dMsg, 'bot', closure(@msgID){
									@cacheID = import('DiscordBot.bot.msg.IP.Review')
									if(!is_array(@cacheID)) { @cacheID = array() }
									array_set(@cacheID, @msgID, @IPList)
									array_set(@cacheID, 'lastedit', time())
									if(array_size(@cacheID) > 400) {
										@selectKey = array_keys(@cacheID)
										_db_msg_Console('[cmd.ip] IP review msg Cache ('.array_size(@cacheID).'): picked: '.@selectKey[0].'   '.@selectKey[1], 'debug')
										array_remove(@cacheID, @selectKey[0]);
										array_remove(@cacheID, @selectKey[1]);
									}
									export('DiscordBot.bot.msg.IP.Review', @cacheID);
									return(true);
								});
							}
						}
						if(@serverConfig['Ping_Message_Console'] == true && @serverConfig['Ping_Message_Level'] > 0) { 
							if(@sender == 'CONSOLE') { @useReturn = false }
							console(@cMsg, false);
						}
					}
					if(@useReturn == true) {
						@results[] = @cMsg;
					}
				}
		#IP ping time averages
			case 'avgtime':
				@raw = false
				@curate = false
				@type = 'blacklist'
				@allprefix = 'these'
				@filecurate = ''
				@enCheckob = true;
				@showobnoxData = true;
				proc _display_duration(@time) {
					@time = ceil(@time)
					@dateType = 'HH\'h\' mm\'m\' ss\'s\''
					@dl = ''
					if(@time < 60000) {
					#less than min
						@dateType = 'ss\'s\''
					} else if(@time >= 60000 && @time < 3600000) {
					#over 1 min
						@dateType = 'mm\'m\' ss\'s\''
					} else if(@time >= 3600000 && @time < 86400000) {
					#over 1 hour - uses above default.
						@dateType = 'HH\'h\' mm\'m\' ss\'s\''
					} else if(@time >= 86400000) {
					#over 1 day
						@dl = (simple_date('D', @time, 'UTC') - 1).'d '
					} 
					return(@dl.simple_date(@dateType, @time, 'UTC'));
				}
				@printAllPings = true
				if(array_contains(@args, 'print') || array_contains(@args, '-p')) {
					@printAllPings = true;
				}
				if(array_contains(@args, 'print') || array_contains(@args, '-noprint')) {
					@printAllPings = false;
				}
				if(array_contains(@args, 'raw') || array_contains(@args, 'all')) { 
					@raw = true
					@filecurate = ' (All)'
					@allprefix = 'All Known';
					array_remove_values(@args, 'raw')
					array_remove_values(@args, 'all')
				}
				if(array_contains(@args, 'curate')) { 
					@curate = true
					@filecurate = ' (Curated)'
					array_remove_values(@args, 'curate')
				}
				if(array_contains(@args, 'ignore')) { 
					@type = 'ignore'
					array_remove_values(@args, 'ignore')
				}	
				if(array_contains(@args, 'blacklist')) { 
					@type = 'blacklist'
					array_remove_values(@args, 'blacklist')
				}
				if(array_contains(@args, 'obnoxious')) {
					@type = 'obnoxious'
					array_remove_values(@args, 'obnoxious')
				}
				if(array_contains(@args, '-u')) {
					@showobnoxData = false;
					array_remove_values(@args, '-u')
				}
				@usearray = @args[];
				@types = array('ignore': 'Ignored', 'blacklist': 'Blacklisted', 'obnoxious': 'Obnoxious')
				@ipdb = array()
				switch(@type) {
				case 'obnoxious':
					@ipdb = get_value('Server.pings.log.blacklist.IP')
					@usearray = array_keys(@ipdb);
					@allprefix = 'All Listed'
					@printAllPings = false;
				default:
					@ipdb = get_value('Server.pings.log.'.@type.'.IP')
					if(!is_array(@ipdb)) { die('No data of type '.@types[@type]) }
				}
				if(@raw) { @usearray = array_keys(@ipdb); }
				if(@showobnoxData) { @results[] = color(14).'Average Ping Times observed for '.color(9).@allprefix.' '.@types[@type].color(14).' IPs:'.@filecurate; }
				@allavg = array()
				@sortedIPData = array()
				@IPsorteddata = array()
				@obnoxData = array()
				@jsoncfg = array()
				if(array_size(@usearray) <= 0) { die(color(12).'No IPs were provided.') }
				@mancfgArray = array('Obnoxious': array());
				try {
					@mancfg = read(import('ipbl.config.dir').'/Template-IP.yml');
					@mancfgArray = yml_decode(@mancfg);
				} catch(Exception @ex) {
					@results[] = color(12).'There was an error with the Template-IP Config file. '
					# console(@ex)
				}
				foreach(@arg in @usearray) {
					@ip = reg_replace('[%][0]$', '', @arg);
					if(@ip == 'raw' || @ip == 'isp' || @ip == 'ip') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@listIPData = color(14).'['.@ip.'] '.color(3)
					if(!array_index_exists(@ipdb, @ip)) {
						@listIPData .= color(10).'Not present'
						array_set(@obnoxData, @ip, 'Not Present')
						continue()
					}
					@asize = array_size(@ipdb[@ip])
					if(!array_index_exists(@sortedIPData, @asize)) { array_set(@sortedIPData, @asize, array()) }
					@avgtime = 0
					if(@asize == 1) { 
						@listIPData .= color(8).' 1 ping'
						if(@curate) { continue() }
					} else {	
						@listIPData .= ' Total Pings: '.color(9).@asize
						@sumtime = array()
						foreach(@i: @p in @ipdb[@ip]) {
							if(@i < 1) { continue() }
							@sumtime[] = @p - @ipdb[@ip][(@i - 1)]
							# msg(@i.': '.@p.'  '.@sumtime)
						}
						@avgtime = ceil(average(@sumtime))
						if(@avgtime < 3000) {
							@listIPData .= color(8).' Average below 3 second threshold'
							if(@curate) { continue() }
						} else {
							@allavg[] = @avgtime
							@listIPData .= color(6).' Average Time between pings: '.color(9).@avgtime.' ('._display_duration(@avgtime).')'
						}
						array_set(@jsoncfg, @ip, array('t': @avgtime, 'f': _display_duration(@avgtime), 'p': @asize))
					}
					if(@listIPData != color(14).'['.@ip.'] '.color(3)) {
						@IPsorteddata[] = @listIPData
						array_set(@sortedIPData[@asize], @ip, @listIPData)
					}
					if(@asize > 9 && @avgtime < 86400000 && @avgtime > 0) {
						@obArray = array('f': _display_duration(@avgtime), 'p': @asize);
						if(array_index_exists(@mancfgArray, 'Spam_Player_Names')) {
							if(array_index(@mancfgArray['Spam_Player_Names'], @ip) != null) { array_set(@obArray, 'u', array_index(@mancfgArray['Spam_Player_Names'], @ip)) }
						}
						array_set(@obnoxData, @ip, @obArray);
					}
				}
				@ipcount = array_size(@ipdb) - 1;
				if(@printAllPings) {
					foreach(@size: @datas in @sortedIPData) {
						# @ipcount += array_size(@datas)
						@results[] = color(13).'IPs with '.@size.' Total Pings: '.color(8).array_size(@datas)
						@results[] = array_implode(@datas, '\n')
					}
				}
				@allavgtime = ceil(average(@allavg))
				@results[] = color(6).'Total IPs listed: '.color(9).@ipcount.color(6).' | Total Average Time between pings: '.color(9).@allavgtime.' ('._display_duration(@allavgtime).')'
				_write_file(import('ipbl.logs.dir').'/Average '.@types[@type].' IP Ping times'.@filecurate.'.txt', strip_colors(array_implode(@results, '\n')), 'overwrite');
				_write_file(import('ipbl.logs.dir').'/Average '.@types[@type].' IP Ping times'.@filecurate.'.json', json_encode(@jsoncfg), 'overwrite');
				_write_file(import('ipbl.logs.dir').'/Average obnoxious IP Ping times'.@filecurate.'.yml', yml_encode(@obnoxData, true), 'overwrite');
				if(array_size(@obnoxData) > 0 && @showobnoxData) { @results[] = color(14).'Obnoxious: IPs with average times below 1 day and over 10 pings: ('.array_size(@obnoxData).')\n'.color(8).map_implode(@obnoxData, color(9).': ', '\n'.color(8)); }
				#--
				@addtoobList = array();
				@checkobList = array();
				@ignoreCheckob = get_value('ipbl.ignore.mismatch.pings');
				if(!is_array(@ignoreCheckob)) { @ignoreCheckob = array() } 
				foreach(@obIP: @obData in @obnoxData) {
					if(!is_array(@obData)) { continue() }
					if(!array_index_exists(@mancfgArray, 'Obnoxious', @obIP, 'p')) {
						if(@obData['p'] > 28) { array_set(@addtoobList, @obIP, @obData); }
					} else {
						if(@obData['p'] > 20 && @mancfgArray['Obnoxious'][@obIP]['p'] != @obData['p']) {
							if(array_contains(@ignoreCheckob, @obIP)) { continue() }
							@obData['p'] = color(12).@obData['p'];
							array_set(@checkobList, @obIP, @obData);
						}
					}
				}
				if(array_size(@addtoobList) > 0) {
					@getgeoIP = _geoip_lookup(array_keys(@addtoobList))
					if(!is_array(@getgeoIP)) { @getgeoIP = array() }
					foreach(@ip1: @data in @addtoobList) {
						if(array_index_exists(@getgeoIP, @ip1, 'aso')) {
							array_set(@addtoobList[@ip1], 'i', @getgeoIP[@ip1]['aso'])
						}
					}		
					@results[] = color(12).array_size(@addtoobList).color(14).' Obnoxious IPs: 30+ pings, Not found on template list: \n'.color(2).yml_encode(@addtoobList, true);
				}
				# if(array_size(@addtoobList) > 0) { @results[] = color(12).array_size(@addtoobList).color(14).' Obnoxious IPs: 30+ pings, Not found on template list: \n'.color(6).map_implode(@addtoobList, color(2).': ', '\n'.color(6)); }
				if(array_size(@checkobList) > 0 && @enCheckob) { @results[] = color(12).array_size(@checkobList).color(14).' Obnoxious IPs: 20+ pings, with mismatched ping count on template list (does not include non-blacklisted pings!): \n'.color(6).map_implode(@checkobList, color(2).': ', '\n'.color(6)); }
		# Lookup ASN number, ISP, and country of any IP address, using the GeoIP shell command lookup feature.
			case 'geoip':
				@blacklistIP = import('ipbl.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				@raw = false
				if(array_contains(@args, 'raw')) { 
					@raw = true
					array_remove_values(@args, 'raw')
				}
				@ipdb = array()
				@results[] = color(14).'ISP Database Lookup Results:';
				@checkIPs = array();
				foreach(@ip in @args) {
					if(@ip == 'raw') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@checkIPs[] = @ip;
				}
				@ipdb = _geoip_lookup(@checkIPs, @raw);
				if(!is_array(@ipdb)) {
					switch(string(@ipdb)) {
					case 'NoPerms':
						die(color(12).'This command requires configuration to use, see console logs.');
					case 'NoIP':
						die('A Given IP was invalid.');
					case 'DBUpdate':
						die('Required Database files are being updated. Try re-running your query later.');
					default:
						die(color(12).'An error occured, see console logs.');
					}
				}
				foreach(@ip in @checkIPs) {
					@listIPData = color(14).'['.@ip.'] '.color(3)
					if(array_index_exists(@blacklistIP, 'IP_Blacklist')) {
						if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
							@listIPData .= ' <<IP present on blacklist>>'
						}
					}
					if(@raw == true) {
						msg(color(14).'['.@ip.'] '.color(7).@ipdb[@ip]['raw']);
					}
					if(@ipdb[@ip]['c'] != '') { @listIPData .= ' Country: '.@ipdb[@ip]['c'] }
					if(@ipdb[@ip]['cn'] != '') { @listIPData .= ' ('.@ipdb[@ip]['cn'].') ' }
					if(@ipdb[@ip]['rc'] != '') { @listIPData .= ' '.'Registered Country: '.@ipdb[@ip]['rc'] }
					if(@ipdb[@ip]['rcn'] != '') { @listIPData .= ' ('.@ipdb[@ip]['rcn'].') ' }
					if(@ipdb[@ip]['asn'] != '') { @listIPData .= ' ASN: '.@ipdb[@ip]['asn'] }
					if(@ipdb[@ip]['aso'] != '') { @listIPData .= color(10).' | '.@ipdb[@ip]['aso'] }
					if(@ipdb[@ip]['asn'] != '' && array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb[@ip]['asn'])) {
						if(@blacklistIP['Discovered_ASNs'][@ipdb[@ip]['asn']] > 0) { @listIPData .= ' <ASN present on blacklist>' } else { @listIPData .= ' <Past ASN>' }
					}
					if(@listIPData != color(14).'['.@ip.'] '.color(3)) {
						@results[] = @listIPData;
					}
				}
			#---
			}
			if(array_size(@results) > 0) { msg(array_implode(@results, '\n')); }
			return(true);
		}
));