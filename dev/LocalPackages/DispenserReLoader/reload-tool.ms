######################################################
#
#   ReLoad: Fill blocks that have inventories in one click!
#   Main.ms: Tool interaction listener.
#   version 1.2-tmc
#
######################################################
#Include required backend functions
include('modules.library/Core.ms')

#Listen for interactions with the ReLoad tool
bind('player_interact', array(id: 'ReLoad.tool'), array(button: 'left'), @reload) {
	@name = import('dispenserreloader.name')
	@player = _reloader_getplayerID(@reload['player'])
	@verbose = import(@name.'.player.'.@player['id'].'.verbose')

	#Find the tool in the players hand. Don't use just a hand, sorry.
	@tool = pinv(@player['name'], null)
	if(@tool == null || !is_array(@tool)) {
	#ReLoad tool does not bind to Hand.
		die()
	}
	@tooldata = import(@name.'.player.'.@player['id'].'.tool.id.'.@tool['name'])
	if(!is_array(@tooldata)) {
		# No tool data set yet, nothing to do here.
		die()
	}
	if(@tooldata['use'] == true && @reload['action'] == 'left_click_block' && has_permission(@player['name'], 'commandhelper.alias.reloader')) {
		@tooldisplay = _reloader_item_name(@tool['name'])
		# Check: Item permissions
		@defaultitem = import(@name.'.default.item.type')
		if(@defaultitem != @tooldata['item']) {
			if(_reloader_check_perm(@player['name'], 'item', @tooldata['item']) == false) {
				die(color('c').'['.color(6).@name.color('c').'] '.color(7).'You do not have permissions to use item type "'._reloader_item_name(@tooldata['item'])['display'].'".')
			}
		}
		#Fuel: Item check:
		#Brewing stand only supports Blaze Powder, continue to next block if this is not the fuel in use.
		if(@tooldata['fuel'] == true) {
			if(@reload['block'] == 'BREWING_STAND' && @tooldata['item'] != 'BLAZE_POWDER') {
				die(color('c').'['.color(6).@name.color('c').'] '.color(7).'A Brewing Stand does not support any fuel other than Blaze Powder!')
			}
		# Vice Versa, Furnaces don't support Blaze Powder
			if(@reload['block'] != 'BREWING_STAND' && @tooldata['item'] == 'BLAZE_POWDER') {
				die(color('c').'['.color(6).@name.color('c').'] '.color(7).'Only Brewing Stands support Blaze Powder as fuel!')
			}
		}

		# Fill the Block, assigning for return value
		@fillreturn = _reloader_fill(@reload['location'][0], @reload['location'][1], @reload['location'][2], @reload['location'][3], @tooldata['item'], @player['name'], @tooldata['qty'], @tooldata['fuel'], @verbose)
		# Stats messages
		if(@fillreturn['fail'] == true) {
			die(@fillreturn['msg'])
		}
		if(@fillreturn['msg'] == '0') {
			die(color(7).'['.color(6).@name.color(7).'] '.color(3).'Success! However this '._reloader_capitalize(@fillreturn['type']).' was already full of '._reloader_item_name(@tooldata['item'])['display'].'!')
		}
		# Record stats
		_reloader_record_stats(@player['name'], 'tool', 1, @fillreturn['filledqty'], @tooldata['item'], @tooldata['qty'])
		if(@verbose == true) {
			msg(@fillreturn['msg'])
		}
	}
}