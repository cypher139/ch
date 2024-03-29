#version 1.1-tmc
# Load Server Configs for Minecraft usage
	@return8239 = _chat_load_config('Death_Messages')
	if(!is_array(@return8239)) { die() }

bind('player_death', array('id': 'Chat.msg.Death', 'priority': 'NORMAL'), null, @death) {
	@uuid = _getplayerID(@death['player'], 'id')
	@displaycount = true
	@entitytype = ''
	@dcdisplay = ''
	@dev = import('ch.player.'.@uuid.'.dev.scripts.test')
	if(@dev == true) { msg('p: '.@death['player'].'   c: '.@death['cause'].'   k:'.@death['killer']) }
	@counter = 0
	@dc = get_value('DeathCount.players.death.counter')
	if(!is_array(@dc)) { @dc = array() }
	if(array_index_exists(@dc, @uuid)) { @counter = @dc[@uuid] }
	@counter++
	if(@displaycount == true) { @dcdisplay = color(8).'[#'.(@counter).'] '.color('r') }
	@weapon = null
	if(@death['killer'] != null) {
		@entitytype = 'PVP'
		@weapon = pinv(@death['killer'], null)
		if(@weapon == null) { 
			@weapon = 'Hand' 
		} else {
			@weapon = _capitalize(string(@weapon['name']), null, null, 'all')
		}
	}	
	if(array_index_exists(@death['cause'], 'damager') && @death['killer'] == null) {
		@entitytype = entity_type(@death['cause']['damager'])
		#entitytype null for player, damager is player name
		#arrow has a entity id
	} else if(@death['killer'] != null) {
		@entitytype = 'PVP'
	} else {
		@entitytype = 'GENERIC'
	}
	if(@dev == true) { msg(@entitytype) }
# @entitytypedisplay = _capitalize(@entitytype, null, null, 'all')
  

# Load master custom messages list
	@newmsg = import('Chat.config.Death_Messages')
	if(!is_array(@newmsg)) { 
		_chat_msg_Admins('[Chat] Death Messages List file is not properly formatted.') 
		die()
	}
# Unload non-matching array IDs
	switch(@death['cause']['cause']) {
	case 'ENTITY_ATTACK':
	case 'PROJECTILE':
		if(array_index_exists(@newmsg, @death['cause']['cause'], @entitytype)) {
		@newmsg = @newmsg[@death['cause']['cause']][@entitytype]
		} else {
		@newmsg = @newmsg[@death['cause']['cause']]['GENERIC']
		console(color(12).'[Chat] Death Messages does not contain any messages for Entity: '.color(14).@entitytype)
		}
	default:
		if(array_index_exists(@newmsg, @death['cause']['cause'])) {
			@newmsg = @newmsg[@death['cause']['cause']]
		} else {
			@newmsg = @newmsg['CUSTOM']
			console(color(12).'[Chat] Death Messages does not contain any messages for Death Type: '.color(14).@death['cause']['cause'])
		}
	}
#Choose and Display the message
	#Now that a group of messages for the appropriate cause has been selected, we must choose one message.
	if(@dev == true) { msg(@newmsg) }
	@selectedmsg = array_get_rand(@newmsg)
#Setup Format
	@selectedmsg = colorize(_chat_death_msg_format(@death['player'], @selectedmsg, @death['killer'], @weapon))


#debug save stats
	#message sent and death types
	array_set(@death, 'newmsg', @selectedmsg)
	@lastd = get_value('server.debug.stats.last.death')
	if(!is_array(@lastd)) { @lastd = array(@death) }
	array_insert(@lastd, @death, 0)
	if(array_index_exists(@lastd, 20)) { array_remove(@lastd, 20) }
	store_value('server.debug.stats.last.death', @lastd)
	
	modify_event('death_message', @dcdisplay.@selectedmsg)
}