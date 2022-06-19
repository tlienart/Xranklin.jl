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

"Opening element of code block see `_code_info`"
const CODE_INFO_PAT = r"^\`+([^\n]+)?"

"Language getter (allow space after language for highlighting in VSCode)"
const CODE_LANG_PAT = r"([^\!\:\s]+)?\s*([\!\:]{1,2})?(\S+)?"

"Check end of code block to see if should be hidden or not.
This is fragile if people do something silly like `x = 5 # foo ; # bar`"
const HIDE_FINAL_OUTPUT_PAT = r";\s*(:?#.*)?\n?"

"Trim the non-relevant part of a stacktrace when evaluating code."
const STACKTRACE_TRIM_PAT = r"\[\d+\]\stop-level\sscope"

"Check if a name hint is given"
const AUTO_NAME_HINT_PAT = r"(?:^|\n)\s*#\s*name\s*\:\s*(.*?)\n"

"Check if a cell is indep of other cells"
const CODE_INDEP_PAT = r"(?:^|\n)\s*#\s*?indep\s*\n"

"Hide some or all lines of code in an executable block."
const CODE_HIDE_PAT = Regex(raw"(?:^|[^\S\r\n]*?)#(\s)*?hide(all)?")

"Show some line of code in an executable block without running it."
const CODE_MOCK_PAT = Regex(raw"(?:^|[^\S\r\n]*?)#(\s)*?(?:mock|norun|noexec|fake)")

"Same as CODE_HIDE_PAT but accounting for Literate syntax."
const LITERATE_HIDE_PAT  = Regex(raw"(?:^|[^\S\r\n]*?)#src")

# ---------- #
# LIST+TABLE #
# ---------- #

"Indicator for a list item. Group 1 = indentation, Group 2 = marker."
const LIST_MARKER_PAT = r"(?:^|\n)([ \t]*)([+\-*][ \t]|[0-9]{1,9}[\.\)][ \t])"

"Pattern to split rows."
const TABLE_ROW_SPLIT_PAT = r"\|[ \t]*\n"

"Pattern for a separator line between header and body."
const TABLE_SEP_LINE_PAT = r"^[ \t]*\|(?:[ \t]*\:?-+\:?[ \t]*\|)+[ \t]*\:?-+\:?[ \t]*$"

"Pattern for an individual column separator (used in `eachmatch`)."
const TABLE_SEP_COL_PAT = r"(\:?-+\:?)"

# ---- #
# MISC #
# ---- #

"Link fixing (see in process_file / final pass)."
const PREPATH_FIX_PAT = r"(src|href|formaction|action|url)\s*?=\s*?([\"\']?)\/"

"Simple link removal (see rss)."
const HTML_LINK_PAT = Regex(raw"""<a\shref=(?:"|')?\#.*?>(.*?)</a>""")

"Simple comment removal (see rss)."
const HTML_COMMENT_PAT = r"<!--(.|\n)*?-->"

"Simple empty line removal (see rss)."
const EMPTY_LINE_PAT = r"\n[\s\n]*\n"
