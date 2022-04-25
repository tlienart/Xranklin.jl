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

# Types that are imported by Franklin should be considered easily serialisable
# as well because Franklin loads them and so the deserialization will work fine
# within a Franklin environment
is_easily_serializable(::Dict{A, B}) where {A, B} =
    all(is_easily_serializable, (A, B))
is_easily_serializable(::Type{Dict{A,B,C,D}}) where {A,B,C,D} =
    all(is_easily_serializable, (A, B, C, D))


lc_cache_path(rp::String) = path(:cache) / noext(rp) / "lc.cache"
gc_cache_path()           = path(:cache) / "gc.cache"

function serialize_lc(lc::LocalContext)
    if !all(is_easily_serializable, values(lc.vars))
        @info "... [lc of $(lc.rpath)] ⚠ (non-serialisable vars, skipping)"
        return
    end
    nt = (
        # glob
        vars     = lc.vars,      # serialisable by explicit check
        lxdefs   = lc.lxdefs,    # always serialisable
        headings = lc.headings,  # as
        rpath    = lc.rpath,     # as
        anchors  = lc.anchors,   # as
        # is_recursive
        # is_math
        req_vars   = lc.req_vars,   # as
        req_lxdefs = lc.req_lxdefs, # as
        # vars_aliases
        nb_vars_cp = lc.nb_vars.code_pairs,  # serialisable since lc.vars is
        nb_code_cp = lc.nb_code.code_pairs,  # as (string only)
        nb_code_cn = lc.nb_code.code_names,  # as
        nb_code_ic = lc.nb_code.indep_code,  # as
        # nb_code
        to_trigger = lc.to_trigger,  # as
        page_hash  = lc.page_hash[], # as
        # --
        applied_prefix = getvar(lc, :_applied_base_url_prefix, "")
    )
    fp = lc_cache_path(lc.rpath)
    mkpath(dirname(fp))
    open(fp, "w") do outf
        serialize(outf, nt)
    end
    @info "... [lc of $(lc.rpath)] ✓"
    return
end

function deserialize_lc(rp::String, gc::GlobalContext)
    nt = deserialize(lc_cache_path(rp))
    lc = DefaultLocalContext(gc; rpath=rp)
    merge!(lc.vars,       nt.vars)
    merge!(lc.lxdefs,     nt.lxdefs)
    merge!(lc.headings,   nt.headings)
    union!(lc.anchors,    nt.anchors)
    merge!(lc.req_vars,   nt.req_vars)
    union!(lc.req_lxdefs, nt.req_lxdefs)
    union!(lc.to_trigger, nt.to_trigger)
    lc.page_hash[] = nt.page_hash

    # deserialise notebooks and mark as stale
    append!(lc.nb_vars.code_pairs, nt.nb_vars_cp)
    append!(lc.nb_code.code_pairs, nt.nb_code_cp)
    append!(lc.nb_code.code_names, nt.nb_code_cn)
    merge!(lc.nb_code.indep_code,  nt.nb_code_ic)
    stale_notebook!(lc.nb_vars)
    stale_notebook!(lc.nb_code)

    setvar!(lc, :_applied_base_url_prefix, nt.applied_prefix)
    return lc
end

function serialize_gc(gc::GlobalContext)
    # we don't need to keep track of vars or lxdefs because we always
    # evaluate config and utils at the beginning of a run.
    # we also don't need to keep track of children, because when we
    # deserialise the LC they get attached to gc via DefaultLocalContext
    # of course this is only true for LC that could be serialised.
    # For those that couldn't we would re-evaluate the page anyway.
    nt = (
        # vars
        # lxdefs
        # vars_aliases
        # nb_vars
        # nb_code
        anchors    = gc.anchors,
        tags       = gc.tags,
        paginated  = gc.paginated,
        # to_trigger
        # init_trigger
        deps_map   = gc.deps_map,
        children   = collect(keys(gc.children_contexts))
    )
    @info "📓 serializing $(hl("global context", :cyan))..."
    open(gc_cache_path(), "w") do outf
        serialize(outf, nt)
    end
    @info "... [global context] ✓"
    nc = length(gc.children_contexts)
    @info "📓 serializing $(hl("$nc local context", :cyan))..."
    for (rp, lc) in gc.children_contexts
        endswith(rp, ".md") || continue
        serialize_lc(lc)
    end
    return
end

function deserialize_gc(gc::GlobalContext)

    @info "📓 de-serializing $(hl("global context", :cyan))..."
    nt = deserialize(gc_cache_path())
    merge!(gc.anchors,   nt.anchors)
    merge!(gc.tags,      nt.tags)
    union!(gc.paginated, nt.paginated)
    merge!(gc.deps_map,  nt.deps_map)

    # recover the children if the cache exists
    nc = length(nt.children)
    @info "📓 de-serializing $(hl("$nc local contexts", :cyan))..."
    for rp in nt.children
        endswith(rp, ".md") || continue
        isfile(lc_cache_path(rp)) && deserialize_lc(rp, gc)
    end

    return gc
end
