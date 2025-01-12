#debug
bind('plugin_message_received', array('id': 'new.test'), null, @event) {
	console(@event)
}