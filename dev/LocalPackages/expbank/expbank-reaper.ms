bind('player_death', array(id: 'EXPBank.Reaper'), null, @death) {
	@rpacc = get_value('expbank.accounts.reaper')
	@dev = import('ch.player.'.puuid(player(), 'dashless').'.developer')
	
	if(is_numeric(@rpacc)) {
		@new = @rpacc + @death['xp']
		if(@dev == true) { msg(@rpacc.' + '.@death['xp'])}
	} else {
		@new = @death['xp']
	}
	store_value('expbank.accounts.reaper', @new)
}

bind('entity_death', array(id: 'EXPBank.Reaper.entity'), null, @death) {
	@rpacc = get_value('expbank.accounts.reaper')
	if(is_numeric(@rpacc)) {
		@new = @rpacc + @death['xp']
	} else {
		@new = @death['xp']
	}
	store_value('expbank.accounts.reaper', @new)
	if(@death['xp'] > 0) {
		console('entity died: '.@death['type'].' dropping XP:'.@death['xp'])
	}
}