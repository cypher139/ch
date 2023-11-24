Run your own Discord Bot from CommandHelper!

This bot is still in active development so internal features may change or break at any time!

To install place the DiscordBot script's folder in your CH's LocalPackages folder.  
Next, configure the Discord.yml config in the Configs folder to match your bot's details.
Finally, configure the config file for each of your guilds in the Configs/Guilds folder. Name the config file after your server's numeric ID. <yourserverid>.yml



Features:
Invite logging, who used which Invite
Member Join:
- Welcome messages in welcome channel and DM
- Restore previous roles if rejoining
- Add "welcome roles": roles meant to be given to all server members
Chat to and from Minecraft server
- player chat goes to all connected Discord server's "#minecraft" channels.
Cross-Server chat between all connected Discord servers
- CS chat by default goes to all connected Discord server's "#minecraft" channels.
Send Player death messages to Discord
Command system
Record members with no roles and those with just welcome roles
Project showcases: no chatting!
Transfer roles from one user to another user in same server.
Add users to Minecraft server whitelist.
Log if bot receives a DM
Role Ranks:
- Gives a role related to how many qualifying roles the user has.
- example: gives "multiple Game Console" role if bot detects user has both "PS1" and "PS2" roles
Voice chat:
- Record each call's length and joiners
- ping a dedicated voice chat role when a role member joins the chat (once every 12 hours)
- DM thanks for joining after call completion (excludes admins and VC role members)
Leaderboard:
- Record how many messages sent
- Level up using earned XP from each messages
- Role rewards: User gains new roles once a certain XP level is reached
- Supports importing leaderboard data from mee6
- Give a "Active in server" role to those who have chatted in last 60 days. ex. only show "Active in server" role in sidebar to better showcase those who chat on your server.
Anti Spam:
- Action on user who is new and chats on many channels.
- Action on user who says the same message many times within a few seconds (more so if on multiple channels)
- Delete all recent messages of user who triggers spam protection
- Use asremove command to remove user from spam protection



Commands:
Codegen
ping
fakeban
wrf
viewlb
transferroles
mc-whitelist



- Required extensions & libraries:
ScriptLibraries folder  
Codegen folder  
CHDiscord  
CHFiles  