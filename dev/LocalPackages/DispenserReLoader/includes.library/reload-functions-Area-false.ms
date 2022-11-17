######################################################
#
#   ReLoad: Fill chests or dispensers, or furnaces in one click!
#   includes for area mode support, to be included if the extension SKCompat is NOT installed.
#   version 1.1-tmc
#
######################################################
proc(_reloader_iterate_cuboid, @proc_name, @world, @item, @player, @qty, @fuel, @verbose,
	assign(@name, import('dispenserreloader.name'))
	_reloader_msgAdmins(color('c').'['.color(7).@name.color('c').'] '.color('c').'SKCompat extension not installed! '.color(7).@player.' tried using "/reloader area". '.color('r').@name.' is unable to determine WorldEdit selection data for Area Mode.', color(3).'Download the SKCompat extension from the downloads link below and save it to <server root>/plugins/CommandHelper/extensions. \n'.color('r').moo(color(2).'https://letsbuild.net/jenkins/job/SKCompat/'.color('r')), true) 
        return(array(fail: true, failmsg: color('c').'['.color(7).@name.color('c').'] '.color('c').'SKCompat extension not installed! '.color('r').@name.' is unable to determine WorldEdit selection data for Area Mode.'))

)
