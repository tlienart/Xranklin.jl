import Literate
import HTTP
import Downloads: download

const PKG = "Xranklin.jl"
const RAW = "https://raw.githubusercontent.com/tlienart/$PKG"

const PLIBS = Dict{String,String}(
    "cairomakie"   => "CairoMakie",   # dec 28'22
    "gadfly"       => "Gadfly",       # dec 28'22
    "gaston"       => "Gaston",       # dec 28'22
    # "gleplots"     => "GLEPlots",   # todo
    "pgfplots"     => "PGFPlots",     # dec 28'22
    "pgfplotsx"    => "PGFPlotsX",    # dec 28'22
    "plots"        => "Plots",        # dec 28'22
    "pyplot"       => "PyPlot",       # dec 28'22
    "unicodeplots" => "UnicodePlots", # dec 28'22
    "wglmakie"     => "WGLMakie"      # dec 28'22
)

# used in syntax/vars+funs #e-strings demonstrating that e-strings are
# evaluated in the Utils module
bar(x) = "hello from foo <$x>"

struct Foo
    x::Int
end
html_show(f::Foo) = "<strong>Foo: $(f.x)</strong>"

struct Baz
    z::Int
end
newbaz(z) = Baz(z)



# ####################################
# # TTFX
# ####################################

function hfun_plotlib(p)
    lib = first(p)
    bgh = "$RAW/gh-plots/$lib"
    req = try
        download(
            "$bgh/index.html",
            IOBuffer(),
            timeout=1
        ) |> take! |> String
    catch
        "Failed to retrieve results for plotting lib: '$(uppercasefirst(lib))'."
    end

    return """
        <div class="plotlib plotlib-$lib">$(
        replace(req,
            r"src=\".*?\/figs-html\/(.*)\.svg\"" =>
            SubstitutionString("src=\"$bgh/assets/$lib/figs-html/\\1.svg\"")
            )
        )</div>
        """
end

# function hfun_ttfx(p)
#     p  = first(p)
#     r  = ""
#     r2 = ""

#     # XXX PERF XXX
#     return ""

#     try
#         r = HTTP.request(
#             "GET",
#             "https://raw.githubusercontent.com/tlienart/Xranklin.jl/gh-ttfx/ttfx/$(p)/timer"
#         )
#         r2 = HTTP.request(
#             "GET",
#             "https://raw.githubusercontent.com/tlienart/Xranklin.jl/gh-ttfx/ttfx/$(p)/timer2"
#         )
#     catch e
#         return ""
#     end
#     t  = first(reinterpret(Float64, r.body))
#     t2 = first(reinterpret(Float64, r2.body))
#     return "$(t)min / $(t2)s"
# end


####################################
# UnicodePlots
####################################

# function html_show(p::UnicodePlots.Plot)
#     td = tempdir()
#     tf = tempname(td)
#     io = IOBuffer()
#     UnicodePlots.savefig(p, tf; color=true)
#     # assume ansi2html is available
#     if success(pipeline(`cat $tf`, `ansi2html -i -l`, io))
#         return "<pre>" * String(take!(io)) * "</pre>"
#     end
#     return ""
# end


####################################
# Utils examples lxfun/envfun/hfun
####################################
function lx_exlx(p::Vector{String})
    # {hello}{foo}
    return "<i>$(uppercase(p[1]))</i> <b>$(uppercasefirst(p[2]))</b>"
end
function lx_exlx2()
    return "<s>hello</s>"
end
function lx_exlx3()
    return "<span style='color:blue'>{{a_global_variable}}</span>"
end

# function env_exenv(p::Vector{String})
#
# end


# =============================================================================
# =============================================================================
# =============================================================================

#########
# Layout
#########

"""
    {{generate_menu}}

Generates the left-menu as a depth-1 list based off the global var `menu` which
is structured as:

    {
        ("top_path" => "Top Name") => [
            "sub_path" => "Sub Name",
            "sub_path" => "Sub Name"
            ...
        ],
        ...
    }
"""
function hfun_generate_menu()
    menu = getgvar(:menu)
    io = IOBuffer()
    write(io, """
         <ul class="pure-menu-list">
         """)
    for m in menu
         # (top-url => top-name) => [ (sub-url => sub-name) ]
         base = m.first.first    # top path
         name = m.first.second   # top title text
         write(io, """
             <li class="pure-menu-item">
             """)        
         write(io, """
             <a href="/$base/$(first(m.second).first)/" class="pure-menu-link">
                 $name
             </a>
             <ul class="pure-menu-list">
             """)
         for e in m.second
            # Going over submenus            
            write(io, """
                <li class="pure-menu-item">
                    <a href="/$base/$(e.first)/" class="pure-menu-link {{ispage /$base/$(e.first)/}}selected{{end}}">
                        $(e.second)
                    </a>
                </li>
                """)
         end
         write(io, """
             </ul>
             </li>
             """)
    end
    write(io, """
         </ul>
         """)
     return html2(String(take!(io)), cur_lc())
 end

 ###############
# Actual Utils
###############

"""
{{rm_headings ...}}

Remove headings from page TOC. Useful for a page demonstrating headings which
ends up adding a lot of dummy headings to the toc.
"""
function hfun_rm_headings(ps::Vector{String})
    c = cur_lc()
    c === nothing && return ""
    for h in ps
        if h in keys(c.headings)
            delete!(c.headings, h)
        end
    end
    return ""
end

function hfun_add_plot_headings()
    c = cur_lc()
    c === nothing && return ""
    for h in keys(PLIBS)
        if h ∉ keys(c.headings)
            c.headings[h] = (1, 3, PLIBS[h])
        end
    end
    return ""
end