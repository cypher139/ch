
bind(player_interact, array(id: 'expbank'), null, @expbank,
	assign(@player, @expbank[player])
	assign(@you, @player)
#name of script
	assign(@name, ExpBank)
#verbose settings
	assign(@verbose, get_value(@you.'.'.@name.'.verbose'))
	assign(@dev, get_value(@you.'.script.developer'))

#stop running script if you are whacking at the air.
if(@expbank['action'] !== 'right_click_block' && @expbank['action'] !== 'left_click_block', return())

#is it a sign
	if(reg_count('(63|68)(:[0-9]*)?', @expbank['block']) > 0,
		assign(@here, @expbank[location])
		#make location array with key names
		assign(@herea, array(X: @expbank[location][0], Y: @expbank[location][1], Z: @expbank[location][2], world: @expbank[location][3]))
		assign(@currentlevel, plevel(@player))
		assign(@signtext, get_sign_text(@here))

	#has the player created a sign before
		assign(@hassign, get_value(@player.'.'.@name.'.hassign'))
		#error checks
		if(@signtext[0] == '', assign(@signtext[0], 'nulltext'))
		assign(@signtext[0], to_lower(@signtext[0]))

	#grab the correct value from the list
		assign(@locationarray, get_value(@name.'.locations'))
		foreach(array_keys(@locationarray), @key,
			if(@locationarray[@key][location] == @herea,
				assign(@isaexpbank, yes)
				assign(@signvalue, @locationarray[@key])
				assign(@signvalue[key], @key)
			)
		)

	#assign SIGN values
		#easier to strip colors than to add the colors into == below.
		assign(@signlevel, strip_colors(@signtext[2]))
		assign(@signplayer, strip_colors(@signtext[1]))
		assign(@signname, strip_colors(@signtext[0]))

		#if(@dev == 'yes',
		#	try(msg(@signvalue))
		#	msg('sl: .'.@signlevel.'...')
		#	try(msg('real: .'.@signvalue[level].'...'))
		#)


	# Start script, if it is a expbank sign
		if(@signname == '[expbank]' && @isaexpbank == yes,
		
	# Error / hacking checks.

		#Permissions.
			if(has_permission(@player, 'commandhelper.alias.expbank'), null,
				die(color(c).'['.color(gold).@name.color(c).'] '.color(c).'You don\'t have permission to use a '.@name.'!')
			)

		# Create your own sign first!
			if(@hassign !== yes || @hassign == null,
				die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'You need to create a '.@name.' first!')
			)
		

		#Hack check: Colors.
		#A random color is given on sign creation and put in the sign where a player won't notice it. The color on sign must match to continue.

		#exact match: level
		#No value color check: We will never be using the &k color code, for this purpose: we know no color is in the system if a &k color shows up.
		if(array_index_exists(@signvalue, color) == true,
			assign(@color, @signvalue[color])
			,
			assign(@signvalue[color], k)
		)
		#A for()? We are checking 2 lines of text, and it would be useless to repeat code.
		for(assign(@i, 1), @i < 3, @i++,
			#This assigns what each line of text means to the value.
			if(@i == 1, assign(@arraysection, player))
			if(@i == 2, assign(@arraysection, level))
			#This is a exact match, checking the exact pattern of the color as it should be on the sign normally.
			if(reg_count(@signvalue[@arraysection].color(@signvalue[color]), @signtext[@i]) > 0, null,
				#Fail: The color is not present in the exact pattern. Here we check if the color is present at all.
		 		if(string_position(@signtext[@i], color(@signvalue[color])) != -1,
					# Found color somewhere: This means someone probably tried to edit the sign, and happened to get the right color, but not in the right position.
					msg(color(c).'['.color(gold).@name.color(c).'] '.color(c).'This '.@name.' sign has been altered:')
					#If one color fails, the other probably will. We will just assume hacked sign.
					break()
				,
				# No colors at all.
					# Compatibility: If everything in the value matches sign, but the color is missing from both value and sign, continue, as it's a old sign.
					if(@signvalue[player] == @player && @signvalue[level] == @signlevel && @signvalue[color] == k,
						#assign color
						assign(@colorarray, array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c, d, e, f, l, m, n, o, r))
						assign(@color, array_rand(@colorarray, 1, false))
						assign(@color, array_implode(@color))
						assign(@signvalue[color], @color)						
					,
					# Nothing matches. This sign must be hacked.
						msg(color(c).'['.color(gold).@name.color(c).'] '.color(c).'This '.@name.' sign has been altered:')
						break()
					)
				)
			)
		)
	

		# Hack check: Incorrect player listed on sign.
		# Scenario: Player1 makes a ExpBank sign, deposits some levels, then edits sign with sign editor to be in Player2's name, so as to allow Player2 to get some levels.

		assign(@tplayer, @player)
		# A sign only holds 15 characters on one line, so if player's name is more than 15 chars, truncate.
		# Note: Testing reveals the sign's text actually has the full name/text, even though it isn't all displayed on the sign in-game.
		# So this player name truncating will work, if the sign actually IS 15 characters or less.
		# For now it is commented out for future reference.
		# if(length(@player) > 15,
		#	assign(@tplayer, @player[..15])
		# )			
			
		#Is this their sign? checking value: is this player the owner of the sign as reported by the value?
			if(@signvalue[player] !== @player,
					if(@signplayer == @tplayer, 
					#This isn't the correct player, but the sign says otherwise.
					#msg admins as to bad sign
					_msgAdmins(color(c).'['.color(gold).@name.color(c).'] '.color(c).'WARNING! '.color(7).@player.' tried to redeem levels on a sign that isn\'t theirs, yet the sign was altered to their player name!')
					die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'This isn\'t the right player!'.color(4).' Transaction halted.')
					,
					#No match: NO stealing from others!
					die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'This isn\'t your own '.@name.'!')
				)
				,
				if(@signplayer !== @tplayer, 
					#While the value reports this is the correct player, the sign doesn't. Transaction will continue and fix the sign.
					msg(color(c).'['.color(gold).@name.color(c).'] '.color(c).'This '.@name.' sign has been altered to be in someone else\'s name. '.color(7).'Since this is really your sign and you are trying to use it, we will reset the sign to report your player name.')
				)
			)
		assign(@valuelevel, @signvalue[level])
		# Hack check: incorrect level on sign.
		# Scenario: Classic hack: Edit sign's level to more than what you actually have deposited, then withdraw the levels. Free EXP!

		#Somehow the sign's level isn't a integer, according to is_integer(), so a strict non-equals (!==) will fail here, thinking every sign is hacked.
			if(@signlevel != @valuelevel,
			#msg admins as to bad sign
				_msgAdmins(color(c).'['.color(gold).@name.color(c).'] '.color(c).'WARNING! '.color(7).@player.' tried to redeem levels on a sign reporting a incorrect amount of levels!')
				die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'This isn\'t the correct amount of levels!'.color(4).' Transaction halted.')
			)
			
			
	# Start transaction.
	
	#economy
	assign(@enableecon, get_value(@name.'.econ.enable'))
	if(@enableecon == '' || @enableecon == null, assign(@enableecon, no))
	assign(@dfee, get_value(@name.'.econ.fee.deposit'))
	if(@dfee == '' || @dfee == null, assign(@dfee, 30))
	assign(@wfee, get_value(@name.'.econ.fee.withdraw'))
	if(@wfee == '' || @wfee == null, assign(@wfee, 30))
	assign(@currentfunds, acc_balance(@player))
	
	#Check: max amount of levels stored
	assign(@maxlevels, get_value(@name.'.max.levels'))
		if(@maxlevels == '' || @maxlevels == null, assign(@maxlevels, 104))
			foreach(@locationarray, @currentvar,
			#Find your signs
			if(@currentvar[player] == @player,
				if(@tsl == '' || @tsl == null, assign(@tsl, 0))
				assign(@tsl, @currentvar[level] + @tsl)
			)
		)			
		if(@expbank[action] == 'left_click_block',
		#bug: if you dont check what the NEW level amount will be, then the max limit is useless.
			if(pinfo(@player)[11] == true,
				assign(@depositamount, @currentlevel)
				,
				assign(@depositamount, 1)
			)
			assign(@newtsl, @tsl + @depositamount)
			if(@tsl == @maxlevels,
				die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'Sorry, but you have already stored the maximum amount of levels allowed on your '.@name.' signs!')
			)
			if(@newtsl > @maxlevels,
				die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'Sorry, but you can\'t deposit that many levels, as you will go over the maximum amount of levels allowed to be stored on your '.@name.' signs!')
			)
		)
	
	
		# Leftclick: deposit
			if(@expbank[action] == 'left_click_block',
				#error check: no levels.
				if(@currentlevel < 1, 
					die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'You don\'t have any levels to deposit!')
				)
				#economy: withdrawal fee.
				if(@enableecon == yes,
					if(@currentfunds < @dfee, 
						die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'You don\'t have enough funds to deposit any levels!')
					)
					_eb_econ_fee(@player, @dfee)
					assign(@feemsg, color(2).' Fee: $'.@dfee)
				)
				#deposit
				assign(@newlevel, @currentlevel)
				##### Record lifetime levels redeemed.
				assign(@lifelevels, get_value(@name.'.alltime.levels'))
				if(@lifelevels == null || @lifelevels == '',
					assign(@lifelevels, 0)
				)
				if(pinfo(@player)[11] == true,
					assign(@plevel, plevel(@player))
					#save how many levels you deposited
					assign(@ttypea, @plevel)
					assign(@newsignlevel, @valuelevel + @plevel)
					set_plevel(@player, 0)
					set_sign_text(@here, color(9).'['.@name.']', @player.color(@color), @newsignlevel.color(@color))
					#value
					assign(@newvalue, array(location: @herea, player: @player, level: @newsignlevel, color: @color))
					assign(@ttype, 3)
					tmsg(@player, color(e).'['.color(gold).@name.color(e).'] '.color(7).'You deposited all your levels! ('.@plevel.')'.@feemsg)
					##### Record lifetime levels redeemed.
					assign(@newlifelevels, @lifelevels + @plevel)
					,
				#not sneaking		
					#math	
					dec(@newlevel, 1)
					inc(@valuelevel, 1)
					set_plevel(@player, @newlevel)
					set_sign_text(@here, color(9).'['.@name.']', @player.color(@color), @valuelevel.color(@color))
					#value
					assign(@newvalue, array(location: @herea, player: @player, level: @valuelevel, color: @color))
					assign(@ttype, 1)
					assign(@ttypea, 1)
					tmsg(@player, color(e).'['.color(gold).@name.color(e).'] '.color(7).'You deposited 1 level!'.@feemsg)
					##### Record lifetime levels redeemed.
					assign(@newlifelevels, @lifelevels + 1)
				)
				store_value(@name.'.alltime.levels', @newlifelevels)				
			)

		# Rightclick: withdraw
			if(@expbank[action] == 'right_click_block',
				#Error check: no levels.
				if(@valuelevel < 1, 
					die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'You don\'t have any levels left to withdraw!')
				)
				#economy: withdrawal fee.
				if(@enableecon == yes,
					if(@currentfunds < @wfee, 
						die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'You don\'t have enough funds to withdraw any levels!')
					)
					_eb_econ_fee(@player, @wfee)
					assign(@feemsg, color(2).' Fee: $'.@wfee)
				)
				#withdraw
				assign(@newlevel, @currentlevel)
				if(pinfo(@player)[11] == true,
					assign(@plevel, plevel(@player))
					#save how many levels you withdrew
					assign(@ttypea, @valuelevel)
					assign(@newsignlevel, 0)
					assign(@newplevel, @plevel + @valuelevel)
					set_plevel(@player, @newplevel)
					set_sign_text(@here, color(9).'['.@name.']', @player.color(@color), @newsignlevel.color(@color))
					#value
					assign(@newvalue, array(location: @herea, player: @player, level: @newsignlevel, color: @color))
					assign(@ttype, 4)
					tmsg(@player, color(e).'['.color(gold).@name.color(e).'] '.color(7).'You withdrew all your levels! ('.@valuelevel.')'.@feemsg)
					,
				#not sneaking
					inc(@newlevel, 1)
					dec(@valuelevel, 1)
					set_plevel(@player, @newlevel)
					set_sign_text(@here, color(9).'['.@name.']', @player.color(@color), @valuelevel.color(@color))
					#value
					assign(@newvalue, array(location: @herea, player: @player, level: @valuelevel, color: @color))
					assign(@ttype, 2)
					assign(@ttypea, 1)
					tmsg(@player, color(e).'['.color(gold).@name.color(e).'] '.color(7).'You withdrew 1 level!'.@feemsg)
				)	
			)
