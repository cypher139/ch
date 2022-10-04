export('cmdrepeat.console.command.show', get_value('cmdrepeat.console.command.show'))

proc _cmd_getplayerID(@option1) {
	@pid = array()
	if(@option1 == '~console'){
		@pid = array(display: 'Console', name: '~console', id: 'console', nick: 'Server Console')
	} else {
	@pid['display'] = pinfo(@option1)[0];
	@pid['name'] = pinfo(@option1)[0];
	@pid['id'] = puuid(@option1, 'dashless');
	@pid['nick'] = pinfo(@option1)[4];
	}
	#Bedrock to Java players come in with name ".NAME", remove dot
	if(reg_count('^[\\.].*', @pid['name']) == 1, 
		assign(@pid['display'], reg_replace('^[\\.]','', @pid['name']))
	)
	return(@pid)
}