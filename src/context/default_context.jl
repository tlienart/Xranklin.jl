#=
heading_link    -- make headers into links
keep_path      -- don't insert `index.html` at the end of the path for these files
                  e.g. ["foo/bar.md", "foo/bar.html", "foo/"]
layout         -- head * (<tag>content * pg_foot<tag>) * foot
=#
const DefaultGlobalVars = Vars(
    # General
    :author          => "The Author",
    :base_url_prefix => "",
    :website_url     => "",     # necessary for generate_{rss,sitemap}
    :config_path     => "",
    # Layout
    :content_tag         => "div",
    :content_class       => "franklin-content",
    :content_id          => "",
    :autosavefigs        => true,
    :skiplatex           => true,
    :autoshowfigs        => true,
    # each of those path(:layout)/
    :layout_skeleton     => "skeleton.html",
    :layout_head         => "head.html",
    :layout_foot         => "foot.html",
    :layout_page_foot    => "page_foot.html",
    :layout_tag          => "tag.html",
    :layout_head_lx      => "latex" / "head.tex",
    :parse_script_blocks => true,  # see html2; possibly disable DBB in <script>
    # Date format
    :date_format      => "U d, yyyy",
    :date_days        => String[],
    :date_shortdays   => String[],
    :date_months      => String[],
    :date_shortmonths => String[],
    # File management
    :ignore_base      => StringOrRegex[
                           r"(?:.*?)\.DS_Store$", ".gitignore", "node_modules/",
                           "LICENSE.md", "README.md"
                         ],
    :ignore           => StringOrRegex[],
    :keep_path        => String[],
    # Robots/sitemap
    :robots_disallow  => String[],
    :generate_robots  => false,
    :robots_file      => "robots",
    :generate_sitemap => false,
    :sitemap_file     => "sitemap",
    :_sitemap_url     => "",
    # Headings
    :heading_class      => "",
    :heading_link       => true,
    :heading_link_class => "",
    :heading_post       => "",
    # General classes
    :toc_class         => "toc",
    :anchor_class      => "anchor",
    :anchor_math_class => "anchor-math",
    :anchor_bib_class  => "anchor-bib",
    :eqref_class       => "eqref",
    :bibref_class      => "bibref",
    :table_class        => "",
    # Dates
    :date_format      => "U dd, yyyy",
    :date_days        => String[],
    :date_shortdays   => String[],
    :date_months      => String[],
    :date_shortmonths => String[],
    # RSS
    :generate_rss        => false,
    :rss_website_title   => "",
    :rss_website_descr   => "",
    :rss_full_content    => false,
    :rss_file            => "feed",
    :rss_layout_head     => "head.xml", # path(:rss)/...
    :rss_layout_item     => "item.xml", # path(:rss)/...
    :rss_layout_head_tag => "head.xml", # path(:rss)/...
    :rss_layout_item_tag => "item.xml", # ...
    :rss_feed_url       => "",         # generated
    # Tags
    :tags_prefix => "tags",
    # Literate
    :literate_mdstrings => false,
    :literate_credits   => false,
    # Misc
    :tabs_to_spaces => 2,   # \t -> ' ' conversion (see convert_list)
    # Paths related
    :_offset_lxdefs => -typemax(Int),
    :_paths         => Dict{Symbol, String}(),
    :_idx_rpath     => 1,
    :_idx_ropath    => 1,
    # Utils related
    :_utils_code         => "",
    :_utils_hfun_names   => Symbol[],
    :_utils_lxfun_names  => Symbol[],
    :_utils_envfun_names => Symbol[],
    :_utils_var_names    => Symbol[],
    # Hyperrefs
    :_refrefs => LittleDict{String, String}(),  # id => location (ordering may matter!)
    :_bibrefs => LittleDict{String, String}(),  # id => location (ordering may matter!)
    # Is it the final build (prepath application)
    :_final => false,
)
const DefaultGlobalVarsAlias = Alias(
    :prepath                 => :base_url_prefix,
    :prefix                  => :base_url_prefix,
    :base_path               => :base_url_prefix,
    :website_title           => :rss_website_title,
    :website_description     => :rss_website_descr,
    :website_descr           => :rss_website_descr,
    :rss_website_description => :rss_website_descr,
)

