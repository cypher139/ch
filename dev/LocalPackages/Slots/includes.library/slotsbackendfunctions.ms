#-----

proc(_weighted_random, @choices,
        assign(@sumOfWeight, 0)
        foreach(@choices, @choice){
                assign(@sumOfWeight, @sumOfWeight + @choice)
        }
 
        assign(@random, rand(@sumOfWeight))
 
        foreach(array_keys(@choices), @choiceKey){
                if(@random < @choices[@choiceKey]){
                        return(@choiceKey)
                }
                assign(@random, @random - @choices[@choiceKey])
        }
)

proc(_sl_set_sign_text, @here, @0, @1, @2, @3,
	#set up array translations for the picky functions.
	assign(@herea2, array(x: @here[X], y: @here[Y], z: @here[Z], world: @here[world]))
	assign(@herea3, array(@here[X], @here[Y], @here[Z]))
	#Get the item type of the block at the location specified
	assign(@itemdata, get_block_at(@herea3, @here[world]))
	#Check if that block is still a sign.
	if(reg_count('(63|68)(:[0-9]*)?', @itemdata) > 0,
		set_sign_text(@herea2, @0, @1, @2, @3)
		return('complete2')
	,
		return('Not a sign!')
	)
)



proc(_sl_econ_fee, @player, @amount,
	assign(@name, Slots)
	assign(@currentfunds, acc_balance(@player))
	if(@currentfunds < @amount || @currentfunds == @amount,
		if(@currentfunds != 0,
			return(array(die: yes, msg: 'You don\'t have enough funds! '.color(9).'You need '.color(e).'$'.@amount.color(9).' to continue.'))
			,
			return(array(die: yes, msg: 'There isn\'t any funds to collect!'))
		)
		die()
	)
	acc_subtract(@player, @amount)
	assign(@static, get_value(@name.'.econ.static'))
	assign(@acc, get_value(@name.'.econ.static.account'))
	if(@static == yes,
		acc_add(@acc, @amount)
	)

	##### Player Stats: Record lifetime fees charged.
	assign(@plifefees, get_value(@player.'.'.@name.'.stats.alltime.fees'))
	if(@plifefees == null || @plifefees == '',
		assign(@plifefees, 0)
	)
	assign(@pnewlifefees, @plifefees + @amount)
	store_value(@player.'.'.@name.'.stats.alltime.fees', @pnewlifefees)

	##### Stats: Record lifetime fees charged.
	assign(@lifefees, get_value(@name.'.stats.alltime.econ.fees'))
	if(@lifefees == null || @lifefees == '',
		assign(@lifefees, 0)
	)
	assign(@newlifefees, @lifefees + @amount)
	store_value(@name.'.stats.alltime.econ.fees', @newlifefees)

	##### Jackpot: record current useable fees.
	assign(@fees, get_value(@name.'.gameplay.jackpot'))
	if(@fees == null || @fees == '',
		assign(@fees, 0)
	)
	assign(@newfees, @fees + @amount)
	store_value(@name.'.gameplay.jackpot', @newfees)

	##### Stats: Record alltime highest jackpot.
	assign(@alltimejackpot, get_value(@name.'.stats.alltime.jackpot'))
	if(@alltimejackpot == null || @alltimejackpot == '',
		assign(@alltimejackpot, 0)
	)
	assign(@newalltimejackpot, @alltimejackpot + @amount)
	if(@alltimejackpot < @newalltimejackpot,
		store_value(@name.'.stats.alltime.jackpot', @newalltimejackpot)
	)
	return(array(die: no, msg: color(2).' Fee: $'.@amount))	
)


proc(_sl_econ_award, @player, @amount,
	assign(@name, Slots)
	acc_add(@player, @amount)
	assign(@static, get_value(@name.'.econ.static'))
	assign(@acc, get_value(@name.'.econ.static.account'))
	if(@static == yes,
		assign(@currentfunds, acc_balance(@acc))
		if(@currentfunds <= @amount,
			_msgAdmins(color(c).'['.color(7).@name.color(c).'] '.color(c).'WARNING! '.color(7).@name.' detects the "'.@acc.'" account used for funding is out of money, yet a player was supposed to be awarded earnings!'.color(e).' Please refill the account with more money!')
			if(@currentfunds != 0,
				assign(@amount, @currentfunds)
				tmsg(@player, color(c).'['.color(7).@name.color(c).'] '.color(c).'Sorry!! '.color(7).'All we can award you is $'.@amount.'!')
				,
				tmsg(@player, color(c).'['.color(7).@name.color(c).'] '.color(c).'Sorry!! '.color(7).'We are currently bankrupt and cannot award you your earnings.')
				return('FAIL: no funds to give.')
			)
		)
		acc_subtract(@acc, @amount)
	)
	##### Player Stats: Record lifetime earnings.
	assign(@plifeaward, get_value(@player.'.'.@name.'.stats.alltime.earnings'))
	if(@plifeaward == null || @plifeaward == '',
		assign(@plifeaward, 0)
	)
	assign(@pnewlifeaward, @plifeaward + @amount)
	store_value(@player.'.'.@name.'.stats.alltime.earnings', @pnewlifeaward)

	##### Record total money awarded.
	assign(@lifeaward, get_value(@name.'.stats.alltime.econ.award'))
	if(@lifeaward == null || @lifeaward == '',
		assign(@lifeaward, 0)
	)
	assign(@newlifeaward, @lifeaward + @amount)
	store_value(@name.'.stats.alltime.econ.award', @newlifeaward)	
	
	return('complete')
)

