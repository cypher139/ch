Cypher's Utility scripts, bringing various cool essential features to the Minecraft server.
Note: most of these scripts require Cypher's Script Libraries.

## Commands and Actions

### BackTP
Records the last 10 instances of the player's:
1. Previous location before teleporting. use /back tp to return.
2. Location of death. Use /back death to return to where you died
3. Inventory player had upon death. use /back items to respawn that inventory
- Use /back to teleport back to the previous spot where you died, and /backitems to respawn the items you had.
- Use /back 2 to teleport to the 2nd previous spot of where you died, /backitems 2 to respawn that life's items too.
- Use /back return to return to the location you were at before you went crazy teleporting everywhere.
- BackTP remembers if the last thing you did was teleporting or death, typing just /back will then act according to the last type of event.
- Use /back [number] to: go back to the nth teleport location / death location / respawn death's inventory.

### Bucket
Get block ID information by clicking on it with a bucket!

### Give / i
Adds /give and /i command to give player any item.
 - Supports exact block names **and legacy numeric IDs** *(if supported by the chosen block/item)*
- Supports old ID:data syntax from pre 1.13: Example: 98:1 gives Mossy Stone Bricks
- Supports item meta input via JSON or YAML.
- /i that - gives you whatever block you are looking at. 
- /i this - gives you whatever item you are holding.
- /i refill - refills current stack of what you are holding to full. (if stack of 1 it gives you   another of that item)  
- /i [id] max - gives you max stack size of specified item.
- if Console uses /i command: Item IDs are returned instead.

### Game Mode
Easily switch between game modes, temporarily lock changes to gamemode, and use per game mode inventories!

- Use /mode to switch between Survival and Creative game modes.
- Use /mode [gamemode] to switch to other gamemodes directly.
- /mode [lock / unlock]: Lock game mode changes
- /mode Per-Mode: Enable separate inventories for each gamemode.

### Command Repeat
Add back the lost /repeat command! Type /repeat to re-run the last command you used.

Also includes extra features:
- Broadcast the command used to the console, complete with color coding showing CH aliases or server commands.
- Print the command used back to the player who issued it! (Color coding of alias or command enabled with permission only)
- Repeat nth last command (up to 10) with /repeat [number]
- /repeat print = Toggles printing back any command you use to your chat when you use it.
- Shorthand aliases: /. or /'
- To repeat 2nd or 3rd command alias: add another dot to /., e.x. /... to repeat 3rd last command

### Teleporter
Set Pressure Plates, Redstone Ore, and Farmland to teleport any player that steps on it to a location of your choice!
/teleporter info [x,y,z \| teleporter name]
- Supports teleporters only being active during a specific world time of day
- 

### Death Counter
(requires BackTP command to function)
View how many times players have died, and leaderboard of players sorted by the highest count of deaths.
- Admin permission required to see all offline players in tabcompletion.

## List of Main Commands and Permissions

| Command | Action | Permission |
|--|--|--|
| /back tp | Allows to teleport to previous location before teleport | commandhelper.alias.back.tp |
| /back death | Allows to teleport to previous death location | commandhelper.alias.back.deathtp |
| /back items | Respawns inventory before last death | commandhelper.alias.back.items |
| /bucket | Get block ID information by clicking it with a empty bucket |commandhelper.alias.bucket.info |
| /deathcounter [player names] | View how many times specified player(s) have died | commandhelper.alias.deathcounter |
| /deathcounter [leaderboard] | View server leaderboard of top deaths between players | commandhelper.alias.deathcounter |
| /gamemode | Change gamemode, enable per-mode inventories, local gamemode | commandhelper.alias.shiftmode |
| /gamemode [lock / unlock] | Lock or Unlock setting your gamemode | |
| /gamemode [Per-mode Inventory] | Enable separate inventories per game mode |
| /give [player] [item] [qty] | Give player specified item and qty | commandhelper.alias.creative <br> (If Receiver does not have permission: Giver needs: commandhelper.alias.admin ) |
| /i [item] [qty] | Give yourself specified item and qty | commandhelper.alias.creative |
| /repeat [number] | Repeat last command, or if number the nth last command | commandhelper.alias.repeat |
| /repeat print | Toggles printing back any command you use when you use it. | |
| /repeat recent | Shows your last 10 recently used commands | |
| /teleporter set | Setup pressure plates, redstone ore, farmland, etc. as a teleporter when stepped on | commandhelper.alias.teleporter.set |
| /teleporter info | Get info about registered teleporters | commandhelper.alias.teleporter.info |


## Advanced Permissions
| Cmd | Action | Permission |
|--|--|--|
| /deathcounter console | View times CH reloaded / server started | commandhelper.alias.deathcounter.console | 
| /deathcounter console | View times CH reloaded / server started | commandhelper.alias.deathcounter.console | 
| /mode [specify game mode] | Remove nag message about /mode shortcut | commandhelper.alias.shiftmode.notip |
| /mode [gamemode] [player] | Change gamemode of another player | commandhelper.alias.shiftmode.others |
| /mode [gamemode] [player] [player2] | Change gamemode of multiple players at once | commandhelper.alias.shiftmode.others.multi |
| /gamemode [game mode] | Admin Lock Bypass| commandhelper.alias.shiftmode.lock.bypass |
| /mode [gamemode] | Allow switching to listed gamemode, **any** world | commandhelper.alias.shiftmode.any.world.[survival \| creative \| adventure \| spectator] |
| /mode [gamemode] | Per world permissions: | commandhelper.alias.shiftmode.world.[world name, in lower case].[survival \| creative \| adventure \| spectator] |
| /i [options] | See legacy item IDs of item given | commandhelper.alias.creative.see.id|
| /repeat | Repeat Display: differentiate CH Aliases from server commands | commandhelper.alias.see.is.alias |
| /repeat console | Log / print commands used to console | commandhelper.alias.admin |
| /world | Show current world time | commandhelper.alias.world.show.time |

