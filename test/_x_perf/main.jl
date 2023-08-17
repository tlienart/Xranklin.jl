include("../utils.jl")
using Random
using BenchmarkTools

#
# Gist here is that per page, the processing time should be
# no more than 10ms (exec cell code time excluded).
#
# - instantiation of context (DefaultLocalContext)
# - parsing and resolution
# - assembling of page + writing page
#
# idea being that the processing of 100 pages would then take
# 1 second (less would be better of course)
# 
# ORDERING: whenever running these benchmarks, the order should
# go from most significant (at the top) to least significant.
# if the order changes, it needs to be investigated.
#
# Last ordering: Aug 4, 2023
#


#
# HTML conversion of a realistic page ⌛ ~10ms 🔴
#
# with or without a date doesn't change much eval of hfun fill takes
# negligible time on top of that
# begin
u = raw"""
    @reexport using Dates
    """
gc = X.DefaultGlobalContext()
X.process_utils(gc, u)
lc = X.DefaultLocalContext(gc; rpath=randstring(5))
ct = read(joinpath(@__DIR__, "ex" / "pg1.md"), String)

# this is a decomposition of the call to html
# the most significant call, by far, is the convert_md.

X.env(:log_times)
X.reset_timer()

@btime html($ct)

@btime X.convert_md($ct, $lc)

X.convert_md(ct, lc)
X.topk(X.TIMER)

@btime X.FP.md_partition($ct)


#######################

begin
    u = raw"""
        @reexport using Dates
        """
    gc = X.DefaultGlobalContext()
    X.process_utils(gc, u)
    function foo(_gc)
        lc = X.DefaultLocalContext(_gc; rpath=randstring(5))
        c = """
            | a  | `b` | c  | d |
            | -- | --- | -- | - |
            | 0  |  1  | 2  | 3 |
            | 5  | *a* | 4  | 5 |
            """
        html(c, lc)
    end
    @btime foo($gc);
end

#
# Creation of DefaultLocalContext + eval front matter ⌛ ~1.9ms 🟠
#
# with or without a date doesn't change much eval of hfun fill takes
# negligible time on top of that
begin
    u = raw"""
        @reexport using Dates
        """
    gc = X.DefaultGlobalContext()
    X.process_utils(gc, u)
    function foo(_gc)
        lc = X.DefaultLocalContext(_gc; rpath=randstring(5))
        c = """
            +++
            pub = Date(2023, 8, 15)
            title = "hello"
            +++
            ABC {{pub}}
            """
        html(c, lc)
    end
    @btime foo($gc);
end

#
# Creation of DefaultLocalContext ⌛ ~ 0.3ms ✅
#
begin
    u = raw"""
    import Literate
    @reexport using Dates
    using Literate
    import Hyperscript as HS

    node = HS.m

    dfmt(d) = Dates.format(d, "U d, yyyy")
    function hfun_dfmt(p::Vector{String})
        d = getlvar(Symbol(p[1]))
        return dfmt(d)
    end
    function hfun_page_tags()
        tags = get_page_tags()
        base = globvar(:tags_prefix)
        return join(
            (
                node("span", class="tag",
                    node("a", href="/$base/$id/", name)
                )
                for (id, name) in tags
            ),
            node("span", class="separator", "•")
        )
    end
    function hfun_taglist()
        return hfun_list_posts(getlvar(:tag_name))
    end
    """

    gc = X.DefaultGlobalContext()
    X.process_utils(gc, u)
    @btime X.DefaultLocalContext($gc; rpath=randstring(5));
end

