

bind(player_interact, array(id: 'Slots.interaction'), null, @slots,
	assign(@player, @slots[player])
	assign(@you, @player)
#name of script
	assign(@name, Slots)
#name of money
	assign(@mname, Orbs)
#verbose settings
	assign(@verbose, get_value(@you.'.'.@name.'.verbose'))
	assign(@dev, get_value(@you.'.script.developer'))

#stop running script if you are whacking at the air.
if(@slots['action'] !== 'right_click_block' && @slots['action'] !== 'left_click_block', return())

#is it a sign
	if(reg_count('(63|68)(:[0-9]*)?', @slots['block']) > 0,
		assign(@ploc, ploc(@player))
		assign(@here, @slots[location])
		#make location array with key names
		assign(@herea, array(X: @slots[location][0], Y: @slots[location][1], Z: @slots[location][2], world: @slots[location][3]))
		assign(@plevel, plevel(@player))
		assign(@signtext, get_sign_text(@here))

	#has the player created a sign before
		assign(@hassign, get_value(@player.'.'.@name.'.hassign'))
		#error checks
		if(@signtext[0] == '', assign(@signtext[0], 'nulltext'))
		assign(@signtext[0], to_lower(@signtext[0]))

	#grab the correct value from the list
		assign(@locationarray, get_value(@name.'.locations'))
		try(
			foreach(array_keys(@locationarray), @key,
				if(@locationarray[@key][location] == @herea,
					assign(@isaslots, yes)
					assign(@signvalue, @locationarray[@key])
					assign(@signvalue[key], @key)
				)
			)
		,@fail,
			_msgAdmins(color(c).'['.color(7).@name.color(c).'] '.color(c).@name.' is not initialized yet! Please make a '.@name.' sign! (type "['.to_lower(@name).']" when creating a sign)')
			die()
		)

	#assign SIGN values
		#easier to strip colors than to add the colors into == below.
		assign(@sign2, strip_colors(@signtext[2]))
		assign(@sign1, strip_colors(@signtext[1]))
		assign(@signname, strip_colors(@signtext[0]))

		if(@dev == yes,
			try(msg(@signvalue))
		)


	# Start script, if it is a slots sign
		if(@signname == '[slots]' && @isaslots == yes,

		#economy
			assign(@usefee, get_value(@name.'.econ.fee.use'))
			if(@usefee == '' || @usefee == null, assign(@usefee, 50))
			assign(@currentfunds, acc_balance(@player))
	
		
		# Error / hacking checks.

		#Permissions.
			if(has_permission(@player, 'commandhelper.alias.slots'), null,
				die(color(c).'['.color(7).@name.color(c).'] '.color(c).'You don\'t have permission to use '.@name.'!')
			)
		#economy: fee to use sign.
			if(@currentfunds < @usefee, 
				die(color(c).'['.color(7).@name.color(c).'] '.color(7).'You don\'t have enough funds to play!')
			)
			_sl_econ_fee(@player, @usefee)
			assign(@feemsg, color(2).' Fee: $'.@usefee)

		#hacked sign checks
		#Hack check: Colors.
		#A random color is given on sign creation and put in the sign where a player won't notice it. The color on sign must match to continue.

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
				if(reg_count('(.*)'.color(@signvalue[color]), @signtext[@i]) > 0, null,
					#Fail: The color is not present in the exact pattern. Here we check if the color is present at all.
			 		if(string_position(@signtext[@i], color(@signvalue[color])) != -1,
						# Found color somewhere: This means someone probably tried to edit the sign, and happened to get the right color, but not in the right position.
						msg(color(c).'['.color(7).@name.color(c).'] '.color(c).'This '.@name.' sign has been altered:')
						#If one color fails, the other probably will. We will just assume hacked sign.
						break()
					,
					# No colors at all.
						# Compatibility: If everything in the value matches sign, but the color is missing from both value and sign, continue, as it's a old sign.
						if(@signvalue[location] == @herea && @signvalue[color] == k,
							#assign color
							assign(@colorarray, array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c, d, e, f, l, m, n, o, r))
							assign(@color, array_rand(@colorarray, 1, false))
							assign(@color, array_implode(@color))
							assign(@signvalue[color], @color)						
						,
						# Nothing matches. This sign must be hacked.
							msg(color(c).'['.color(7).@name.color(c).'] '.color(c).'This '.@name.' sign has been altered:')
							break()
						)
					)
				)
			)
	#add check: is script already running
		
		# decision: choose what this run's output will be.
		# Numbers here are the percentages you will get the action.
			assign(@choices, array(
				jackpot: 3,
				win: 25,
				block: 35,
				explode: 700,
				nothing: 40,
			))
			assign(@action, _weighted_random(@choices))

			#what to display
			if(@action == 'jackpot', assign(@display0, '$') assign(@display1, '$') assign(@display2, '$'))
			if(@action == 'win', assign(@display0, '/') assign(@display1, '/') assign(@display2, '/'))
			if(@action == 'block', assign(@display0, '=') assign(@display1, '=') assign(@display2, '='))
			if(@action == 'explode', assign(@display0, '!') assign(@display1, '!') assign(@display2, '!'))
			if(@action == 'nothing',
				assign(@rdisplay, array('!', '/', '\\', '$', '=', '*', '^', '(', ')', '-', '~'))
				assign(@d1, array_rand(@rdisplay, 1, false))
				assign(@d2, array_rand(@rdisplay, 1, false))
				assign(@d3, array_rand(@rdisplay, 1, false))
				assign(@display0, array_implode(@d1))
				assign(@display1, array_implode(@d2))
				assign(@display2, array_implode(@d3))
			)

		#todo:
		#decision 
		#stats: all time earnings, all time fees, fees not used up by a jackpot, sign locations, last action done by a sign, total runs, total runs of each action, player total earnings, player total types of wins, highest jackpot, last player that used sign, player and global total blocks earned (Type and qty)
		#more stats: show percentages of choices, 
		#static econ
		#limit of usage of sign in one moment? day?
		#actions
		#fees: econ is mandatory.
		#set_timeout for sign to be random each time. rand(1000-3000), then add previous time for next timeout. run rest of action after last set_timeout.
		#

			#random time for the display to appear.
			assign(@displaytime1, rand(1000, 3500))
			assign(@displaytime2, rand(1500, 2500) + @displaytime1)
			assign(@displaytime3, rand(1000, 2500) + @displaytime2)
			assign(@displaytimeclose, rand(1000, 1500) + @displaytime3)
			if(@dev == yes,
				msg(@displaytime1)
				msg(@displaytime2)
				msg(@displaytime3)
				msg(@displaytimeclose)
			)

			set_timeout(@displaytime1, closure(
				set_sign_text(@here, color(6).'['.@name.']', @display0.'    '.color(@color), color(@color))
			))
			set_timeout(@displaytime2, closure(
				set_sign_text(@here, color(6).'['.@name.']', @display0.'  '.@display1.'  '.color(@color), color(@color))
			))
			set_timeout(@displaytime3, closure(
				set_sign_text(@here, color(6).'['.@name.']', @display0.'  '.@display1.'  '.@display2.color(@color), color(@color))		
			))
			set_timeout(@displaytimeclose, closure(
				if(@action == 'jackpot',
					#get fees charged. multiply by rand(1-4). give player result
					assign(@jackpot, get_value(@name.'.play.jackpot'))
					assign(@reward, @jackpot * rand(1,3))
					if(@dev == yes,
						msg('jackpot: '.@jackpot)
						msg('reward: '.@reward)
					)
					assign(@giveaward, _sl_econ_award(@player, @reward))
					if(@dev == yes, msg(@giveaward))
					#player stats
					store_value(@name.'.play.jackpot', '0')
					set_sign_text(@here, color(6).'['.@name.']', @display0.'  '.@display1.'  '.@display2.color(@color), , color(a).'Jackpot!!!'.color(@color))
					tmsg(@player, color(6).'['.color(7).@name.color(6).'] '.color(a).'You just won the jackpot!!'.color(e).' Awarded: $'.@reward.' '.color(a).@mname)
				)
				if(@action == 'win',
					assign(@jackpot, get_value(@name.'.play.jackpot'))
					assign(@reward, rand(25,100))
					if(@dev == yes,
						msg('jackpot is still: '.@jackpot)
						msg('reward: '.@reward)
					)
					assign(@giveaward, _sl_econ_award(@player, @reward))
					if(@dev == yes, msg(@giveaward))
					set_sign_text(@here, color(9).'['.@name.']', @display0.'  '.@display1.'  '.@display2.color(@color), , color(9).'Win'.color(@color))
					tmsg(@player, color(6).'['.color(7).@name.color(6).'] '.color(9).'You won '.color(e).'$'.@reward.color(9).' '.@mname.'!')
				)
				if(@action == 'block',
				#random blocks, whitelist
					assign(@blocks, get_value(@name.'.play.blocks'))
					if(@blocks == '' || @blocks == null,
						assign(@blocks, array(1, 3, 4, 5, 12, 13, 20, 24, 30, 50, 54, 65, 85, 86, 101, 102))
					)
					assign(@reward, array_rand(@blocks, 1, false))
					assign(@reward, array_implode(@reward))
					assign(@rewardqty, rand(2, 16))
					pgive_item(@player, @reward, @rewardqty)
					#stats: record amount of blocks awarded, player and global. array(INDEX is ID: VALUE is how many)
					#player stats:
					assign(@playerblocks, get_value(@player.'.'.@name.'.alltime.blocks'))
					if(@blocks == '' || @blocks == null, assign(@playerblocks, array()))
					if(array_index_exists(@playerblocks, @reward) == false, 
						assign(@playerblocks[@reward], 0)
					)
					assign(@playerblocks[@reward], @rewardqty + @playerblocks[@reward])
					store_value(@player.'.'.@name.'.alltime.blocks', @playerblocks)
					set_sign_text(@here, color(e).'['.@name.']', @display0.'  '.@display1.'  '.@display2.color(@color), , color(e).'Blocks.'.color(@color))
					tmsg(@player, color(6).'['.color(7).@name.color(6).'] '.color(e).'You won '.color(7).@rewardqty.' '.data_name(@reward).color(e).' blocks!')
				)
				if(@action == 'explode',
				#idea: worldguard region check, if part of no explode region set explosion to 0, and kill player instead.
					set_timeout(1000, closure(msg(color(4).'['.color(7).@name.color(4).'] '.color(7).'3')))
					set_timeout(2000, closure(msg(color(4).'['.color(7).@name.color(4).'] '.color(7).'2')))
					set_timeout(3000, closure(msg(color(4).'['.color(7).@name.color(4).'] '.color(7).'1')))
					#sound effect, then
					set_timeout(4000, closure(
						make_effect(@ploc, GHAST_SHRIEK, 32)
					))
					#explosion at sign location
					set_timeout(4900, closure(
						explosion(@ploc, 3)
					))

					#idea to make sure sign is blown up an dnot rely on bad player positiong, find what is different in the x and z coords of player than sign, then add 1 to x z of sign loc for explosion use player				
			
					#ungrief: store last location of exploded sign and the 2 other last ones
					assign(@e1, get_value(@name.'.last.explodedsign.1'))
					assign(@e2, get_value(@name.'.last.explodedsign.2'))
					store_value(@name.'.last.explodedsign.1', @signvalue)
					store_value(@name.'.last.explodedsign.2', @e1)
					store_value(@name.'.last.explodedsign.3', @e2)
					set_sign_text(@here, color(4).'['.@name.']', @display0.'  '.@display1.'  '.@display2.color(@color), , color(4).'Explode!!'.color(@color))
					tmsg(@player, color(4).'['.color(7).@name.color(4).'] '.color(7).'This '.@name.' will now explode!')
				)
				if(@action == 'nothing',
					set_sign_text(@here, color(7).'['.@name.']', @display0.'  '.@display1.'  '.@display2.color(@color), color(7), color(@color))
				)


			))
	

			##### Stats:
			#record last action for this sign
			assign(@locationarray, get_value(@name.'.locations'))
			foreach(array_keys(@locationarray), @key,
				if(@locationarray[@key][location] == @herea,
					assign(@signvalue, @locationarray[@key])
					assign(@signvalue[key], @key)
				)
			)
			assign(@array, array(location: @herea, creator: @signvalue[creator], lastrun: @action, lastplayer: @player, color: @signvalue[color]))
			if(@action != 'explode',
				array_set(@locationarray, @signvalue[key], @array)
			,
				array_remove(@locationarray, @key)
				try(
					break_block(@herea)
				,@fail, msg('b: '.@fail)
				)
			)
			store_value(@name.'.locations', @locationarray)

			#last location used - player
			store_value(@player.'.'.@name.'.last.signused', @signvalue)
			#last location used - global
			store_value(@name.'.stats.lastsignused', @signvalue)
			#total runs
			assign(@tr, get_value(@name.'.stats.alltime.runs'))
			if(@tr == '' || @tr == null, assign(@tr, 0))
			assign(@ntr, @tr + 1) 
			store_value(@name.'.stats.alltime.runs', @ntr)
			#total runs - action
			assign(@atr, get_value(@name.'.stats.alltime.runs.'.@action))
			if(@atr == '' || @atr == null, assign(@atr, 0))
			assign(@antr, @atr + 1) 
			store_value(@name.'.stats.alltime.runs.'.@action, @antr)
			#total runs - player
			assign(@ptr, get_value(@player.'.'.@name.'.stats.alltime.runs'))
			if(@ptr == '' || @ptr == null, assign(@ptr, 0))
			assign(@pntr, @ptr + 1) 
			store_value(@player.'.'.@name.'.stats.alltime.runs', @pntr)
			#total runs - player action
			assign(@patr, get_value(@player.'.'.@name.'.stats.alltime.runs.'.@action))
			if(@patr == '' || @patr == null, assign(@patr, 0))
			assign(@pantr, @patr + 1) 
			store_value(@player.'.'.@name.'.stats.alltime.runs.'.@action, @pantr)





			if(@dev == yes,
				try(msg('0: '.@signtext[0].' ...extra data'))
				try(msg('1: '.@signtext[1].' ...extra data'))
				try(msg('2: '.@signtext[2].' ...extra data'))
				try(msg('3: '.@signtext[3].' ...extra data'))
			)
		#sign
		)
	#reg
	)
