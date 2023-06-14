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

## Errors

    * environment not closed properly >> handled in html2
    * one of the henv part is ill formed
    * e-string error
    * reference to a variable that doesn't exist
    * reference to a variable that doesn't have the right type
"""
function find_henv(
            parts::Vector{Block},
            idx::Int,
            fname::Symbol,
            args::Vector{String}
        )::Tuple{Vector{HEnvPart},Int}

    # first block (if/for)
    block    = parts[idx]
    henv     = [HEnvPart(fname, block, args)]
    branch   = fname in INTERNAL_HENV_IF
    has_else = false

    closing_index = idx+1
    henv_depth    = 1

    # look at blocks ahead until the environment is closed with {{end}}
    for j in idx+1:length(parts)

        candb        = parts[j]
        candb.name  == :DBB || continue
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

    # if not closed properly, return an empty env
    henv_depth > 0 && return (HEnvPart[], closing_index)

    # otherwise return the full environment
    return (henv, closing_index)
end


"""
    resolve_henv(lc, henv, io)

Take a `henv` (vector of key double brace blocks) resolve it and write to `io`
within the context `lc`.
"""
function resolve_henv(
            lc::LocalContext,
            henv::Vector{HEnvPart},
            io::IOBuffer
        )::Nothing

    env_name = first(henv).name
    crumbs(@fname, env_name)

    if env_name in INTERNAL_HENV_IF
        resolve_henv_if(lc, io, henv)

    elseif env_name in INTERNAL_HENV_FOR
        resolve_henv_for(lc, io, henv)
    end
    return
end
