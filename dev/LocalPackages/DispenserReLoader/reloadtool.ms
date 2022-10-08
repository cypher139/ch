######################################################
#
#   ReLoad: Fill chests or dispensers, or furnaces in one click!
#   Main.ms: Tool interaction listener.
#   version 1.1-tmc
#
######################################################
#Include required backend functions
include('includes.library/reload-functions-Core.ms')

#Listen for interactions with the ReLoad tool
bind(player_interact, array(id: 'ReLoad.tool'), null, @reload,
	assign(@name, import('dispenserreloader.name'))
	assign(@player, _reloader_getplayerID(@reload['player']))
	assign(@verbose, import(@name.'.player.'.@player['id'].'.verbose'))
	if(@verbose == null,
		export(@name.'.player.'.@player['id'].'.verbose', get_value(@name.'.player.'.@player['id'].'.verbose'))
	)

	assign(@index, null)
	try(
		assign(@usetool, pinv(@player['name'], @index)[type])
	,@fail,
		#No tool equipped, hand
		die()
	)
	assign(@checktool, import(@name.'.player.'.@player['id'].'.tool.id.'.@usetool))
	if(@checktool == true && @reload['action'] == 'left_click_block' && has_permission(@player['name'], 'commandhelper.alias.reloader'),
		assign(@item, import(@name.'.player.'.@player['id'].'.tool.id.'.@usetool.'.item'))
		assign(@qty, import(@name.'.player.'.@player['id'].'.tool.id.'.@usetool.'.qty'))
		assign(@fuel, import(@name.'.player.'.@player['id'].'.tool.id.'.@usetool.'.fuel'))
		# Check: Item permissions
		assign(@defaultitem, import(@name.'.default.item.type'))
		if(@defaultitem != @item,
			if(has_permission('commandhelper.alias.reloader.any.item.use'), null,
				if(has_permission('commandhelper.alias.reloader.use.'.@item), null,
					die(color(c).'['.color(6).@name.color(c).'] '.color(7).'You do not have permissions to use this item type. ('.data_name(@item).')')
				)
			)
		)
		#assigning for return value
		assign(@return, _reloader_fill(@reload['location'][0], @reload['location'][1], @reload['location'][2], @reload['location'][3], @item, @player['name'], @qty, @fuel, @verbose))
		#stats
		if(@return['fail'] == true,
			die(@return['msg'])
		)
		if(@return['msg'] == '0', 
			die(color(7).'['.color(6).@name.color(7).'] '.color(3).'Success! However this '.to_lower(@return['type']).' was already full of '.data_name(@item).'!')
		)
		#record stats
		_reloader_record_stats(@player['name'], tool, 1, @return['filledqty'], @item, @qty)
		if(@verbose == true,
			msg(@return['msg'])
		)
	)
)
