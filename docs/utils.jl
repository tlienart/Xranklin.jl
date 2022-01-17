function hfun_rm_headers(ps::Vector{String})
    c = cur_lc()
    for h in ps
        if h in keys(c.headers)
            delete!(c.headers, h)
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
