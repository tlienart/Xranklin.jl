const INTERNAL_ENVFUNS = Symbol[
    # /math.jl
    :equation, :equation_star,
    :align, :align_star,
    :aligned, :aligned_star,
    :eqnarray, :eqnarray_star,
]

"""
    failed_env(p; tohtml)

Returns an error message when a LaTeX-like environment fails.
"""
function failed_env(c::Context, p::VS; tohtml::Bool=true)::String
    s = "\\begin{$(p[1])}" *
        prod("{$e}" for e in p[3:end]) *
        "... \\end{$(p[1])}"
    isa(c, LocalContext) && setvar!(lc, :_has_failed_blocks, true)
    tohtml && return html_failed(s)
    return latex_failed(s)
end
failed_env(c, s::String, p::VS; kw...) = failed_env(c, [s, p...]; kw...)


function _env_check_nargs(c, n::Symbol, p::VS, k::Int)
    # - 1 because first argument is always the environment content
    np = length(p) - 1
    if np != k
        @warn """
            \\begin{$n}...
            $n environment expects $k arg(s) ($k bracket(s) {...}), $np given.
            """
        return failed_env(c, [n |> string, p...])
    end
    return ""
end
