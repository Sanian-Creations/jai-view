# jai-view
Simple module for making array and string views.

This module exposes the following procedures:

```odin
view      :: (arr, start_index, count,     trunc := false, check := true) -> arr
rview     :: (arr, start_index, end_index, trunc := false, check := true) -> arr
view_from :: (arr, start_index,                            check := true) -> arr

// * 'arr' may also be string
// * Every proc has a *_safe counterpart which has no 'check' param but returns an extra 'ok' bool
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
