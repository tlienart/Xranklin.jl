"""
    outputof(f, args; tohtml)

Output (string) of a hfun `f` with arguments `args`.
"""
function outputof(f::Function, args::Vector{String}; tohtml::Bool=true)::String
    res = hasmethod(f, Tuple{Vector{String}}, (:tohtml,)) ?
               (
                 isempty(args) ?
                   (Base.@invokelatest f(; tohtml)) :
                   (Base.@invokelatest f(string.(args); tohtml))
               ) : (
                 isempty(args) ?
                   (Base.@invokelatest f()) :
                   (Base.@invokelatest f(string.(args)))
               )
    isnothing(res) && return ""
    return string(res)
end
