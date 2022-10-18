Bucket
Get block ID information by hitting it with a bucket!

Creative
Adds /i command with support for exact block names and legacy numeric IDs (if supported by the chosen block/item)
You can also use the old ID:data syntax, e.g. 98:1 to give mossy stone bricks
Also a few extra features:
/i that - gives you whatever block you are looking at.
/i this - gives you whatever item you are holding
/i refill - refills current stack of what you are holding to full. (if stack of 1 it gives you another of that item)
/i <id> max - gives you max stack size of specified item.
if Console uses /i command Item IDs are returned instead.

Permissions:
commandhelper.alias.creative - use /i
commandhelper.alias.creative.see.id - returns the legacy numeric ID when /i is used

DeathTP
Records where you died and what inventory you had, and alos records where you had previously.
- Use /back to teleport back to the previous spot where you died, and /backitems to respawn the items you had.
- Use /back 2 to teleport to the 2nd previous spot of where you died, /backitems 2 to respawn that life's items too.

Permissions: /back: commandhelper.alias.deathtp  /backitems: commandhelper.alias.deathitems  

gamemode
Use /mode to switch betwen Survival and Creative game modes.

getplayerID
a procedure to call, returns an array of player info: name, display name (dot remvoed for bedrock players), UUID dashless for use in storing data, and the nickname.

sign