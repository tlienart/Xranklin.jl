using Xranklin
using Xranklin: (/)
using Test
using Dates
using Logging
using Colors
import Base: (//)

import LiveServer
X = Xranklin;

X.setenv!(:strict_parsing, false)

X = Xranklin
MDL = X.env(:module_name)


nowarn() = Logging.disable_logging(Logging.Warn)
logall() = (
    Logging.disable_logging(Logging.Debug - 100);
    ENV["JULIA_DEBUG"] = "all";
)

logall()

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
