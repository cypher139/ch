#version 1.1-tmc
bind(player_chat, array(id: 'Wish.granter.lolz'), null, @chat,

	assign(@name, 'Wish')
	assign(@player, player())
	assign(@allplayers, all_players())

	assign(@dev, import('ch.player.'.pinfo(player())[20].'.developer'))


#did you say a player name? this will catch it
	@themsg = array()
	assign(@themsg, reg_split(' ', @chat[message]))
	@otherplayer = ''
	foreach(@themsg, @word, 
		if(array_contains_ic(all_players(), @word), assign(@otherplayer, @word))
	)

#	tmsg(@player, @themsg)
#	tmsg(@player, @otherplayer)
#
	if(array_contains(@themsg, 'kick'),
		if(array_contains_ic(@themsg, @otherplayer),
			pkick(@otherplayer, @player.'s wish has been granted')
		)
		if(array_contains_ic(@themsg, 'me'),
			pkick(@player, 'Your wish has been granted.')
			die()
		)
	)
	if(@dev == true, msg(color(7).'[DEV] themsg: '.color(f).@themsg))

	#foreach to find the first instance of "i". save key, then check key + 1 to see == wish.
	#if so, this is a wish (you found "i wish" somewhere in the message), continue.
	#once found, the next key after "wish" should specify the 'victim' player: i (player()), you (meaning last player other than player() who chatted), and @otherplayer - a playername referenced in the chat message. save this as 'victim' player
	#then each action can be written once, using saved player data from this check.
	# for action, only check keys after the player key, as all words in chat message before are not keywords, or have already been checked (i wish $player)
	#action: foreach the split words to evaluate one word at a time, starting from key after playername.
	#use switch for actions, allowing for aliases to keywords (google, or googling). break(2) - switch consumes a break counter- after a action is found and finished, to avoid multiple actions calls (scenario: i wish i was a flying artist would just call 'fly' action and ignore the 'artist' keyword by breaking when finished with 'fly')
	assign(@lastplayerwhochat, array(0: array(player: '~default', message: '0')))
	for(@i = 1, @i <= 5, @i++,
	
		assign(@j, import('server.last.player.chat.'.@i))
		if(@j == '' || @j == null,
			assign(@lastplayerwhochat[@i], array(player: player(), message: 'defaultnull'))
		,
			assign(@lastplayerwhochat[@i], @j)
		)
	 

	)
	#detect i and then wish
	assign(@iswish, false)
	assign(@vplayer, false)
	@ikey = false
	@wishkey = false
	@vpkey = false
	foreach(@key: @word in @themsg){
		if(equals_ic(@word, 'i'),
			#check for wish as the next word
			if(equals_ic(@themsg[@key + 1], 'wish'),
				assign(@iswish, true)
				switch(to_lower(@themsg[@key + 2])){
				case i:
				case me:
					assign(@vpkey, @key + 2)
					if(@dev == true, msg(color(7).'[DEV] player: '.color(f).'It\'s all on you man.'))
					assign(@vplayer, player())
				case you:
				case u:
				case fu:
				case yo:
					assign(@vpkey, @key + 2)
					if(@dev == true, msg(color(7).'[DEV] player: '.color(f).'Using last player who chatted.'))
					for(@i = 1, @i <= 5, @i++,
						if(@lastplayerwhochat[@i][player] == player(),
							assign(@vplayer, player())
	#						msg(1)
							,
							assign(@vplayer, @lastplayerwhochat[@i][player])
	#						msg(2)
							break()
						)
					)
				case for:
				case that:
				#remap, scenario: i wish for PLAYER to BLAH
					assign(@vpkey, @key + 3)
					switch(to_lower(@themsg[@key + 3])){
					case i:
					case me:
						if(@dev == true, msg(color(7).'[DEV] player: '.color(f).'It\'s all on you man.2'))
						assign(@vplayer, player())
					case you:
					case u:
					case yo:
					case fu:
					case idiot:
						if(@dev == true, msg(color(7).'[DEV] player: '.color(f).'Using last player who chatted.2'))
						for(@i = 1, @i <= 5, @i++,
							if(@lastplayerwhochat[@i][player] == player(),
								assign(@vplayer, player())
								,
								assign(@vplayer, @lastplayerwhochat[@i][player])
								break()
							)
						)
					default:
						if(@dev == true, msg(color(7).'[DEV] player: '.color(f).' Default switch, assuming you mentioned a playername.2'))
						assign(@vplayer, @otherplayer)
						if(@otherplayer == '' || @otherplayer == null,
							assign(@vplayer, player())
							if(@dev == true, msg(color(7).'[DEV] player: '.color(f).'No other players online, or no players matching that name! Using player().2'))
						)
					}

				default:
					assign(@vpkey, @key + 2)
					if(@dev == true, msg(color(7).'[DEV] player: '.color(f).' Default switch, assuming you mentioned a playername.'))
					assign(@vplayer, @otherplayer)
					if(@otherplayer == '' || @otherplayer == null,
						assign(@vplayer, player())
						if(@dev == true, msg(color(7).'[DEV] player: '.color(f).'No other players online, or no players matching that name! Using player()'))
					)
					msg('if you got here idk')
				}
			assign(@ikey, @key)
			assign(@wishkey, @key + 1)
			break()
			)
		)
	}

	if(@dev == true, msg(color(7).'[DEV] keys:'.color(3).'i key:'.@ikey.' wish key: '.@wishkey.' player key: '.@vpkey))
	if(@dev == true, msg(color(7).'[DEV] last chatter[1]: '.color(r).@lastplayerwhochat[1][player]))
	if(@dev == true, msg(color(7).'[DEV] last msg[1]: '.color(r).@lastplayerwhochat[1][message]))

	if(@dev == true, msg(color(7).'[DEV] gameplay: '.color(r).'iswish: '.@iswish))
	if(@dev == true, msg(color(7).'[DEV] gameplay: '.color(r).'vplayer: '.@vplayer))


	#must be at end.
	export('server.last.player.chat.5', import('server.last.player.chat.4'))
	export('server.last.player.chat.4', import('server.last.player.chat.3'))
	export('server.last.player.chat.3', import('server.last.player.chat.2'))
	export('server.last.player.chat.2', import('server.last.player.chat.1'))
	export('server.last.player.chat.1', @chat)



	if(@iswish == true,		
		if(@dev == true, 
			msg(color(7).'[DEV] gameplay: '.color(r).'key to start action keywords: '.add(@vpkey, 1))
			msg(color(7).'[DEV] gameplay: '.color(r).'to array size - 1: '.subtract(array_size(@themsg), 1).'. foreach iterations: '.subtract(array_size(@themsg), @vpkey + 1))
		)
		foreach(@key: @word in @themsg[cslice(@vpkey + 1, array_size(@themsg) - 1)]){ 
			if(@dev == true, 
				msg(color(7).'[DEV] gameplay: '.color(r).'Word "'.@key.'" after playername: '.@word)
			)


			switch(to_lower(@word)){
			#die after each action, otherwise multiple actions can be done.
				case die:
				case kill:
				case dead:
				case dust:
					set_timeout(400, closure(broadcast(color(e).'['.color(gold).@name.color(e).'] '.color(6).@player.'\'s wish has been granted.')))
					set_timeout(1000, closure(pkill(@vplayer)))
					die()
				
				case fly:
				case flew:
					broadcast(color(e).'['.color(gold).@name.color(e).'] '.color(6).@player.'s wish has been granted.')
					runas(~console, /rocket @vplayer)

				case google:
				case googling:
					broadcast(color(e).'['.color(gold).@name.color(e).'] '.color(6).@player.'s wish has been granted.')
					assign(@gkey, '')
					foreach(@key: @word in @themsg){
						if(@word == 'google',
							assign(@gkey, @key)
							#Break, in case the search query contains "google", in which case we need the first instance of "google" here.
							break()
						)
					}
					msg('g'.@gkey)
					msg(array_size(@themsg))
					@skey1 = @gkey + 1
					@skey2 = array_size(@themsg) - 1
					@skey3 = @themsg[cslice(@gkey + 1, array_size(@themsg) - 1)]
					msg(@skey3)
					@googlemsg = array_implode(@skey3, +)
					broadcast(color(e).'['.color(gold).@name.color(e).'] '.color(6).'Googling: '.color(3).array_implode(@skey3))
	#not working, keeps 403ing/TOS
	#				http_request('https://cse.google.com/cse?cx=partner-pub-9300639326172081%3Aqi7dvj9mh31&ie=UTF-8&num=5&output=xml_no_dtd&safe=high&q='.@googlemsg, closure(@response){
	#				      console(@response['body']);
	#				});
					die()
			

				case explode:
				case explosion:
					broadcast(color(e).'['.color(gold).@name.color(e).'] '.color(6).@player.'s wish has been granted.')
					assign(@ploc, ploc(@vplayer))
					assign(@ploc[1], @ploc[1] + 1)
					assign(@ploc[y], @ploc[y] + 1)
					explosion(@ploc, 4, false)
			
				case friend:
				case friends:
					broadcast(color(e).'['.color(gold).@name.color(e).'] '.color(6).@player.'s wish has been granted.')
					assign(@ploc, ploc(@vplayer))
					spawn_entity(CREEPER, 2, @ploc)
			
				case artist:
					broadcast(color(e).'['.color(gold).@name.color(e).'] '.color(6).@player.'s wish has been granted.')
					assign(@ploc, ploc(@vplayer))
					assign(@ploc[1], @ploc[1] + 1)
					assign(@ploc[y], @ploc[y] + 1)
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'black')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'red')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'green')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'brown')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'blue')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'purple')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'cyan')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'light_gray')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'gray')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'pink')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'lime')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'yellow')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'light_blue')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'magenta')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'orange')); })
					spawn_entity('sheep', 1, @ploc, closure(@id){ set_entity_spec(@id, array('color': 'white')); })
			#switch
			}
#		if(@dev == true, 
#			msg(color(7).'[DEV] Action returned: '.color(r).@test)
#		)
		#foreach
		}
		play_sound(puuid(player()), array(sound: 'ENTITY_EXPERIENCE_ORB_PICKUP', volume: '16'))
	#if iswish
	)
#bind
)
