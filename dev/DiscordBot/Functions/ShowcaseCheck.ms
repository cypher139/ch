#version 1.1-tmc
#Check Showcase chat for attachment only
bind('discord_message_received', array('id': 'DiscordBot.showcase.check'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	array_set(@discord, 'time', time());
	@botconfig = import('DiscordBot.config.Discord');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	
	if(@discord['channelid'] == @config['Showcase_Channel']) {
		@lastmsgs = get_value('DiscordBot.'.@discord['serverid'].'.last.message.showcase')
		@isUser = false
		@isOtherUser = false
		@isAllowed = false
		@reaction = 'To show your cool project please include a picture!\n To react, add a reaction and talk in <#'.@config['Welcome_Text_Channel_ID'].'>'
		if(!array_index_exists(@discord, 'attachments', 0, 'filename')) {
			@checkMsg = array();
			@checkIndex = @discord['time']
			if(is_array(@lastmsgs)) {
				foreach(@i: @msg in @lastmsgs) {
					if(@msg['channelid'] != @config['Showcase_Channel']) {
						continue()
					} 
					#check for picture, or description if same user
					if(!array_index_exists(@msg, 'attachments', 0, 'filename') && @msg['userid'] != @discord['userid']) {
						continue()
					}
					#If last message was beyond timeout, continue
					if(time() > (@msg['time'] + 345600000)) {
						array_remove(@lastmsgs, @i)
						continue()
					}				
					@checkMsg = @msg
					@checkIndex = @i
					break()
				}
				export('DiscordBot.'.@discord['serverid'].'.debug.showcase.checkmsg', array(@checkIndex, @checkMsg));
				if(array_index_exists(@checkMsg, 'time')) {
				#reference: id,message,userid,username
					#same user commenting
					if(@checkMsg['userid'] == @discord['userid']) {
						# previous message was the showcase
						if(array_index_exists(@checkMsg, 'attachments', 0, 'filename')) {
							@isAllowed = true
						} else {
						#previous message already is a comment
							@isAllowed = false
							@reaction = 'To include more details about your project please edit the additional info into your post above.'
						}
					} else {
					#different user just commenting
						@isAllowed = false
						@reaction = 'Thanks for your comment! To avoid chat in the showcases, **add a reaction** to the original post and **talk in <#'.@config['Welcome_Text_Channel_ID'].'>** about the showcased project!'
					}
					#reference your own post: OK
					if(array_index_exists(@checkMsg, 'reference', 'userid')) {
						if(@checkMsg['reference']['userid'] == @discord['userid']) {
							@isAllowed = true
						}
					}
				} else {
				# No matches found, allow.
					@isAllowed = true
				}
			} else {
				#no previous data, allow once.
				@isAllowed = true
			}
			#this new post references your own
			if(array_index_exists(@discord, 'reference', 'userid')) {
				if(@discord['reference']['userid'] == @discord['userid']) {
					@isAllowed = true
				}
			}
			if(@isAllowed == false) {
				consume();
				discord_delete_message(@discord['serverid'], @discord['channelid'], @discord['id']);
				discord_broadcast(@discord['serverid'], @discord['channelid'], @reaction);
			}
		} else {
		# Allow new person to post with their project
			@isAllowed = true
		}
		if(@isAllowed == true) {
		# Save recent messages (persistently, not ram)
			@lastmsgs = get_value('DiscordBot.'.@discord['serverid'].'.last.message.showcase')
			if(!is_array(@lastmsgs)) { @lastmsgs = array() }
			array_insert(@lastmsgs, @discord, 0)
			if(array_index_exists(@lastmsgs, 50)) { array_remove(@lastmsgs, 50) }
			store_value('DiscordBot.'.@discord['serverid'].'.last.message.showcase', @lastmsgs)
		}
	}	
}