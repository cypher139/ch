proc _read_essentials_usermap(@option1) {
#Check for Essentials player UUID database, and import it.
	@file = ''
	@floodgateprefix = '_'
	try {
		@file = parse_args(reg_replace('\\n', ' ', read(file_resolve(sys_properties()['user.dir'].'/plugins/Essentials/usermap.csv'))))
	} catch(Exception @ex) {
		console('[read essentials usermap] '.@ex['message'])
		return(false)
	}
	try {
		@floodgateprefix = string(yml_decode(read(file_resolve(sys_properties()['user.dir'].'/plugins/floodgate/config.yml')))['username-prefix'])
	} catch(Exception @ex) {
		@floodgateprefix = '_'
	}
	@euuid = associative_array()
	# playername (lowercase), uuid (dashes)
	foreach(@line in @file) {
		@data = reg_split(',', @line)
		array_set(@euuid, reg_replace('-', '', @data[1]), reg_replace('^_', @floodgateprefix, @data[0]))
	}
#	msg('3 '.@euuid)
	export('primus.database.Essentials.usermap', @euuid)
	return(@euuid)
}