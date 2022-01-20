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
function failed_env(p::VS; tohtml::Bool=true)::String
    s = "\\begin{$(p[1])}" *
        prod("{$e}" for e in p[3:end]) *
        "... \\end{$(p[1])}"
    tohtml && return html_failed(s)
    return latex_failed(s)
end
failed_env(s::String, p::VS; kw...) = env_failed([s, p...]; kw...)


function _env_check_nargs(n::Symbol, p::VS, k::Int)
    # - 1 because first argument is always the environment content
    np = length(p) - 1
    if np != k
        @warn """
            \\begin{$n}...
            $n environment expects $k arg(s) ($k bracket(s) {...}), $np given.
            """
        return failed_env([n |> string, p...])
    end
    return ""
end
