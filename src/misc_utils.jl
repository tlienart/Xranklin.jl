# useful for hfuns
const VS = Vector{String}
# used in default context
const StringOrRegex = Union{String, Regex}

"""
    p1 / p2

Acts as joinpath.
"""
(/)(s...) = joinpath(s...)

 """
    hl(s, c)

Make a string coloured and printable within a macro such as `@info`.
Courtesy of Andrey Oskin on discourse.
Allowed colours are the ones of `printstyled`.
"""
function hl(s, c::Symbol=:light_magenta)
    io = IOBuffer()
    printstyled(IOContext(io, :color => true), s, color=c)
    return io |> take! |> String
end
hprint(a...) = println(hl(a...))

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
function str_fmt(s::AbstractString, l=65)
    ss = last(s, l)
    ss == s && return "$s"
    return "[...]$ss"
end


"""
    change_ext(fname, new_extension)

Change the file extension of a filename.
"""
change_ext(fn, ext=".html") = noext(fn) * ext

"""
    noext(fpath)

Return `fpath` without extension `foo/bar.md` --> `foo/bar`.
"""
noext(fp::String) = first(splitext(fp))

"""
    anymatch(v1, v2)

Check if there's any matching pairs of element in v1 and v2.
"""
anymatch(v1, v2) = any(a == b for a in v1, b in v2)


"""
    match_url(base, cand)

Try to match two url indicators.
"""
function match_url(base::AbstractString, cand::AbstractString)
    sbase = first(base) === '/' ? base[2:end] : base
    scand = first(cand) === '/' ? cand[2:end] : cand
    # joker-style syntax
    if endswith(scand, "/*")
        return startswith(sbase, scand[1:prevind(scand, lastindex(scand), 2)])
    elseif endswith(scand, "/")
        scand = scand[1:prevind(scand, lastindex(scand))]
    end
    return noext(scand) == sbase
end


crumbs(s1, s2="") = @debug "🚧 ... $(hl(s1, :yellow)) $(s2 === "" ? "" : "> $(hl(s2, :light_green))")"
alert(s)          = @error "🚧 ... $s"


assetpath(s...) = begin
    p = joinpath(path(:assets), s...)
    mkpath(dirname(p))
    p
end

# see hfun_paginate
const PAGINATOR_TOKEN = "%##PAGINATOR##%"


"""
    filehash(fpath)

Compute a hash of a file that can be stored between sessions to check whether
two files have changed. For instance this can be used to check whether a
literate file has changed since last time the site was built.

Note that between two static files (e.g. two images), it's better to use
`filecmp` as it is significantly faster and can break early if the files
don't look identical.

In short: within session where you may have to check whether a file in
location A is identical to a file in location B, one should  use `filecmp`.
Across sessions, where we want to check whether a given file has changed,
we store the filehash and compare.
"""
filehash(fpath::String) = open(crc32c, fpath)


"""
    sstrip(s, a...)

Like strip except returns a string.
"""
sstrip(s, a...) = strip(s, a...) |> string
