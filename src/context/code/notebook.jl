#=
XXX

Notebook = struct that keeps track of code run, attached to a module,

Context
|- Notebook_vars
  |- module
  |- current counter
  |- ordered list of [(hash=..., result=...)]
  |- little dict of {id => idx} to help get the result of a code block by id
|- Notebook_code
    ...

When parsing a string in a context, instantiate a counter

c = 1
add!(Notebook, code, c)
c += 1
=#

const CodePair      = NamedTuple{(:hash, :result), Tuple{UInt64, Any}}
const DummyCodePair = CodePair((zero(UInt64), nothing))
const CodeMap       = LittleDict{String, Int}

struct Notebook
    mdl::Module
    cntr_ref::Ref{Int}
    code_pairs::Vector{CodePair}
    code_map::LittleDict{String, Int}
end

Notebook(n::String) = Notebook(
    submodule(modulename(n, true), wipe=true),
    Ref(1),
    CodePair[],
    CodeMap()
)

counter(nb::Notebook)     = nb.cntr_ref[]
increment!(nb::Notebook)  = (nb.cntr_ref[] += 1)
Base.length(nb::Notebook) = length(nb.code_pairs)

reset_counter!(nb::Notebook) = (nb.cntr_ref[] = 1)


"""
    reset_notebook!(nb)

Note: assumed that `nb` is attached to the current local context, see
remove_bindings.
"""
function reset_notebook!(nb::Notebook; ismddefs::Bool=false)
    reset_counter!(nb)
    ismddefs && remove_bindings(nb, 1)
    empty!(nb.code_pairs)
    empty!(nb.code_map)
end


function add!(
            nb::Notebook,
            code::SS;
            name::String="",
            ismddefs::Bool=false,
            kw...
            )
    # retrieve the counter, check if there's something there
    cntr = counter(nb)
    h    = hash(code)

    # check if there's a match
    if (get(nb.code_pairs, cntr, DummyCodePair).hash == h)
        increment!(nb)
        return
    end

    # there isn't a match (either code is different or it's a new block)
    # --> eval
    res = ismddefs ?
            process_md_defs(nb.mdl, code; kw...) :
            run_code(nb.mdl, code; kw...)

    cp  = CodePair((h, res))
    lnb = length(nb)
    if cntr ≤ lnb
        # for mddefs, need to remove all bindings since they might be obsolete now
        # for the ones that have a default value, use that
        ismddefs && remove_bindings(nb, cntr)
        # replace, leave the counter where it was and discard
        # everything after (gets re-evaled)
        nb.code_pairs[cntr] = cp
        deleteat!(nb.code_pairs, cntr+1:lnb)
    else
        push!(nb.code_pairs, cp)
    end
    increment!(nb)

    # if an id was given, keep track (if none was given, the empty string
    # links to lots of stuff, like "ans" in a way)
    nb.code_map[name] = cntr
    return
end
