"""
    process_md_file_pass_i(lc)
"""
function process_md_file_pass_i(
            lc::LocalContext
        )::Nothing

    crumbs(@fname)

    gc    = lc.glob
    rpath = lc.rpath

    # Anchors to remove
    default = Set{String}()
    for id in getvar(lc, :_rm_anchors, default)
        rm_anchor(gc, id, rpath)
    end
    setvar!(lc, :_rm_anchors, default)

    # Tags to remove
    for id in getvar(lc, :_rm_tags, default)
        rm_tag(gc, id, rpath)
    end
    setvar!(lc, :_rm_tags, default)

    # Tags to add
    for (id, name) in getvar(lc, :_add_tags)
        add_tag(gc, id, name, rpath)
    end
    setvar!(lc, :_add_tags, default)

    return
end
