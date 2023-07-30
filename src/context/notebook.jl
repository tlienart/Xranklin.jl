"""
    Notebook

Structure wrapping around a module in which code gets evaluated sequentially.
A Notebook is always contained within a context and is always accessed via
that context.
"""
abstract type Notebook end

#=
A VarsNotebook essentially wraps around a Vector of VarsCodePair, each
element is a (code_string => vars) where the vars is a vector of VarPair
with each element a (var_symbol => var_value).
=#
const VarPair       = NamedTuple{(:var,  :value), Tuple{Symbol, Any}}
const VarsCodePair  = NamedTuple{(:code, :vars),  Tuple{String, Vector{VarPair}}}
const VarsCodePairs = Vector{VarsCodePair}

#=
A CodeNotebook essentially wraps around a Vector of CodeCodePair, each
element is a (code_string => code_representation) where the code_representation
is a (;html="...", latex="...", raw="...") representation of the code output.
=#
const CodeRepr      = NamedTuple{(:html, :latex, :raw, :ansi),
                            Tuple{String, String, String, String}}
const CodeCodePair  = NamedTuple{(:code, :repr),
                            Tuple{String, CodeRepr}}
const CodeCodePairs = Vector{CodeCodePair}


"""
    VarsNotebook

Notebook for vars assignments.

## Fields

    mdl         : the module in which code gets evaluated
    cntr_refs   : keeps track of the evaluated "cell number" when sequentially
                   evaluating code
    code_pairs  : keeps track of [(code => vnames)]
    is_stale    : whether the notebook was loaded from cache.
"""
struct VarsNotebook <: Notebook
    mdl::Module
    cntr_ref::Ref{Int}
    code_pairs::VarsCodePairs
    is_stale::Ref{Bool}
end
VarsNotebook(mdl::Module) =
    VarsNotebook(mdl, Ref(1), VarsCodePairs(), Ref(false))


const DUMMY_CODE_MODULE = Module(:dummy_code_module, false, false)

"""
    CodeNotebook

Notebook for code.

## Fields

Same as VarsNotebook with additionally

    code_names: list of code block names in sequential order.
    is_stale:   keeps track of whether the notebook was loaded from cache.
                  If it was loaded from cache and a cell changes, all
                  previous cells will have to be re-evaluated.
    indep_code: keeps track of mapping {code_string => code_repr} for code
                 blocks explicitly marked as 'indep' so that their result
                 is "frozen" and the cell can be skipped.
    repl_code_hash: list of repl blocks and their hash (so that if they change
                    they get reevaluated).
"""
mutable struct CodeNotebook <: Notebook
    # see VarsNotebook
    mdl::Module
    cntr_ref::Ref{Int}
    code_pairs::CodeCodePairs
    # specific ones
    code_names::Vector{String}
    is_stale::Ref{Bool}
    indep_code::Dict{String, CodeRepr}
    repl_code_hash::Dict{String, UInt64}
end
CodeNotebook(mdl::Module=DUMMY_CODE_MODULE) =
    CodeNotebook(mdl, Ref(1), CodeCodePairs(),
                 String[], Ref(false),
                 Dict{String, CodeRepr}(),
                 Dict{String, UInt64}())

is_stale(nb::Notebook)        = nb.is_stale[]
stale_notebook!(nb::Notebook) = (nb.is_stale[] = true;)
fresh_notebook!(nb::Notebook) = (nb.is_stale[] = false;)

is_dummy(nb::CodeNotebook) = (nb.mdl === DUMMY_CODE_MODULE)
