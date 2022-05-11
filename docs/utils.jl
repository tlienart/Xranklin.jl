import Literate
import HTTP
import UnicodePlots

function hfun_rm_headings(ps::Vector{String})
    c = cur_lc()
    c === nothing && return ""
    for h in ps
        if h in keys(c.headings)
            delete!(c.headings, h)
        end
    end
    return ""
end

# used in syntax/vars+funs #e-strings demonstrating that e-strings are
# evaluated in the Utils module
bar(x) = "hello from foo <$x>"

struct Foo
    x::Int
end
html_show(f::Foo) = "<strong>Foo: $(f.x)</strong>"

struct Baz
    z::Int
end

####################################
# Layout
####################################

function hfun_navmenu()
    io = IOBuffer()
    for m in getgvar(:menu)
        name = m.first
        subs = m.second

        # Submenu title + start of subs
        write(io, """
            <div class="submenu-title">
                $(uppercasefirst(name))
            </div>
            <ul class="pure-menu-list">
            """)

        # subs items
        for s in subs
            loc   = "$name/$s"
            title = getvarfrom(:menu_title, loc * ".md")
            write(io, """
                <li class="pure-menu-item">
                    <a href="/$loc/" class="pure-menu-link">
                        $title
                    </a>
                </li>
                """)
        end

        # end of list
        write(io, "</ul>")
    end
    return String(take!(io))
end


####################################
# TTFX
####################################

function hfun_ttfx(p)
    p  = first(p)
    r  = ""
    r2 = ""

    # XXX PERF XXX
    return ""

    try
        r = HTTP.request(
            "GET",
            "https://raw.githubusercontent.com/tlienart/Xranklin.jl/gh-ttfx/ttfx/$(p)/timer"
        )
        r2 = HTTP.request(
            "GET",
            "https://raw.githubusercontent.com/tlienart/Xranklin.jl/gh-ttfx/ttfx/$(p)/timer2"
        )
    catch e
        return ""
    end
    t  = first(reinterpret(Float64, r.body))
    t2 = first(reinterpret(Float64, r2.body))
    return "$(t)min / $(t2)s"
end


####################################
# UnicodePlots
####################################

function html_show(p::UnicodePlots.Plot)
    td = tempdir()
    tf = tempname(td)
    io = IOBuffer()
    UnicodePlots.savefig(p, tf; color=true)
    # assume ansi2html is available
    if success(pipeline(`cat $tf`, `ansi2html -i -l`, io))
        return "<pre>" * String(take!(io)) * "</pre>"
    end
    return ""
end
