Plugins monitoring
version 1.0

This script system was made after a few players decided to study the /plugins command on the server at the time, 
looking for confirmation of certain plugins that can be used to cause chaos, i.e. WorldEdit, dynMap, etc.

Based on many permissions, this is setup to hide certain (configurable list) plugins from the plugins list, 
providing a curated list to the player calling /plugins, 
so that the player wont suspect the /plugins command return is faked and it wont show them plugins they do not have permission to see.

If configured right, the monitor should also block registered commands if the player fails the plugin check. 
This was before register_command() iirc, so it's not perfect.

Untested past CH 3.3.1, and probably could use an update to switch(@action) {case} for easier use.
