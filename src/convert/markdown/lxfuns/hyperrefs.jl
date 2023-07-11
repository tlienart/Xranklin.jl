#=
(See list of internal commands in ./utils.jl)

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
function lx_toc(
             lc::LocalContext;
             tohtml::Bool=true
         )::String

    # TODO in LaTeX it's a bit more subtle, we could play
    # with tocdepth setting, it won't be exactly the same
    tohtml || return "\\tableofcontents"
    minlevel = getvar(lc, :mintoclevel, 1)
    maxlevel = getvar(lc, :maxtoclevel, 6)
    return "{{toc $minlevel $maxlevel}}"
end
lx_tableofcontents = lx_toc


"""
    \\label{s|id}

Includes an anchor with a name so that it can be referenced elsewhere.
"""
function lx_label(
             lc::LocalContext,
             p::VS;
             tohtml::Bool=true
         )::String

    c = _lx_check_nargs(:label, p, 1)
    isempty(c) || return c
    # -------------------------------
    tohtml || return "\\label{$(p[1])}"
    # here we have a non empty label for a HTML output
    id = string_to_anchor(p[1])
    # keep track of the anchor, note that if there is already one
    # with that exact same id, then it will be overwritten!
    add_anchor(lc.glob, id, lc.rpath)
    class = getvar(lc.glob, :anchor_class, "anchor")
    return html_a(; id, class)
end


"""
    \\biblabel{id}{text}

Includes an anchor for a reference with first the id of the reference
(something to call in a \\cite{...} for instance) and second the
appearance of the reference.

Example: \\biblabel{fukumizu04}{Fukumizu et al. (2004)}
"""
function lx_biblabel(
             lc::LocalContext,
             p::VS;
             tohtml::Bool=true
         )::String

    c = _lx_check_nargs(:biblabel, p, 2)
    isempty(c) || return c
    # ----------------------------------
    # TODO in LaTeX could be with \bibitem but they need
    # to be placed inside a \begin{thebibliography} ...
    # \end{thebibliography}
    tohtml || return ""

    if tohtml
        id  = string_to_anchor(p[1])
        txt = replace(p[2], r"^<p>|</p>\n?$" => "")
        bibrefs(lc)[id] = txt
        class = getvar(lc.glob, lc, :anchor_class, "anchor") * " " *
                getvar(lc.glob, lc, :anchor_bib_class, "anchor-bib")
        return html_a(; id, class)
    end
end


"""
    \\eqref{s|id}

Refer to an equation possibly defined later.
"""
function lx_eqref(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:eqref, p, 1)
    isempty(c) || return c
    # -------------------------------
    tohtml || return "\\eqref{$(p[1])}"
    ids   = string_to_anchor.(string.(split(p[1], ',')))
    inner = prod(
        "{{eqref $id}}$(ifelse(i < length(ids), ", ", ""))"
        for (i, id) in enumerate(ids)
    )
    return "(" * inner * ")"
end


"""
    \\cite{s|id} or \\citet{s|id}

Refer to a bib item possibly defined later.
"""
function lx_cite(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true,
            wp::Bool=false
        )::String
    s = ifelse(wp, :citep, :cite)
    c = _lx_check_nargs(s, p, 1)
    isempty(c) || return c
    # --------------------------
    tohtml || return ifelse(wp, "\\citep{$(p[1])}", "\\cite{$(p[1])}")
    ids   = string_to_anchor.(string.(split(p[1], ',')))
    inner = prod("{{cite $id}}$(ifelse(i < length(ids), ", ", ""))"
                 for (i, id) in enumerate(ids))
    return ifelse(wp, "($inner)", inner)
end
lx_citet = lx_cite

lx_citep(a...; kw...) = lx_cite(a...; wp=true, kw...)