#Why this foreach at the end too? To avoid a ultra rare, probably never gonna happen, potential bug if someone breaks a expbank sign, which removes a index and makes the current index to write to invalid, making this write to wrong index. Just having all bases covered ;)
		assign(@locationarray, get_value(@name.'.locations'))
		foreach(array_keys(@locationarray), @key,
			if(@locationarray[@key][location] == @herea,
				assign(@signvalue[key], @key)
			)
		)
		array_set(@locationarray, @signvalue[key], @newvalue)
		store_value(@name.'.locations', @locationarray)

		#last location used:
		assign(@newvalue[type], @ttype)
		assign(@newvalue[typea], @ttypea)
		store_value(@player.'.'.@name.'.last.signused', @newvalue)

		if(@verbose == yes,
			msg(color(e).'['.color(gold).@name.color(e).'] '.color(7).'Done!')
		)
		,
		if(@verbose == yes,
			if(@signname == '[expbank]',
				msg(color(c).'['.color(gold).@name.color(c).'] '.color(7).'The required data to use this sign was not found!'.color(c).' Transaction halted.')
			)
		)
		#read
		)
	#reg_
	)
#bind
)


bind(sign_changed, array(id: 'expbankcreate'), null, @expbank,
	assign(@name, ExpBank)
	msg('L: '.@expbank[location])
	#dynamic vars
	assign(@player, @expbank[player])
	assign(@you, @player)
	assign(@verbose, get_value(@you.'.'.@name.'.verbose'))
	assign(@dev, get_value(@you.'.script.developer'))

	assign(@here, pcursor(@player))
	assign(@signtext, get_sign_text(@here))
	#if(@dev == 'yes', 
	#	msg('L: '.@expbank[location])
	#)
	if(@dev == 'yes', 
		if(@expbank[text][0] == '', msg(null))
	)
	assign(@expbank[text][0], to_lower(@expbank[text][0]))
	if(@dev == 'yes', 
		msg(@expbank[text][0])
	)	


#has the player created a sign before
	assign(@hassign, get_value(@player.'.'.@name.'.hassign'))
	if(@expbank[text][0] == '[expbank]',
		if(has_permission(@you, 'commandhelper.alias.expbank.create'),	
			cancel()				

			#new random color
			assign(@colorarray, array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c, d, e, f, l, m, n, o, r))
			assign(@color, array_rand(@colorarray, 1, false))
			assign(@color, array_implode(@color))

			#set up value
			assign(@alllocations, get_value(@name.'.locations'))
			if(@alllocations == null || @alllocations == '', assign(@alllocations, array()))
			assign(@locarray, array(X: @expbank[location][0], Y: @expbank[location][1], Z: @expbank[location][2], world: @expbank[location][world]))
			assign(@array, array(location: @locarray, player: @player, level: 0, color: @color))

			#economy
			assign(@enableecon, get_value(@name.'.econ.enable'))
			if(@enableecon == '' || @enableecon == null, assign(@enableecon, no))
			assign(@cfee, get_value(@name.'.econ.fee.create'))
			if(@cfee == '' || @cfee == null, assign(@cfee, 100))
			assign(@currentfunds, acc_balance(@player))

		#existing value? If so this will award the levels lost when re-creating the sign here.

			assign(@herea, @expbank[location])
			foreach(array_keys(@alllocations), @key,
				if(@alllocations[@key][location] == @herea,
					assign(@existingvalue, yes)
					assign(@existingvaluekey, @key)
					, 
					assign(@existingvalue, no)
				)
				if(@existingvalue == yes,
					if(@player == @alllocations[@existingvaluekey][player],
						assign(@awardlevels, @alllocations[@existingvaluekey][level])
						assign(@currentlevel, plevel(@alllocations[@existingvaluekey][player]))
						assign(@newlevel, @currentlevel + @awardlevels)
						set_plevel(@alllocations[@existingvaluekey][player], @newlevel)
						tmsg(@alllocations[@existingvaluekey][player], color(e).'['.color(gold).@name.color(e).'] '.color(c).'One of your '.@name.' signs was destroyed! '.color(7).'There were '.@awardlevels.' levels stored on the sign, so here they are!')
						assign(@useakey, yes)
						assign(@usekey, @existingvaluekey)
						,
						#Another player's sign. This will award the levels on login.
						assign(@awardlevels, @alllocations[@existingvaluekey][level])
						assign(@paward, get_value(@alllocations[@existingvaluekey][player].'.'.@name.'.awardlevels'))
						#check: in case more than one sign has been destroyed before player logs back on, this will add the levels to award together.
						assign(@newlevel, @awardlevels + @paward)
						store_value(@alllocations[@existingvaluekey][player].'.'.@name.'.awardlevels', @newlevel)
						assign(@useakey, yes)
						assign(@usekey, @existingvaluekey)
						msg(color(c).'['.color(gold).@name.color(c).'] '.color(c).'Um... You just took over someone else\'s '.@name.' sign!!')
					)
				)
			)
			#economy: create fee.
			if(@enableecon == yes,
				if(@currentfunds < @cfee, 
					set_sign_text(@here, color(c).'['.@name.']')
					die(color(c).'['.color(gold).@name.color(c).'] '.color(7).'You don\'t have enough funds to create a new sign!')
				)
				_eb_econ_fee(@player, @cfee)
				assign(@feemsg, color(2).' Fee: $'.@cfee)
			)
			#Create sign.
			if(@useakey == yes,
				array_set(@alllocations, @usekey, @array)
				,
				array_push(@alllocations, @array)
			)
			#done!
			if(@hassign == '' || @hassign == null,
				store_value(@player.'.'.@name.'.hassign', 'yes')
				tmsg(@player, color(e).'['.color(gold).@name.color(e).'] '.color(a).'You just created a '.@name.'!'.@feemsg)
				,
				tmsg(@player, color(e).'['.color(gold).@name.color(e).'] '.color(a).'You created another '.@name.'!'.@feemsg)
			)
			if(@dev == 'yes', msg('a: '.@array))
			store_value(@name.'.locations', @alllocations)
			set_sign_text(@here, color(9).'['.@name.']', @player.color(@color), '0'.color(@color))
			,
			set_sign_text(@here, color(c).'['.@name.']')
			tmsg(@player, color(c).'['.color(gold).@name.color(c).'] '.color(c).'You don\'t have permission to create a '.@name.'!')
			cancel()
		)
	)
)



