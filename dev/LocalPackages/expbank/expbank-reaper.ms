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