#=
autofig: automatically save figures that can be saved
prerender: specific switch, there can be a global optimise but a page skipping it
slug: allow specific target url
=#
const DefaultLocalVars = Vars(
    # General
    :title        => "",
    :date         => Date(1),
    :lang         => "julia",
    :tags         => String[],
    :slug         => "",
    :redirect     => "",
    :ignore_cache => false,
    :project      => "",
    # toc
    :mintoclevel => 1,
    :maxtoclevel => 6,
    # code
    :showall => true,
    # footnotes
    :fn_title => "Notes",
    # rss
    :rss_descr     => "",
    :rss_title     => "",
    :rss_author    => "",
    :rss_category  => "",
    :rss_comments  => "",
    :rss_enclosure => "",
    :rss_pubdate   => Date(1),
    # sitemap
    :sitemap_changefreq => "monthly",
    :sitemap_priority   => 0.5,
    :sitemap_exclude    => false,
    # robots
    :robots_disallow_page => false,
    # latex config
    :latex_img_opts => "width=0.5\\textwidth",
    #
    # INTERNAL VARIABLES
    #
    :_hasmath => false,
    :_hascode => false,
    # meta
    :_output_path       => "",
    :_relative_path     => "",
    :_relative_url      => "",
    :_creation_time     => 0.0,
    :_modification_time => 0.0,
    # mddefs related
    :_setvar => Set{Symbol}(),
    # set of anchor ids defined on the page (used to check removals)
    :_anchors => Set{String}(),
    # references (note: headings are part of context, see ctx.headings)
    :_refrefs => LittleDict{String, String}(),
    :_fnrefs  => LittleDict{String, Int}("__cntr__" => 0),
    :_eqrefs  => LittleDict{String, Int}("__cntr__" => 0),
    :_bibrefs => LittleDict{String, String}(),
    # cell counter
    :_auto_cell_counter => 0,
    # pagination
    :_paginator_name => "",
    :_paginator_npp  => 10,
    # Check if a base url prefix was applied
    :_applied_base_url_prefix => "",
    # Generated HTML (when skipping, allows to recover previously generated)
    :_generated_ihtml  => "",
    :_generated_ihtml2 => "",
    :_generated_html   => "",
    :_rm_anchors       => Set{String}(),
    :_rm_tags          => Set{String}(),
    :_add_tags         => Vector{Pair{String}}(),
    :_generated_latex  => "",
    #
    :_has_parser_error  => false,   # page is not rendered
    :_has_failed_blocks => false,   # page may be rendered but with stuff to fix
)
const DefaultLocalVarsAlias = Alias(
    :fd_rpath        => :_relative_path,
    :fd_url          => :_relative_url,
    :fd_ctime        => :_creation_time,
    :fd_mtime        => :_modification_time,
    :reeval          => :ignore_cache,
    :force_eval_all  => :ignore_cache,
    :hasmath         => :_hasmath,
    :hascode         => :_hascode,
    :rss_description => :rss_descr,
    :_generated_body => :_generated_html
)

##############################################################################

function DefaultGlobalContext()
    gc = GlobalContext(
        deepcopy(DefaultGlobalVars),
        LxDefs(),
        alias=copy(DefaultGlobalVarsAlias)
    )
    setvar!(gc, :project, Pkg.project().path)
    return gc
end

function DefaultLocalContext(gc::GlobalContext; rpath::String="")
    LocalContext(
        gc,
        deepcopy(DefaultLocalVars),
        LxDefs();
        alias=copy(DefaultLocalVarsAlias),
        rpath
    )
end
DefaultLocalContext(; kw...) =
    DefaultLocalContext(env(:cur_global_ctx); kw...)
DefaultLocalContext(::Nothing; kw...) =
    DefaultLocalContext(DefaultGlobalContext(); kw...)

# for tag pages
function TagLocalContext(
        gc::GlobalContext;
        rpath::String=""
    )
    LocalContext(gc; rpath, keep_current_lc=true)
end

# Detached context for simple eval str
ToyLocalContext(rpath="_toy_") = LocalContext(GlobalContext(); rpath)


##############################################################################
# These will fail for contexts that haven't been constructed out of Default
# NOTE: anchors is GC so that anchors can be used across pages.
# NOTE: we don't use getvar here because we want the actual object (pointer) for
# in place operations, we don't want a copy! and they're guaranteed to exist if
# LocalContext comes from DefaultLocalContext.

eqrefs(c::LocalContext)  = c.vars[:_eqrefs]::LittleDict{String, Int}
bibrefs(c::LocalContext) = c.vars[:_bibrefs]::LittleDict{String, String}
fnrefs(c::LocalContext)  = c.vars[:_fnrefs]::LittleDict{String, Int}
refrefs(c::Context)      = c.vars[:_refrefs]::LittleDict{String,String}
