#Ignored & Blacklisted IP pings notification
set_cron('59 23 * * *', closure(){
	export('Chat.cmd.IP.report', 'auto');
	run_cmd('/chatip report');
});

#------------------------------
try(unregister_command('chatip'))

register_command('chatip', array(
	'description': 'Chat: Admin: IP address Blacklist management.',
	'usage': color(8).'Examples: /chatip report, /chatip avgtime <IP>, /chatip check <IP>, /chatip geo <IP>',
	'permission': 'Chat.Admin.cmd.IP',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@actsub = array('report', 'avgtime', 'check', 'geoip');
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
	# 'aliases': array('dc'),
	'executor':
		closure(@alias, @sender, @args, @info) {
			@player = @sender;
			@uuid = puuid(@player, 'dashless');
			@id = 0;
			@returnMsg = array(12, '?');
			@cmd = ''
			@name = 'ChatIP'
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
					array_remove(@args, 0);
				case 'c':
				case 'b':
					@cmd = 'check';
					array_remove(@args, 0);
				case 'g':
				case 'l':
					@cmd = 'geoip';
					array_remove(@args, 0);
				case 'a':
				case 't':
					@cmd = 'avgtime';
					array_remove(@args, 0);
				}
			} 
			if(!@cmd) {
				msg(color(12).'['.color(7).@name.color(12).'] '.color(12).'You need to specify a command to run!'); 
				return(false);
			}
		#Common Args
			if(!has_permission(player(), 'Chat.Admin.cmd.IP.'.@cmd)) {
				@cmdmsg = array('report': 'to view the Blackisted IP report', 'check': 'to check if IP is blacklisted here.', 'avgtime': 'to check average IP ping times.', 'geoip': 'to lookup GeoIP information.');
				msg(color(12).'['.color(7).@name.color(12).'] '.color(12).'You do not have permission '.color(7).@cmdmsg[@cmd]); 
				return(true);
			}
			@time = time();
			@serverConfig = import('Chat.config.Server');
			@results = array();
		# Sub Actions:
			switch(@cmd) {
			case 'check':
		#Check if a given IP is already in IP Blacklist config
				@blacklistIP = import('Chat.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				@results[] = color(14).'is IPs on Chat IP Blacklist: ';
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
			# case 'leaderboard':
		# Setup Leaderboard of most pings
			case 'report':
		# Ignored & Blacklisted IP pings notification
				@useMsg = false
				@useReturn = true
				if(array_index_exists(@args, 0)) {
					if(string(@args[0]) == 'true') { @useMsg = true; }
				}
				if(import('Chat.cmd.IP.report') == 'auto') { @useMsg = true; @useReturn = false; }
				export('Chat.cmd.IP.report', null);
				@blacklistIP = import('Chat.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
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
								@ipdb = _chat_lookup_ip_db(@ip);
								if(is_array(@ipdb)) {
									@listIPData = ''
									@cnFlag = ''
									if(@ipdb['cn'] != '') { @cnFlag = ':flag_'.to_lower(@ipdb['cn']).':' }
									if(@ipdb['rcn'] != '') { @cnFlag .= '(reg: :flag_'.to_lower(@ipdb['rcn']).':)' }
									# if(@ipdb['c'] != '') { @listIPData .= ' '.'Country: '.@ipdb['c'] }
									if(@ipdb['asn'] != '') {		
										@listIPData .= ' ASN: '.@ipdb['asn']
										if(array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb['asn'])) {
											if(@blacklistIP['Discovered_ASNs'][@ipdb['asn']] > 0) {	@addemoji = 1 } else { @addemoji = 3 }
										}
										if(array_index_exists(@blacklistIP, 'Spam_Player_ASNs')) {
											if(array_contains(@blacklistIP['Spam_Player_ASNs'], @ipdb['asn'])) { @addemoji = 4 }
										}
										if(array_index_exists(@blacklistIP, 'Auto_Blacklist_ASNs')) {
											if(array_contains(@blacklistIP['Auto_Blacklist_ASNs'], @ipdb['asn'])) {
												@addemoji = 2
												@blacklistIP['IP_Blacklist'][] = @ip;
												export('Chat.config.IPBlacklist', @blacklistIP);
											}
										}
										if(@addemoji > 0) { @listIPData .= ' %a'.@addemoji.'%' }
									}  else { @listIPData = 'No ASN Found' }
									if(@ipdb['aso'] != '') { @listIPData .= ' ISP: '.@ipdb['aso'] }
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
										@key = array_keys(@cacheID)
										array_remove(@key, 'c')
										array_remove(@cacheID, array_sort(@key, 'NUMERIC')[0])
									}
									export('DiscordBot.bot.msg.IP.Review', @cacheID)
									return(true)
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
						@dl = (simple_date('D', @time) - 1).'d '
					} 
					return(@dl.simple_date(@dateType, @time));
				}
				if(array_contains(@args, 'raw')) { 
					@raw = true
					@filecurate = ' (All)'
					@allprefix = 'All Known';
					array_remove_values(@args, 'raw')
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
				@usearray = @args[];
				@types = array('ignore': 'Ignored', 'blacklist': 'Blacklisted', 'obnoxious': 'Obnoxious')
				@ipdb = array()
				switch(@type) {
				case 'obnoxious':
					@odb = import('Chat.config.IPBlacklist')
					if(!is_array(@odb)) { die('Chat config not loaded.') }
					if(!array_index_exists(@odb, 'Obnoxious')) { die('Chat config not loaded..') }
					@usearray = array_keys(@odb['Obnoxious'])
					@allprefix = 'All Listed'
					@ipdb = get_value('Server.pings.log.blacklist.IP')
				default:
					@ipdb = get_value('Server.pings.log.'.@type.'.IP')
					if(!is_array(@ipdb)) { die('No data of type '.@types[@type]) }
				}
				if(@raw) { @usearray = array_keys(@ipdb); }
				@results[] = color(14).'Average Ping Times observed for '.color(9).@allprefix.' '.@types[@type].color(14).' IPs:'.@filecurate;
				@allavg = array()
				@sortedIPData = array()
				@IPsorteddata = array()
				@obnoxData = array()
				@jsoncfg = array()
				if(array_size(@usearray) <= 0) { die(color(12).'No IPs were provided.') }
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
						array_set(@obnoxData, @ip, array('f': _display_duration(@avgtime), 'p': @asize))
					}
				}
				@ipcount = 0
				foreach(@size: @datas in @sortedIPData) {
					@ipcount += array_size(@datas)
					@results[] = color(13).'IPs with '.@size.' Total Pings: '.color(8).array_size(@datas)
					@results[] = array_implode(@datas, '\n')
				}
				@allavgtime = ceil(average(@allavg))
				@results[] = color(6).'Total IPs listed: '.color(9).@ipcount.color(6).' | Total Average Time between pings: '.color(9).@allavgtime.' ('._display_duration(@allavgtime).')'
				_write_file(import('Chat.logs.dir').'/Average '.@types[@type].' IP Ping times'.@filecurate.'.txt', strip_colors(array_implode(@results, '\n')), 'overwrite');
				_write_file(import('Chat.logs.dir').'/Average '.@types[@type].' IP Ping times'.@filecurate.'.json', json_encode(@jsoncfg), 'overwrite');
				_write_file(import('Chat.logs.dir').'/Average obnoxious IP Ping times'.@filecurate.'.yml', yml_encode(@obnoxData, true), 'overwrite');
				if(array_size(@obnoxData) > 0) { @results[] = color(14).'Obnoxious: IPs with average times below 1 day and over 10 pings: ('.array_size(@obnoxData).')\n'.color(8).map_implode(@obnoxData, color(9).': ', '\n'.color(8)); }
		# Lookup ASN number, ISP, and country of any IP address, using the GeoIP shell command lookup feature.
			case 'geoip':
				@blacklistIP = import('Chat.config.IPBlacklist', array('IP_Blacklist': array(), 'IP_Block_Blacklist': array()))
				@raw = false
				if(array_contains(@args, 'raw')) { 
					@raw = true
					array_remove_values(@args, 'raw')
				}
				@ipdb = array()
				@results[] = color(14).'ISP Database Lookup Results:';
				foreach(@ip in @args) {
					if(@ip == 'raw') { continue() }
					if(xor(string_contains(@ip, '.'), string_contains(@ip, ':')) == false) {
						msg(color(12).'Not a valid IP: '.@ip);
						continue()
					}
					@listIPData = color(14).'['.@ip.'] '.color(3)
					@ipdb = _chat_lookup_ip_db(@ip, @raw);
					if(!is_array(@ipdb)) { 
						switch(string(@ipdb)) {
							case 'NoPerms':
								die(color(12).'This command requires configuration to use, see console logs.');
							case 'NoIP':
								msg('Given IP '.@ip.' is invalid.');
								continue()
							default:
								die(color(12).'An error occured, see console logs.');
							}
					}
					if(array_index_exists(@blacklistIP, 'IP_Blacklist')) {
						if(array_contains(@blacklistIP['IP_Blacklist'], @ip)) {
							@listIPData .= ' <<IP present on blacklist>>'
						}
					}
					if(@raw == true) {
						msg(color(14).'['.@ip.'] '.color(7).@ipdb['raw']);
					}
					if(@ipdb['c'] != '') { @listIPData .= ' Country: '.@ipdb['c'] }
					if(@ipdb['cn'] != '') { @listIPData .= ' ('.@ipdb['cn'].') ' }
					if(@ipdb['rc'] != '') { @listIPData .= ' '.'Registered Country: '.@ipdb['rc'] }
					if(@ipdb['rcn'] != '') { @listIPData .= ' ('.@ipdb['rcn'].') ' }
					# if(@ipdb['asn'] != '') { @listIPData .= ' '.'ASN: '.@ipdb['asn'] }
					if(@ipdb['asn'] != '') {
						@listIPData .= ' '.'ASN: '.@ipdb['asn']
						if(array_index_exists(@blacklistIP, 'Discovered_ASNs', @ipdb['asn'])) {
							if(@blacklistIP['Discovered_ASNs'][@ipdb['asn']] > 0) {	@listIPData .= ' <ASN present on blacklist>' } else { @listIPData .= ' <Past ASN>'}
						}
					}
					if(@ipdb['aso'] != '') { @listIPData .= ' '.color(10).'ISP: '.@ipdb['aso'] }
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