"""
    is_easily_serializable(x)

Checks if a value is "easily" serialisable, what this means is that we can use
Julia's `Serialization.serialize` on the value and, in a completely
independent session, use `Serialization.deserialize` to recover exactly the
initial value. This assumes that the data can be completely represented in
terms of "pure" Julia types (any type defined in Core or Base or stdlib or
composites of such).
"""
is_easily_serializable(x) = is_easily_serializable(typeof(x))

# types descending from Base, Core or Stdlib are easily serializable except Any
function is_easily_serializable(T::DataType)
    T === Any && return false
    m = parentmodule(T)
    m in (Base, Core) && return true
    p = pathof(m)
    return p !== nothing && "stdlib" in splitpath(p)
end

# composite types are serialisable if the composition is and if each element is
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

# other objects are not serialisable
is_easily_serializable(::Function) = false
is_easily_serializable(::Module)   = false
is_easily_serializable(::Ref)      = false
is_easily_serializable(::Ptr)      = false


"""
    serialize_notebook(nb, fpath)

If the notebook has all its cells easily serialisable, serialise them so that
the notebook can be cached. If it has code pairs that are not easily
serialisable in the sense of the `is_easily_serializable` function, give up
and the notebook won't be cached (which is not an issue, it will just be
re-evaluated as needed).

If a notebook is empty or cannot be easily serialised at time of serialisation
but a previous file exists, then remove it to avoid having an old cache being
loaded in the next step.

For the code notebook, we just have a bunch of strings so we don't need to
check whether things are easily serialisable. We also need to keep track of
the code map.
"""
function serialize_notebook(nb::VarsNotebook, fpath::String)::Nothing
    skip = (length(nb) == 0) || !is_easily_serializable(nb.code_pairs)
    if skip
        isfile(fpath) && rm(fpath)
        return
    end
    mkpath(splitdir(fpath)[1])
    serialize(fpath, nb.code_pairs)
    return
end
function serialize_notebook(nb::CodeNotebook, fpath::String)::Nothing
    skip = (length(nb) == 0)
    if skip
        isfile(fpath) && rm(fpath)
        return
    end
    mkpath(splitdir(fpath)[1])
    serialize(fpath, (code_pairs=nb.code_pairs, code_map=nb.code_map))
    return
end


"""
    load_vars_cache!(ctx, fpath)

Load a cached vars-notebook into the context. This can only happen in the
initial pass (see for instance `process_md_file_io!`) and so the notebook
has an empty set of code pairs (so we don't need to empty it here); we do
need to reconstruct all the var bindings though in order for `getvar` and
derivatives to work well.

The notebook is marked as stale so that a specific logic is triggered when
existing code cells are modified or new code cells added
(see `eval_code_cell!`).
"""
function load_vars_cache!(ctx::Context, fpath::String)
    start = time(); @info """
          🔄  loading vars cache $(hl(str_fmt(get_rpath(fpath)), :cyan))
        """
    nb = ctx.nb_vars
    try
        append!(nb.code_pairs, deserialize(fpath))
    catch
        # deserialization failed because of changed julia version or something of the sorts
        @info """
            ... [load vars] ❌ (deserialization failed, usually due to Julia version switch).
            """
        return
    end
    for vcp in nb.code_pairs, vp in vcp.vars
        setvar!(ctx, vp.var, vp.value)
    end
    stale_notebook!(nb)
    @info """
        ... [load vars] ✔ $(hl(time_fmt(time()-start)))
        """
    return
end

"""
    load_code_cache!(ctx, fpath)

Same as `load_vars_cache!` but for a code-notebook.
"""
function load_code_cache!(ctx::Context, fpath::String)
    start = time(); @info """
          🔄  loading code cache $(hl(str_fmt(get_rpath(fpath)), :cyan))
        """
    nb = ctx.nb_code
    try
        code_pairs, code_map = deserialize(fpath)
        append!(nb.code_pairs, code_pairs)
        merge!(nb.code_map, code_map)
    catch
        # deserialization failed because of changed julia version or something of the sorts
        @info """
            ... [load code] ❌ (deserialization failed, usually due to Julia version switch).
            """
        return
    end
    stale_notebook!(nb)
    @info """
        ... [load code] ✔ $(hl(time_fmt(time()-start)))
        """
    return
end
