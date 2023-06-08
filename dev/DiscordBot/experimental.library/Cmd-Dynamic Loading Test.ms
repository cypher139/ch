#!/usr/bin/env /usr/local/bin/mscript
<!
	strict: off;
	name: Test.ms;
	author: cypher139;
	created: 2023-03-14;
	description: Provides functionality to a connected Discord Bot.;
	requiredExtensions: Core, CHDiscord, CHFiles;
>
#version 1.3-tmc
# from PseudoKnight
# Something like this would work like LocalPackages. Keep in mind that you have to have static analysis disabled.
array proc _find_scripts(string @parent = pwd().'/Addons', array @files = array()) {
    foreach(@file in ls(@parent)) {
        @path = @parent.'/'.@file;
        if(is_dir(@path)) {
            if(!string_ends_with(@file, '.disabled') && !string_ends_with(@file, '.library')) {
			msg(color('a').'1.'.@files)
                _find_scripts(@path, @files);
				msg(color(3).'2.'.@files)
            }
        } else if(string_ends_with(@file, 'auto_include.ms')) {
            array_insert(@files, @path, 0);
        } else if(string_ends_with(@file, '.ms')) {
            @files[] = @path;
        }
    }
    return(@files);
}

msg(_find_scripts())
die()
	

/*
array proc _find_scripts(string @parent = pwd(), array @files = array()) {
    foreach(@file in ls(@parent)) {
        @path = @parent.'/'.@file;
        if(is_dir(@path)) {
            if(!string_ends_with(@file, '.disabled') && !string_ends_with(@file, '.library')) {
                _find_scripts(@path, @files);
            }
        } else if(string_ends_with(@file, 'auto_include.ms')) {
            array_insert(@files, @path, 0);
        } else if(string_ends_with(@file, '.ms')) {
            @files[] = @path;
        }
    }
    return(@files);
}

foreach(@file in _find_scripts()) {
    include(@file);
}
*/