#bind
)





bind(sign_changed, array(id: 'Slots.sign.creation'), null, @slots,
	assign(@name, Slots)
	#dynamic vars
	assign(@player, @slots[player])
	assign(@you, @player)
	assign(@verbose, get_value(@you.'.'.@name.'.verbose'))
	assign(@dev, get_value(@you.'.script.developer'))

	assign(@here, pcursor(@player))
	assign(@signtext, get_sign_text(@here))
	if(@dev == 'yes', 
		if(@slots[text][0] == '', msg(null))
	)
	assign(@slots[text][0], to_lower(@slots[text][0]))
	if(@dev == 'yes', 
		msg(@slots[text][0])
	)	


#has the player created a sign before
	assign(@hassign, get_value(@player.'.'.@name.'.hassign'))
	if(@dev == 'yes', 
		msg(@slots[text][0])
	)
	if(@slots[text][0] == '[slots]',
		if(has_permission(@you, 'commandhelper.alias.slots.create'),	
			cancel()				

			#new random color
			assign(@colorarray, array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c, d, e, f, l, m, n, o, r))
			assign(@color, array_rand(@colorarray, 1, false))
			assign(@color, array_implode(@color))

			#set up value
			assign(@alllocations, get_value(@name.'.locations'))
			if(@alllocations == null || @alllocations == '', assign(@alllocations, array()))
			assign(@array, array(location: @slots[location], creator: @player, lastrun: new, lastplayer: new, color: @color))

			#economy
			assign(@cfee, get_value(@name.'.econ.fee.create'))
			if(@cfee == '' || @cfee == null, assign(@cfee, 500))
			assign(@currentfunds, acc_balance(@player))

			#economy: create fee.
			if(@currentfunds < @cfee, 
				set_sign_text(@here, color(c).'['.@name.']')
				die(color(c).'['.color(7).@name.color(c).'] '.color(7).'You don\'t have enough funds to create a new sign!')
			)

		#existing value?
			assign(@herea, @slots[location])
			foreach(array_keys(@alllocations), @key,
				if(@alllocations[@key][location] == @herea,
					assign(@existingvalue, yes)
					assign(@existingvaluekey, @key)
					, 
					assign(@existingvalue, no)
				)
				if(@existingvalue == yes,
					if(@player == @alllocations[@existingvaluekey][player],
						tmsg(@alllocations[@existingvaluekey][player], color(c).'['.color(7).@name.color(c).'] '.color(c).' A '.@name.' sign was already here!')
						assign(@useakey, yes)
						assign(@usekey, @existingvaluekey)
						,
						#Another player's sign.

						assign(@useakey, yes)
						assign(@usekey, @existingvaluekey)
						msg(color(c).'['.color(7).@name.color(c).'] '.color(c).'Um... You just took over someone else\'s '.@name.' sign!')
					)
				)
			)
			#Create sign.
			if(@useakey == yes,
				array_set(@alllocations, @usekey, @array)
				,
				array_push(@alllocations, @array)
			)
			_sl_econ_fee(@player, @cfee)
			assign(@feemsg, color(2).' Fee: $'.@cfee)
			#done!
			if(@hassign == '' || @hassign == null,
				store_value(@player.'.'.@name.'.hassign', 'yes')
				tmsg(@player, color(a).'['.color(7).@name.color(a).'] '.color(a).'You just created a '.@name.'!'.@feemsg)
				,
				tmsg(@player, color(a).'['.color(7).@name.color(a).'] '.color(a).'You created another '.@name.'!'.@feemsg)
			)
			store_value(@name.'.locations', @alllocations)
			set_sign_text(@here, color(9).'['.@name.']', color(@color), color(@color))
			,
			set_sign_text(@here, color(c).'['.@name.']')
			tmsg(@player, color(c).'['.color(7).@name.color(c).'] '.color(c).'You don\'t have permission to create a '.@name.'!')
			cancel()


			if(@dev == yes,
				try(msg('0: '.@signtext[0].' ...extra data'))
				try(msg('1: '.@signtext[1].' ...extra data'))
				try(msg('2: '.@signtext[2].' ...extra data'))
				try(msg('3: '.@signtext[3].' ...extra data'))
			)
		)
	)
)

