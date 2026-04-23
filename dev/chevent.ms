#!/usr/bin/env /usr/local/bin/mscript
<!
	strict: on;
	name: chevent.ms;
	author: cypher139;
	created: 2025-10-8;
	description: Dump CH events for use in syntax highlights.;
	requiredExtensions: Core, CHFiles;
>

	@corefunc = array();
	@extfunc = array();
	@coreevents = array();
	@extevents = array();
	msg(color(6).'All Available Events & Functions:');
	foreach(@ext: @data in extension_info()) {
		if(@ext == 'Core') {
			if(array_size(@data['events']) > 0) { 
				msg(color(10).@ext.' '.color(2).'Events: '.color(7).@data['events']);
				array_push_all(@coreevents, @data['events']);
			}
			if(array_size(@data['functions']) > 0) { 
				msg(color(10).@ext.' '.color(9).'Functions: '.color(7).@data['functions']);
				array_push_all(@corefunc, @data['functions']);
			}
		} else {
			if(array_size(@data['events']) > 0) { 
				msg(color(3).@ext.' '.color(2).'Events: '.color(7).@data['events']);
				array_push_all(@extevents, @data['events']);
			}
			if(array_size(@data['functions']) > 0) { 
				msg(color(3).@ext.' '.color(9).'Functions: '.color(7).@data['functions']);
				array_push_all(@extfunc, @data['functions']);
			}
		}
	}
	@corespecial = array('implements', 'synchronized', 'auto', 'private', 'internal', 'notinstanceof', 'for', 'do', 'while', 'switch', 'foreach', 'default', 'bind', 'protected', 'public', 'native', 'else', 'continue', 'catch', 'if', 'closure', 'class', 'case', 'proc', 'static', 'package', 'in', 'break', 'finally', 'false', 'switch_ic', 'abstract', 'instanceof', 'as', 'immutable', 'iclosure', 'null', 'true', 'final', 'try', 'return');
	foreach(@f in @corefunc) {
		if(string_starts_with(@f, '__') && string_ends_with(@f, '__')) { array_remove_values(@corefunc, @f); continue(); }
		if(array_contains(@corespecial, @f)) { array_remove_values(@corefunc, @f); }
	}
	write_file('coreevent.txt', array_implode(@coreevents, ' '), 'overwrite');
	write_file('corefunc.txt', array_implode(@corefunc, ' '), 'overwrite');
	write_file('extevent.txt', array_implode(@extevents, ' '), 'overwrite');
	write_file('extfunc.txt', array_implode(@extfunc, ' '), 'overwrite');

