#version 1.9-tmc

bind('entity_damage', array('id': 'Chat.Wish.PvP.listener', 'priority': 'MONITOR'), array('type': 'PLAYER'), @event) {
	if(array_index_exists(@event, 'damager')) {
		if(array_contains_ic(all_players(), @event['damager'])) {
			export('Wish.player.'.puuid(@event['player'], 'dashless').'recent.PvP.damage', array('damager': @event['damager'], 'time': time()))
		}
	}
}

bind('player_chat', array('id': 'Chat.Wish.player', 'priority': 'LOW'), null, @chat) {
	@name = 'Wish'
	@player = player()
	@dev = import('ch.player.'._getplayerID(player())['id'].'.dev.scripts.wish')

	#Save chat for later recall of players who have recently chatted.
	@wlpc = import('wish.last.player.chat', array(@chat))
	if(!is_array(@wlpc)) { @wlpc = array(@chat) }
	#don't save if player already chatted as last player (catches multiple messages by same player, so otherplayers are more likely to be saved)
	if(@wlpc[0]['player'] != player()) { array_insert(@wlpc, @chat, 0) }
	if(array_index_exists(@wlpc, 10)) { array_remove(@wlpc, 10) }
	export('wish.last.player.chat', @wlpc)

# Find if this is a wish or normal chat.
	@wish = _wish_finder('chat', @chat['message'], @player)
	if(@wish['wish'] != true) { 
		if(@dev == true) { msg(@wish['message']) }
		die()
	}
# Are there available wishes?

	
# Is a wish! perform action 
	@grantwish = _wish_granter(@wish['action'], @wish['target'], @player)
	if(@grantwish['success'] == true) {
		broadcast(@grantwish['message'])
	} else {
		if(@dev == true) { msg(@grantwish['message']) }
	}

#save # of wishes made? limit to 100 across server, buy more with econ funds. exponetially more wish more wishes. eg fee = $50 + @wishcounter for 5 wishes


}