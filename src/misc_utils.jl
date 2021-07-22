const StringOrRegex = Union{String, Regex}

"""
    time_fmt(δt)

Simple formatting for times in min, s, ms.
"""
function time_fmt(δt)
    δt ≥ 10  && return "(δt = $(round(δt / 60, digits=1))min)"
    δt ≥ 0.1 && return "(δt = $(round(δt, digits=1))s)"
    return "(δt = $(round(Int, δt * 1000))ms)"
end


"""
    change_ext(fname, new_extension)

Change the file extension of a filename.
"""
change_ext(fn, ext=".html") = splitext(fn)[1] * ext


"""
    html_attr

Convenience function to add an attribute to a html element.
"""
html_attr(n::Symbol, v::String) = ifelse(isempty(v), "", " $n=\"$v\"")
