Run your own Discord Bot from CommandHelper!

This bot is still in active development so internal features may change or break at any time!

These scripts are still in development! You might find them useful as-is, but please note features are still being added and finalized, and may not be operational!   
To install a script, place the script's folder in your CH's LocalPackages folder.  
Next, configure the Discord.yml config to match your bot's details.
Finally, configure the config for each of your guilds. Name the config file <yourserverid>.yml



Features:
Invite logging, who used which Invite
Memberjoin:
- welcome messages in welcome channel and DM
- Restore previous roles if rejoining
- Add "welcome roles": roles meant to be given to all server members
Chat to and from Minecraft server
Player death messages to Discord
Command system
Record members with no roles and those with just welcome roles
Project showcases: no chatting!
Transfer roles from one user to another user in same server.
voice chat:
- Record each call's length and joiners
- ping a dedicated voice chat role when a role member joins the chat (once every 12 hours)
- DM thanks for joining after call completion (excludes admins and VC role members)
Leaderboard:
- Record how many messages sent
- Level up using earned XP from each messages
- Role rewards: gain new roles once a certain XP level reached
- Supports importing leaderboard data from mee6



Commands:
Codegen
ping
fakeban
wrf



- Required extensions & libraries:
ScriptLibraries folder  
Codegen folder  
CHDiscord  
CHFiles  