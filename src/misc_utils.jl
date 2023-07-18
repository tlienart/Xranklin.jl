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
    repr(o)

Calls `repr` but strips away the `\"` for string-like objects (+ spurious
whitespace characters).
"""
function stripped_repr(s::AbstractString)
    wsp_nrm   = replace(s, r"\s"=>" ")
    wsp_strip = strip(wsp_nrm)
    r = repr(wsp_strip)
    r = replace(wsp_strip, r"\\\\\\\"" => "\"")
    return strip(r, '"')
end
stripped_repr(o) = repr(o)

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
yprint(a) = hprint("\n<"*string(a)*">\n", :yellow)

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


function info_thread(n::Int)
    @info "🧵 loop (n=$(Threads.nthreads())) over $n items"
end


"""
    change_ext(fname, new_extension)

Change the file extension of a filename.
"""
function change_ext(fn, ext=".html")
    return noext(fn) * ext
end

"""
    noext(fpath)

Return `fpath` without extension `foo/bar.md` --> `foo/bar`.
"""
function noext(fp::AbstractString)
    return first(splitext(fp))
end

"""
    anymatch(v1, v2)

Check if there's any matching pairs of element in v1 and v2.
"""
function anymatch(v1, v2)
    return any(a == b for a in v1, b in v2)
end


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
lines and line number node lines. Used in `is_code_equal`.
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


"""
Minified CSS sheet from https://watercss.kognise.dev/ (MIT licensed), 
used for the toy example.
"""
const WATER_CSS = raw"""
    :root {--background-body: #fff;--background: #efefef;--background-alt: #f7f7f7;--selection: #9e9e9e;--text-main: #363636;--text-bright: #000;--text-muted: #70777f;--links: #0076d1;--focus: #0096bfab;--border: #dbdbdb;--code: #000;--animation-duration: 0.1s;--button-base: #d0cfcf;--button-hover: #9b9b9b;--scrollbar-thumb: rgb(170, 170, 170);--scrollbar-thumb-hover: var(--button-hover);--form-placeholder: #949494;--form-text: #1d1d1d;--variable: #39a33c;--highlight: #ff0;--select-arrow: url("data:image/svg+xml;charset=utf-8,%3C?xml version='1.0' encoding='utf-8'?%3E %3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='62.5' width='116.9' fill='%23161f27'%3E %3Cpath d='M115.3,1.6 C113.7,0 111.1,0 109.5,1.6 L58.5,52.7 L7.4,1.6 C5.8,0 3.2,0 1.6,1.6 C0,3.2 0,5.8 1.6,7.4 L55.5,61.3 C56.3,62.1 57.3,62.5 58.4,62.5 C59.4,62.5 60.5,62.1 61.3,61.3 L115.2,7.4 C116.9,5.8 116.9,3.2 115.3,1.6Z'/%3E %3C/svg%3E");}@media (prefers-color-scheme: dark) {:root {--background-body: #202b38;--background: #161f27;--background-alt: #1a242f;--selection: #1c76c5;--text-main: #dbdbdb;--text-bright: #fff;--text-muted: #a9b1ba;--links: #41adff;--focus: #0096bfab;--border: #526980;--code: #ffbe85;--animation-duration: 0.1s;--button-base: #0c151c;--button-hover: #040a0f;--scrollbar-thumb: var(--button-hover);--scrollbar-thumb-hover: rgb(0, 0, 0);--form-placeholder: #a9a9a9;--form-text: #fff;--variable: #d941e2;--highlight: #efdb43;--select-arrow: url("data:image/svg+xml;charset=utf-8,%3C?xml version='1.0' encoding='utf-8'?%3E %3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='62.5' width='116.9' fill='%23efefef'%3E %3Cpath d='M115.3,1.6 C113.7,0 111.1,0 109.5,1.6 L58.5,52.7 L7.4,1.6 C5.8,0 3.2,0 1.6,1.6 C0,3.2 0,5.8 1.6,7.4 L55.5,61.3 C56.3,62.1 57.3,62.5 58.4,62.5 C59.4,62.5 60.5,62.1 61.3,61.3 L115.2,7.4 C116.9,5.8 116.9,3.2 115.3,1.6Z'/%3E %3C/svg%3E");}}html {scrollbar-color: rgb(170, 170, 170) #fff;scrollbar-color: var(--scrollbar-thumb) var(--background-body);scrollbar-width: thin;}@media (prefers-color-scheme: dark) {html {scrollbar-color: #040a0f #202b38;scrollbar-color: var(--scrollbar-thumb) var(--background-body);}}@media (prefers-color-scheme: dark) {html {scrollbar-color: #040a0f #202b38;scrollbar-color: var(--scrollbar-thumb) var(--background-body);}}@media (prefers-color-scheme: dark) {html {scrollbar-color: #040a0f #202b38;scrollbar-color: var(--scrollbar-thumb) var(--background-body);}}@media (prefers-color-scheme: dark) {html {scrollbar-color: #040a0f #202b38;scrollbar-color: var(--scrollbar-thumb) var(--background-body);}}@media (prefers-color-scheme: dark) {html {scrollbar-color: #040a0f #202b38;scrollbar-color: var(--scrollbar-thumb) var(--background-body);}}@media (prefers-color-scheme: dark) {html {scrollbar-color: #040a0f #202b38;scrollbar-color: var(--scrollbar-thumb) var(--background-body);}}body {font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', 'Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji', sans-serif;line-height: 1.4;max-width: 800px;margin: 20px auto;padding: 0 10px;word-wrap: break-word;color: #363636;color: var(--text-main);background: #fff;background: var(--background-body);text-rendering: optimizeLegibility;}@media (prefers-color-scheme: dark) {body {background: #202b38;background: var(--background-body);}}@media (prefers-color-scheme: dark) {body {color: #dbdbdb;color: var(--text-main);}}button {transition: background-color 0.1s linear, border-color 0.1s linear, color 0.1s linear, box-shadow 0.1s linear, transform 0.1s ease;transition: background-color var(--animation-duration) linear, border-color var(--animation-duration) linear, color var(--animation-duration) linear, box-shadow var(--animation-duration) linear, transform var(--animation-duration) ease;}@media (prefers-color-scheme: dark) {button {transition: background-color 0.1s linear, border-color 0.1s linear, color 0.1s linear, box-shadow 0.1s linear, transform 0.1s ease;transition: background-color var(--animation-duration) linear, border-color var(--animation-duration) linear, color var(--animation-duration) linear, box-shadow var(--animation-duration) linear, transform var(--animation-duration) ease;}}input {transition: background-color 0.1s linear, border-color 0.1s linear, color 0.1s linear, box-shadow 0.1s linear, transform 0.1s ease;transition: background-color var(--animation-duration) linear, border-color var(--animation-duration) linear, color var(--animation-duration) linear, box-shadow var(--animation-duration) linear, transform var(--animation-duration) ease;}@media (prefers-color-scheme: dark) {input {transition: background-color 0.1s linear, border-color 0.1s linear, color 0.1s linear, box-shadow 0.1s linear, transform 0.1s ease;transition: background-color var(--animation-duration) linear, border-color var(--animation-duration) linear, color var(--animation-duration) linear, box-shadow var(--animation-duration) linear, transform var(--animation-duration) ease;}}textarea {transition: background-color 0.1s linear, border-color 0.1s linear, color 0.1s linear, box-shadow 0.1s linear, transform 0.1s ease;transition: background-color var(--animation-duration) linear, border-color var(--animation-duration) linear, color var(--animation-duration) linear, box-shadow var(--animation-duration) linear, transform var(--animation-duration) ease;}@media (prefers-color-scheme: dark) {textarea {transition: background-color 0.1s linear, border-color 0.1s linear, color 0.1s linear, box-shadow 0.1s linear, transform 0.1s ease;transition: background-color var(--animation-duration) linear, border-color var(--animation-duration) linear, color var(--animation-duration) linear, box-shadow var(--animation-duration) linear, transform var(--animation-duration) ease;}}h1 {font-size: 2.2em;margin-top: 0;}h1, h2, h3, h4, h5, h6 {margin-bottom: 12px;margin-top: 24px;}h1 {color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {h1 {color: #fff;color: var(--text-bright);}}h2 {color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {h2 {color: #fff;color: var(--text-bright);}}h3 {color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {h3 {color: #fff;color: var(--text-bright);}}h4 {color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {h4 {color: #fff;color: var(--text-bright);}}h5 {color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {h5 {color: #fff;color: var(--text-bright);}}h6 {color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {h6 {color: #fff;color: var(--text-bright);}}strong {color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {strong {color: #fff;color: var(--text-bright);}}h1, h2, h3, h4, h5, h6, b, strong, th {font-weight: 600;}q::before {content: none;}q::after {content: none;}blockquote {border-left: 4px solid #0096bfab;border-left: 4px solid var(--focus);margin: 1.5em 0;padding: 0.5em 1em;font-style: italic;}@media (prefers-color-scheme: dark) {blockquote {border-left: 4px solid #0096bfab;border-left: 4px solid var(--focus);}}q {border-left: 4px solid #0096bfab;border-left: 4px solid var(--focus);margin: 1.5em 0;padding: 0.5em 1em;font-style: italic;}@media (prefers-color-scheme: dark) {q {border-left: 4px solid #0096bfab;border-left: 4px solid var(--focus);}}blockquote > footer {font-style: normal;border: 0;}blockquote cite {font-style: normal;}address {font-style: normal;}a[href^='mailto\:']::before {content: '📧 ';}a[href^='tel\:']::before {content: '📞 ';}a[href^='sms\:']::before {content: '💬 ';}mark {background-color: #ff0;background-color: var(--highlight);border-radius: 2px;padding: 0 2px 0 2px;color: #000;}@media (prefers-color-scheme: dark) {mark {background-color: #efdb43;background-color: var(--highlight);}}a > code, a > strong {color: inherit;}button, select, input[type='submit'], input[type='reset'], input[type='button'], input[type='checkbox'], input[type='range'], input[type='radio'] {cursor: pointer;}input, select {display: block;}[type='checkbox'], [type='radio'] {display: initial;}input {color: #1d1d1d;color: var(--form-text);background-color: #efefef;background-color: var(--background);font-family: inherit;font-size: inherit;margin-right: 6px;margin-bottom: 6px;padding: 10px;border: none;border-radius: 6px;outline: none;}@media (prefers-color-scheme: dark) {input {background-color: #161f27;background-color: var(--background);}}@media (prefers-color-scheme: dark) {input {color: #fff;color: var(--form-text);}}button {color: #1d1d1d;color: var(--form-text);background-color: #efefef;background-color: var(--background);font-family: inherit;font-size: inherit;margin-right: 6px;margin-bottom: 6px;padding: 10px;border: none;border-radius: 6px;outline: none;}@media (prefers-color-scheme: dark) {button {background-color: #161f27;background-color: var(--background);}}@media (prefers-color-scheme: dark) {button {color: #fff;color: var(--form-text);}}textarea {color: #1d1d1d;color: var(--form-text);background-color: #efefef;background-color: var(--background);font-family: inherit;font-size: inherit;margin-right: 6px;margin-bottom: 6px;padding: 10px;border: none;border-radius: 6px;outline: none;}@media (prefers-color-scheme: dark) {textarea {background-color: #161f27;background-color: var(--background);}}@media (prefers-color-scheme: dark) {textarea {color: #fff;color: var(--form-text);}}select {color: #1d1d1d;color: var(--form-text);background-color: #efefef;background-color: var(--background);font-family: inherit;font-size: inherit;margin-right: 6px;margin-bottom: 6px;padding: 10px;border: none;border-radius: 6px;outline: none;}@media (prefers-color-scheme: dark) {select {background-color: #161f27;background-color: var(--background);}}@media (prefers-color-scheme: dark) {select {color: #fff;color: var(--form-text);}}button {background-color: #d0cfcf;background-color: var(--button-base);padding-right: 30px;padding-left: 30px;}@media (prefers-color-scheme: dark) {button {background-color: #0c151c;background-color: var(--button-base);}}input[type='submit'] {background-color: #d0cfcf;background-color: var(--button-base);padding-right: 30px;padding-left: 30px;}@media (prefers-color-scheme: dark) {input[type='submit'] {background-color: #0c151c;background-color: var(--button-base);}}input[type='reset'] {background-color: #d0cfcf;background-color: var(--button-base);padding-right: 30px;padding-left: 30px;}@media (prefers-color-scheme: dark) {input[type='reset'] {background-color: #0c151c;background-color: var(--button-base);}}input[type='button'] {background-color: #d0cfcf;background-color: var(--button-base);padding-right: 30px;padding-left: 30px;}@media (prefers-color-scheme: dark) {input[type='button'] {background-color: #0c151c;background-color: var(--button-base);}}button:hover {background: #9b9b9b;background: var(--button-hover);}@media (prefers-color-scheme: dark) {button:hover {background: #040a0f;background: var(--button-hover);}}input[type='submit']:hover {background: #9b9b9b;background: var(--button-hover);}@media (prefers-color-scheme: dark) {input[type='submit']:hover {background: #040a0f;background: var(--button-hover);}}input[type='reset']:hover {background: #9b9b9b;background: var(--button-hover);}@media (prefers-color-scheme: dark) {input[type='reset']:hover {background: #040a0f;background: var(--button-hover);}}input[type='button']:hover {background: #9b9b9b;background: var(--button-hover);}@media (prefers-color-scheme: dark) {input[type='button']:hover {background: #040a0f;background: var(--button-hover);}}input[type='color'] {min-height: 2rem;padding: 8px;cursor: pointer;}input[type='checkbox'], input[type='radio'] {height: 1em;width: 1em;}input[type='radio'] {border-radius: 100%;}input {vertical-align: top;}label {vertical-align: middle;margin-bottom: 4px;display: inline-block;}input:not([type='checkbox']):not([type='radio']), input[type='range'], select, button, textarea {-webkit-appearance: none;}textarea {display: block;margin-right: 0;box-sizing: border-box;resize: vertical;}textarea:not([cols]) {width: 100%;}textarea:not([rows]) {min-height: 40px;height: 140px;}select {background: #efefef url("data:image/svg+xml;charset=utf-8,%3C?xml version='1.0' encoding='utf-8'?%3E %3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='62.5' width='116.9' fill='%23161f27'%3E %3Cpath d='M115.3,1.6 C113.7,0 111.1,0 109.5,1.6 L58.5,52.7 L7.4,1.6 C5.8,0 3.2,0 1.6,1.6 C0,3.2 0,5.8 1.6,7.4 L55.5,61.3 C56.3,62.1 57.3,62.5 58.4,62.5 C59.4,62.5 60.5,62.1 61.3,61.3 L115.2,7.4 C116.9,5.8 116.9,3.2 115.3,1.6Z'/%3E %3C/svg%3E") calc(100% - 12px) 50% / 12px no-repeat;background: var(--background) var(--select-arrow) calc(100% - 12px) 50% / 12px no-repeat;padding-right: 35px;}@media (prefers-color-scheme: dark) {select {background: #161f27 url("data:image/svg+xml;charset=utf-8,%3C?xml version='1.0' encoding='utf-8'?%3E %3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='62.5' width='116.9' fill='%23efefef'%3E %3Cpath d='M115.3,1.6 C113.7,0 111.1,0 109.5,1.6 L58.5,52.7 L7.4,1.6 C5.8,0 3.2,0 1.6,1.6 C0,3.2 0,5.8 1.6,7.4 L55.5,61.3 C56.3,62.1 57.3,62.5 58.4,62.5 C59.4,62.5 60.5,62.1 61.3,61.3 L115.2,7.4 C116.9,5.8 116.9,3.2 115.3,1.6Z'/%3E %3C/svg%3E") calc(100% - 12px) 50% / 12px no-repeat;background: var(--background) var(--select-arrow) calc(100% - 12px) 50% / 12px no-repeat;}}@media (prefers-color-scheme: dark) {select {background: #161f27 url("data:image/svg+xml;charset=utf-8,%3C?xml version='1.0' encoding='utf-8'?%3E %3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='62.5' width='116.9' fill='%23efefef'%3E %3Cpath d='M115.3,1.6 C113.7,0 111.1,0 109.5,1.6 L58.5,52.7 L7.4,1.6 C5.8,0 3.2,0 1.6,1.6 C0,3.2 0,5.8 1.6,7.4 L55.5,61.3 C56.3,62.1 57.3,62.5 58.4,62.5 C59.4,62.5 60.5,62.1 61.3,61.3 L115.2,7.4 C116.9,5.8 116.9,3.2 115.3,1.6Z'/%3E %3C/svg%3E") calc(100% - 12px) 50% / 12px no-repeat;background: var(--background) var(--select-arrow) calc(100% - 12px) 50% / 12px no-repeat;}}@media (prefers-color-scheme: dark) {select {background: #161f27 url("data:image/svg+xml;charset=utf-8,%3C?xml version='1.0' encoding='utf-8'?%3E %3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='62.5' width='116.9' fill='%23efefef'%3E %3Cpath d='M115.3,1.6 C113.7,0 111.1,0 109.5,1.6 L58.5,52.7 L7.4,1.6 C5.8,0 3.2,0 1.6,1.6 C0,3.2 0,5.8 1.6,7.4 L55.5,61.3 C56.3,62.1 57.3,62.5 58.4,62.5 C59.4,62.5 60.5,62.1 61.3,61.3 L115.2,7.4 C116.9,5.8 116.9,3.2 115.3,1.6Z'/%3E %3C/svg%3E") calc(100% - 12px) 50% / 12px no-repeat;background: var(--background) var(--select-arrow) calc(100% - 12px) 50% / 12px no-repeat;}}@media (prefers-color-scheme: dark) {select {background: #161f27 url("data:image/svg+xml;charset=utf-8,%3C?xml version='1.0' encoding='utf-8'?%3E %3Csvg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='62.5' width='116.9' fill='%23efefef'%3E %3Cpath d='M115.3,1.6 C113.7,0 111.1,0 109.5,1.6 L58.5,52.7 L7.4,1.6 C5.8,0 3.2,0 1.6,1.6 C0,3.2 0,5.8 1.6,7.4 L55.5,61.3 C56.3,62.1 57.3,62.5 58.4,62.5 C59.4,62.5 60.5,62.1 61.3,61.3 L115.2,7.4 C116.9,5.8 116.9,3.2 115.3,1.6Z'/%3E %3C/svg%3E") calc(100% - 12px) 50% / 12px no-repeat;background: var(--background) var(--select-arrow) calc(100% - 12px) 50% / 12px no-repeat;}}select::-ms-expand {display: none;}select[multiple] {padding-right: 10px;background-image: none;overflow-y: auto;}input:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}@media (prefers-color-scheme: dark) {input:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}}select:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}@media (prefers-color-scheme: dark) {select:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}}button:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}@media (prefers-color-scheme: dark) {button:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}}textarea:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}@media (prefers-color-scheme: dark) {textarea:focus {box-shadow: 0 0 0 2px #0096bfab;box-shadow: 0 0 0 2px var(--focus);}}input[type='checkbox']:active, input[type='radio']:active, input[type='submit']:active, input[type='reset']:active, input[type='button']:active, input[type='range']:active, button:active {transform: translateY(2px);}input:disabled, select:disabled, button:disabled, textarea:disabled {cursor: not-allowed;opacity: 0.5;}::-moz-placeholder {color: #949494;color: var(--form-placeholder);}:-ms-input-placeholder {color: #949494;color: var(--form-placeholder);}::-ms-input-placeholder {color: #949494;color: var(--form-placeholder);}::placeholder {color: #949494;color: var(--form-placeholder);}@media (prefers-color-scheme: dark) {::-moz-placeholder {color: #a9a9a9;color: var(--form-placeholder);}:-ms-input-placeholder {color: #a9a9a9;color: var(--form-placeholder);}::-ms-input-placeholder {color: #a9a9a9;color: var(--form-placeholder);}::placeholder {color: #a9a9a9;color: var(--form-placeholder);}}fieldset {border: 1px #0096bfab solid;border: 1px var(--focus) solid;border-radius: 6px;margin: 0;margin-bottom: 12px;padding: 10px;}@media (prefers-color-scheme: dark) {fieldset {border: 1px #0096bfab solid;border: 1px var(--focus) solid;}}legend {font-size: 0.9em;font-weight: 600;}input[type='range'] {margin: 10px 0;padding: 10px 0;background: transparent;}input[type='range']:focus {outline: none;}input[type='range']::-webkit-slider-runnable-track {width: 100%;height: 9.5px;-webkit-transition: 0.2s;transition: 0.2s;background: #efefef;background: var(--background);border-radius: 3px;}@media (prefers-color-scheme: dark) {input[type='range']::-webkit-slider-runnable-track {background: #161f27;background: var(--background);}}input[type='range']::-webkit-slider-thumb {box-shadow: 0 1px 1px #000, 0 0 1px #0d0d0d;height: 20px;width: 20px;border-radius: 50%;background: #dbdbdb;background: var(--border);-webkit-appearance: none;margin-top: -7px;}@media (prefers-color-scheme: dark) {input[type='range']::-webkit-slider-thumb {background: #526980;background: var(--border);}}input[type='range']:focus::-webkit-slider-runnable-track {background: #efefef;background: var(--background);}@media (prefers-color-scheme: dark) {input[type='range']:focus::-webkit-slider-runnable-track {background: #161f27;background: var(--background);}}input[type='range']::-moz-range-track {width: 100%;height: 9.5px;-moz-transition: 0.2s;transition: 0.2s;background: #efefef;background: var(--background);border-radius: 3px;}@media (prefers-color-scheme: dark) {input[type='range']::-moz-range-track {background: #161f27;background: var(--background);}}input[type='range']::-moz-range-thumb {box-shadow: 1px 1px 1px #000, 0 0 1px #0d0d0d;height: 20px;width: 20px;border-radius: 50%;background: #dbdbdb;background: var(--border);}@media (prefers-color-scheme: dark) {input[type='range']::-moz-range-thumb {background: #526980;background: var(--border);}}input[type='range']::-ms-track {width: 100%;height: 9.5px;background: transparent;border-color: transparent;border-width: 16px 0;color: transparent;}input[type='range']::-ms-fill-lower {background: #efefef;background: var(--background);border: 0.2px solid #010101;border-radius: 3px;box-shadow: 1px 1px 1px #000, 0 0 1px #0d0d0d;}@media (prefers-color-scheme: dark) {input[type='range']::-ms-fill-lower {background: #161f27;background: var(--background);}}input[type='range']::-ms-fill-upper {background: #efefef;background: var(--background);border: 0.2px solid #010101;border-radius: 3px;box-shadow: 1px 1px 1px #000, 0 0 1px #0d0d0d;}@media (prefers-color-scheme: dark) {input[type='range']::-ms-fill-upper {background: #161f27;background: var(--background);}}input[type='range']::-ms-thumb {box-shadow: 1px 1px 1px #000, 0 0 1px #0d0d0d;border: 1px solid #000;height: 20px;width: 20px;border-radius: 50%;background: #dbdbdb;background: var(--border);}@media (prefers-color-scheme: dark) {input[type='range']::-ms-thumb {background: #526980;background: var(--border);}}input[type='range']:focus::-ms-fill-lower {background: #efefef;background: var(--background);}@media (prefers-color-scheme: dark) {input[type='range']:focus::-ms-fill-lower {background: #161f27;background: var(--background);}}input[type='range']:focus::-ms-fill-upper {background: #efefef;background: var(--background);}@media (prefers-color-scheme: dark) {input[type='range']:focus::-ms-fill-upper {background: #161f27;background: var(--background);}}a {text-decoration: none;color: #0076d1;color: var(--links);}@media (prefers-color-scheme: dark) {a {color: #41adff;color: var(--links);}}a:hover {text-decoration: underline;}code {background: #efefef;background: var(--background);color: #000;color: var(--code);padding: 2.5px 5px;border-radius: 6px;font-size: 1em;}@media (prefers-color-scheme: dark) {code {color: #ffbe85;color: var(--code);}}@media (prefers-color-scheme: dark) {code {background: #161f27;background: var(--background);}}samp {background: #efefef;background: var(--background);color: #000;color: var(--code);padding: 2.5px 5px;border-radius: 6px;font-size: 1em;}@media (prefers-color-scheme: dark) {samp {color: #ffbe85;color: var(--code);}}@media (prefers-color-scheme: dark) {samp {background: #161f27;background: var(--background);}}time {background: #efefef;background: var(--background);color: #000;color: var(--code);padding: 2.5px 5px;border-radius: 6px;font-size: 1em;}@media (prefers-color-scheme: dark) {time {color: #ffbe85;color: var(--code);}}@media (prefers-color-scheme: dark) {time {background: #161f27;background: var(--background);}}pre > code {padding: 10px;display: block;overflow-x: auto;}var {color: #39a33c;color: var(--variable);font-style: normal;font-family: monospace;}@media (prefers-color-scheme: dark) {var {color: #d941e2;color: var(--variable);}}kbd {background: #efefef;background: var(--background);border: 1px solid #dbdbdb;border: 1px solid var(--border);border-radius: 2px;color: #363636;color: var(--text-main);padding: 2px 4px 2px 4px;}@media (prefers-color-scheme: dark) {kbd {color: #dbdbdb;color: var(--text-main);}}@media (prefers-color-scheme: dark) {kbd {border: 1px solid #526980;border: 1px solid var(--border);}}@media (prefers-color-scheme: dark) {kbd {background: #161f27;background: var(--background);}}img, video {max-width: 100%;height: auto;}hr {border: none;border-top: 1px solid #dbdbdb;border-top: 1px solid var(--border);}@media (prefers-color-scheme: dark) {hr {border-top: 1px solid #526980;border-top: 1px solid var(--border);}}table {border-collapse: collapse;margin-bottom: 10px;width: 100%;table-layout: fixed;}table caption {text-align: left;}td, th {padding: 6px;text-align: left;vertical-align: top;word-wrap: break-word;}thead {border-bottom: 1px solid #dbdbdb;border-bottom: 1px solid var(--border);}@media (prefers-color-scheme: dark) {thead {border-bottom: 1px solid #526980;border-bottom: 1px solid var(--border);}}tfoot {border-top: 1px solid #dbdbdb;border-top: 1px solid var(--border);}@media (prefers-color-scheme: dark) {tfoot {border-top: 1px solid #526980;border-top: 1px solid var(--border);}}tbody tr:nth-child(even) {background-color: #efefef;background-color: var(--background);}@media (prefers-color-scheme: dark) {tbody tr:nth-child(even) {background-color: #161f27;background-color: var(--background);}}tbody tr:nth-child(even) button {background-color: #f7f7f7;background-color: var(--background-alt);}@media (prefers-color-scheme: dark) {tbody tr:nth-child(even) button {background-color: #1a242f;background-color: var(--background-alt);}}tbody tr:nth-child(even) button:hover {background-color: #fff;background-color: var(--background-body);}@media (prefers-color-scheme: dark) {tbody tr:nth-child(even) button:hover {background-color: #202b38;background-color: var(--background-body);}}::-webkit-scrollbar {height: 10px;width: 10px;}::-webkit-scrollbar-track {background: #efefef;background: var(--background);border-radius: 6px;}@media (prefers-color-scheme: dark) {::-webkit-scrollbar-track {background: #161f27;background: var(--background);}}::-webkit-scrollbar-thumb {background: rgb(170, 170, 170);background: var(--scrollbar-thumb);border-radius: 6px;}@media (prefers-color-scheme: dark) {::-webkit-scrollbar-thumb {background: #040a0f;background: var(--scrollbar-thumb);}}@media (prefers-color-scheme: dark) {::-webkit-scrollbar-thumb {background: #040a0f;background: var(--scrollbar-thumb);}}::-webkit-scrollbar-thumb:hover {background: #9b9b9b;background: var(--scrollbar-thumb-hover);}@media (prefers-color-scheme: dark) {::-webkit-scrollbar-thumb:hover {background: rgb(0, 0, 0);background: var(--scrollbar-thumb-hover);}}@media (prefers-color-scheme: dark) {::-webkit-scrollbar-thumb:hover {background: rgb(0, 0, 0);background: var(--scrollbar-thumb-hover);}}::-moz-selection {background-color: #9e9e9e;background-color: var(--selection);color: #000;color: var(--text-bright);}::selection {background-color: #9e9e9e;background-color: var(--selection);color: #000;color: var(--text-bright);}@media (prefers-color-scheme: dark) {::-moz-selection {color: #fff;color: var(--text-bright);}::selection {color: #fff;color: var(--text-bright);}}@media (prefers-color-scheme: dark) {::-moz-selection {background-color: #1c76c5;background-color: var(--selection);}::selection {background-color: #1c76c5;background-color: var(--selection);}}details {display: flex;flex-direction: column;align-items: flex-start;background-color: #f7f7f7;background-color: var(--background-alt);padding: 10px 10px 0;margin: 1em 0;border-radius: 6px;overflow: hidden;}@media (prefers-color-scheme: dark) {details {background-color: #1a242f;background-color: var(--background-alt);}}details[open] {padding: 10px;}details > :last-child {margin-bottom: 0;}details[open] summary {margin-bottom: 10px;}summary {display: list-item;background-color: #efefef;background-color: var(--background);padding: 10px;margin: -10px -10px 0;cursor: pointer;outline: none;}@media (prefers-color-scheme: dark) {summary {background-color: #161f27;background-color: var(--background);}}summary:hover, summary:focus {text-decoration: underline;}details > :not(summary) {margin-top: 0;}summary::-webkit-details-marker {color: #363636;color: var(--text-main);}@media (prefers-color-scheme: dark) {summary::-webkit-details-marker {color: #dbdbdb;color: var(--text-main);}}dialog {background-color: #f7f7f7;background-color: var(--background-alt);color: #363636;color: var(--text-main);border: none;border-radius: 6px;border-color: #dbdbdb;border-color: var(--border);padding: 10px 30px;}@media (prefers-color-scheme: dark) {dialog {border-color: #526980;border-color: var(--border);}}@media (prefers-color-scheme: dark) {dialog {color: #dbdbdb;color: var(--text-main);}}@media (prefers-color-scheme: dark) {dialog {background-color: #1a242f;background-color: var(--background-alt);}}dialog > header:first-child {background-color: #efefef;background-color: var(--background);border-radius: 6px 6px 0 0;margin: -10px -30px 10px;padding: 10px;text-align: center;}@media (prefers-color-scheme: dark) {dialog > header:first-child {background-color: #161f27;background-color: var(--background);}}dialog::-webkit-backdrop {background: #0000009c;-webkit-backdrop-filter: blur(4px);backdrop-filter: blur(4px);}dialog::backdrop {background: #0000009c;-webkit-backdrop-filter: blur(4px);backdrop-filter: blur(4px);}footer {border-top: 1px solid #dbdbdb;border-top: 1px solid var(--border);padding-top: 10px;color: #70777f;color: var(--text-muted);}@media (prefers-color-scheme: dark) {footer {color: #a9b1ba;color: var(--text-muted);}}@media (prefers-color-scheme: dark) {footer {border-top: 1px solid #526980;border-top: 1px solid var(--border);}}body > footer {margin-top: 40px;}@media print {body, pre, code, summary, details, button, input, textarea {background-color: #fff;}button, input, textarea {border: 1px solid #000;}body, h1, h2, h3, h4, h5, h6, pre, code, button, input, textarea, footer, summary, strong {color: #000;}summary::marker {color: #000;}summary::-webkit-details-marker {color: #000;}tbody tr:nth-child(even) {background-color: #f2f2f2;}a {color: #00f;text-decoration: underline;}}
    """
