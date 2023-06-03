#version 1.1-tmc
#Check Showcase chat for attachment only
bind('discord_message_received', array('id': 'DiscordBot.showcase.check'), null, @discord) {
	array_set(@discord, 'guild', import('DiscordBot.server.ID'));
	if(!array_contains(import('DiscordBot.Guilds'), @discord['guild'])) { die('noGuild') }
	@botconfig = import('DiscordBot.config.Discord');
	@config = import('DiscordBot.config.'.@discord['guild']);
	
	if(@discord['channelid'] == @config['Showcase_Channel']) {
		@isUser = false
		@isOtherUser = false
		@isAllowed = false
		@reaction = 'To show your cool project please include a picture!\n To react, add a reaction and talk in <#'.@config['Welcome_Text_Channel_ID'].'>'
		if(!array_index_exists(@discord, 'attachments', 0, 'filename')) {
			@lastmsgs = import('DiscordBot.'.@discord['guild'].'.last.message')
			@checkMsg = array();
			@checkIndex = time();
			if(is_array(@lastmsgs)) {
				foreach(@i: @msg in @lastmsgs) {
					if(@msg['channelid'] != @config['Showcase_Channel']) {
						continue()
					} 
					#check for picture, or description if same user
					if(!array_index_exists(@msg, 'attachments', 0, 'filename') && @msg['userid'] != @discord['userid']) {
						continue()
					}
					@checkMsg = @msg
					@checkIndex = @i
					break()
				}
				export('DiscordBot.'.@discord['guild'].'.debug.showcase.checkmsg', array(@checkIndex, @checkMsg));
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
				#no data to check, allow once.
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
				discord_delete_message(@discord['channel'], @discord['id']);
				discord_broadcast(@discord['channelid'], @reaction);
			}
		}
	}	
}