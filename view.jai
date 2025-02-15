#module_parameters(IMPLICIT_VIEW_FROM := false);

/*
	IMPLICIT_VIEW_FROM:
	Overload 'view' and 'rview' with 'view_from', so that it is automatically used if you do not
	specify a 'count' or 'end_index'.

	This makes

	   view(arr, 5)        // No count given,     normally an error
	   rview(arr, 5)       // No end_index given, normally an error

	the same as

	   view_from(arr, 5)   // View from start_index to the end of the array
*/

/*
	Error messages use the following syntax to represent the view that was attempted to be made:

	[start_index, end_index)

	Notes:
	* [...) Means the start index is inclusive and the end index is exclusive.
	* Since view() does not accept an end_index, `count=?` is appended to see your exact input.
*/

// Simple view ... [start_index, start_index + count)
view ::      inline ($$source: string, $$start_index := 0, $$count: int, $trunc := false, $check := true, $loc := #caller_location) -> string { #insert,scope() __view; }
view ::      inline ($$source: []$E,   $$start_index := 0, $$count: int, $trunc := false, $check := true, $loc := #caller_location) -> []E    { #insert,scope() __view; }
view_safe :: inline ($$source: string, $$start_index := 0, $$count: int, $trunc := false, $loc := #caller_location) -> string, ok := true     { #insert,scope() __view; }
view_safe :: inline ($$source: []$E,   $$start_index := 0, $$count: int, $trunc := false, $loc := #caller_location) -> []E   , ok := true     { #insert,scope() __view; }

// Range view ... [start_index, end_index)
rview ::      inline ($$source: string, $$start_index: int, $$end_index: int, $trunc := false, $check := true, $loc := #caller_location) -> string { #insert,scope() __rview; }
rview ::      inline ($$source: []$E,   $$start_index: int, $$end_index: int, $trunc := false, $check := true, $loc := #caller_location) -> []E    { #insert,scope() __rview; }
rview_safe :: inline ($$source: string, $$start_index: int, $$end_index: int, $trunc := false, $loc := #caller_location) -> string, ok := true     { #insert,scope() __rview; }
rview_safe :: inline ($$source: []$E,   $$start_index: int, $$end_index: int, $trunc := false, $loc := #caller_location) -> []E   , ok := true     { #insert,scope() __rview; }

// View from start_index to the end of the array ... [start_index, source.count)
view_from ::      inline ($$source: string, $$start_index: int, $check := true, $loc := #caller_location) -> string { #insert,scope() __view_from; }
view_from ::      inline ($$source: []$E,   $$start_index: int, $check := true, $loc := #caller_location) -> []E    { #insert,scope() __view_from; }
view_from_safe :: inline ($$source: string, $$start_index: int, $loc := #caller_location) -> string, ok := true     { #insert,scope() __view_from; }
view_from_safe :: inline ($$source: []$E,   $$start_index: int, $loc := #caller_location) -> []E   , ok := true     { #insert,scope() __view_from; }

#if IMPLICIT_VIEW_FROM {
	view  :: view_from;
	rview :: view_from;
	view_safe  :: view_from_safe;
	rview_safe :: view_from_safe;
}



#scope_file



__view :: #code {
	error :: view_error;
	#insert,scope() common_header_code;

	#if is_constant(count)
		#if count < 0
			#run error("View has negative count");

	#if !trunc && is_constant(count + source.count)
		#if count > source.count
			#run error("View count is bigger than source array");

	#if !trunc && is_constant(start_index + count + source.count)
		#if start_index + count > source.count
			#run error("View ends beyond end of source array");

	#if SAFE || check {
		is_valid := #ifx trunc
		then (start_index >= 0) && (count >= 0) && (start_index         <= source.count)
		else (start_index >= 0) && (count >= 0) && (start_index + count <= source.count);
	}

	#if SAFE {
		if !is_valid return .{}, false;
	} else #if check {
		if !is_valid && assert_helper("On source.count=%, couldn't make view [%, %), count=%\n",
			source.count, start_index, start_index + count, count, loc=loc) then debug_break();
	}

	new_count := #ifx trunc then min(count, source.count - start_index) else count;
	return .{ new_count, start_index + source.data };
}

__rview :: #code {
	error :: rview_error;
	#insert,scope() common_header_code;

	#if is_constant(end_index)
		#if end_index < 0
			#run error("View has negative end index");

	#if is_constant(start_index + end_index)
		#if start_index > end_index
			#run error("View end index comes before start index");

	#if !trunc && is_constant(end_index + source.count)
		#if end_index > source.count
			#run error("View end index exceeds end of source array");

	#if SAFE || check {
		is_valid := #ifx trunc
		then (start_index >= 0) && (start_index <= end_index) && (start_index <= source.count)
		else (start_index >= 0) && (start_index <= end_index) && (end_index   <= source.count);
	}

	#if SAFE {
		if !is_valid return .{}, false;
	} else #if check {
		if !is_valid && assert_helper("On source.count=%, couldn't make view [%, %)\n",
			source.count, start_index, end_index, loc=loc) then debug_break();
	}

	#if trunc
	then new_count := min(end_index - start_index, source.count - start_index);
	else new_count := end_index - start_index;

	return .{ new_count, start_index + source.data };
}

__view_from :: #code {
	error :: view_from_error;
	#insert,scope() common_header_code;

	#if SAFE || check {
		is_valid := (start_index >= 0) && (start_index <= source.count);
	}

	#if SAFE {
		if !is_valid return .{}, false;
	} else #if check {
		if !is_valid && assert_helper("On source.count=%, couldn't make view [%, source.count)\n",
			source.count, start_index, loc=loc) then debug_break();
	}

	return .{ source.count - start_index, start_index + source.data };
}

common_header_code :: #code #if true { // '#if true' ensures this code is *not* block scoped.

	SAFE :: !#exists(check);
	#if SAFE { check :: false; }

	#if is_constant(start_index)
		#if start_index < 0
			#run error("View has negative start index");

	#if is_constant(start_index + source.count)
		#if start_index > source.count
			#run error("View start index exceeds end of source array");
}

view_error :: (message: string) #expand #compile_time {
	compiler_report(tprint("%. On source.count=%, can't make view [%, %), count=%\n",
		message,
		#ifx is_constant(`source.count)         then `source.count.(Any)           else "?".(Any),
		#ifx is_constant(`start_index)          then `start_index.(Any)            else "?".(Any),
		#ifx is_constant(`start_index + `count) then (`start_index + `count).(Any) else "?".(Any),
		#ifx is_constant(`count)                then `count.(Any)                  else "?".(Any),
	), loc=`loc);
}

rview_error :: (message: string) #expand #compile_time {
	compiler_report(tprint("%. On source.count=%, can't make view [%, %)\n",
		message,
		#ifx is_constant(`source.count) then `source.count.(Any) else "?".(Any),
		#ifx is_constant(`start_index)  then `start_index.(Any)  else "?".(Any),
		#ifx is_constant(`end_index)    then `end_index.(Any)    else "?".(Any),
	), loc=`loc);
}

view_from_error :: (message: string) #expand #compile_time {
	compiler_report(tprint("%. On source.count=%, can't make view [%, source.count)\n",
		message,
		#ifx is_constant(`source.count) then `source.count.(Any) else "?".(Any),
		#ifx is_constant(`start_index)  then `start_index.(Any)  else "?".(Any),
	), loc=`loc);
}

using,only(compiler_report) _ :: #import "Compiler";
#import "Basic";
