"""
    convert_list(io, g, ctx; tohtml, kw...)

The group `g` corresponds to a substring which is expected to be list-like.
This parses it, extracts the relevant element and writes the converted list
to `io`.

# Rules

    * indent with either two whitespaces (or more) or one tab (or more) from
        the previous level; extra indentation is ignored.
"""
function convert_list(io::IOBuffer, g::Group, ctx::LocalContext;
                      tohtml=true, kw...)::Nothing
    # ---------------------------------------------------------------------------------
    # g is just a wrapper around a block of text (g.ss)
    #
    #   > UNORDERED ITEM
    #       generic processing
    #   > ORDERED ITEM
    #       validate (has "1. " or "1) ")
    #       generic processing
    #       NOTE: first item is either a 1 OR has to have a new line before it
    #             and then it's a <ol start='...'> see specs (see commonmark specs)
    #
    # Generic Processing
    #       get level based on indentation and context
    #       NOTE: indentation based on increments of two whitespaces or one tab
    #       if more spaces, ignore.
    #       close <ul> or <ol> if relevant based on level
    #       open <ul> or <ol> if relevant
    #       grab raw text on line
    #       grab raw text of any subsequent inline blocks
    #       form overall string of that item, use convert_md
    #       write <li>CONVERTED_MD</li>
    #       NOTE: line skips are not allowed (so only tight lists)
    #
    # 'Enough indentation'
    #    \t is counted as globvar(tabs_to_spaces) number of whitespaces
    #
    # NOTE invalid is not a good idea because they won't be merged with previous
    # paragraph if any, so for instance if someone is writing
    #
    # ABC
    # 1.foo
    #
    # this will lead to <p>ABC</p><p>1.foo</p>
    # ---------------------------------------------------------------------------------

    # this may be empty e.g. if it's an invalid OL item
    markers = eachmatch(LIST_MARKER_PAT, g.ss) |> collect

    if isempty(markers)
        # no valid marker found, re-convert but without item parsing
        write(io,
            convert_md(
                g.ss, ctx;
                tohtml, disable=[:ITEM_O_CAND, :ITEM_U_CAND]
            )
        )
        return
    end

    # process items iteratively keeping track of what's open
    prev_levels = Symbol[]
    init_ind    = Ref{Int}(0)

    # convenience function
    _process_item!(mrk, item_str) = process_item!(
        prev_levels, init_ind, io, ctx,
        item_str, mrk, tohtml
    )

    nxt_mrk = first(markers)
    @inbounds for i in 1:length(markers)-1
        cur_mrk  = nxt_mrk
        nxt_mrk  = markers[i+1]
        idx_from = nextind(g.ss, cur_mrk.offset + length(cur_mrk.match) - 1)
        idx_to   = prevind(g.ss, nxt_mrk.offset)
        item_str = subs(g.ss, idx_from, idx_to)
        _process_item!(cur_mrk, item_str)
    end
    # last item
    cur_mrk  = nxt_mrk
    idx_from = nextind(g.ss, cur_mrk.offset + length(cur_mrk.match) - 1)
    idx_to   = lastindex(g.ss)
    item_str = subs(g.ss, idx_from, idx_to)
    _process_item!(cur_mrk, item_str)

    # close all levels
    if tohtml
        close_ol   = "</ol>\n"
        close_ul   = "</ul>\n"
        close_item = "</li>\n"
    else
        close_ol   = "\\end{enumerate}\n"
        close_ul   = "\\end{itemize}\n"
        close_item = "\n"
    end

    write(io, close_item)
    while true
        lvl_to_close = pop!(prev_levels)
        write(io, ifelse(lvl_to_close == :ol, close_ol, close_ul))
        if isempty(prev_levels)
            break
        else
            write(io, close_item)
        end
    end
    return
end


"""
    process_item!(prev_levels, init_ind, io, ctx, item_str, cur_marker, tohtml)

Helper function to process a new item in a previously existing list context
(as per `prev_levels`). This is the function that is called on each item.
"""
function process_item!(
        prev_levels::Vector{Symbol},
        init_ind::Ref{Int},
        io::IOBuffer,
        ctx::LocalContext,
        item_str::SS,
        cur_marker::RegexMatch,
        tohtml::Bool
    )

    if tohtml
        open_ol    = "<ol>\n"
        close_ol   = "</ol>\n"
        open_ul    = "<ul>\n"
        close_ul   = "</ul>\n"
        open_item  = "<li>"
        close_item = "</li>\n"
    else
        open_ol    = "\\begin{enumerate}\n"
        close_ol   = "\\end{enumerate}\n"
        open_ul    = "\\begin{itemize}\n"
        close_ul   = "\\end{itemize}\n"
        open_item  = "\\item "
        close_item = "\n"
    end

    conv_str = convert_md(item_str, ctx; tohtml, nop=true)
    item_ind = cur_marker.captures[1]
    item_mrk = cur_marker.captures[2]
    # --------------------------------------------------------
    # check type
    is_ol = first(item_mrk) |> isdigit
    if is_ol && (init_num = parse(Int, chop(strip(item_mrk)))) > 1
        if tohtml
            open_ol = "<ol start=\"$init_num\">\n"
        else
            depth   = sum(prev_levels .== :ol)
            cidx    = ifelse(depth > 3, 1, depth + 1)
            counter = ["enumi", "enumii", "enumiii", "enumiv"][cidx]
            open_ol = "\\begin{enumerate}\\setcounter{$counter}{$(init_num-1)}\n"
        end
    end
    # level of indentation
    nlvls = length(prev_levels)    # number of openings
    # check raw indentation of current item
    tabs  = count("\t", item_ind)
    wsps  = count(" ", item_ind)
    level = tabs + div(wsps, 2)

    if nlvls == 0  # currently no list open
        init_ind[] = level
        incr       = 1
    else
        # 'dedent' with init_ind
        level = max(0, level - init_ind[])
        # if too much indentation, cap at +1 increment
        incr = min(level - nlvls + 1, 1)
    end

    if incr == 1
        write(io, ifelse(is_ol, open_ol, open_ul))
        push!(prev_levels, ifelse(is_ol, :ol, :ul))

    else
        write(io, close_item)
        # if reduced level, close the relevent levels
        if incr < 0
            # pop levels one by one
            for _ in 1:abs(incr)
                lvl_to_close = pop!(prev_levels)
                write(io, ifelse(lvl_to_close == :ol, close_ol, close_ul))
                write(io, close_item)
            end
        end

        # check previous item at same level
        # --> no previous item at same level: open
        # --> same type: do nothing
        # --> other type: close/open
        if isempty(prev_levels)
            write(io, ifelse(is_ol, open_ol, open_ul))
            push!(prev_levels, ifelse(is_ol, :ol, :ul))
        else
            prev_is_ol = last(prev_levels) == :ol
            # different type -> close+open
            if xor(is_ol, prev_is_ol)
                pop!(prev_levels)
                write(io, ifelse(prev_is_ol, close_ol, close_ul))
                write(io, ifelse(is_ol, open_ol, open_ul))
                push!(prev_levels, ifelse(is_ol, :ol, :ul))
            end
        end
    end
    write(io, open_item, conv_str)
end
