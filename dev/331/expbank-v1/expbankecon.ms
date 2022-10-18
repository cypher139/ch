proc(_eb_econ_fee, @player, @amount,
	acc_subtract(@player, @amount)
	assign(@static, get_value('ExpBank.econ.static'))
	assign(@acc, get_value('ExpBank.econ.static.account'))
	if(@static == yes,
		acc_add(@acc, @amount)
	)
	##### Record lifetime money earned.
	assign(@lifefees, get_value('ExpBank.alltime.fees'))
	if(@lifefees == null || @lifefees == '',
		assign(@lifefees, 0)
	)
	assign(@newlifefees, @lifefees + @amount)
	store_value('ExpBank.alltime.fees', @newlifefees)
)