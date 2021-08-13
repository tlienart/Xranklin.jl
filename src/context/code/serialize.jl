"""
    is_easily_serializable(x)

Checks if a value is "easily" serializable, what this means is that we can use
Julia's `Serialization.serialize` on the value and, in a completely
independent session, use `Serialization.deserialize` to recover exactly the
initial value. This assumes that the data can be completely represented in
terms of "pure" Julia types (any type defined in Core or Base or stdlib or
composites of such).
"""
is_easily_serializable(x) = is_easily_serializable(typeof(x))
function is_easily_serializable(T::DataType)
    T === Any && return false
    m = parentmodule(T)
    m in (Base, Core) && return true
    p = pathof(m)
    return p !== nothing && "stdlib" in splitpath(p)
end

is_easily_serializable(x::Union{Tuple, NamedTuple}) =
    all(is_easily_serializable, v for v in x)

is_easily_serializable(x::AA) where AA <: AbstractArray{T} where T =
    all(is_easily_serializable, (T, AA))
is_easily_serializable(x::AR) where AR <: AbstractRange{T} where T =
    all(is_easily_serializable, (T, AR))
is_easily_serializable(x::AD) where AD <: AbstractDict{K, V} where {K, V} =
    all(is_easily_serializable, (K, V, AD))

# For composites with Any type, we need to go over each entry
is_easily_serializable(x::AA) where AA <: AbstractArray{Any} =
    all(is_easily_serializable, (AA, x...))
is_easily_serializable(x::AD) where AD <: AbstractDict{K, Any} where {K} =
    all(is_easily_serializable, (K, AD, values(x)...))

is_easily_serializable(::Function) = false
is_easily_serializable(::Module)   = false
is_easily_serializable(::Ref)      = false
is_easily_serializable(::Ptr)      = false


# ======================== #
# Serialize a VarsNotebook #
# ======================== # ---------------------------------------------
# In this case, for each var assignment, we check whether it's easily
# serializable, if it is, we serialize and push to an equivalent struct
# if the struct is built to the end, we use JSON3 to write it to file
#
# if at some point it fails, the serialization attempt is given up on
# and that notebook will not be cached (which is not a problem)
# ------------------------------------------------------------------------

const VarPair_sz      = NamedTuple{(:var,  :value), Tuple{Symbol, String}}
const VarsCodePair_sz = NamedTuple{(:code, :vars),  Tuple{String, Vector{VarPair_sz}}}

"""
    serialize_vars_code_pairs(nb)

Goes through every code pair and tries to serialize the assignments and write
a corresponding nested structure with the serialized results.
Note that we go through a serialisation to avoid JSON3 losing information in
the process, particularly for composite types or things like dates.
"""
function serialize_vars_code_pairs(nb::VarsNotebook)::String
    all   = Vector{VarsCodePair_sz}()
    Utils = cur_utils_module()
    io    = IOBuffer()
    for (i, cp) in enumerate(nb.code_pairs)
        # (cp.code, cp.vars)
        vcp_sz = Vector{VarPair_sz}()
        for vp in cp.vars
            # vp.var, vp.value
            if is_easily_serializable(vp.value)
                value_sz = serialize(io, vp.value)
                push!(vcp_sz, VarPair_sz((vp.var, String(take!(io)))))
            else
                return empty!(all)
            end
        end
        push!(all, VarsCodePair_sz((
            cp.code,
            vcp_sz
            ))
        )
    end
    return JSON3.write(all)
end

function serialize_notebook(nb::VarsNotebook, fpath::String)
    length(nb) == 0 && return
    json = serialize_vars_code_pairs(nb)
    isempty(json) && return
    mkpath(splitdir(fpath)[1])
    open(fpath, "w") do outf
        write(outf, json)
    end
    return
end

# ========================== #
# DeSerialize a VarsNotebook #
# ========================== # -------------------------------------------
# Use JSON3 to reconstruct an object with the same structure then
# use Serialization.deserialize to reconstruct the values
# ------------------------------------------------------------------------

function reform(ctx::Context, io::IOBuffer, svp)::VarPair
    vname = Symbol(svp.var)
    # recuperate value
    write(io, svp.value)
    value = deserialize(seekstart(io))
    take!(io)
    # assign the value in the context
    setvar!(ctx, vname, value)
    return VarPair((vname, value))
end

# No file check, we know the file exists
# No emptying of the code pairs, it's assumed to be empty
function load_vars_cache!(ctx::Context, fpath::String)
    nb = ctx.nb_vars
    open(fpath, "r") do inf
        json = JSON3.read(inf)
        io   = IOBuffer()
        for cell in json
            push!(nb.code_pairs,
                VarsCodePair((
                    cell.code,
                    [
                        reform(ctx, io, svp)
                        for svp in cell.vars
                    ]
                ))
            )
        end
    end
    stale_notebook!(nb)
    return
end


# ======================== #
# Serialize a CodeNotebook #
# ======================== # ---------------------------------------------
# In this case, it's much easier because we only care about the text
# representation of the result of the code if any and that is just a
# couple of strings that we have to keep track of
# ------------------------------------------------------------------------

function serialize_notebook(nb::CodeNotebook, fpath::String)
    length(nb) == 0 && return
    mkpath(splitdir(fpath)[1])
    open(fpath, "w") do outf
        JSON3.write(outf,
            (
                code_pairs=nb.code_pairs,
                code_map=nb.code_map
            )
        )
    end
    return
end

function load_code_cache!(ctx::Context, fpath::String)
    nb = ctx.nb_code
    open(fpath, "r") do inf
        json = JSON3.read(inf)
        for cell in json.code_pairs
            push!(nb.code_pairs,
                CodeCodePair(
                    (
                        cell.code,
                        CodeRepr(
                            (
                                cell.repr.html,
                                cell.repr.latex
                            )
                        )
                    )
                )
            )
        end
        for cm in json.code_map
            nb.code_map[string(cm.first)] = cm.second
        end
    end
    stale_notebook!(nb)
    return
end
