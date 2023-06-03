#version 1.1-tmc

# todo: port death messages to yml file
bind('player_death', array('id': 'Chat.msg.Death', 'priority': 'NORMAL'), null, @death) {
	# Include required backend functions
	include('MessageList.library/DMList-placeholder-'.function_exists('set_placeholders').'.ms')
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
	
	
#---TEST	
#	die(@newmsg)
#---TEST	


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
	@selectedmsg = array_get_rand(@newmsg)
#Setup Format
	if(function_exists('set_placeholders') == true) {
	array(@death['player'], 'weaponnn', 'opponent': 'op')
		@selectedmsg = set_placeholders(array('player': @death['player'], 'weapon': @weapon, 'opponent': @death['killer']), @selectedmsg)
	}

#debug save stats
	#message sent and death types
	array_set(@death, 'newmsg', @selectedmsg)
	@lastd = get_value('server.debug.stats.last.death')
	if(!is_array(@lastd)) { @lastd = array(@death) }
	array_insert(@lastd, @death, 0)
	if(array_index_exists(@lastd, 10)) { array_remove(@lastd, 10) }
	store_value('server.debug.stats.last.death', @lastd)
	
	modify_event('death_message', @dcdisplay.@selectedmsg)
}


#https://letsbuild.net/jenkins/job/CHPlaceholderAPI/
if(function_exists('register_placeholder_hook')) {
	register_placeholder_hook('dm', closure(@player, @placeholder){
		#Death message colors.
		#Color of victim's name.
		@colorplayer = '&7'
		#Color of message.
		@colormsg = '&c'
		#Color of alternate item, such as the person/entity who killed the victim.
		@coloralt = '&9'
		#Color of weapon used in a PvP battle
		@colorweapon = '&3'   
		if(is_array(@player)) {
			@weapon = @player['weapon']
			@opponent = @player['opponent']
			@user = @player['player']
		} else {
			@weapon = 'test1'
			@opponent = 'test2'
			@user = @player
		}

		if(@placeholder == 'weapon') {
			return(@weapon);
		}
		if(@placeholder == 'opponent') {
			return(@opponent);
		}
		if(@placeholder == 'player') {
			return(@user);
		}
		if(@placeholder == 'color_alt') {
			return(@coloralt);
		}
		if(@placeholder == 'color_msg') {
			return(@colormsg);
		}
		if(@placeholder == 'color_player') {
			return(@colorplayer);
		}
		if(@placeholder == 'color_weapon') {
			return(@colorweapon);
		}
	});
}