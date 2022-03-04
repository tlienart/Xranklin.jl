#= ---------------------------------------------------------------------------
# NOTE
    hfun must necessarily return a String; see outputof hfun can *optionally*
    take one specific keyword tohtml=(true|false). If a hfun doesn't have that
    keyword then its output will be used in all cases;
    If it does have the keyword, then it may behave differently when the
    requested output is html or latex.
 -------------------------------------------------------------------------- =#

const INTERNAL_HENV_IF = [
    # PRIMARY
    :if,
    # SECONDARY
    :ifdef, :isdef, :isdefined,
    :ifndef, :ifnotdef, :isndef, :isnotdef, :isnotdefined,
    :ifempty, :isempty,
    :ifnempty, :ifnotempty, :isnotempty,
    :ispage, :ifpage,
    :isnotpage, :ifnotpage,
    :hasmath, :hascode,
]
const INTERNAL_HENV_FOR = [
    :for
]
const INTERNAL_HENVS = vcat(INTERNAL_HENV_IF, INTERNAL_HENV_FOR)

# if seen on their own --> hfunfailed
const INTERNAL_HORPHAN = [
    :elseif, :else, :end
]

const INTERNAL_HFUNS = [
    # .
    :failed,
    # /input.jl
    :fill,
    :insert, :include,
    :page_content,
    # /tags_pagination.jl
    :taglist,
    :paginate,
    # /hyperrefs.jl
    :toc,
    :eqref,
    :reflink,
    :cite,
    :link_a, :img_a,
    :footnotes,
    # /dates.jl
    :last_modification_date, :creation_date,
]


"""
    {{failed ...}}

Hfun used for when other hfuns fail.
"""
function hfun_failed(p::VS; tohtml::Bool=true)::String
    tohtml && return _hfun_failed_html(p)
    return _hfun_failed_latex(p)
end
hfun_failed(s::String, p::VS; kw...) = hfun_failed([s, p...]; kw...)

_hfun_failed_html(p::VS) = html_failed(
    "&lbrace;&lbrace; " * join(p, " ") * "&rbrace;&rbrace;"
)
_hfun_failed_latex(p::VS) = latex_failed(
    s = raw"\texttt{\{\{ " * join(p, " ") * raw"\}\}}"
)


"""
    _hfun_check_nargs(n, p; kmin, kmax)

Helper function to check the number of arguments in a hfun `n` with a vector
of parameters `p` and an expected number of arguments between `kmin` and
`kmax`. If only `kmin` is set then exactly that many arguments are expected.
"""
function _hfun_check_nargs(n::Symbol, p::VS; k::Int=0, kmin::Int=k, kmax::Int=k)
    np = length(p)
    if !(kmin ≤ np ≤ kmax)
        rge = ifelse(kmin == kmax, "$kmin", "[$kmin, $kmax]")
        @warn """
            {{$n ...}}
            $n expects $rge arg(s), $np given.
            """
        return hfun_failed(n |> string, p)
    end
    return ""
end
