#Send messages about server events to the Discords

bind('player_death', array('id': 'DiscordBot.mc.Death', 'priority': 'MONITOR'), null, @death) {
	@botconfig = import('DiscordBot.config.Discord')
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild'])
	@counter = 0
	@dc = get_value('DeathCount.players.death.counter')
	if(!is_array(@dc)) { @dc = array() }
	@uuid = _getplayerID(@death['player'], 'id')
	if(array_index_exists(@dc, @uuid)) { @counter = @dc[@uuid] }
	@counter++
	@countDisplay = '[#'.@counter.'] '
	
	if(has_bind('Chat.msg.Death')) {
		@death['death_message'] = strip_colors(@death['death_message'])
		@death['death_message'] = reg_replace('^\\[#[0-9]+\\]\\s', '', @death['death_message'])
	}

	if(@death['killer'] != null) {
		if(has_bind('Chat.msg.Death')) {
			@pvpmsg = @death['death_message']
		} else {
			@weapon = pinv(@death['killer'], null)
			if(@weapon == null) { 
				@weapon = 'Hand' 
			} else {
				@weapon = _capitalize(string(@weapon['name']), null, null, 'all')
			}
			@pvpmsg = array(
				@death['killer'].' killed '.@death['player'].' wielding '.@weapon, 
				@death['killer'].' slays '.@death['player'].' with a '.@weapon, 
				@death['killer'].' hunts '.@death['player'].' down with a '.@weapon, 
				@death['player'].' took a leap of faith but landed on '.@death['killer'].'\'s '.@weapon, 
				'Score '.@death['killer'].' +1 - '.@death['player'].' 0', 
				@death['player'].' was fragged by '.@death['killer'], 
				@death['player'].' is now redstone thanks to '.@death['killer'].'\'s '.@weapon, 
				@death['killer'].' slapped '.@death['player'].' around a bit too hard.'
			)
			@pvpmsg = array_get_rand(@pvpmsg)
		}
		_discordBot_send_mc_chat(@countDisplay.'\n'.':put_litter_in_its_place: '.@pvpmsg, 'death')
	} else {
		_discordBot_send_mc_chat(@countDisplay.@death['death_message'], 'death')
	}
}
# :people_wrestling: :put_litter_in_its_place: