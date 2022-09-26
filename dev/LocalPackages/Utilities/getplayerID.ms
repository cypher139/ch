proc(_getplayerID, @option1,
	@pid = array()
	@pid[player] = pinfo(@option1)[0];
	@pid[name] = pinfo(@option1)[0];
	@pid[id] = puuid(@option1, dashless);
	@pid[nick] = pinfo(@option1)[4];
	
	#Bedrock to Java players come in with name ".NAME", remove dot
	if(reg_count('^[\\.].*', @pid[player]) == 1, 
		assign(@pid[display], reg_replace('^[\\.]','', @pid[player]))
	)
	return(@pid)
)

proc(_getnick, @player,
	
	assign(@player, pinfo(@player)[0])
	assign(@nick, pinfo(@player)[4])

	if(@player == @nick, return(@player), return(@nick))
)