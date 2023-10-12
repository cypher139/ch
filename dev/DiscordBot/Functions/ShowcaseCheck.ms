#version 1.2-tmc
#Check Showcase chat for attachment only
bind('discord_message_received', array('id': 'DiscordBot.showcase.check'), null, @discord) {
	if(!array_contains(import('DiscordBot.Guilds'), @discord['serverid'])) { die('noGuild') }
	array_set(@discord, 'time', time());
	@botconfig = import('DiscordBot.config.Discord');
	@config = import('DiscordBot.config.'.@discord['serverid']);
	@ytregex = '^https:[/]{2}[w]{0,3}[.]?youtu[.]?be[./](?:com[/]watch[?]v=)?[A-z0-9]{11}(?:[?]?si=[A-z0-9-]{16})?$'
	
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
					#Check for picture, or description if same user
					if(!array_index_exists(@msg, 'attachments', 0, 'filename') && @msg['userid'] != @discord['userid']) {
						continue()
					}
					#If this message was beyond timeout (3 days), remove & continue
					if(time() > (@msg['time'] + 259200000)) {
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
					# --- Same user commenting ---
					if(@checkMsg['userid'] == @discord['userid']) {
						# Previous message was the showcase - via picture
						# Allowed to show multiple project pictures
						if(array_index_exists(@checkMsg, 'attachments', 0, 'filename')) {
							@isAllowed = true
						} else if(reg_count(@ytregex, @discord['message']) > 0) {
						# Previous message was the showcase	- comment.
						# YT link in new message Allowed, in case of new project post / multiple videos needed
							@isAllowed = true
						} else if(@checkMsg['time'] > (time() - 120000)) {
						# Multiple comments in short time period (2 mins) - might be about the same project, allow just in case.
							@isAllowed = true
						} else {
						# Previous message already is a comment
							@isAllowed = false
							@reaction = '<@'.@discord['userid'].'> To include more details about your project please edit the additional info into your previous post.'
						}
					# --- Different user commenting ---
					} else if(reg_count(@ytregex, @discord['message']) > 0) {
						# Presumin new project post via YT link, if user is replying via a gif style video: shame
						@isAllowed = true
					} else {
						@isAllowed = false
						@reaction = 'Thanks for your comment <@'.@discord['userid'].'>! To avoid chat in the showcases, **add a reaction** to the original post and **talk in <#'.@config['Welcome_Text_Channel_ID'].'>** about the showcased project!'
					}
				} else {
				# No matches found, allow.
					@isAllowed = true
				}
			} else {
				#no previous data, allow once.
				@isAllowed = true
			}
			#Bypass: new post references your previous post
			if(array_index_exists(@discord, 'reference', 'userid')) {
				if(@discord['reference']['userid'] == @discord['userid']) {
					@isAllowed = true
				}
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
			store_value('DiscordBot.'.@discord['serverid'].'.last.message.showcase', @lastmsgs)
		} else { 
		# Save recent deleted messages (ram this time)
			@removedmsgs = import('DiscordBot.'.@discord['serverid'].'.last.message.showcase.removed')
			if(!is_array(@removedmsgs)) { @removedmsgs = array() }
			array_set(@discord, 'reaction', @reaction)
			array_insert(@removedmsgs, @discord, 0)
			if(array_index_exists(@removedmsgs, 20)) { array_remove(@removedmsgs, 20) }
			export('DiscordBot.'.@discord['serverid'].'.last.message.showcase.removed', @removedmsgs)
		}
	#Remove disallowed Post, and message copy to user
		if(@isAllowed == false) {
			consume();
			_discordBot_send_message(':x: '.@reaction.'\n:arrow_right: A copy of your recent message in the Showcase chat is below:\n\n'.@discord['message'], @discord['serverid'], 'bot', @discord['userid'], 'dm');
			try {
				discord_delete_message(@discord['serverid'], @discord['channelid'], @discord['id']);
			} catch(Exception @ex) {
				_db_msg_Console('  ['.@discord['serverid'].'] [Showcase] Cannot remove message "'.@discord['id'].'" from '.@discord['username'].' <@'.@discord['userid'].'> '.@ex['classType'].@ex['message'], @discord['serverid'])
			}
			discord_broadcast(@discord['serverid'], @discord['channelid'], @reaction, closure(@reactionID){
				set_timeout(300000, closure(){
					try {
						discord_delete_message(@discord['serverid'], @discord['channelid'], @reactionID);
					} catch(Exception @ex) {
						_db_msg_Console('  ['.@discord['serverid'].'] [Showcase] Cannot remove my reaction message "'.@reactionID.'" from '.@discord['username'].' <@'.@discord['userid'].'> '.@ex['classType'].@ex['message'], @discord['serverid'])
					}
				});
			});	
		}
	}	
}