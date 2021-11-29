function html_prepost(s, pre; kw...)
   tmp = pre
   for (k, v) in kw
      tmp = replace(tmp, ">" => " " * attr(k, v) * " >")
   end
   post = replace(pre, "<"=>"</")
   pre  = replace(tmp, " >"=>">")
   return pre * s * post
end

function latex_prepost(s, pre)
    pre  = "\\$pre{"
    post = "}"
    return pre * s * post
end


"""
    string_to_anchor(s)

Takes a string `s` and replace spaces by underscores so that that we can use
it for hyper-references. So for instance `"aa  bb"` will become `aa_bb`.
It also defensively removes any non-word character so for instance `"aa bb !"`
will be `"aa_bb"`
"""
function string_to_anchor(s::AbstractString; keep_first_caret::Bool=false)
    # remove html tags
    st = replace(strip(s), r"<[a-zA-Z\/]+>" => "")
    # remove non-word characters or non-ascii
    st = replace(st, r"&#[0-9]+;" => "")
    if keep_first_caret
        st = replace(st, r"(?!^)\^" => "")
    else
        st = replace(st, r"\^" => "")
    end
    # non-ascii
    st = replace(st, r"[^\x00-\x7F]" => "")
    # replace spaces by underscores
    st = replace(lowercase(strip(st)), r"\s+|\-+" => "_")
    # to avoid clashes with numbering of repeated headers, replace
    # double underscores by a single one
    st = replace(st, r"__" => "_")
    # in the unlikely event we don't have anything here, return the hash
    # of the original string
    return ifelse(isempty(st), string(hash(s)), st)
end
string_to_anchor(ss::SS) = string_to_anchor(string(ss))


"""
    escape_xml(s)

Take a (sub)string (typically from code) and escape XML characters that could
otherwise lead to html tags.
"""
escape_xml(s::SS) = occursin(XML_SPECIAL, s) ?
    replace(s, XML_SPECIAL => replace_unsafe_char) : s

const XML_SPECIAL = Regex("[&<>\"]")
const UNSAFE_MAP  = LittleDict(
    "&"  => "&amp;",
    "<"  => "&lt;",
    ">"  => "&gt;",
    "\"" => "&quot;",
)
replace_unsafe_char(s::AbstractString) = get(UNSAFE_MAP, s, s)


"""
    hascode!(c)

Set the context as having code.
"""
hascode!(c::LocalContext) = setvar!(c, :hascode, true)


"""
    hasmath!(c)

Set the context as having math
"""
hasmath!(c::LocalContext) = setvar!(c, :hasmath, true)
