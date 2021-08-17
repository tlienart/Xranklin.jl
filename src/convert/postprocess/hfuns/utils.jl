#= ---------------------------------------------------------------------------
# NOTE
    hfun must necessarily return a String; see outputof hfun can *optionally*
    take one specific keyword tohtml=(true|false). If a hfun doesn't have that
    keyword then its output will be used in all cases;
    If it does have the keyword, then it may behave differently when the
    requested output is html or latex.
 -------------------------------------------------------------------------- =#

const INTERNAL_HENVS = [
    # :if,
    # :ifdef, :isdef,
    # :ifndef, :ifnotdef, :isndef, :isnotdef,
    # :ifempty, :isempty,
    # :ifnempty, :ifnotempty, :isnotempty,
    # :ispage, :ifpage,
    # :isnotpage, :ifnotpage,
    # :for
]

const INTERNAL_HFUNS = [
    # .
    :failed,
    # /input.jl
    :fill,
    :insert, :include,
    # /hyperrefs.jl
    :toc,
]


"""
    {{failed ...}}

Hfun used for when other hfuns fail.
"""
function hfun_failed(p::VS; tohtml::Bool=true)::String
    tohtml && return _hfun_failed_html(p)
    return _hfun_failed_latex(p)
end
hfun_failed(s::String, p::VS) = hfun_failed([s, p...])

_hfun_failed_html(p::VS) = html_failed(
    "&lbrace;&lbrace; " * prod(e * " " for e in p) * "&rbrace;&rbrace;"
)
_hfun_failed_latex(p::VS) = latex_failed(
    s = raw"\texttt{\{\{ " * prod(e * " " for e in p) * raw"\}\}}"
)


"""
    {{href a b}}

Primarily for internal use and constructed by lxfuns such as eqref, cite etc.
They construct hfuns so that this is resolved at a secondary
"""
# function hfun_insert(p::VS; tohtml::Bool=true)::String
