#version 1.0-tmc
proc _chat_wrf(@option) {
@name = 'Discord'
	@return = array('msg': '', 'amount': '', 'list': array())
	#Welcome roles
	if(reg_count('^[Ww]', @option) > 0) {
			@roles = get_value('server.Discord.members.welcomerolesonly')
			if(is_array(@roles)) {
				@return['msg'] = 'members were detected as having only the Welcome Roles.'
				@return['amount'] = array_size(@roles)
			} else {
				@return['msg'] = 'Please run the command before trying to view results!'
				return(@return)
			}
			@membernames = get_value('server.Discord.members.names')
			if(!is_array(@membernames)) { die('plz fill members.names array') }
			foreach(@username: @userid in @membernames) {
				if(array_contains(@roles, @userid)) {
					array_push(@return['list'], @username.' <'.@userid.'>')
				}
			}
		return(@return)
	}
	#No Roles
	if(reg_count('^[Nn]', @option) > 0) {
			@roles = get_value('server.Discord.members.noroles')
			if(is_array(@roles)) {
				@return['msg'] = 'members were detected as having 0 roles.'
				@return['amount'] = array_size(@roles)
			} else {
				@return['msg'] = 'Please run the command before trying to view results!'
				return(@return)
			}
			@membernames = get_value('server.Discord.members.names')
			if(!is_array(@membernames)) { die('plz fill members.names array') }
			foreach(@username: @userid in @membernames) {
				if(array_contains(@roles, @userid)) {
					array_push(@return['list'], @username.' <'.@userid.'>')
				}
			}
		return(@return)
	}
		
	#Save Who Has Roles
	@config = import('Chat.config.Discord')
	if(@config['Welcome_Text_Channel_Name'] == '' || @config['Welcome_Text_Channel_ID'] == '') { die() }

	@membernames = get_value('server.Discord.members.names')
	if(!is_array(@membernames)) { die('plz fill members.names array') }
	@memberroles = get_value('server.Discord.members.roles')
	if(!is_array(@memberroles)) { die('plz fill members.roles array') }
	if(!is_array(@config['Welcome_Roles'])) { die('plz fill welcome roles config') }
	@results = array()
	@sortWR = array_sort(@config['Welcome_Roles'], 'NUMERIC')
	@usersnoroles = array()
	@userswelcomeroles = array()
	foreach(@username: @userid in @membernames) {
	try {
		@userroles = array_normalize(@memberroles[@userid])
	} catch(IndexOverflowException @ex) {
		try {
#		msg('No saved roles for: '.@username)
			@userroles = discord_member_get_roles(@userid)
			if(!array_index_exists(@userroles, 0)) {
				array_push(@usersnoroles, @userid)
				continue()
			} else {
				console('[Discord] User '.@userid.' : discord said roles: '.@userroles, false)
			}
		} catch(NotFoundException @ex) {
			console('[Discord] User '.@username.' "'.@userid.'" was not found on server.', false)
			continue()
		}
	}
		# member.roles: id: ass_array(rolename: roleid)
	#has JUST the welcome roles awarded (amount wise)	
#	msg('ur:'.array_size(@userroles))
		if(array_size(@userroles) == array_size(@sortWR)) {
			#sort arrays so roles are in same key order
			@sortUR = array_sort(@userroles, 'NUMERIC')

			foreach(@key: @roleid in @sortWR) {
				if(@roleid == @sortUR[@key]) {
					array_push(@results, true)
				} else {
					array_push(@results, false)
				}
			}
			if(array_every(@results, closure(@value) { return(@value) }) == true) {
#				msg(@username.' <'.@userid.'> has just the Welcome Roles.')
				array_push(@userswelcomeroles, @userid)
			}
			@results = array()
		}
	}
	array_set(@return, 'zero', array_size(@usersnoroles))
	array_set(@return, 'welcome', array_size(@userswelcomeroles))
	store_value('server.Discord.members.welcomerolesonly', @userswelcomeroles)
	store_value('server.Discord.members.noroles', @usersnoroles)
	return(@return)	
}