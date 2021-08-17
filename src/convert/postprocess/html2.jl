
"""
    html2(s, c)

Postprocess a html string `s` in the context `c` (e.g. find and process double
brace blocks).
"""
html2(s::String, c::Context) = html2(FP.default_html_partition(s), c)


# there's currently 3 types of html blocks (see FranklinParser):
# * comment
# * script
# * DBB --> these are the ones we hunt for and re-process
# NOTE: the fact that we isolate script blocks also means that we do
# not get caught by DBB that happen within them. This, on the other hand,
# means that a user cannot use hfun or page var within a script.
#
# NOTE: since the hfuns might call a process_file function which, itself
# sets a cur_local_ctx, it's important to re-set the cur_local_ctx after
# calling any hfun.
#
function html2(parts::Vector{Block}, c::Context)::String
    # Keep track of the current gc and lc, these may be changed
    # by the call to hfuns but should be re-set afterwards
    # we use the direct `env/setenv` for local since it may be nothing!
    cgc = cur_gc()
    clc = env(:cur_local_ctx)

    io = IOBuffer()
    idx = 0
    while idx < length(parts)
        idx += 1
        b    = parts[idx]
        if b.name == :COMMENT
            continue
        elseif b.name in (:TEXT, :SCRIPT)
            write(io, string(b.ss))
            continue
        end
        # Double Brace Block processing
        cb = strip(content(b))
        isempty(cb) && continue
        split_cb = string.(split(cb))
        fname    = Symbol(lowercase(first(split_cb)))
        if fname in INTERNAL_HENVS
            # look for the matching closing END then pass the scope
            # to a dedicated sub-processing which can recurse
            throw(ErrorException("NOT IMPLEMENTED YET"))

        elseif (u = fname in utils_hfun_names()) || fname in INTERNAL_HFUNS
            # 'external' functions defined with `hfun_*`, they
            # take precedence so a user can overwrite the behaviour of
            # internal functions
            mdl = ifelse(u, cgc.nb_code.mdl, @__MODULE__)
            args  = split_cb[2:end]
            fsymb = Symbol("hfun_$fname")
            f     = getproperty(mdl, fsymb)
            write(io, outputof(f, args; tohtml=true))

            # re-set current local and global context, just in case these were
            # changed by the call to the hfun (e.g. by triggering a processing)
            set_current_global_context(cgc)
            clc === nothing || set_current_local_context(clc)

        else
            # try to see if it could be an implicit fill {{vname}}
            if (length(split_cb) == 1) && ((v = getvar(clc, fname)) !== nothing)
                write(io, string(v))
            elseif (length(split_cb) == 1) && (fname in utils_var_names())
                mdl = cgc.nb_code.mdl
                write(io, string(getproperty(mdl, fname)))
            else
                @warn """
                    {{ ... }}
                    ---------
                    A block '{{$fname ...}}' was found but the name '$fname'
                    does not correspond to a built-in block or hfun nor does it
                    match anything defined in `utils.jl`. It might have been
                    misspelled.
                    """
            end
        end

        # ensure the cu

    end
    return String(take!(io))
end
