######################################################
#
#   ReLoad: Fill blocks that have inventories in one click!
#   includes for Reload that requite the extension: SKCompat.
#   version 1.2-tmc
#
######################################################
proc _reloader_get_pos1(@player) {
	@name = import('dispenserreloader.name')
	#SKCompat available in multiple versions, checking for functionality instead.	
	if(function_exists('sk_pos1')) {
		return(sk_pos1(@player))
	} else {
		_reloader_msgAdmins(color('c').'['.color(7).@name.color('c').'] '.color('c').'SKCompat extension not installed! '.color(7).@player.' tried using "/reloader area". '.color('r').@name.' is unable to determine WorldEdit selection data for Area Mode.', color(3).'Download the SKCompat extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions. \n'.color('r').moo(color(2).'https://letsbuild.net/jenkins/job/SKCompat/'.color('r')), true) 
		return('No Extension')
	}
}

proc _reloader_get_pos2(@player) {
	@name = import('dispenserreloader.name')
	if(function_exists('sk_pos2')) {
		return(sk_pos2(@player))
	} else {
		_reloader_msgAdmins(color('c').'['.color(7).@name.color('c').'] '.color('c').'SKCompat extension not installed! '.color(7).@player.' tried using "/reloader area". '.color('r').@name.' is unable to determine WorldEdit selection data for Area Mode.', color(3).'Download the SKCompat extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions. \n'.color('r').moo(color(2).'https://letsbuild.net/jenkins/job/SKCompat/'.color('r')), true) 
		return('No Extension')
	}
}
