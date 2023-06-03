bind('player_move', array('id': 'movetest'), null, @event) {
@dev = import('ch.dev.move.test')
if(@dev == true) { msg(pvelocity())}
}

bind('player_toggle_sneak', array('id': 'sneaktest'), null, @event) {
#msg(@event)
@dev = import('ch.dev.move.test')
if(@event['sneaking'] == true) {
if(is_array(pinv()[100]) && @dev == true) {
	#msg(pinv()[100])
	if(pinv()[100]['name'] == 'GOLDEN_BOOTS') {
		msg('1: '.pvelocity()['magnitude'].' ('.pvelocity()['x'].' , '.pvelocity()['y'].' , '.pvelocity()['z'].')')
		set_pvelocity(player(), array('x': 9, 'y': 2, 'z': -9))
		msg('2: '.pvelocity()['magnitude'].' ('.pvelocity()['x'].' , '.pvelocity()['y'].' , '.pvelocity()['z'].')')
	}
}
}
}

bind('entity_damage', array('id': 'RocketBoots.fall'), array('type': 'PLAYER', 'cause': 'FALL'), @event) {
	if(is_array(pinv()[100])) {
		if(pinv()[100]['name'] == 'GOLDEN_BOOTS') {
			msg(color('c').'Ouch, no need for breaking ankles!')
			if(array_index_exists(pinv()[100], 'meta', 'damage')) {
				@setitem = pinv()[100]
				@setitem['meta']['damage'] = 0
				set_pinv(player(), 100, @setitem)
			}
			cancel()
		}
	}
}