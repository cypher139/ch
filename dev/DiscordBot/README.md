**Run your own Discord Bot from CommandHelper!**

**This bot is still in active development so internal features may change or break at any time!**

## Installation
1. Install the Required extensions & libraries:  
[cypher139's ScriptLibraries](https://github.com/cypher139/ch/tree/release/dev/ScriptLibraries)  
[CHDiscord](https://letsbuild.net/jenkins/job/CHDiscord/) extension  
[CHFiles](https://letsbuild.net/jenkins/job/CHFiles/) extension  
2. Place the DiscordBot script's folder in your CH's LocalPackages folder. 
3. Add the token details for your bot to CH's profiles. [CHDiscord readme on how to add to profiles](https://github.com/PseudoKnight/CHDiscord/blob/master/README.md#discord_connecttoken-serverid-callback--profile-callback)  
4. Configure the Bot.yml config in the DiscordBot/Configs folder to match your bot's details. Enter the profile name from the previous step here.  
5. Get the [Default Server Config file](https://github.com/cypher139/ch/blob/release/dev/DiscordBot/Configs/123/config-123.yml) and configure it for each of your guilds:  
    A. In the Configs folder make a new folder named after your server's ID.  
    B. Name the config file ```config-[your server's numeric ID].yml```. For example: config-123456.yml



## Bot Features:  
- #### Minecraft server <-> Discord features:
    - Chat to and from Minecraft server  
        - Player chat goes to all connected Discord server's "#minecraft" channels.  
    - Send various Minecraft player events messages to Discord  
       - Player death
	   - Player earned XP
	   - etc...
    - Add users to Minecraft server whitelist.  
    - Log if bot receives a DM.

- #### Discord server features:  
    - Command system
	- Cross-Server chat between all connected Discord servers  
        - CS chat by default goes to all connected Discord server's "#minecraft" channels.  
    - Member Joins:  
       - Welcome messages in welcome channel and DM  
       - Restore previous roles if rejoining  
       - Add "welcome roles": roles meant to be given to all server members  
       - Invite logging, who used which Invite
    - Role Ranks:  
       - Gives a role related to how many qualifying roles the user has.  
       - example: gives "multiple Game Console" role if bot detects user has both "PS1" and "PS2" roles  
    - Voice Chat:  
       - Record each call's length and joiners, and post in server logs
       - Ping a dedicated voice chat role when a role member joins the chat (once every 12 hours)  
       - DM thanks for joining after call completion (excludes admins and VC role members)  
    - Leaderboard:  
       - Record how many messages and words each user has sent  
       - Level up using earned XP from each messages  
       - Role rewards: User gains new roles once a certain XP level is reached  
       - Supports importing leaderboard data from mee6  
       - Give a "Active in server" role to those who have chatted in last 60 days. ex. only show "Active in server" role in sidebar to better showcase those who chat on your server.  
    - Moderation Tools:
	    - Transfer roles from one user to another user in same server.  
	    - Project Showcase channel: Prevent chat on a channel meant for showcasing art projects! 
		- Record members with no roles and those with just welcome roles (wrf command)
	    - Anti Spam:  
          - Action on user who is new and chats on many channels.  
          - Action on user who says the same message many times within a few seconds (more so if on multiple channels)  
          - Delete all recent messages of user who triggers spam protection  
          - Timeout or nickname user who triggers spam protection  
          - Use asremove command to remove user from spam protection.  



#### Commands:
```
codegen  
ping  
fakeban
cointoss    
wrf  
leaderboard   
rank  
transferroles 
asremove  
whois 
mc-whitelist  
mc-give  
geoiplookup  
```