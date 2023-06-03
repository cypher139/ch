bind('plugin_message_received', array(id: 'new.test'), null, @event) {
	console(@event)
}

bind('broadcast_message', array(id: 'new.test2'), null, @event) {
	console(@event)
}