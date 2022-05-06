"""
    outputof(fsymb, args, lc; tohtml)

Output (string) of a utils function `f` with arguments `args`.
"""
function outputof(
             fsymb::Symbol,
             args::Vector{String},
             lc::LocalContext;
             # kwargs
             internal::Bool=true,
             tohtml::Bool=true
         )::String

    if internal
        f   = getproperty(@__MODULE__, fsymb)
        res = isempty(args) ?
                f(lc; tohtml) :
                f(lc, args; tohtml)
    else
        f = getproperty(utils_module(lc), fsymb)
        res = hasmethod(f, Tuple{Vector{String}}, (:tohtml,)) ?
                   ( # there is a method with a ;tohtml
                     isempty(args) ?
                       (Base.@invokelatest f(; tohtml)) :
                       (Base.@invokelatest f(args; tohtml))
                   ) : (
                     # there isn't a method with a  ;tohtml
                     isempty(args) ?
                       (Base.@invokelatest f()) :
                       (Base.@invokelatest f(args))
                   )
    end
    return isnothing(res) ? "" : string(res)
end
