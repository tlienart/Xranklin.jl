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


info_thread(n::Int) = @info "🧵 loop (n=$(Threads.nthreads())) over $n items"


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
function match_url(
            base::AbstractString,       # comes from get_rurl
            cand::AbstractString        # candidate in args
        )::Bool

    base = replace(base, r"(?:^|/)index.html" => "")
    base = replace(base, "/1/" => "")
    base = strip(base, '/')

    cand = replace(cand, r"(?:^|/)index.html" => "")
    cand = replace(cand, r"/?404/" => "404.html")
    cand = strip(cand, '/')

    base == cand && return true

    # joker-style syntax
    return endswith(cand, "/*") && startswith(base, cand[1:prevind(cand, lastindex(cand), 2)])
end

# get the function name (used in crumbs)
macro fname()
    return :($(esc(Expr(:isdefined, :var"#self#"))) ? $(esc(:var"#self#")) : nothing)
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


"""
    filecmp(path1, path2)

Take 2 absolute paths and check if the files are different (return false if
different and true otherwise).
This code was suggested by Steven J. Johnson on discourse:
https://discourse.julialang.org/t/how-to-obtain-the-result-of-a-diff-between-2-files-in-a-loop/23784/4
"""
function filecmp(path1::AbstractString, path2::AbstractString)
    stat1, stat2 = stat(path1), stat(path2)
    if !(isfile(stat1) && isfile(stat2)) || filesize(stat1) != filesize(stat2)
        return false
    end
    stat1 == stat2 && return true # same file
    open(path1, "r") do file1
        open(path2, "r") do file2
            buf1 = Vector{UInt8}(undef, 32768)
            buf2 = similar(buf1)
            while !eof(file1) && !eof(file2)
                n1 = readbytes!(file1, buf1)
                n2 = readbytes!(file2, buf2)
                n1 != n2 && return false
                0 != Base._memcmp(buf1, buf2, n1) && return false
            end
            return eof(file1) == eof(file2)
        end
    end
end


"""
    utilscmp(path1, path2)

Similar to `filecmp` but allows for changes which do not affect code. This
allows to avoid triggering re-builds if changes in utils are irrelevant.
Note: this is called at a point where it is certain that path1 and path2 exist.
"""
function utilscmp(path1, path2)
    (isfile(path1) && isfile(path2)) || return false
    p1, p2 = Meta.parseall.(read.((path1, path2), String))
    return is_code_equal(p1, p2)
end

"""
    is_code_equal(a, b)

Try to assess whether the code in a and b (e.g. two strings) is the same
apart from small changes like whitespaces and docstrings. This allows to
check whether changes on `utils.jl` need to trigger a rebuild or not.
"""
function is_code_equal(e1::Expr, e2::Expr)
    v1, v2 = _trim.((e1, e2))
    is_code_equal(v1, v2)
end
function is_code_equal(a::Vector, b::Vector)
    length(a) == length(b) || return false
    for (ai, bi) in zip(a, b)
        is_code_equal(ai, bi) || return false
    end
    return true
end
is_code_equal(c1, c2) = (c1 == c2)
is_codestr_equal(s1, s2) = is_code_equal(Meta.parseall.((s1, s2))...)

"""
    _trim(e)

Internal function to trim the args of an Expr to discard toplevel docstring
lines and line number node lines.
"""
function _trim(e::Expr)
    if e.head != :toplevel
        return filter(x -> !(x isa LineNumberNode), e.args)
    end

    # for toplevel, discard docstring lines (+ LineNumberNode)
    r = []
    for ei in e.args
        if ei isa LineNumberNode
            continue
        elseif ei isa Expr && ei.head == :macrocall
            for a in ei.args
                if !(typeof(a) in (LineNumberNode, GlobalRef, String))
                    push!(r, a)
                end
            end
        else
            push!(r, ei)
        end
    end
    return r
end


"""
    dic2vec(d)

Return a vector of (k, v) pairs. Allows the dict to be iterated over
in a threaded loop.
"""
dic2vec(d::Dict) = [(k, v) for (k, v) in d]


