### codegen

###### 2.4 (2/1/23)
Added:
- Generate 8-bit or 16-bit numbers.
- Switched main generation loop to foreach. (Testing has determined CH is faster at foreach than for).

###### 2.3 (1/1/23)
Added:
- Numbers for all character types (used for randomly generated options).

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

###### 1.2 (1/21/23)
Added:  
- Saves up to 10 recent commands used (up from 3)
- Automatic command cast fixes:
	- Remove extra slashes and spaces
	- Cancel command if only a single slash is given
Fixes:  
- Updated player ID proc to latest version, and proc is only installed if not already present.

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