bind(block_break, array(id: 'Slots.sign.deletion'), null, @slots,
	assign(@player, @slots[player]
	assign(@name, Slots)

	#array with keys	
	assign(@herea, array(X: @slots[block][X], Y: @slots[block][Y], Z: @slots[block][Z], world: @slots[block][world]))
	#value

	assign(@locationarray, get_value(@name.'.locations'))

	# Is the location of the broken block part of the locations for Slots?
	# If so we assume this is a sign, and award the player levels he just lost.
	# We don't care if this block actually isn't a sign, as if it isn't a sign (aka worldedited to something else),
	# then we need to get rid of the value for it anyways ;)
	try(
		foreach(array_keys(@locationarray), @key,
			try(if(@locationarray[@key][location] == @herea,
				if(@locationarray[@key][creator] != @player,
					_msgAdmins(color(c).'['.color(7).@name.color(c).'] '.color(c).@player.' just destroyed '.@locationarray[@key][creator].'\'s '.@name.' sign! '.color(7).'Sign Location: '.@locationarray[@key][location])
				)
				#get rid of reference to sign
				array_remove(@locationarray, @key)
				store_value(@name.'.locations', @locationarray)
			))
		)
	,@fail,
		_msgAdmins(color(c).'['.color(7).@name.color(c).'] '.color(c).@name.' is not initialized yet! Please 1make a '.@name.' sign! (type "['.to_lower(@name).']" when creating a sign)')
	)
)
