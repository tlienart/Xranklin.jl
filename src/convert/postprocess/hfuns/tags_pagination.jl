"""
    {{taglist}}

List corresponding to the ambient tag. So for a tag `tag_id` this will
generate a simple list with all the pages that have that tag.
"""
function hfun_taglist(; tohtml::Bool=true)::String
    tohtml || return
    gc = cur_gc()
    c  = IOBuffer()
    write(c, "<ul>")
    id     = locvar(:tag_id)
    tag    = gc.tags[id]
    rpaths = collect(tag.locs)

    # sort the rpaths by date (either given or take ctime otherwise)
    sorter(rp) = begin
        pd = getvarfrom(:date, rp)
        if pd === nothing
            lc = gc.children_contexts[rp]
            ct = lc.vars[:_creation_time]
            pd = Date(Dates.unix2datetime(ct))
        end
        return pd
    end
    sort!(rpaths, by=sorter, rev=true)

    # write each item
    for rp in rpaths
        title = getvarfrom(:title, rp, "")
        if isempty(title)
            title = "/$rp/"
        end
        url = unixify(rp)
        write(c, """
            <li>
              <a href="$(get_rurl(rp))">$title</a>
            </li>
            """)
    end

    # finalise
    write(c, "</ul>")
    return String(take!(c))
end


"""
    {{paginate iterable n_per_page}}

Generates pagination on a page (so that we get `/foo/bar/` and
`/foo/bar/2/`, etc.).

## Note

It is assumed there is at most one such call per page.
"""
function hfun_paginate(p::VS; tohtml::Bool=true)::String
    # check parameters
    c = _hfun_check_nargs(:paginate, p; k=2)
    isempty(c) || return c
    tohtml     || return

    ps = Symbol.(p)
    iter = getlvar(ps[1])
    npp  = getlvar(ps[2])

    # check parameters
    wm = "{{paginate $(p[1]) $(p[2])}}"
    if isnothing(iter)
        @warn """
            $wm
            The name '$(p[1])' does not match a page variable in the current
            local context. The call will be ignored.
            """
        return ""
    end
    if isnothing(npp)
        try
            npp = parse(Int, p[2])
        catch
            @warn """
                $wm
                Failed to parse the number of items per page '$(p[2])'.
                Setting to 10.
                """
            npp = 10
        end
    end

    # Cast to int and check it's greater than zero
    npp = round(Int, npp)
    if npp <= 0
        @warn """
            $wm
            Non-positive number of items per page ('$npp' from '$(p[2])').
            Setting to 10.
            """
        npp = 10
    end

    # was there already a pagination element on this page?
    # if so, warn and ignore.
    if !isempty(getlvar(:_paginator_name)::String)
        @warn """
            $wm
            Multiple calls to '{{paginate ...}}' on the page. You can have at
            most one. Ignoring this one.
            """
    end

    # Storing the name
    lc = cur_lc()
    setvar!(lc, :_paginator_name, p[1])
    setvar!(lc, :_paginator_npp,  npp)

    return PAGINATOR_TOKEN
end
