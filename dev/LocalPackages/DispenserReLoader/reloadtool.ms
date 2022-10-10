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
bind('player_interact', array(id: 'ReLoad.tool'), null, @reload) {
	assign(@name, import('dispenserreloader.name'))
	assign(@player, _reloader_getplayerID(@reload['player']))
	assign(@verbose, import(@name.'.player.'.@player['id'].'.verbose'))

	assign(@index, null)
	assign(@tool, pinv(@player['name'], @index)['name'])
	if(@tool == null) {
		#ReLoad tool does not bind to Hand. 
		die()
	}
	
	
	assign(@tooldata, import(@name.'.player.'.@player['id'].'.tool.id.'.@tool))
	if(@tooldata['use'] == true && @reload['action'] == 'left_click_block' && has_permission(@player['name'], 'commandhelper.alias.reloader'),
	#	assign(@tooldata['item'], import(@name.'.player.'.@player['id'].'.tool.id.'.@usetool.'.item'))
	#	assign(@tooldata['qty'], import(@name.'.player.'.@player['id'].'.tool.id.'.@usetool.'.qty'))
	#	assign(@tooldata['fuel'], import(@name.'.player.'.@player['id'].'.tool.id.'.@usetool.'.fuel'))
		assign(@tooldisplay, _reloader_item_name(@tool))
		# Check: Item permissions
		assign(@defaultitem, import(@name.'.default.item.type'))
		if(@defaultitem != @tooldata['item'],
			if(has_permission('commandhelper.alias.reloader.any.item.use'), null,
				if(has_permission('commandhelper.alias.reloader.use.'.@tooldata['item']), null,
					die(color(c).'['.color(6).@name.color(c).'] '.color(7).'You do not have permissions to use item type "'._reloader_item_name(@tooldata['item'])['display'].'".')
				)
			)
		)
		#assigning for return value
		assign(@fillreturn, _reloader_fill(@reload['location'][0], @reload['location'][1], @reload['location'][2], @reload['location'][3], @tooldata['item'], @player['name'], @tooldata['qty'], @tooldata['fuel'], @verbose))
		#stats
		if(@fillreturn['fail'] == true,
			die(@return['msg'])
		)
		if(@fillreturn['msg'] == '0', 
			die(color(7).'['.color(6).@name.color(7).'] '.color(3).'Success! However this '.to_lower(@fillreturn['type']).' was already full of '._reloader_item_name(@tooldata['item'])['display'].'!')
		)
		#record stats
		_reloader_record_stats(@player['name'], tool, 1, @fillreturn['filledqty'], @tooldata['item'], @tooldata['qty'])
		if(@verbose == true,
			msg(@return['msg'])
		)
	)
}
