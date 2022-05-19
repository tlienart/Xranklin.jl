"""
    \\par{paragraph}

Force the content of the command to be treated as a paragraph.
"""
function lx_par(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:par, p, 1)
    isempty(c) || return c
    # -----------------------------
    tohtml && return rhtml(p[1], lc; nop=false)
    return rlatex(p[1], lc; nop=false)
end

"""
    \\nonumber{display_equation}

Suppress the numbering of that equation.
"""
function lx_nonumber(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:nonumber, p, 1)
    isempty(c) || return c
    # ----------------------------------
    tohtml || return p[1]
    eqrefs(lc)["__cntr__"] -= 1
    return "<div class=\"nonumber\">" *
            rhtml(p[1], lc; nop=true) *
           "</div>"
end

"""
    \\activate{path}

For a unix relative path (relative to the website folder) that has a project
file in it, activate it.

If path is empty or a `.`, activate the directory containing the current page.
"""
function lx_activate(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:activate, p, 1)
    isempty(c) || return c

    # assume the given path is given in unix style
    # split it according to "/", reform it adjoined
    # to path(:site) and if it's a valid directory
    # with a Project.toml file, load it.
    given_path = strip(p[1])

    if isempty(given_path) || given_path == "."
        full_path = path(lc.glob, :folder) / lc.rpath
        cand_dir  = dirname(full_path)
    else
        cand_dir  = joinpath(
            path(lc.glob, :folder),
            split(given_path, "/", keepempty=false)...
        )
    end

    # check if cand_dir has a Project.toml
    if isfile(cand_dir / "Project.toml")
        Pkg.activate(cand_dir)
        Pkg.instantiate()
    else
        @warn """
            \\activate{...}
            Attempted to activate '$given_path' but failed to find a project
            file in the given dir (either the dir doesn't exist or doesn't
            contain a Project.toml file).
            """
    end

    return ""
end
