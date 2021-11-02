"""
    {{toc min max}}

H-Function for the table of contents, where `min` and `max` control the
minimum level and maximum level of  the table of content.
"""
function hfun_toc(p::VS)::String
    # check parameters
    c = _hfun_check_nargs(:toc, p; kmin=2)
    isempty(c) || return c

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

    return html_div(String(take!(io)); class=getlvar(:toc_class, "toc"))
end


"""
    {{eqref id}}

Reference to an equation, processed as hfun to allow forward references.
Necessarily in html context (this is generated by `\\eqref`).
"""
function hfun_eqref(p::VS)::String
    # no check needed as generated
    id      = p[1]
    eqrefs_ = eqrefs()
    id ∈ keys(eqrefs_) || return "<b>??</b>"
    text  = eqrefs_[id] |> string
    class = getgvar(:eqref_class, "eqref")
    return html_a(text; href="#$(id)", class)
end

"""
    {{cite id}}

Reference to a bib anchor. Necessarily in html context (generated by `\\cite`,
`\\citet` and `\\citep`).
"""
function hfun_cite(p::VS)::String
    # no check needed as generated
    id       = p[1]
    bibrefs_ = bibrefs()
    id ∈ keys(bibrefs_) || return "<b>??</b>"
    text  = bibrefs_[id]
    class = getgvar(:bibref_class, "bibref")
    return html_a(text; href="#$(id)", class)
end

"""
    {{link_a ref title}}

Insert a link if the reference exists otherwise just insert `[title]`.
"""
function hfun_link_a(p::VS)::String
    ref, title = p
    title      = strip(title, '\"') |> string
    refrefs_   = refrefs()
    ref ∈ keys(refrefs_) || return "[$title]"
    return html_a(title; href="$(refrefs_[ref])")
end

"""
    {{img_a ref title}}

Insert an img if the reference exists otherwise just insert `![title]`.
"""
function hfun_img_a(p::VS)::String
    ref, alt   = p
    alt        = strip(alt, '\"') |> string
    refrefs_   = refrefs()
    ref ∈ keys(refrefs_) || return "![$title]"
    return html_img(refrefs_[ref]; alt)
end
