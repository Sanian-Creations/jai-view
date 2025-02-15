# jai-view
Simple module for making array and string views.

## Importing
`view.jai` is the only required file, `module.jai` only loads it, so you can do either of these:

* Copy `view.jai` to your modules directory and be done with it.
* Clone this whole directory to you modules:
  * `cd project_dir`
  * `git clone git@github.com:Sanian-Creations/jai-view.git modules/view`

This project is licensed under Zero-Clause BSD, aka do whatever the hell you want I don't care.

## Basic Usage
```odin
view      :: (src, start_index, count,     trunc := false, check := true) -> []E
rview     :: (src, start_index, end_index, trunc := false, check := true) -> []E
view_from :: (src, start_index,                            check := true) -> []E
```
```odin
src := "0123456789"; // Supports both arrays and strings

a := view(src, 3, 5);   // "34567"   Starting at index 3, 5 elements
b := rview(src, 3, 5);  // "34"      Range view from index 3 to 5, end index is exclusive
c := view_from(src, 3); // "3456789" From index 3 to end of array

d     := view(src, 3, 8);      // Assertion failed: On source.count=10, couldn't make view [3, 11), count=8
e, ok := view_safe(src, 3, 8); // "", false
```

## Why not use Basic.array_view?
`Basic.array_view` only asserts that `start_index` and `count` are not negative, and that's it. If
the view wouldn't fit the source array, it either truncates the count to fit, or, if there's no
overlap with the source array at all, it returns an empty view. I argue this is usually unwanted
behaviour. Silently continuing with an empty view just makes potential bugs harder to find.

### What do these procs give you that Basic.array_view does not?
- Each proc has an overload for string views. (`Basic.array_view` can't do this, you need
  `String.slice` instead, which is annoying asf)
- They assert that the view you ask for fits exactly.
  - The assertion prints out the values that were used, so you know what went wrong.
  - It also asserts at compile time, if any args are constant.
  - You can optionally turn off the *runtime* asserts with `(check=false)`.
- Every proc has a `*_safe` counterpart which returns an `ok` bool rather than asserting.
- You can *optionally* turn on truncation with `(trunc=true)`.
  - Truncation will shorten the end of the view if the given region does not completely fit the
    source array.
  - Even with truncation, it still asserts that `start_index` is in bounds (`0 <= start_index <=
    source.count`), disabling this with `(check=false)` can potentially result in views with
    negative count. You can instead use truncation with `view_safe`, which wil return an empty
    view if `ok` was false.
- Variants with slightly different args for convienience
  - `rview`     - supports an index range (start/end indeces) rather than a start/count.
  - `view_from` - supports view-to-end-of-array

## Advanced usage
```odin
// In this example any ? represents memory outside the source array/string
src := "0123456789";
vw: string;
ok: bool;

// Views exceeding the end of the array
// 0123456789???????
//       |------|

vw = view(src, 6, 8); // Assertion failed: On source.count=10, couldn't make view [6, 14), count=8
vw = view(src, 6, 8, check=false);  // "6789????" It just makes the array without checking
vw = view(src, 6, 8, trunc=true);   // "6789" Shortens the array to fit in bounds
vw, ok = view_safe(src, 6, 8);             // ""     ok=false
vw, ok = view_safe(src, 6, 8, trunc=true); // "6789" ok=true


// Views entirely beyond the end of the array
// 0123456789??????????
//             |---|

vw = view(src, 12, 5, check=false); // "?????" It just makes a garbo view, be careful
vw = view(src, 12, 5, trunc=true);  // Even with truncation, start index must be in bounds
// Assertion failed: On source.count=10, couldn't make view [12, 20), count=5

// With truncation, turning off check is bad. You can get negative sized arrays if start index
// is outside the array. If you want to not assert, use *_safe and ignore the ok value:
vw     = view(src, 12, 5, trunc=true, check=false); // string with count = -2 This is bad!
vw, ok = view_safe(src, 12, 5, trunc=true);         // "" ok=false


// Views starting before the array
// ?????0123456789
//   |---|

neg3 := -3;
vw = view(src, -3, 5);   // Comptime assert because -3 is constant
vw = view(src, neg3, 5); // Runtime assert
vw = view(src, neg3, 5, trunc=true); // Still runtime assert, truncation only works at the end

// Though I could add an additional option for truncation from the start, I have found no good reason for it.
// If you have a good reason, or other things that could be added, let me know in the SB discord, @Sanian
```
