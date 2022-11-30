### codegen

###### 2.2 (11/29/22)
Fixes:
- Fixed mis-named variables
- Quoted array keys
- Removed a foreach loop in favor of equivalent function

###### 2.1 (10/2/22)
Added:
- Swear replacement codegen (symbol)
- /codegen now uses a special thread separate from main thread to generate code.
- Added code length limiter to 512 characters.
	- avoids unintentional potential server crash with crazy high code length requested.
	- if called from specific thread ID this limit is bypassed.
- 'full' and 'all' code types are now separated. full is all alphanumeric characters. all is Full + symbols

Fixes:
- Put version in /codegen help
- Quoted switch cases
- requires permission commandhelper.alias.codegen

###### 2.0 (1/17/16)
Additions:
- mslp setup

###### 1.0 to 2.0 (?)
Changelogs not found.


### cmdrepeat

###### 1.1 (10/5/22)
Added:  
- Saves up to 3 recent commands used (up from 1)
	- Use /repeat 2 or /repeat 3 to access 2nd or 3rd recent commands.
	- Added short command //. to repeat 2nd recent command.
- Renamed script to cmdrepeat
- /repeat recent. Lists your last 3 commands!
Fixes:  
- Updated player persistence storage to use UUID
- Quote switch cases, updated defaults
- Updated console log messages on repeat command usage.

###### 1.0 (1/17/16)
Initial Release