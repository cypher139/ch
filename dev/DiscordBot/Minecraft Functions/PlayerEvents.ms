#Send messages about server events to the Discords

bind('player_death', array('id': 'DiscordBot.mc.Death', 'priority': 'MONITOR'), null, @death) {
	@botconfig = import('DiscordBot.config.Bot');
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild']);
	@counter = 0
	@dc = get_value('DeathCount.players.death.counter');
	if(!is_array(@dc)) { @dc = array(); }
	@uuid = _getplayerID(@death['player'], 'id');
	if(array_index_exists(@dc, @uuid)) { @counter = @dc[@uuid]; }
	@counter++
	@countDisplay = '[#'.@counter.'] ';
	
	if(has_bind('Chat.msg.Death')) {
		@death['death_message'] = strip_colors(@death['death_message']);
		@death['death_message'] = reg_replace('^\\[#[0-9]+\\]\\s', '', @death['death_message']);
	}

	if(@death['killer'] != null) {
		@pvpmsg = '';
		if(has_bind('Chat.msg.Death')) {
			@pvpmsg = @death['death_message'];
		} else {
			@weapon = pinv(@death['killer'], null);
			if(@weapon == null) { 
				@weapon = 'Hand';
			} else {
				@weapon = _capitalize(string(@weapon['name']), true);
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
			);
			@pvpmsg = array_get_rand(@pvpmsg);
		}
		_discordBot_send_mc_chat(array('event': 'death-pvp', 'emoji': 'death'), @countDisplay.'\n'.':put_litter_in_its_place: '.@pvpmsg);
	} else {
		_discordBot_send_mc_chat(array('event': 'death', 'emoji': 'death'), @countDisplay.@death['death_message']);
	}
}
# :people_wrestling: :put_litter_in_its_place:


bind('player_advancement_done', array('id': 'DiscordBot.mc.adv', 'priority': 'MONITOR'), null, @event) {
	@adv = replace(@event['advancement'], 'minecraft:', '');
	@botconfig = import('DiscordBot.config.Bot');
	@advTrophies = import('DiscordBot.config.AdvancementTrophies');
	if(!@advTrophies) { @advTrophies = _db_load_config('AdvancementTrophies', true); }
	if(!is_array(@advTrophies)) { @advTrophies = array('advancement_trophy': array()); }
	@config = import('DiscordBot.config.'.@botconfig['Primary_Guild']);
	@emoji = 'trophy';
	# 'trophy': array(':onion:', ':trophy:', ':PS5Hidden:', ':PS5Bronze:', ':PS5Silver:', ':PS5Gold:', ':PS5Plat:');
	@emojiTrophies = array('h': 2, 'b': 3, 's': 4, 'g': 5, 'p': 6);
	@title = '';
	@sentence = 'earned the advancement:';
	@eventType = 'advancement';
	# Event also handles player learning Recipes:
	if(!@event['title']) {
		#Recipes: {advancement: minecraft:recipes/combat/iron_boots, player: player, title: }
		if(string_starts_with(@event['advancement'], 'minecraft:recipes')) {
			@emoji = 'paper';
			@sentence = 'found the recipe:';
			@eventType = 'recipe';
			foreach(@i: @word in reg_split('[/]', @event['advancement'])) {
				if(@word == 'minecraft:recipes') { continue(); }
				@punc = ':';
				if(@i == 1) { @punc = ''; }
				@title .= @punc.' '._capitalize(@word, true);
			}
		}
	} else {
	# {advancement: minecraft:story/smelt_iron, player: player, title: Acquire Hardware}
	# {advancement: minecraft:adventure/sleep_in_bed, player: player, title: Sweet Dreams}
		@title = @event['title'];
	}
	if(@title == '') { console(color(12).'Advancement title not given!\n'.@event); die(); }
	#Check for Bedrock equivalent trophy/achievement, if so use corresponding trophy rank emoji.
	if(array_index_exists(@advTrophies, 'advancement_trophy', @adv)) {
		@emoji = array('trophy', @emojiTrophies[@advTrophies['advancement_trophy'][@adv]]);
	}
	@pid = _getplayerID(@event['player']);
	@msg = @pid['nick'].' '.@sentence.' '.@title;
	# console(@msg, false);
	_discordBot_send_mc_chat(array('event': @eventType, 'emoji': @emoji), @msg);
}