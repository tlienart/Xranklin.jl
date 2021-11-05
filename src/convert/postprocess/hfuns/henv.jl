#= Conditional blocks

{{if XXX}}          [==1]

{{elseif XXX}}      [>=0]

{{else}}            [∈{0,1}]

{{end}}             [==1]

CONDS FORMAT
------------

{{if var}}
{{if e"f($var)"}}
{{if e"""f($var)"""}}

v        --> equivalent to e"$v"
e"$v"    --> equivalent to e"getlvar(:v)"
e"f($v)" --> run in utils module
e"..."  --> ANY failure and ignore code block (with warning)

---------------------------------
. find all corresponding DBB
. assemble them into COND blocks
. go through them in sequence (allow evaluation as )

---------------------------------
. derive cond blocks (ispage, ...) should basically be specific if blocks
=#



struct HEnvPart
    name::Symbol
    block::Block
    args::Vector{String}
end


"""
    find_henv(parts, idx)

Starting from `parts[idx]` find the relevant closing block and keep track
of branching block (elseif, else) if appropriate.
If no closing block is found, an empty environment is returned.

Once returned the blocks need to be validated.

## Example

    {{if ...}}  ... {{end}}              --> [IF, ELSE, END]
    {{if ...}}  ... {{elseif ...}} ...   --> [IF, ELSEIF, ELSEIF, ..., ELSE, END]
    {{for ...}} ... {{end}}              --> [FOR, END]
"""
function find_henv(parts::Vector{Block}, idx::Int)
    # first block (if/for)
    block = parts[idx]
    fn, args... = FP.split_args(strip(content(block)))
    fname = Symbol(lowercase(fn))

    henv     = [HEnvPart(fname, block, args)]
    branch   = fname in INTERNAL_HENV_IF
    has_else = false

    closing_index  = -1
    henv_depth     = 1
    # look at blocks ahead until the environment is closed with {{end}}
    for j in idx+1:length(parts)
        candb = parts[j]
        cand  = strip(content(candb))
        isempty(cand) && continue
        cn, cargs... = FP.split_args(cand)
        cname = Symbol(lowercase(cn))

        if (cname in INTERNAL_HENVS)
            henv_depth += 1

        elseif (cname == :end)
            henv_depth -= 1
            if henv_depth == 0
                push!(henv, HEnvPart(cname, candb, cargs))
                break
            end

        elseif branch && (henv_depth == 1) && !has_else

            if (cname == :elseif)
                push!(henv, HEnvPart(:elseif, candb, cargs))

            elseif (cname == :else)
                push!(henv, HEnvPart(:else, candb, cargs))
                has_else = true
            end
        end
    end
    # check
    if henv_depth > 0
        return HEnvPart[]
    end
    return henv
end

estr(s)  = "e\"$s\""
nestr(s) = replace(s, r"^e\"" => "e\"!")

_isemptyvar(v::T) where T = hasmethod(isempty, (T,)) ? isempty(v) : false
_isemptyvar(::Nothing)    = true
_isemptyvar(v::Date)      = (v == Date(1))


"""
"""
function resolve_henv(henv::Vector{HEnvPart}, io::IOBuffer, c::Context)
    env_name = first(henv).name

    if env_name in INTERNAL_HENV_IF
        scope = ""
        # evaluates conditions
        for (i, p) in enumerate(henv)
            p.name == :end && continue
            if _resolve_henv_cond(p)
                b_cur = p.block
                b_nxt = henv[i+1].block
                scope = subs(parent_string(b_cur),
                             next_index(b_cur),
                             prev_index(b_nxt)) |> string
                break
            end
        end
        # recurse
        write(io, html2(scope, c))


    elseif env_name in INTERNAL_HENV_FOR
        throw("NOT IMPLEMENTED ERROR")
    end
end


function _resolve_henv_cond(henv::HEnvPart)
    # XXX assumptions about the number of arguments
    env_name = henv.name
    env_name == :else && return true
    args     = henv.args
    cond_str = estr("false")
    if env_name in (:if, :elseif)
        # XXX
        @assert length(args) == 1
        cond_str = args[1]
        if !startswith(cond_str, "e\"")
            cond_str = estr("(\$$cond_str)")
        end

    # IS DEF
    elseif env_name in (:ifdef, :isdef, :ifndef, :ifnotdef, :isndef, :isnotdef)
        cond_str = estr("(getlvar(\$$arg) !== nothing)")
        if env_name in (:ifndef, :ifnotdef, :isndef, :isnotdef)
            cond_str = nestr(cond_str)
        end

    # IS EMPTY
    elseif env_name in (:ifempty, :isempty, :ifnempty, :ifnotempty, :isnotempty)
        cond_str = estr("Xranklin._isemptyvar(\$$arg)")
        if env_name in (:ifnempty, :ifnotempty, :isnotempty)
            cond_str = nestr(cond_str)
        end

    # IS PAGE (XXX tag)
    elseif env_name in (:ispage, :ifpage, :isnotpage, :ifnotpage)
        cond_str = estr("""
            begin
                rp = splitext(Xranklin.unixify(getlvar(:fd_rpath)))[1]
                any(p -> Xranklin.match_url(rp, p), $args)
            end
            """)
        if env_name in (:isnotpage, :ifnotpage)
            cond_str = nestr(cond_str)
        end
    end
    # XXX cast will fail
    return Bool(eval_str(cond_str))
end
