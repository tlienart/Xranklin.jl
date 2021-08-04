"""
    html2(s, c)

Postprocess a html string `s` in the context `c` (e.g. find and process double
brace blocks).
"""
html2(s::String, c::Context) = html2(FP.default_html_partition(s), c)


const HTML_OPEN = [
    :if,
    :ifdef, :isdef,
    :ifndef, :ifnotdef, :isndef, :isnotdef,
    :ifempty, :isempty,
    :ifnempty, :ifnotempty, :isnotempty,
    :ispage, :ifpage,
    :isnotpage, :ifnotpage,
    :for
]
const HTML_FUNCTIONS = [
    :insert, :include,
    :fill,
    :href,
    :toc,
    :taglist,
    :redirect,
    :paginate,
    :sitemap_opts,
    :fd2rss,
    :fix_relative_links,
    :rfc822
]

# there's currently 3 types of html blocks (see FranklinParser):
# * comment
# * script
# * DBB --> these are the ones we hunt for and re-process
# NOTE: the fact that we isolate script blocks also means that we do
# not get caught by DBB that happen within them. This, on the other hand,
# means that a user cannot use hfun or page var within a script.
function html2(parts::Vector{Block}, c::Context)::String
    io = IOBuffer()
    idx = 0
    while idx < length(parts)
        idx += 1
        b    = parts[idx]
        if b.name == :COMMENT
            continue
        elseif b.name in (:TEXT, :SCRIPT)
            write(io, string(b.ss))
            continue
        end
        # Double Brace Block processing
        cb = strip(content(b))
        isempty(cb) && continue
        split_cb = split(cb)
        fname    = Symbol(lowercase(first(split_cb)))
        if fname in HTML_OPEN
            # look for the matching closing END then pass the scope
            # to a dedicated sub-processing which can recurse
            throw(ErrorException("NOT IMPLEMENTED YET"))

        elseif fname in utils_hfun_names()
            # 'external' functions defined with `hfun_*`, they
            # take precedence so a user can overwrite the behaviour of
            # internal functions

            # XXX isdelayed() && return ""

            um   = cur_gc().nb_code.mdl
            args = split_cb[2:end]
            f    = getproperty(um, Symbol("hfun_$fname"))
            # force the output to be a string to not risk the write to io
            # being a bunch of gibberish
            out  = (isempty(args) ? f() : f(string.(args))) |> string
            write(io, out)

        elseif fname in HTML_FUNCTIONS
            # 'internal' function like {{insert ...}} or {{fill ...}}
            throw(ErrorException("NOT IMPLEMENTED YET"))

        else
            # try to see if it could be an implicit fill {{vname}}
            if (length(split_cb) == 1) && ((v = getvar(cur_lc(), fname)) !== nothing)
                write(io, string(v))
            elseif (length(split_cb) == 1) && (fname in utils_var_names())
                mdl = cur_gc().nb_code.mdl
                write(io, string(getproperty(mdl, fname)))
            else
                @warn """
                    {{ ... }}
                    ---------
                    A block '{{$fname ...}}' was found but the name '$fname'
                    does not correspond to a built-in block or hfun nor does it
                    match anything defined in `utils.jl`. It might have been
                    misspelled.
                    """
            end
        end
    end
    return String(take!(io))
end
