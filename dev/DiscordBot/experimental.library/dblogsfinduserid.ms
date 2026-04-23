#!/usr/bin/env /usr/local/bin/mscript
<!
	strict: on;
	name: dblogsfinduserid.ms;
	author: cypher139;
	created: 2025-11-11;
	description: Search member log files from the Discordbot to find all occurences of a user ID.;
	requiredExtensions: Core, CHFiles;
>
# Command line only. Place and run script file in: DiscordBot/Logs
@serverID = prompt_line(color(14).'Enter numeric Server ID:'.color('r').' > ');
if(!@serverID) { die('Requires User ID'); }
if(!is_numeric(@serverID)) { die('Requires numeric User ID'); }
@userID = prompt_line(color(14).'Enter numeric User ID:'.color('r').' > ');
if(!@userID) { die('Requires User ID'); }
if(!is_numeric(@userID)) { die('Requires numeric User ID'); }

@showallFile = false;
@fileType = 'Info';
@startTime = time();
@LogFileDir = list_files(@serverID);
@UserFoundIn = array();
@sorttest = array();
#MM, yy, dd
@lowDate = 0;
@highDate = 0;
@lowFile = '';
@useFile = '';
@useData = array();
@countDate = 0;
foreach(@monthDir in @LogFileDir) {
	if(length(@monthDir) !== 4) { continue(); }
	foreach(@file in list_files(@serverID.'/'.@monthDir)) {
		if(!string_ends_with(@file, 'members'.@fileType.'.json')) {continue();}
		@data = json_decode(read(file_resolve(@serverID.'/'.@monthDir.'/'.@file)));
		if(array_index_exists(@data, @userID)) {
			@UserFoundIn[] = @monthDir.'/'.@file;
			@fileDate = parse_date('MM-dd-yy', split('_', @file)[1]);
			# MM-dd-yy
			if(@fileDate < @lowDate || @lowDate === 0) { @lowDate = @fileDate; @lowFile = @monthDir.'/'.@file; }
			if(@fileDate > @highDate) {
				@countDate++;
				msg(color(9).'date update '.color(8).'#'.color(11).@countDate.color(8).': '.color('r').@fileDate.' > '.@highDate);
				@highDate = @fileDate;
				@useFile = @monthDir.'/'.@file;
				@useData = @data[@userID];
			}
		}
	}
}

if(array_size(@UserFoundIn) > 0) {
	@userFoundInMsg = color(10).'User '.@userID.' was found in '.color(5).array_size(@UserFoundIn).color(10).' entries.';
	if(@showallFile) { @userFoundInMsg .= '\n'.color('r').array_implode(@UserFoundIn, '\n'); }
	msg(@userFoundInMsg);
	msg(color(5).' Earliest file: '.color(3).@lowFile);
	msg(color(13).' Latest file: '.color(11).@useFile);
	msg(@useData)
} else {
	msg(color(14).'User '.@userID.' was not found.');
}
@timeElapsed = time() - @startTime;
	msg(color(3).'Time elapsed: '.@timeElapsed.'ms.');	
	
	
	

	
	
	
	
	
	
	
	
	