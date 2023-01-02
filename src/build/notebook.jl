const NB_HEAD = """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1.0">
      <style>
      $(read(
          dirname(FRANKLIN_ENV[:module_path]) / "other" / "water.css",
          String
        ))
      </style>
    </head>
    <body>
    """
const NB_FOOT = """
    </body>
    </html>
    """

"""
    notebook(rpath)

Serves a single markdown page at a given path with a barebone layout.
Any layout, css or javascript files are ignored unless explicitly included. 
This can help do quick iterative work on a single page without distraction.
It is effectively a stripped down version of `serve`.

## Args

    * rpath: path to the file taken relative to the current working directory.

If a project file, config file or utils file are present in the current directory, these will be activated as well.

## Example

    nb("post/post1.md")
"""
function notebook(
            rpath::String="index.md";
            #
            launch::Bool=true
        )::Nothing

    if !isfile(rpath)
        @error "No file found at $rpath."
    end

    old_project = Pkg.project().path
    if isfile("Project.toml")
        Pkg.activate(".")
        Pkg.instantiate()
    end

    gc = DefaultGlobalContext()
    isfile("config.md") && process_config(gc)
    isfile("utils.jl")  && process_utils(gc)

    lc = DefaultLocalContext(gc; rpath="__local_nb__")
    md = read(rpath, String)

    res = NB_HEAD * html(md, lc) * NB_FOOT

    tdir = tempdir()
    outf = joinpath(tdir, "index.html")
    write(outf, res)

    LiveServer.serve(
        dir=tdir,
        launch_browser=launch
    )
    println("")

    if Pkg.project().path != old_project
        Pkg.activate(old_project)
    end
    return
end
