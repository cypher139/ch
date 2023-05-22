@msgids = get_value('DiscordBot.Welcome.msg.IDs')
	foreach(@k: @v in @msgids) {
	# console(@k.': '.@v, false)
	try {
		@test = @v['time']
	} catch(CastException @ex) {
		console('Error on index: '.@k.'\n\n '.@v)
		array_remove(@msgids, @k)
		store_value('DiscordBot.Welcome.msg.IDs', @msgids)
	}
		/*
			if(time() > (@v['time'] + 1209600000)) {
			# Join Date is past 2 weeks message removal limits, remove msgids and archive join time
				@rmmsgids++
				@user = ''
				if(array_index_exists(@v, 'user')) { @user = ','.@v['user'] }
				_write_file(import('DiscordBot.logs.dir').'/Archived-Join-Dates.csv', @v['time'].','.@k.@user.'\n', 'Append')
				array_remove(@msgids, @k)
			}
			*/
		}
# _discordBot_backup_members();	
_discordBot_update_members();	