#=
NOTE

IMPORTANT to understand the order.

1. MD parsing
2. gradual processing including solving of lxcoms (resolves lxfuns)
3. HTML2/LATEX2 postprocessing (resolves hfuns)

So lxfuns are resolved PRIOR to hfuns, and, for instance, can generate
a hfun so that that hfun takes the full context into account (this is
useful for forward references where you'd do \eqref{equation later} and
blah
$$ equation \label{equation later} $$

or biblabels etc.
=#

"""
    \\toc or \\tableofcontents

Includes a table of content, in the HTML case, this takes into account the
page variables `mintoclevel` and `maxtoclevel`.
"""
function lx_toc(; tohtml::Bool=true)::String
    # TODO in LaTeX it's a bit more subtle, we could play
    # with tocdepth setting, it won't be exactly the same
    tohtml || return "\\tableofcontents"

    minlevel = getlvar(:mintoclevel)::Int
    maxlevel = getlvar(:maxtoclevel)::Int
    return "{{toc $minlevel $maxlevel}}"
end
lx_tableofcontents = lx_toc


"""
    \\label{s|id}

Includes an anchor with a name so that it can be referenced elsewhere.
"""
function lx_label(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:label, p, 1)
    isempty(c) || return c

    tohtml || return "\\label{$(p[1])}"

    id = string_to_anchor(p[1])
    # keep track of the anchor, note that if there is already one with that
    # exact same id, then it will be overwritten!
    anchors()[id] = relative_url_curpage()
    class = getvar(c, :anchor_class, "anchor")
    return html_a(; id, class)
end

"""
    \\biblabel{id}{text}

Includes an anchor for a reference with first the id of the reference
(something to call in a \\cite{...} for instance) and second the
appearance of the reference.

Example: \\biblabel{fukumizu04}{Fukumizu et al. (2004)}
"""
function lx_biblabel(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:biblabel, p, 2)
    isempty(c) || return c

    # TODO in LaTeX could be with \bibitem but they need to be placed inside
    # a \begin{thebibliography} ... \end{thebibliography}
    tohtml || return ""

    if tohtml
        id  = string_to_anchor(p[1])
        txt = html(p[2])
        bibrefs()[id] = replace(txt, r"^<p>|</p>$" => "")
        class = getvar(c, :anchor_class, "anchor") * " " *
                getvar(c, :anchor_bib_class, "anchor-bib")
        return html_a(; id, class)
    end

end


"""
    \\reflink{s|id}

Refer to an anchor that might be anywhere on the site (not necessarily on the
current page).
"""
function lx_reflink(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:reflink, p, 1)
    isempty(c) || return c

    tohtml || return ""

    id = string_to_anchor(p[1])
    anchors_ = anchors()
    id in keys(anchors_) || return "#"
    return "$(anchors_[id])#$(id)"
end

"""
    \\eqref{s|id}

Refer to an equation possibly defined later.
"""
function lx_eqref(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:eqref, p, 1)
    isempty(c) || return c

    tohtml || return "\\eqref{$(p[1])}"

    ids   = string_to_anchor.(split(p[1], ','))
    inner = prod("{{eqref $id}}$(ifelse(i < length(ids), ", ", ""))"
                 for (i, id) in enumerate(ids))
    return "(" * inner * ")"
end

"""
    \\cite{s|id} or \\citet{s|id}

Refer to a bib item possibly defined later.
"""
function lx_cite(p::VS; tohtml::Bool=true, wp::Bool=false)::String
    s = ifelse(wp, :citep, :cite)
    c = _lx_check_nargs(s, p, 1)
    isempty(c) || return c

    tohtml || return ifelse(wp, "\\citep{$(p[1])}", "\\cite{$(p[1])}")

    ids   = string_to_anchor.(split(p[1], ','))
    inner = prod("{{cite $id}}$(ifelse(i < length(ids), ", ", ""))"
                 for (i, id) in enumerate(ids))
    return ifelse(wp, "($inner)", inner)
end
lx_citet = lx_cite

lx_citep(a...; kw...) = lx_cite(a...; wp=true, kw...)
