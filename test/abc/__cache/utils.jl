function hfun_allv()
    va = getvarfrom(:v, "syntax/aa.md")
    vb = getvarfrom(:v, "syntax/bb.md")
    # vb = 0
    return "result: $va ; $vb"
end

function hfun_navmenu()
    io = IOBuffer()
    for m in getgvar(:menu)
        name = m.first
        subs = m.second

        # Submenu title + start of subs
        write(io, """
            <strong>
              $(uppercasefirst(name))
            </strong>
            <ul>
            """)

        # subs items
        for s in subs
            loc   = "$name/$s"
            title = getvarfrom(:header, loc * ".md")
            write(io, """
                <li><a href="/$loc/">
                        $title
                </a></li>
                """)
        end

        # end of list
        write(io, "</ul>")
    end
    return String(take!(io))
end
