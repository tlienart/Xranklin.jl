const INTERNAL_LXFUNS = Symbol[
    # /hyperrefs.jl
    :toc, :tableofcontents,
    :eqref,
    :cite, :citet, :citep,
    :label, :biblabel,
    :reflink,
    # /show.jl (a coderepr)
    :show, :mdshow, :htmlshow,
    # /literate.jl
    :literate,
    # /misc.jl
    :par,
    :nonumber,
    :activate,
]


"""
    failed_lxc(p; tohtml)

Returns an error message when a LaTeX-like command fails.
"""
function failed_lxc(
            p::VS;
            tohtml::Bool=true
        )::String

    s = "\\" * p[1] * prod("{$e}" for e in p[2:end])
    tohtml && return html_failed(s)
    return latex_failed(s)
end
failed_lxc(s::String, p::VS; kw...) = failed_lxc([s, p...]; kw...)


"""
    _lx_check_nargs(n, p, k)

Helper function to check whether the number of arguments (contained in `p`)
match the expected number of arguments `k` for the command `n`.
"""
function _lx_check_nargs(n::Symbol, p::VS, k::Int)
    np = length(p)
    if np != k
        @warn """
            \\$n...
            $n expects $k arg(s) ($k bracket(s) {...}), $np given.
            """
        return failed_lxc([n |> string, p...])
    end
    return ""
end


"""
    _lx_split_args_kwargs(s::String)

Attempt at splitting a string of the form "a, b, c; d=..., e=...".
Return a corresponding (tuple, namedtuple). In the case where the parsing
failed, return empty tuples and let the calling command handle the issue by
calling `failed_lxc`.
"""
function _lx_split_args_kwargs(s::String)::Tuple{Tuple, NamedTuple}
    try
        p = Meta.parse("_splitter_helper($s)")
        e = eval(p)
        if length(e) == 1
            typeof(e) == Tuple && return (e, (;))
            return ((), e)
        else
            return (e[1], NamedTuple(e[2]))
        end
    catch
        return ((), (;))
    end
end

_splitter_helper(a...; kw...) = (a, kw)

