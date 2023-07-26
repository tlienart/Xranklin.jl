#=
RESOURCES
* Generate tables in LaTeX https://www.tablesgenerator.com
* LaTeX default style requires booktabs (toprule/midrule/bottomrule)

Example HTML table

<table>
  <thead>
    <tr>
      <th style="text-align:right">Header cell 1</th>
      <th>Header cell 2</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align:right">Body Row 1, cell 1</td>
      <td>Body Row 1, cell 2</td>
    </tr>
    <tr>
      <td style="text-align:right">Body Row 2, cell 1</td>
      <td>Body Row 2, cell 2</td>
    </tr>
  </tbody>
</table>

Example LaTeX table (note: requires number of columns a priori)

\begin{tabular}{lll}
  \toprule
  A & B & C \\
  \midrule
  0 & 1 & 2 \\
  \midrule
  3 & 4 & 5 \\
  \bottomrule
\end{tabular}

=#

const ALIGN_NONE   = 0  # c / nothing
const ALIGN_LEFT   = 1  # l / text-align: left
const ALIGN_CENTER = 2  # c / text-align: center
const ALIGN_RIGHT  = 3  # r / text-align: right


function convert_table(io::IOBuffer, g::Group, c::Context;
                       tohtml=true, kw...)::Nothing
    # after the split, the last pipe is not there apart from last
    rows      = split(g.ss, TABLE_ROW_SPLIT_PAT, keepempty=false)
    rows[end] = rstrip(rows[end], '|')

    # There must be at least two rows (head + body)
    length(rows) == 1 && return g.ss

    # Check separator row if any (row 2, optional)
    alignment = check_sep_row!(rows)

    #= table parsing
    .  process all rows -> Vector of Vector of substrings
    .  get number of column
    .  write header using information in alignment + number of columns
    .  convert each cell and write
    =#
    all_cells = row_partition.(rows)
    max_cols  = maximum(length.(all_cells))

    # Lambdas for html/latex
    if tohtml
        get_align   = i -> begin
            a = i <= length(alignment) ? alignment[i] : ALIGN_NONE
            s = a == ALIGN_LEFT   ? "style=\"text-align:left;\"" :
                a == ALIGN_CENTER ? "style=\"text-align:center;\"" :
                a == ALIGN_RIGHT  ? "style=\"text-align:right;\"" :
                ""
            end
        table_open  = "<table class=\"{{table_class}}\">\n"
        table_close = "</table>\n"
        head_open   = "<thead>\n"
        head_close  = "</thead>\n"
        body_open   = "<tbody>\n"
        body_close  = "</tbody>\n"
        head_cell   = (i, s) -> "<th $(get_align(i))>$s</th>\n"
        row_cell    = (i, s) -> begin
            ifelse(i==1, "<tr>\n", "") *
            "<td $(get_align(i))>$s</td>\n" *
            ifelse(i==max_cols, "</tr>\n", "")
        end
    else
        align_str = prod((
            e == ALIGN_NONE   ? "c" :
            e == ALIGN_LEFT   ? "l" :
            e == ALIGN_CENTER ? "c" : "r"
            for e in alignment))
        # padding for cols without header
        for i in 1:(max_cols-length(alignment))
            align_str *= "c"
        end
        table_open  = "\\begin{tabular}{$align_str}\n"
        table_close = "\\bottomrule\n\\end{tabular}"
        head_open   = "\\toprule\n"
        head_close  = "\\midrule\n"
        body_open   = ""
        body_close  = ""
        head_cell   = (i, s) -> "$s $(ifelse(i==max_cols, "\\\\\n", "& "))"
        row_cell    = head_cell
    end

    #=
    TABLE WRITING
    . note that cells are re-converted without <p>.
    =#
    write(io, table_open)
    # HEADER
    write(io, head_open)
    n = 0
    for (i, hc) in enumerate(all_cells[1])
        chc = convert_md(hc, c; tohtml, nop=true)
        write(io, head_cell(i, chc))
        n = i
    end
    for i in 1:(max_cols-length(all_cells[1]))
        write(io, head_cell(n+i, ""))
    end
    write(io, head_close)

    # CONTENT
    write(io, body_open)
    for k in 2:length(rows)
        n = 0
        for (i, hc) in enumerate(all_cells[k])
            chc = convert_md(hc, c; tohtml, nop=true)
            write(io, row_cell(i, chc))
            n = i
        end
        for i in 1:(max_cols-length(all_cells[k]))
            write(io, row_cell(n+i, ""))
        end
    end
    write(io, body_close)
    # END
    write(io, table_close)

    return
end


#=
Expected:

1. every line starts with   <[ \t]*|>  and end with   <|[ \t]*>  (note: if it's not the
    case, then the line is not in the group as it won't have been added by
    FranklinParser.process_line_return!)
2. linereturns should not occur within the scope of a table, use insertions ({{...}})
3. number of columns doesn't matter (we're similar to kramdown here)
4. <line 1> determines the header separated by <|> (:PIPE)
5. <line 2> determines the centering of columns, separated by <|> note that
    in HTML5 'align' is deprecated, users should prefer leveraging CSS for this,
    i.e. td:nth-child(col_idx){text-align:center;}
    It doesn't need to be present.
6. <line 3+> determines content, any missing cell will be replaced by empty

This is close to kramdown (http://kramdown.electricbook.works)
=#

"""
    check_sep_row!(rows)

Check the second row to see if it's a separator row, if it is, populate an
alignment vector which indicates the alignment information for the columns.
"""
function check_sep_row!(rows::Vector{SS})
    alignment = Int[]
    m_sep     = match(TABLE_SEP_LINE_PAT, rows[2])
    # there is no separator row (note that if there is one but it's badly
    # formatted, it will just be ingested as a content row)
    m_sep === nothing && return alignment
    # there is a separator row, check the alignment
    for m in eachmatch(TABLE_SEP_COL_PAT, rows[2])
        cand  = m.captures[1]
        left  = startswith(cand, ":")
        right = endswith(cand, ":")
        if left && right
            push!(alignment, ALIGN_CENTER)
        elseif left
            push!(alignment, ALIGN_LEFT)
        elseif right
            push!(alignment, ALIGN_RIGHT)
        else
            push!(alignment, ALIGN_NONE)
        end
    end
    deleteat!(rows, 2)
    return alignment
end


function row_partition(row::SS)
    tokens = FP.default_md_tokenizer(row)
    idx1   = findfirst(t -> t.name == :PIPE, tokens)
    parts  = FP.md_partition(row; tokens=@view tokens[idx1:end])
    # there will typically only be one part, in any case we only consider text
    # parts and the pipes in those and determine substrings based on that
    pipes = Token[]
    for p in parts
        pp = filter(t -> t.name == :PIPE, p.inner_tokens)
        append!(pipes, ifelse(p.name == :TEXT, pp, Token[]))
    end
    ps = parent_string(row)

    # partitioning into cells, remember that there is necessarily a starting |
    # but there isn't a closing | because it gets stripped in the split
    cells = SS[]
    curp  = first(pipes)
    for i in eachindex(pipes)
        i == 1 && continue
        nextp = pipes[i]
        push!(cells, subs(ps, next_index(curp), prev_index(nextp)))
        curp  = nextp
    end
    # last cell
    push!(cells, subs(ps, next_index(curp), to(row)))
    return cells
end
