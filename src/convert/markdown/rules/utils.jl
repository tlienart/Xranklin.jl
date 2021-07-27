"""
    attr(name, val)

Convenience function to add an attribute to a HTML element.
"""
attr(name::Symbol, val::String) =
    ifelse(isempty(val), val, " $name=\"$val\"")

"""
    string_to_anchor(s)

Takes a string `s` and replace spaces by underscores so that that we can use it
for hyper-references. So for instance `"aa  bb"` will become `aa_bb`.
It also defensively removes any non-word character so for instance `"aa bb !"` will be `"aa_bb"`
"""
function string_to_anchor(s::String)
    # remove html tags
    st = replace(s, r"<[a-z\/]+>" => "")
    # remove non-word characters
    st = replace(st, r"&#[0-9]+;" => "")
    st = replace(st, r"[^\p{L}0-9_\-\s]" => "")
    # replace spaces by underscores
    st = replace(lowercase(strip(st)), r"\s+" => "_")
    # to avoid clashes with numbering of repeated headers, replace
    # double underscores by a single one
    st = replace(st, r"__" => "_")
    # in the unlikely event we don't have anything here, return the hash
    # of the original string
    return ifelse(isempty(st), string(hash(s)), st)
end
