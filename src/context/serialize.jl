lc_cache_path(rp::String) = path(:cache) / noext(rp) / "lc.cache"
gc_cache_path()           = path(:cache) / "gc.cache"

function serialize_lc(c::LocalContext)
    if !all(is_easily_serializable, values(c.vars))
        @info "... [lc of $(c.rpath)] ⚠ (non-serialisable vars, skipping)"
        return
    end
    nt = (
        # glob
        vars     = c.vars,      # serialisable by explicit check
        lxdefs   = c.lxdefs,    # always serialisable
        headings = c.headings,  # as
        rpath    = c.rpath,     # as
        anchors  = c.anchors,   # as
        # is_recursive
        # is_math
        req_vars   = c.req_vars,   # as
        req_lxdefs = c.req_lxdefs, # as
        # vars_aliases
        # nb_vars
        # nb_code
        to_trigger = c.to_trigger, # as
        page_hash  = c.page_hash[] # as
    )
    fp = lc_cache_path(c.rpath)
    mkpath(dirname(fp))
    open(fp, "w") do outf
        serialize(outf, nt)
    end
    @info "... [lc of $(c.rpath)] ✓"
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
    return lc
end

function serialize_gc(c::GlobalContext)
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
        anchors    = c.anchors,
        tags       = c.tags,
        paginated  = c.paginated,
        # to_trigger
        # init_trigger
        deps_map   = c.deps_map,
        children   = collect(keys(c.children_contexts))
    )
    @info "📓 serializing $(hl("global context", :cyan))..."
    open(gc_cache_path(), "w") do outf
        serialize(outf, nt)
    end
    @info "... [gc] ✓"

    for (rp, lc) in c.children_contexts
        endswith(rp, ".md") || continue
        @info "📓 serializing $(hl("local context of $(str_fmt(rp))", :cyan))..."
        serialize_lc(lc)
    end
    return
end

function deserialize_gc(gc::GlobalContext)
    nt = deserialize(gc_cache_path())
    merge!(gc.anchors,   nt.anchors)
    merge!(gc.tags,      nt.tags)
    union!(gc.paginated, nt.paginated)
    merge!(gc.deps_map,  nt.deps_map)

    # recover the children if the cache exists
    for rp in nt.children
        isfile(lc_cache_path(rp)) && deserialize_lc(rp, gc)
    end

    return gc
end
