proc _hex_to_rgb(@num, @string = false) {
	@num = reg_replace('#', '', @num);
	if(length(@num) == 3) {
		@num = reg_split('(?<=\\G.)', @num);
		@num[0] = @num[0].@num[0];
		@num[1] = @num[1].@num[1];
		@num[2] = @num[2].@num[2];
	} else if(length(@num) == 6) {
		@num = reg_split('(?<=\\G..)', @num);
	} else {
		throw('ms.lang.CastException', 'Unsupported Hex code given.');
	}
	@results = array('r': parse_int(@num[0], 16), 'g': parse_int(@num[1], 16), 'b': parse_int(@num[2], 16));
	if(@string == true) { @results = @results['r'].', '.@results['g'].', '.@results['b']; }
	return(@results);
}

proc _rgb_to_hex(array @rgb, string @prefix = '') {
	if(array_size(@rgb) < 3) { throw('ms.lang.CastException', 'Not enough array elements present.'); }
	@cast = array();
	if(is_associative(@rgb)) { 
		if(!array_index_exists(@rgb, 'r') || !array_index_exists(@rgb, 'g') || !array_index_exists(@rgb, 'b')) { throw('ms.lang.CastException', 'RGB element missing.'); }
		@cast = array(@rgb['r'], @rgb['g'], @rgb['b']);
	} else {
		@cast = @rgb;
	}
	foreach(@k: @v in @cast) {
		if(@k > 2) { break(); }
		if(@v > 255) { throw('ms.lang.CastException', 'Unsupported RGB code given. ('.@k.')'); }
	}
	#order: bgr
	@results = to_radix(bit_or(@cast[2], lshift(@cast[1], 8), lshift(@cast[0], 16)), 16);
	if(length(@results) < 6 && @cast[0] < 16) { @results = string_multiply('0', (6 - length(@results))).@results; }
	if(@prefix != '') { @results = @prefix.@results; }
	return(@results);
}