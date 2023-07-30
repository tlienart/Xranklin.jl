include("utils.jl")
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

# ====================================
# Time to create a DefaultLocalContext
# as of 29/7/2023 it's around 0.33ms. 
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
    @btime X.DefaultLocalContext($gc; rpath=randstring(5));
end
