# ------------------ #
# LATEX COMMANDS ETC #
# ------------------ #

"Find the number of argument in a new command."
const LX_NARGS_PAT = r"[^\S\n]*\[\s*(\d+)\s*\][^\S\n]*"

"Check if there's a label in a display math block"
const MATH_LABEL_PAT = r"\\label{(.*?)}"

# --------------- #
# CODE BLOCKS ETC #
# --------------- #

"Check end of code block to see if should be hidden or not.
This is fragile if people do something silly like `x = 5 # foo ; # bar`"
const HIDE_FINAL_OUTPUT_PATTERN = r";\s*(:?#.*)?\n?"

"Trim the non-relevant part of a stacktrace when evaluating code."
const STACKTRACE_TRIM_PATTERN = r"\[\d+\]\stop-level\sscope"

"Indicator for a list item. Group 1 = indentation, Group 2 = marker."
const LIST_MARKER_PAT = r"(?:^|\n)([ \t]*)([+\-*][ \t]|[0-9]{1,9}[\.\)][ \t])"
