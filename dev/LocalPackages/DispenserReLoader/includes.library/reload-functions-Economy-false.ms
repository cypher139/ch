######################################################
#
#   ReLoad: Fill chests or dispensers, or furnaces in one click!
#   includes for economy support, to be included if the extension CHVault is NOT installed.
#   version 1.1-tmc
#
######################################################
proc(_reloader_econ_fee, @player, @amount,
	@name = import('dispenserreloader.name')
	_reloader_msgAdmins(color('c').'['.color(7).@name.color('c').'] '.color('c').'CHVault extension not installed! '.color(7).@name.' is unable to access economy account data.', color(3).'Download the CHVault extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions. \n'.color('r').moo(color(2).'https://letsbuild.net/jenkins/job/CHVault/'.color('r')), true) 
        return(array(fail: true, failmsg: color('c').'['.color(7).@name.color('c').'] '.color('c').'CHVault extension not installed! '.color('r').@name.' is unable to access economy account data.'))

)
