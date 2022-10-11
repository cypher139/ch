ReadMe.txt

Installation:
To install DispenserReloader, place the DispenserReLoader.mslp file in <server root>/plugins/CommandHelper/LocalPackages. You do not need to extract any files.

This script has required dependencies that must be installed in order to run correctly.
-WorldEdit plugin (for area selection)
-SKCompat extension (for accessing WorldEdit selection data in CH)
-Vault plugin (for access to your economy plugin)
-CHVault extension (For accessing economy functions in CH)
Download CommandHelper extensions from https://letsbuild.net/jenkins/job/CHVault/
Install CommandHelper extensions by saving the extension .jar file to <server root>/plugins/CommandHelper/extensions.
 --You can check the status of installed extensions by typing /rladmin info.

For a list of permissions, see permissions.txt

Note: This script uses CommandHelper plugin features and newer Minecraft item name IDs that are not present in CH versions 3.3.4 or prior, you must use version 3.3.5 builds or higher.



Usage:
How to use Dispenser Reloader:

To use the fill tool:
1. Type "/reloader" while holding a tool/item.
This will bind the ReLoad tool to your currently held item.
[optional] If you want to specify what to fill, and not use the default item or quantity, specify the item and then the quantity after the command.
For example type "/reloader <item> <quantity>", eg "/reloader 12" to specify sand with default quantity, or "/reloader sand 32" to specify: use sand with quantity 32 in each stack.
You can specify a name or item ID number for the item.
2. Left-click a chest, dispenser, or furnace while holding that tool.
Your block will be instantly filled!

To use the area fill mode:
1. Make a selection with WorldEdit.
(Go to http://wiki.sk89q.com/wiki/WorldEdit/Selection to learn how to make a WorldEdit selection.)
2. Type /reloader area. 
[optional] If you want to specify what to fill, and not use the default item or quantity, specify the item and then the quantity after the command.
For example type "/reloader area <item> <quantity>", eg "/reloader area 12" to specify sand with default quantity, or "/reloader area sand 32" to specify to use sand with quantity 32 in each stack.
You can specify a name or item ID number for the item.
Every fillable block in your selection will be instantly filled!

Fuel mode:
Normall the fill operation will fill the item to be smelted in a furnace (top inventory slot). In Fuel mode you can instead fill the item type to burn in the furnace (bottom inventory slot).
To use just specify fuel after typing the command. You can also specify item and quantity as per normal mode.
Example:
For the tool: "/reloader fuel [item] [quantity]"
For area mode: "/reloader area fuel [item] [quantity]"


Settings:
- You can set your default item to use, so you don't have to specify it each time. Use "/reloader set <item> <quantity>"
- You can limit the block types to fill in area mode. To set which block type /reloader area fills: "/reloader mode <blocktype>"
	Accepted block types are: chest , dispenser , furnace , or "all" (To use all 3 types)
	Example: "/reloader mode chest" to only fill chests in area mode
- To view your set settings, use: /reloader info
- To view statistics of how you use ReLoader, use: /reloader stats
- To re-bind a tool that has previously been unbound, type "/reloader managebind" (or the shortcut "/none undo" if installed)
- To view extra messages from teh script, use "/reloader verbose"

Admin settings: /reloaderadmin
- To see global statistics of how reloader is used (ex. Total items used, Total blocks filled, etc): /reloaderadmin stats
- To view a specfic player's stats, use:  /reloaderadmin stats player <playername>.
- To view default item settings for all players: /reloaderadmin default view
- To set the default item type or quantity to use for all players (who haven't set their own item settings): /reloaderadmin default item <type/qty/fuel> <default value to use>
	Use 'type' for the default item ID to use, 'qty' to set the default stack quantity to use, and 'fuel' to set the default item ID to use for filling the fuel portion of furnaces.
- For troubleshooting use only, type /reloaderadmin version to print the script version and status of extension dependencies on-screen.


