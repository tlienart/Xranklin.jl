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


"""
    HEnvPart

Element of a h-environment candidate. A h-environment will be made of a vector
of `HEnvPart` each corresponding to atoms: "IF", "FOR", "ELSEIF", "ELSE" and
"END" as well as variants of "IF".
"""
struct HEnvPart
    name::Symbol            # the role of the part e.g. :if, :for, ...
    block::Block            # the corresponding double brace block e.g. {{if x}}
    args::Vector{String}    # the args of the dbb, e.g. {{if x}} -> ["x"]
end


"""
    find_henv(parts::Vector{Block}, idx::Int)

Starting from `parts[idx]`, an opening h-env block, find the relevant closing
block and keep track of branching block (elseif, else) if appropriate. If no
closing block is found, an empty environment is returned.

Once returned the blocks need to be validated.

## Return

    * the vector of HEnvPart objects
    * the number of blocks in the START - END scope (allows `html2` to move
        the head after the scope).

## Example

    {{if ...}}  ... {{end}}              --> [IF, ELSE, END]
    {{if ...}}  ... {{elseif ...}} ...   --> [IF, ELSEIF, ELSEIF, ..., ELSE, END]
    {{for ...}} ... {{end}}              --> [FOR, END]

## Errors (see XXX)

    * environment not closed properly >> handled in html2
    * one of the henv part is ill formed
    * e-string error
    * reference to a variable that doesn't exist
    * reference to a variable that doesn't have the right type
"""
function find_henv(parts::Vector{Block}, idx::Int)::Tuple{Vector{HEnvPart},Int}
    # first block (if/for)
    block       = parts[idx]
    fn, args... = FP.split_args(strip(content(block)))
    fname       = Symbol(lowercase(fn))

    henv     = [HEnvPart(fname, block, args)]
    branch   = fname in INTERNAL_HENV_IF
    has_else = false

    closing_index  = idx+1
    henv_depth     = 1
    # look at blocks ahead until the environment is closed with {{end}}
    for j in idx+1:length(parts)
        candb        = parts[j]
        cand         = strip(content(candb))
        isempty(cand) && continue
        cn, cargs... = FP.split_args(cand)
        cname        = Symbol(lowercase(cn))

        if (cname in INTERNAL_HENVS)
            henv_depth += 1

        elseif (cname == :end)
            henv_depth -= 1
            if henv_depth == 0
                closing_index = j
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
        return (HEnvPart[], closing_index)
    end
    return (henv, closing_index)
end


_estr(s)  = "e\"$s\""
_nestr(s) = replace(s, r"^e\"" => "e\"!")

_isemptyvar(v::T) where T = hasmethod(isempty, (T,)) ? isempty(v) : false
_isemptyvar(::Nothing)    = true
_isemptyvar(v::Date)      = (v == Date(1))


"""
    resolve_henv(henv, io, c)

Take a `henv` (vector of key double brace blocks) resolve it and write to `io`
within the context `c`.
"""
function resolve_henv(henv::Vector{HEnvPart}, io::IOBuffer, c::Context)
    env_name = first(henv).name
    # ------------------------------------------------
    # IF-style h-env
    # > find the scope corresponding to the validated
    #    condition if any
    # > if a scope is found, recurse on it in context
    #    `c` and write the result to `io`
    if env_name in INTERNAL_HENV_IF
        scope = ""
        # evaluates conditions with `_resolve_henv_cond`
        # the first one that is validated has its scope
        # surfaced and recursed over
        for (i, p) in enumerate(henv)
            p.name == :end && continue
            if _resolve_henv_cond(p)
                b_cur = p.block
                b_nxt = henv[i+1].block
                scope = subs(
                    parent_string(b_cur),
                    next_index(b_cur),
                    prev_index(b_nxt)
                    ) |> string
                break
            end
        end
        # recurse over the validated scope
        write(io, html2(scope, c))

    # ------------------------------------------------
    # FOR-style h-env
    # > resolve the scope with a context in which the
    #    variable(s) from the iterator are inserted
    elseif env_name in INTERNAL_HENV_FOR
        # scope of the loop
        scope = subs(
            parent_string(henv[1].block),
            next_index(henv[1].block),
            prev_index(henv[end].block)
        ) |> string

        # {{for x in iter}}       --> {{for (x) in iter}}
        # {{for (x, y) in iter}}
        argiter    = join(henv[1].args, " ")
        vars, iter = strip.(split(argiter, "in"))

        if is_estr(iter)
            iter = eval_str(iter)
        else
            iter = getlvar(Symbol(iter))
        end

        # (x, y, z) => [:x, :y, :z]
        vars = strip.(split(strip(vars, ['(', ')']), ",")) .|> Symbol

        # check if there are vars with the same name in local context, if
        # so, save them, note that we filter to see if the var is in the
        # direct context (so not the global context associated with loc)
        cvars    = union(keys(c.vars), keys(c.vars_aliases))
        saved_vars = [
            v => getlvar(v)
            for v in vars if v in cvars
        ]

        # XXX lots of things to check here
        for vals in iter                              # loop over iterator values
            for (name, value) in zip(vars, vals)      # loop over variables and set
                setvar!(c, name, value)
            end
            write(io, html2(scope, c))
        end

        # reinstate or destroy bindings
        for (name, value) in saved_vars
            if value === nothing
                delete!(c.vars, name)
            else
                c.vars[name] = value
            end
        end
    end
end


function _resolve_henv_cond(henv::HEnvPart)
    # XXX assumptions about the number of arguments
    env_name = henv.name
    env_name == :else && return true
    args     = henv.args
    cond_str = _estr("false")
    if env_name in (:if, :elseif)
        # XXX
        @assert length(args) == 1
        cond_str = args[1]
        if !startswith(cond_str, "e\"")
            cond_str = _estr("(\$$cond_str)")
        end

    # IS DEF
    elseif env_name in (:ifdef, :isdef, :ifndef, :ifnotdef, :isndef, :isnotdef)
        cond_str = _estr("(getlvar(\$$arg) !== nothing)")
        if env_name in (:ifndef, :ifnotdef, :isndef, :isnotdef)
            cond_str = _nestr(cond_str)
        end

    # IS EMPTY
    elseif env_name in (:ifempty, :isempty, :ifnempty, :ifnotempty, :isnotempty)
        cond_str = _estr("Xranklin._isemptyvar(\$$arg)")
        if env_name in (:ifnempty, :ifnotempty, :isnotempty)
            cond_str = _nestr(cond_str)
        end

    # IS PAGE (XXX tag)
    elseif env_name in (:ispage, :ifpage, :isnotpage, :ifnotpage)
        cond_str = _estr("""
            begin
                rp = splitext(Xranklin.unixify(getlvar(:fd_rpath)))[1]
                any(p -> Xranklin.match_url(rp, p), $args)
            end
            """)
        if env_name in (:isnotpage, :ifnotpage)
            cond_str = _nestr(cond_str)
        end
    end
    # XXX cast will fail
    return Bool(eval_str(cond_str))
end
