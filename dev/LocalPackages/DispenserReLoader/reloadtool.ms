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

	#Find the tool in the players hand. Don't use just a hand, sorry.
	assign(@tool, pinv(@player['name'], null))
	if(@tool == null || !is_array(@tool)) {
	#ReLoad tool does not bind to Hand.
		die()
	}

	assign(@tooldata, import(@name.'.player.'.@player['id'].'.tool.id.'.@tool['name']))	
	if(!is_array(@tooldata)) {
		# No tool data set yet, nothing to do here.
		die()
	}
	if(@tooldata['use'] == true && @reload['action'] == 'left_click_block' && has_permission(@player['name'], 'commandhelper.alias.reloader')) {
		assign(@tooldisplay, _reloader_item_name(@tool['name']))
		# Check: Item permissions
		assign(@defaultitem, import(@name.'.default.item.type'))
		if(@defaultitem != @tooldata['item'],
			if(has_permission('commandhelper.alias.reloader.any.item.use'), null,
				if(has_permission('commandhelper.alias.reloader.use.'.@tooldata['item']), null,
					die(color('c').'['.color(6).@name.color('c').'] '.color(7).'You do not have permissions to use item type "'._reloader_item_name(@tooldata['item'])['display'].'".')
				)
			)
		)
		# Fill the Block, assigning for return value
		assign(@fillreturn, _reloader_fill(@reload['location'][0], @reload['location'][1], @reload['location'][2], @reload['location'][3], @tooldata['item'], @player['name'], @tooldata['qty'], @tooldata['fuel'], @verbose))
		# Stats messages
		if(@fillreturn['fail'] == true) {
			die(@fillreturn['msg'])
		}
		if(@fillreturn['msg'] == '0') {
			die(color(7).'['.color(6).@name.color(7).'] '.color(3).'Success! However this '.to_lower(@fillreturn['type']).' was already full of '._reloader_item_name(@tooldata['item'])['display'].'!')
		}
		# Record stats
		_reloader_record_stats(@player['name'], tool, 1, @fillreturn['filledqty'], @tooldata['item'], @tooldata['qty'])
		if(@verbose == true) {
			msg(@fillreturn['msg'])
		}
	}
}
