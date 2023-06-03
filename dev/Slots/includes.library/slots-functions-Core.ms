proc _weighted_random(@choices) {
        assign(@sumOfWeight, 0)
        foreach(@choices, @choice){
                assign(@sumOfWeight, @sumOfWeight + @choice)
        }
 
        assign(@random, rand(@sumOfWeight))
 
        foreach(array_keys(@choices), @choiceKey){
                if(@random < @choices[@choiceKey]){
                        return(@choiceKey)
                }
                assign(@random, @random - @choices[@choiceKey])
        }
}

proc _sl_set_sign_text(@here, @0, @1, @2, @3) {
	#set up array translations for the picky functions.
	assign(@herea2, array(x: @here['X'], y: @here['Y'], z: @here['Z'], world: @here['world']))
	assign(@herea3, array(@here['X'], @here['Y'], @here['Z']))
	#Get the item type of the block at the location specified
	assign(@itemdata, get_block(@herea2))
	#Check if that block is still a sign.
	if(reg_count('(63|68)(:[0-9]*)?', @itemdata) > 0,
		set_sign_text(@herea2, @0, @1, @2, @3)
		return('complete2')
	,
		return('Not a sign!')
	)
}