bind('player_death', array(id: 'EXPBank.Reaper'), null, @death) {
	@rpacc = get_value('expbank.accounts.reaper')
	@dev = import('ch.player.'.puuid(player(), 'dashless').'.developer')
	@new = ''
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
	@new = ''
	if(is_numeric(@rpacc)) {
		@new = @rpacc + @death['xp']
	} else {
		@new = @death['xp']
	}
	store_value('expbank.accounts.reaper', @new)
	if(@death['xp'] > 0) {
		@msg = 'A '.to_lower(@death['type']).' died and dropped '.@death['xp'].' XP.'
		@fileprefix = ''
		if(@death['type'] == 'PLAYER') {
			@fileprefix = 'player'
		} else {
			@fileprefix = 'entity'
			if(is_proc('_discordBot_send_message')) { _discordBot_send_message(@msg, '', 'death') }
		}
		console(@msg)
		if(is_proc('_write_file')) { _write_file(simple_date('MM-dd-yy_', time()).'entity_death_drop.txt', '\n'.@event, 'append') }
	}
}