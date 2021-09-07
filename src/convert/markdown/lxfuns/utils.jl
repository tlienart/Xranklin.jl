const INTERNAL_LXFUNS = Symbol[
    # .
    :failed,
    # /hyperrefs.jl
    :toc, :tableofcontents,
    :eqref,
    :cite, :citet, :citep,
    :label, :biblabel,
    :reflink,
]

const INTERNAL_ENVFUNS = Symbol[

]


"""
    \\failed{command name}{arg1}{arg2}

LxFun used for when other lxfuns fail.
"""
function lx_failed(p::VS; tohtml::Bool=true)::String
    s = "\\" * p[1] * prod("{$e}" for e in p[2:end])
    tohtml && return html_failed(s)
    return latex_failed(s)
end


function _lx_check_nargs(n::Symbol, p::VS, k::Int)
    np = length(p)
    if np != k
        @warn """
            \\$n...
            $n expects $k arg(s) ($k bracket(s) {...}), $np given.
            """
        return lx_failed([n, p...])
    end
    return ""
end
