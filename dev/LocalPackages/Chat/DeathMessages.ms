bind('player_death', array('id': 'Chat.msg.Death', 'priority': 'NORMAL'), null, @death) {
	# Include required backend functions
	include('includes.library/DeathMessagesList.ms')
	@uuid = puuid(@death['player'], 'dashless')
	@dev = import('ch.player.'.@uuid.'.dev.scripts.test')
	if(@dev == true) { msg('p: '.@death['player'].'   c: '.@death['cause'].'   k:'.@death['killer']) }
	@counter = get_value('DeathCount.players.death.counter')
	@displaycount = true
	if(array_index_exists(@counter, @uuid) && @displaycount == true) { @dcdisplay = color(8).'[#'.(@counter[@uuid] + 1).'] '.color('r') } else { @dcdisplay = ''}
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
  
/*
 checking og death message for mentions superseded by entity id and checks
 $player killed by $entity wielding $weapon
if(string_contains_ic(@death['death_message'], 'by')) {
	@ds = reg_split('by', @death['death_message']) 
	msg(@ds)
}
*/	
# Load master custom messages list
	@newmsg = _chat_death_msg_list(@death['player'], @death['death_message'], @death['killer'], @weapon)
	if(!is_array(@newmsg)) { return(@newmsg) }
# Unload non-matching array IDs
	switch(@death['cause']['cause']) {
	case 'ENTITY_ATTACK':
	case 'PROJECTILE':
		if(array_index_exists(@newmsg, @death['cause']['cause'], @entitytype)) {
		@newmsg = @newmsg[@death['cause']['cause']][@entitytype]
		} else {
		@newmsg = @newmsg[@death['cause']['cause']]['GENERIC']
		console('Death Messages does not contain any messages for Entity: '.@entitytype)
		}
	default:
		if(array_index_exists(@newmsg, @death['cause']['cause'])) {
			@newmsg = @newmsg[@death['cause']['cause']]
		} else {
			@newmsg = @newmsg['CUSTOM']
			console('Death Messages does not contain any messages for Death Type: '.@death['cause']['cause'])
		}
	}
#Choose and Display the message
	#Now that a group of messages for the appropriate cause has been selected, we must choose one message.
	if(@dev == true) { msg(@newmsg) }
	modify_event('death_message', @dcdisplay.array_get_rand(@newmsg))
}