bind(block_break, array(id: 'expbankdelete'), null, @expbank,
	assign(@name, ExpBank)

	#array with keys	
	assign(@herea, array(X: @expbank[block][X], Y: @expbank[block][Y], Z: @expbank[block][Z], world: @expbank[block][world]))
	#value

	assign(@locationarray, get_value(@name.'.locations'))

	# Is the location of the broken block part of the locations for ExpBank?
	# If so we assume this is a sign, and award the player levels he just lost.
	# We don't care if this block actually isn't a sign, as if it isn't a sign (aka worldedited to something else),
	# then we need to get rid of the value for it anyways ;)
	foreach(array_keys(@locationarray), @key,
		try(if(@locationarray[@key][location] == @herea,
			assign(@awardlevels, @locationarray[@key][level])

			#a msg with 0 levels is useless.
			if(@awardlevels == 0,
				#get rid of reference to sign
				array_remove(@locationarray, @key)
				store_value(@name.'.locations', @locationarray) 
				die()
			)

			if(ponline(@locationarray[@key][player]) == true,
				assign(@currentlevel, plevel(@locationarray[@key][player]))
				assign(@newlevel, @currentlevel + @awardlevels)
				set_plevel(@locationarray[@key][player], @newlevel)
				tmsg(@locationarray[@key][player], color(e).'['.color(gold).@name.color(e).'] '.color(c).'One of your '.@name.' signs was destroyed! '.color(7).'There were '.@awardlevels.' levels stored on the sign, so here they are!')
				#get rid of reference to sign
				array_remove(@locationarray, @key)
				store_value(@name.'.locations', @locationarray)
			,
			#not online
				assign(@paward, get_value(@locationarray[@key][player].'.'.@name.'.awardlevels'))
				#check: in case more than one sign has been destroyed before player logs back on, this will add the levels to award together.
				assign(@newlevel, @awardlevels + @paward)
				#assign(@awardarray, array(level: @newlevel, award: yes)) 
				store_value(@locationarray[@key][player].'.'.@name.'.awardlevels', @newlevel)
				#get rid of reference to sign
				array_remove(@locationarray, @key)
				store_value(@name.'.locations', @locationarray)
			)
		))
	)
)

bind(player_join, array(id: 'expbankaward'), null, @expbank,
	assign(@player, player())
	assign(@name, ExpBank)
	assign(@award, get_value(@player.'.'.@name.'.awardlevels'))
	#Award lost levels from destroyed signs when the player logs back in. Using a 3 second timeout so this message isnt regarded as part of the MOTD spam.
	set_timeout(3000, closure(
		if(@award > 0,
			assign(@currentlevel, plevel(@player))
			assign(@newlevel, @currentlevel + @award)
			set_plevel(@player, @newlevel)
			clear_value(@player.'.'.@name.'.awardlevels')
			tmsg(@player, color(e).'['.color(gold).@name.color(e).'] '.color(c).'One or more of your '.@name.' signs were destroyed! '.color(7).'In total there were '.@award.' levels stored on sign(s) that were lost, so here they are!')
		)
	))
)
