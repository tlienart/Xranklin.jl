"""
    outputof(f, args; tohtml)

Output (string) of a hfun `f` with arguments `args`.
"""
function outputof(f::Function, args::Vector{String}; tohtml::Bool=true)::String
    return hasmethod(f, Tuple{Vector{String}}, (:tohtml,)) ?
               (isempty(args) ? f(; tohtml) : f(string.(args); tohtml)) :
               (isempty(args) ? f() : f(string.(args)))
end
