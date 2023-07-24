using Xranklin
using Xranklin: (/)
using Test
using Pkg
using Logging
using Dates
using Logging
using Colors
import Base: (//)
using Base.Threads
using IOCapture

import LiveServer
X = Xranklin;

X.setenv!(:strict_parsing, false)

X = Xranklin
MDL = X.env(:module_name)

ggc = X.DefaultGlobalContext()
X.setvar!(ggc, :skiplatex, false)

function toy_context()
    gc = X.DefaultGlobalContext()
    lc = X.DefaultLocalContext(gc; rpath="_toy_")
    return gc, lc
end

# ----------------------- #
# String comparison utils #
# ----------------------- #

isapproxstr(s1::AbstractString, s2::AbstractString) =
    isequal(map(s->replace(s, r"\s|\n"=>""), String.((s1, s2)))...)

# stricter than isapproxstr, just strips the outside.
(//)(s1::String, s2::String) = strip(s1) == strip(s2)

nmatch(r, s) = sum(1 for i in eachmatch(r, s))

function isbalanced(s)
    op = nmatch(r"<p(?:\s|>)", s)
    cp = nmatch(r"<\/p>", s)
    @test op == cp
    od = nmatch(r"<div(?:\s|>)", s)
    cd = nmatch(r"<\/div>", s)
    @test od == cd
end

function testdir(; tag=true)
    d = mktempdir();
    gc = X.DefaultGlobalContext();
    X.set_paths!(gc, d);
    if !tag
        gc.vars[:content_tag] = ""
    end
    d, gc
end

function readpg(rpath)
    fpath = X.path(:folder)/rpath
    d, f = splitdir(fpath)
    opath = X.get_opath(cur_gc(), d => f, :md)
    read(opath, String)
end

estr(s) = Xranklin._eval_str(Xranklin.DefaultLocalContext(;rpath="loc"), Xranklin.subs(s))

function lc_with_utils(utils="")
    gc = X.DefaultGlobalContext()
    X.process_utils(gc, utils)
    lc = X.DefaultLocalContext(gc; rpath="loc")
    return lc
end

has(h, p) = @test occursin(p, h)

tdir(n) = toy_example(name=n, parent=tempdir(), silent=true)
cdir(n) = isdir(n) && rm(n, recursive=true)


macro test_in_dir(dn, tn, body)
    printstyled(">> in dir: $dn / $tn\n", color=:yellow)
    FOLDER = tdir(dn)
    try
        eval(:(
            @testset(
                $tn,
                begin
                    FOLDER = $FOLDER
                    $body
                end
            )))
    catch
        println("test_in_dir ERROR")
    end
    cdir(FOLDER)
end

function output_contains(folder, p, s; show=false)
    c = read(folder / "__site" / p / "index.html", String)
    if show
        println(c)
    end
    return contains(c, s)
end

function test_contains(folder, p, s::Vector{String})
    for es in s
        @test output_contains(folder, p, es)
    end
end
test_contains(folder, p, s::String) = test_contains(folder, p, [s])



# @test_warn_with something() "partial msg"
macro test_warn_with(body, msg)
    test_logger = TestLogger(; min_level=Warn)
    with_logger(test_logger) do
        eval(:($body))
    end
    w = first(e for e in test_logger.logs if e.level == Logging.Warn)
    :(@test $(esc(contains(w.message, eval(:($msg))))))
end

function html_warn(s, lc=nothing; warn="")
    test_logger = TestLogger(; min_level=Warn)
    h = ""
    with_logger(test_logger) do
        if isnothing(lc)
            h = html(s)
        else
            h = html(s, lc)
        end
    end
    w = first(e for e in test_logger.logs if e.level == Logging.Warn)
    @test contains(w.message, warn)
    return h
end


function dirset(
        folder;
        scratch=false
    )
    if scratch
        for f in (
                folder/"config.md",
                folder/"utils.jl"
            )
            isfile(f) && rm(f)
        end
    end
    return
end
