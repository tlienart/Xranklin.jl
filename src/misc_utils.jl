const StringOrRegex = Union{String, Regex}

 """
    hl(s, c)

Make a string coloured and printable within a macro such as `@info`.
Courtesy of Andrey Oskin.
"""
function hl(o, c::Symbol=:light_magenta)
    io = IOBuffer()
    printstyled(IOContext(io, :color => true), o, color=c)
    return io |> take! |> String
end

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
    str_fmt(s, l=40)

Simple shortening of long strings to a string of max `l` characters
preceding the string with `[...]` if it's been shortened.
"""
function str_fmt(s::String, l=40)
    ss = last(s, l)
    ss == s && return "$s"
    return "[...]$ss"
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


"""
    anymatch(v1, v2)

Check if there's any matching pairs of element in v1 and v2.
"""
anymatch(v1, v2) = any(a == b for a in v1, b in v2)
