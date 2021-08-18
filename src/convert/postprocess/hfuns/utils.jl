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
    :eqref,
    :cite,
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


function _hfun_check_nargs(n::Symbol, p::VS; kmin::Int=0, kmax::Int=kmin)
    np = length(p)
    if !(kmin ≤ np ≤ kmax)
        rge = ifelse(kmin == kmax, "$k", "[$kmin, $kmax]")
        @warn """
            {{$n ...}}
            $n expects $rge arg(s), $np given.
            """
        return hfun_failed(n, p)
    end
    return ""
end
