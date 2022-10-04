### codegen

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
