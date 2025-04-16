######################################################
#
#   bucket: spaming block info to youz
#
######################################################

register_command('bucket', array(
	'description': 'Returns info about the block interacted with, while holding a bucket.',
	'usage': color(8).'Enable with /bucket, then click on a block while holding a bucket.',
	'permission': 'commandhelper.alias.bucket.info',
	'noPermMsg': 'Unknown command. Type "/help" for help.',
	'tabcompleter':
		closure(@alias, @sender, @args, @info) {
			@arg = @args[-1];
			@argPos = array_size(@args) - 1;
			@usetabs = array('<No further arguments>');
		#Compute Tabs for each arg position
			switch(@argPos) {
			case 0:
		#Options
				if(has_permission(@sender, 'commandhelper.alias.bucket.info')) {
					@usetabs = array('Enable')
					if(import('bucket.info.'.puuid(@sender, 'dashless')) == true) { @usetabs = array('Disable') }
				}
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
			@name = 'Bucket';
			if(player() == '~console') { die(color(7).'['.color(6).@name.color(7).'] '.color(7).@name.' is only available for in-game players.') }
			@player = _getplayerID(@sender);
			if(!has_permission(@sender, 'commandhelper.alias.bucket.info')) {
				msg('Unknown command. Type "/help" for help.')
				return(true);
			}
			@enable = import('bucket.info.'.@player['id']);
			if(!is_boolean(@enable)) { @enable = false }
			if(@enable == true) {
				export('bucket.info.'.@player['id'], false)
				msg(color(7).'['.color(6).@name.color(7).'] '.color(7).'Info display for '.@player['display'].color(10).' disabled.')
			} else {
				export('bucket.info.'.@player['id'], !@enable)
			#Give free bucket if none found
				if(phas_item(@player['name'], array('name': 'BUCKET')) <= 0) {
					pgive_item(@player['name'], array('qty': '1', 'name': 'BUCKET'))
					msg(color(6).'You\'ve been given a free bucket!')
				}
			#Add Bind at First Runtime
				if(!has_bind('bucket.info')) {
					bind('player_interact', array('id': 'bucket.info'), array('itemname': 'BUCKET'), @event) {
						if(import('bucket.info.'.puuid(@event['player'], 'dashless')) == true) {
							if(@event['action'] == 'left_click_block' || @event['action'] == 'right_click_block') {
								cancel()
								@id = ''
								@idn = ''
								if(is_numeric(@event['block'])) {
									@id = _capitalize(data_name(@event['block']), true)
									@idn = color(3).' ('.@event['block'].')'
								} else {
									@id = _capitalize(@event['block'], true)
									if(is_proc('_get_data_values')) {
										@idn = color(3).' ('._get_data_values(@event['block']).')'
									} else { 
										@idn = ''
										console('Cannot get data_values info, proc is missing!')
									}
								}
							msg(color(7).'Block ID: '.color(11).@id.color(5).@idn.color(7).' (@'.color(8).integer(@event['location']['x']).','.integer(@event['location']['y']).','.integer(@event['location']['z']).'  Face: '.@event['facing'].color(7).')');
							}
						}
					}
				}
				msg(color(7).'['.color(6).@name.color(7).'] '.color(6).'Enabled!'.color(7).' Left-click a block using a bucket to get information about the block. Use "/bucket" again to disable.');
			}
			return(true);
		}
));