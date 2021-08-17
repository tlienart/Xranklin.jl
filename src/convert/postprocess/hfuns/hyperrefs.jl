"""
    {{toc min max}}

H-Function for the table of contents, where `min` and `max` control the
minimum level and maximum level of  the table of content.
"""
function hfun_toc(p::VS)::String
    # check parameters
    np = length(p)
    if np != 2
        @warn """
            {{toc ...}}
            Toc should get two parameters, $np given.
            """
        return hfun_failed("toc", p)
    end

    # retrieve the headers of the local context
    # (type PageHeaders = LittleDict{String, Tuple{Int, Int}})
    headers = cur_lc().headers
    isempty(headers) && return ""

    # try to parse min-max level
    min = 0
    max = 100
    try
        min = parse(Int, p[1])
        max = parse(Int, p[2])
    catch
        @warn """
            {{toc ...}}
            Toc should get two integers, couldn't parse the args to int.
            """
        return hfun_failed("toc", p)
    end

    # trim the headers corresponding to min/max, each header is (id => (nocc, lvl))
    headers = [
        (; id, level, text)
        for (id, (_, level, text)) in headers
        if min ≤ level ≤ max
    ]
    base_level = minimum(h.level for h in headers) - 1
    cur_level  = base_level

    io = IOBuffer()
    for h in headers
        if h.level ≤ cur_level
            # close previous list item
            write(io, "</li>")
            # close additional sublists for each level eliminated
            for i in cur_level-1:-1:h.level
                write(io, "</ol></li>")
            end
            # reopen for this list item
            write(io, "<li>")

        elseif h.level > cur_level
            # open additional sublists for each level added
            for i in cur_level+1:h.level
                write(io, "<ol><li>")
            end
        end
        write(io, "<a href=\"#$(h.id)\">$(h.text)</a>")
        cur_level = h.level
    end

    # Close remaining lists, as if going down to the base level
    for i = cur_level-1:-1:base_level
        write(io, "</li></ol>")
    end

    return "<div class=\"franklin-toc\">$(String(take!(io)))</div>"
end
