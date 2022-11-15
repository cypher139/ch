######################################################
#
#   Main.ms file. This file is run when the server
#   starts up, or the plugin is reloaded. It can be used
#   as an opportunity to register events or do other things
#   when the server initially starts.
#
######################################################

bind('plugin_message_received', array(id: 'new.test'), null, @event) {
	console(@event)
}