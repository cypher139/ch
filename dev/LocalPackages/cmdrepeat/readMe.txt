cmdrepeat adds back the lost /repeat command! Type /repeat to re-run the last command you used.

Also included:
- Broadcast the command used to the console, complete with color coding showing CH aliases or server commands.
- Print the command used back to the player who issued it! (Color coding of alias or command enabled with permission only)

Usage:

/repeat = Repeats last used command
/repeat printrepeat = Toggles printing back to you the command you just used when using the "/repeat" repeat command.
 -- This makes your in-game chat log look similar to a terminal. Useful for organizing your chat.
/repeat print = Toggles printing back any command you use when you use it.
/repeat consolecmd = Toggles whether to broadcast to the console what commmand was used.

Notes:
- The console doesn't use "/" to start a command. To use the "/repeat" command in the console, use "repeat" instead.
- Aliases for /repeat: /. and /'

Permissions:
commandhelper.alias.everyone: Use /repeat
commandhelper.alias.admin: Allows you to toggle setting the broadcast of command used to console.
commandhelper.alias.see.is.alias: In the message sent back to player of command used, allows players to see by color code if the command is a CH alias or a plugin command.
