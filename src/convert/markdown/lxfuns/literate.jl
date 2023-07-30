#=
NOTE:

1. we use the Literate convention here with quadruple backticks (this was introduced
in v2.9 which is the minimal version allowed).

2. the logic here could be copied and adapted for other files like Pluto,
    PlutoStaticHTML, Weave etc. The key bit is the registration of the file
    to the global context's dependency map.

For point (2) there's a line

```
push!(gc.deps_map, lc.rpath, rpath)
```

This adds a dependent file `rpath` to a page file `lc.rpath`.
More exlicitly it amounts to

push!(dependency_map, page.md, literate.jl)

=#

"""
    \\literate{rpath}

Try to find a literate file, resolve it and return it.

## Notes

1. the `rpath` is taken relative to the website folder
2. the `rpath` must end with `.jl` and must not start with a `/`
3. it is recommended to have a dedicated 'literate' folder but not mandatory
"""
function lx_literate(
             lc::LocalContext,
             p::VS;
             tohtml::Bool=true
         )::String

    c = _lx_check_nargs(:literate, p, 1)
    isempty(c) || return c
    # -------------------------------------------------------------------------
    # i144 allow \literate{path; project=ppath} and activate the dir
    # at project if it exists.
    # Special cases:
    # - project is not specified, nothing is activated
    # - project doesn't exist, warning shown, nothing is activated
    # - path starts with a './' (or is just a '.'): look relative to where the
    #   literate file is, with '.' assuming it's just next to it
    if occursin(c, ";")
        rpath, cand_ppath = strip.(split(p[1], ';', limit=2))
    else
        rpath = strip(p[1])
        cand_ppath = ""
    end

    # check rpath first
    if !endswith(rpath, ".jl")
        @warn """
            \\literate{...}
            The relative path
                <$rpath>
            does not end with '.jl'.
            """
        return failed_lxc("literate", p)
    end

    # try to form the full path to the literate file and check it's there
    fpath = path(lc.glob, :folder) / rpath
    if !isfile(fpath)
        @warn """
            \\literate{...}
            Couldn't find a literate file at path
                <$fpath>
            (resolved from '$rpath').
            """
        return failed_lxc("literate", p)
    end

    # check ppath
    if !isempty(cand_ppath)
        m = match(r"project\s*=\s*\"?([^\s\"]*)\"?", cand_ppath)
        if isnothing(cand_ppath)
            @warn """
                \\literate{...; ...}
                Couldn't properly parse '$([1])' allowed syntax are either
                \\literate{rpath} or \\literate{rpath; project=ppath}
                """
            return failed_lxc("literate", p)
        end
        ppath = m.captures[1]
        if ppath == "."
            ppath = dirname(fpath)
        elseif startswith(ppath, "./")
            ppath = path(:folder) / ppath[3:end]
        end
        if !isdir(ppath)
            @warn """
                \\literate{...; project=...}
                The path to the project directory '$ppath' couldn't be
                found; leaving the environment unchanged.
                """
        else
            Pkg.activate(ppath)
            Pkg.instantiate()
        end
    end

    return _process_literate_file(lc, string(rpath), fpath)
end


# assumes Literate 2.9+ with the quad-backticks convention.
const LITERATE_FENCER        = "julialit"
const LITERATE_JULIA_FENCE   = "````$LITERATE_FENCER"
const LITERATE_JULIA_FENCE_L = length(LITERATE_JULIA_FENCE)
const LITERATE_JULIA_FENCE_R = Regex(LITERATE_JULIA_FENCE)

const LITERATE_CONFIG = Dict(
    "codefence" => (LITERATE_JULIA_FENCE => "````")
    )


"""
    _process_literate_file(rpath, fpath)

Helper function to process a literate file located at `rpath` (`fpath`).
We pass `fpath` because it's already been resolved.
"""
function _process_literate_file(
             lc::LocalContext,
             rpath::String,
             fpath::String
         )::String
    # check if Literate.jl is loaded, otherwise interrupt
    if !env(:literate)
        if !isdefined(get_utils_module(lc), :Literate)
            @warn """
                \\literate{...}
                It looks like you have not imported Literate in your Utils.
                Add 'using Literate' or 'import Literate' in your utils.jl.
                """
            return failed_lxc("literate", VS([rpath]))
        else
            setenv!(:literate, true)
        end
    end
    L = get_utils_module(lc).Literate

    # check the version, we want a version after 2.9 as that's the one that
    # introduced the 4-backticks fence (as opposed to 3 earlier).
    literate_toml    = (pathof(L) |> dirname  |> dirname) / "Project.toml"
    literate_version = VersionNumber(
        TOML.parsefile(literate_toml)["version"]
    )
    if !(v"2.9" <= literate_version)
        @warn """
            \\literate{...}
            It looks like you're using a version of Literate that's older than
            v2.9. Please update your version of Literate.
            """
        return failed_lxc("literate", VS([rpath]))
    end

    # add the dependency lc.rpath <=> literate rpath
    attach(lc, rpath)

    # Disable the logging
    pre_log_level = Base.CoreLogging._min_enabled_level[]
    Logging.disable_logging(Logging.Warn)

    # output the markdown (this is a reasonably safe operation which
    # shouldn't fail, it's just writing a file with some modifiers.
    ofile = Base.@invokelatest L.markdown(
        fpath, mktempdir();
        flavor      = (Base.@invokelatest L.FranklinFlavor()),
        mdstrings   = getvar(lc, :literate_mdstrings, false),
        config      = LITERATE_CONFIG,
        preprocess  = s -> replace(s, r"#hide\s*?\n" => "# hide\n"),
        postprocess = _postprocess_literate_script,
        credit      = getvar(lc, :literate_credits, false),
    )

    # bring back logging level
    Base.CoreLogging._min_enabled_level[] = pre_log_level

    return html(read(ofile, String), lc)
end


"""
    _postprocess_literate_script(s)

Take a markdown string generated by literate and post-process to mark all code
blocks as auto-executed code blocks.
"""
function _postprocess_literate_script(s::String)::String
    isempty(s) && return s
    return replace(s, LITERATE_JULIA_FENCE_R => "````!")
end
