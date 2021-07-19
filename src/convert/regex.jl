"Find the number of argument in a new command."
const LX_NARGS_PAT = r"[^\S\n]*\[\s*(\d+)\s*\][^\S\n]*"

"Trim the non-relevant part of a stacktrace when evaluating code."
const STACKTRACE_TRIM_PATTERN = r"\[\d+\]\stop-level\sscope"

"""
Check end of code block to see if should be hidden or not.
This is fragile if people do something silly like `x = 5 # foo ; # bar`
"""
const HIDE_FINAL_OUTPUT_PATTERN = r";\s*(:?#.*)?\n?"
