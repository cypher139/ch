if(is_proc('_discordBot_send_mc_chat')) {
	set_cron('* * * * *', closure(){
		@reaperxpdata = import('expbank.reaper.xp.msg', array());
		@cmsg = '';
		@dmsg = '';
		@mc = 0
		foreach(@m: @data in @reaperxpdata) {
			@Mob = _capitalize(@m, true);
			@count = 'A';
			@s = '';
			@sentence = ' and dropped ';
			if(@data['c'] > 1) { @count = @data['c']; @s = 's'; @sentence = ', dropping a total of '; }
			@cline = '\n';
			@dline = '\n:skull_crossbones: ';
			if(@mc == 0) { @cline = ''; @dline = '' }
			@cmsg .= @cline.@count.' '.@Mob.@s.' died'.@sentence.@data['x'].' XP.';
			@dmsg .= @dline.@count.' '.@Mob.@s.' died'.@sentence.@data['x'].' XP.';
			@mc++
		}
		export('expbank.reaper.xp.msg', null);
		if(@cmsg != '') { console(@cmsg, false) }
		if(@dmsg != '') { _discordBot_send_mc_chat('death', @dmsg); }
	});
} else {
	set_cron('@daily', closure(){
		export('expbank.reaper.xp.msg', null);
	});
}

#Auto convert prototype expbank-reaper version
if(has_value('expbank.accounts.reaper')) {
	console('expbank: Running one time conversion')
	@rpacc = get_value('expbank.accounts.reaper')
	console(@rpacc)
	if(!is_numeric(@rpacc)) { @rpacc = 0 }
	console(@rpacc)
	@newrpacc = get_value('expbank.accounts.server')
	if(!is_array(@newrpacc)) { @newrpacc = array('Community': 0, 'Reaper': @rpacc) }
	@newrpacc['Reaper'] = @rpacc
	store_value('expbank.accounts.server', @newrpacc)
	clear_value('expbank.accounts.reaper')
}


bind('entity_death', array(id: 'EXPBank.Reaper.entity'), null, @death) {
# all entities, includes players
# Save XP dropped to Reaper account
	@rpacc = get_value('expbank.accounts.server')
	if(!is_array(@rpacc)) { @rpacc = array('Community': 0, 'Reaper': 0) }
	@oldxp = @rpacc['Reaper']
	@rpacc['Reaper'] = @rpacc['Reaper'] + @death['xp']
	store_value('expbank.accounts.server', @rpacc)
#Messages:	
	if(@death['xp'] > 0) {
		@reaperxpdata = import('expbank.reaper.xp.msg', array())
		if(!array_index_exists(@reaperxpdata, @death['type'])) { array_set(@reaperxpdata, @death['type'], array('c': 0, 'x': 0)) }
		@reaperxpdata[@death['type']]['c']++
		@reaperxpdata[@death['type']]['x'] = @reaperxpdata[@death['type']]['x'] + @death['xp'] 
		export('expbank.reaper.xp.msg', @reaperxpdata)
	# @msg = 'A '.to_lower(@death['type']).' died and dropped '.@death['xp'].' XP.'
		@fileprefix = 'entity'
		if(@death['type'] == 'PLAYER') {
			@dev = import('ch.player.'.puuid(player(), 'dashless').'.developer')
			if(@dev == true) { msg(@oldxp.' + '.@death['xp']) }
			@fileprefix = 'player'
			# console('debug: entity: PLAYER died')
		}
	}
}