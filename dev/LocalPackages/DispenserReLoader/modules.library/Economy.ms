######################################################
#
#   ReLoad: Fill blocks that have inventories in one click!
#   includes for economy support, requires extension: CHVault
#   version 1.1-tmc
#
######################################################
proc _reloader_econ_fee(@player, @amount) { 
	@name = import('dispenserreloader.name')
	if(function_exists('acc_balance') && function_exists('acc_add') && function_exists('acc_subtract')) {
		@currentfunds = acc_balance(@player)
		if(@currentfunds < @amount || @currentfunds == @amount) {
			if(@currentfunds != 0) { @amount = @currentfunds } else { return(false) }
		}
		acc_subtract(@player, @amount)
		if(get_value(@name.'.econ.static') == true) {
			acc_add(get_value(@name.'.econ.static.account'), @amount)
		}
		##### Record lifetime money earned.
		assign(@lifefees, get_value(@name.'.stats.econ.fees'))
		if(@lifefees == null || @lifefees == '') { @lifefees = 0 }
		@newlifefees = @lifefees + @amount
		store_value(@name.'.stats.econ.fees', @newlifefees)
		return(true)
	} else {
		_reloader_msgAdmins(color('c').'['.color(7).@name.color('c').'] '.color('c').'CHVault extension not installed! '.color(7).@name.' is unable to access economy account data.', color(3).'Download the CHVault extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions. \n'.color('r').moo(color(2).'https://letsbuild.net/jenkins/job/CHVault/'.color('r')), true) 
			return(array(fail: true, failmsg: color('c').'['.color(7).@name.color('c').'] '.color('c').'CHVault extension not installed! '.color('r').@name.' is unable to access economy account data.'))
	}
}