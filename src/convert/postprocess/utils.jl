"""
    outputof(f, args; tohtml)

Output (string) of a utils function `f` with arguments `args`.
"""
function outputof(f::Function, args::Vector{String}; tohtml::Bool=true)::String
    res = hasmethod(f, Tuple{Vector{String}}, (:tohtml,)) ?
               ( # there is a method with a ;tohtml
                 isempty(args) ?
                   (Base.@invokelatest f(; tohtml)) :
                   (Base.@invokelatest f(string.(args); tohtml))
               ) : (
                 # there isn't a method with a  ;tohtml
                 isempty(args) ?
                   (Base.@invokelatest f()) :
                   (Base.@invokelatest f(string.(args)))
               )
    return isnothing(res) ? "" : string(res)
end
