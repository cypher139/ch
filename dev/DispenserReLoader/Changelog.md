### DispenserReLoader

###### 2.0 (?)
Additions:
- Related block types Minecraft 1.14 added are now also supported: Barrel, Trapped Chest, Smoker, Blast Furnace, Shulker Box.
	- Area mode: Dyed Shulker Boxes are also supported separately as well if it's desired to only fill a certain color Shulker Box.
- /reloader this - when used with reloader tool binds the current item as tool, using settings of a max stack of whatever item you are holding.
	- Area mode: uses item and qty of what you are holding.

Fixes:
- Fuel mode: Now supports placing Blaze Powder in Brewing Stands (and nothing else as fuel in a brew stand.)
- Minecraft 1.13+ now uses item names instead of numeric IDs. 
	- Numeric IDs are still supported by the script. When such an ID is available for the item the script will automatically convert to the name instead.
	- Legacy Item:data syntax is also supported still, script will automatically convert this to the name format as well.
- Fixed several compile errors with newer CH versions (all switch cases, array names, and color codes must be quoted)
	- Many procedure rewrites and upgrades as required for new item arrays and arguments for CH 3.3.3 / Minecraft 1.13 and newer.
- Add player persistance storage via player UUID, required for name prefixes using a dot (i.e. name prefix defaults for Bedrock to Java players)
- Persistence values: Use tool name over numeric ID, optimize some value importing, switch tool to use one array value.
- Exception Handler now only registers if one isn't already set.

Notes:
- Blocks not supported by design: Ender Chest, Hopper, Dropper. May revisit this in a future release.


###### 1.0 (1/1/16)
Additions:
- Added redirect aliases to commands that may accidentally be used by players intending to use ReLoad, and also convienence aliases.
	--- /reload or /rl redirects to the main /reloader command, instead of reloading server. Console can still use /reload, but needs to type /reload now.
	*********It is highly recommended that you stop and restart your server, rather than reload it.***********
	--- /none will unbind ReLoad tool if is bound, otherwise redirects to WorldEdit's /none to unbind a WE tool.
- Added version value into script, for potential use in troubleshooting. Use /reloaderadmin version to view the script version installed.
- Added default item specifically for Fuel mode. This should prevent accidentally trying to use Arrows - the normal default item - to fill as fuel.
- Added nag messages for installing CH extensions required by this script.
- Added aliases to several action commands. Examples: a for Area mode, ? for help, mode d for setting area mode to dispenser. (Changed if() actions to switch() action selector)

Upgrades:
- Renamed script name to distinguish from the original script.
	-- The command name has changed to /reloader. All permissions also now reference 'reloader' instead of 'dload'.
- Changed persistance ID structure for the Tool function to save using the tool ID number (eg Diamond Pickaxe = 278). 
	-- This means that multiple tools at once can now be used, and each tool has its own item & quantity settings.
	-- Unbinding all tools currently requires a separate operation for each tool, or use /reloadaliases to clear all import/export values for CH.
- You can now undo a tool unbind. (A pleasant side effect of the tool ID change!) Use /reloader managebind, or the shortcut /none undo .
	-- Note: Undo history for the tool is lost on 1)Server restart 2)/reloadaliases 3)Re-binding tool using new settings - using the main /reloader command.
- Changed persistance ID structure to move the playername further into the id (eg ReLoad.player.PLAYERNAME.setting instead of PLAYERNAME.ReLoad.setting).
	-- This allows for easier manual searching of any player-specific value in the Persistance database, or easier deleting of all of players saved values.
- Changed "yes/no" commands to a toggle function
- Moved WorldEdit selection functions calls (And the area iteration procedure that requires the selection) to isolated .ms files.
	-- This allows /reloader and the backend functions to compile if the SKCompat extension is missing, by only loading the file with potentially "unknown functions to the Java Interpreter" if the SKCompat extension exists. 
	-- Note that Area mode requires a WE selection, so if the required extension is not detected Area mode will be disabled.
- Moved reassigning of user option variables for the /reloader tool function to later in the command; this removes the need for the hardcoded actions check and allows for aliases to actions.

Fixes:
- Variables cleanup: 
	- Assigned numerous out-of-scope variables into the correct scope
	- Changed "yes" or "no" values to much cleaner true/false.
	- Removed duplicate variables in use that just pointed to player()
- When enabling tool, useless and incomplete last run stats were unnecessarily saved.  
	-- This ended up causing an exception if these stats were viewed before a new ReLoad run was performed.
- Added exception handler into each command, to clean up the display of an error message. The console will still get all the original message's data (albeit reformatted).
- A bound tool that was set in Fuel mode also filled chest or dispensers when clicked on. Fuel mode is now restricted to furnaces.
- When attempting to use a previously set item type with item data, script erroneously activated an auto fix for bad item id number, which changed the set item type to default.

###### 0.7 to 1.0 (?)
Just tool, iirc? preliminary stats support. changelogs not found.