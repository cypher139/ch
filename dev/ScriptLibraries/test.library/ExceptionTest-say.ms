/** version 1.0
* If compiled, this will throw an exception upon console usage of say command.
* Useful for testing exception handler.
*/
bind('server_command', array('id': 'Chat.Discord.msg.Send2.Console', 'priority': 'MONITOR'), array('prefix': 'say', 'type': 'console'), @event) {
	@channel = 'test'
	# Automatically chat on last channel a message was received on.
	@lastmsg = array(array('channel': 'test', 'time': 23987465))
	if(is_array(@lastmsg)) {
		if(array_index_exists(@lastmsg, 0, 'channel')) {
			if(time() < (@lastmsg[0]['time'] + 234567)) {
				@channel = @lastmsg['channel']
			}	
		}
	}
	console('f')
}	