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
    # Layout
    :content_tag         => "div",
    :content_class       => "franklin-content",
    :content_id          => "",
    :autosavefigs        => true,
    :skiplatex           => false,
    :autoshowfigs        => true,
    :layout_skeleton     => "_layout" / "skeleton.html",
    :layout_head         => "_layout" / "head.html",
    :layout_foot         => "_layout" / "foot.html",
    :layout_page_foot    => "_layout" / "page_foot.html",
    :layout_tag          => "_layout" / "tag.html",
    :layout_head_lx      => "_layout" / "latex/head.tex",
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
    :robots_disallow  => String[],
    :generate_robots  => true,
    :generate_sitemap => true,
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
    :generate_rss      => false,
    :rss_website_title => "",
    :rss_website_url   => "",
    :rss_feed_url      => "",      # generated
    :rss_website_descr => "",
    :rss_file          => "feed",
    :rss_full_content  => false,
    :rss_layout_head   => "_rss" / "head.xml",
    :rss_layout_item   => "_rss" / "item.xml",
    # Tags
    :tags_prefix       => "tags",
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
    :_utils_hfun_names   => Symbol[],
    :_utils_lxfun_names  => Symbol[],
    :_utils_envfun_names => Symbol[],
    :_utils_var_names    => Symbol[],
    # Hyperrefs
    :_refrefs => Dict{String, String}(),  # id => location
    :_bibrefs => Dict{String, String}(),  # id => location
    # Is it the final build (prepath application)
    :_final => false,
)
const DefaultGlobalVarsAlias = Alias(
    :prepath                => :base_url_prefix,
    :prefix                 => :base_url_prefix,
    :base_path              => :base_url_prefix,
    :website_url            => :rss_website_url,
    :website_title          => :rss_website_title,
    :website_description    => :rss_website_descr,
    :website_descr          => :rss_website_descr
)

#=
autofig: automatically save figures that can be saved
prerender: specific switch, there can be a global optimise but a page skipping it
slug: allow specific target url
robots_disallow: disallow the current page
=#
const DefaultLocalVars = Vars(
    # General
    :title        => nothing,
    :date         => Date(1),
    :lang         => "julia",
    :tags         => String[],
    :slug         => "",
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
    :robots_disallow => false,
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
    :_refrefs => Dict{String, String}(),
    :_fnrefs  => Dict{String, Int}("__cntr__" => 0),
    :_eqrefs  => Dict{String, Int}("__cntr__" => 0),
    :_bibrefs => Dict{String, String}(),
    # cell counter
    :_auto_cell_counter => 0,
    # pagination
    :_paginator_name => "",
    :_paginator_npp  => 10,
    # Check if a base url prefix was applied
    :_applied_base_url_prefix => "",
    # Generated HTML (when skipping, allows to recover previously generated)
    :_generated_ihtml  => "",
    :_generated_body   => "",
    :_rm_anchors       => Set{String}(),
    :_rm_tags          => Set{String}(),
    :_add_tags         => Vector{Pair{String}}(),
    :_generated_html   => "",
    :_generated_latex  => "",
)
const DefaultLocalVarsAlias = Alias(
    :fd_rpath        => :_relative_path,
    :fd_url          => :_relative_url,
    :fd_ctime        => :_creation_time,
    :fd_mtime        => :_modification_time,
    :reeval          => :ignore_cache,
    :hasmath         => :_hasmath,
    :hascode         => :_hascode,
    :rss_description => :rss_descr
)

##############################################################################

function DefaultGlobalContext()
    gc = GlobalContext(
            deepcopy(DefaultGlobalVars),
            LxDefs(),
            alias=copy(DefaultGlobalVarsAlias)
         )
    set_current_global_context(gc)
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

DefaultLocalContext(; kw...) = DefaultLocalContext(DefaultGlobalContext(); kw...)

# for html pages
SimpleLocalContext(gc::GlobalContext; rpath::String="") =
    LocalContext(gc; rpath)


##############################################################################
# These will fail for contexts that haven't been constructed out of Default
# NOTE: anchors is GC so that anchors can be used across pages.
# NOTE: we don't use getvar here because we want the actual object (pointer) for
# in place operations, we don't want a copy! and they're guaranteed to exist if
# LocalContext comes from DefaultLocalContext.

eqrefs(c::LocalContext)  = c.vars[:_eqrefs]::Dict{String, Int}
bibrefs(c::LocalContext) = c.vars[:_bibrefs]::Dict{String, String}
fnrefs(c::LocalContext)  = c.vars[:_fnrefs]::Dict{String, Int}
refrefs(c::Context)      = c.vars[:_refrefs]::Dict{String,String}
