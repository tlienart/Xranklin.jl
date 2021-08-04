using Xranklin
using Xranklin: (/)
using Test
using Dates
using Logging
import Base: (//)

X = Xranklin

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

nowarn() = Logging.disable_logging(Logging.Warn)
logall() = (
    Logging.disable_logging(Logging.Debug - 100);
    ENV["JULIA_DEBUG"] = "all";
)
