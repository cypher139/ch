######################################################
#
#   ReLoad: Fill chests or dispensers, or furnaces in one click!
#   includes for economy support, to be included if the extension CHVault is installed.
#   version 1.0-tza
#
######################################################
proc(_reloader_econ_fee, @player, @amount, 
	assign(@name, import('dispenserreloader.name'))
	assign(@currentfunds, acc_balance(@player))
	if(@currentfunds < @amount || @currentfunds == @amount,
		if(@currentfunds != 0,
			assign(@amount, @currentfunds)
			,
			return(false)
		)
	)
	acc_subtract(@player, @amount)
	assign(@static, get_value(@name.'.econ.static'))
	if(@static == true,
		assign(@acc, get_value(@name.'.econ.static.account'))
		acc_add(@acc, @amount)
	)
	##### Record lifetime money earned.
	assign(@lifefees, get_value(@name.'.stats.econ.fees'))
	if(@lifefees == null || @lifefees == '',
		assign(@lifefees, 0)
	)
	assign(@newlifefees, @lifefees + @amount)
	store_value(@name.'.stats.econ.fees', @newlifefees)
)
