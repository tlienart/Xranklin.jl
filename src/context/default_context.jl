#=
header_link    -- make headers into links
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
    :autoshowfigs        => true,
    :layout_head         => "_layout/head.html",
    :layout_foot         => "_layout/foot.html",
    :layout_page_foot    => "_layout/page_foot.html",
    :layout_head_lx      => "_layout/latex/head.tex",
    :parse_script_blocks => true,  # see html2; possibly disable DBB in <script>
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
    # Headers
    :header_class      => "",
    :header_link       => true,
    :header_link_class => "",
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
    # Tags
    :tag_page_path => "tag",
    # Misc
    :tabs_to_spaces => 2,   # \t -> ' ' conversion (see convert_list)
    # Paths related
    :_offset_lxdefs => -typemax(Int),
    :_paths         => LittleDict{Symbol, String}(),
    :_idx_rpath     => 1,
    :_idx_ropath    => 1,
    # Utils related
    :_utils_hfun_names   => Symbol[],
    :_utils_lxfun_names  => Symbol[],
    :_utils_envfun_names => Symbol[],
    :_utils_var_names    => Symbol[],
    # Hyperrefs
    :_refrefs => LittleDict{String, String}(),  # id => location
    :_bibrefs => LittleDict{String, String}(),  # id => location
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
    :title              => nothing,
    :date               => Dates.Date(1),
    :lang               => "julia",
    :tags               => String[],
    :prerender          => true,
    :slug               => "",
    :ignore_cache       => false,
    # toc
    :mintoclevel        => 1,
    :maxtoclevel        => 6,
    # code
    :reeval             => false,
    :showall            => true,
    # rss
    :rss_descr          => "",
    :rss_title          => "",
    :rss_author         => "",
    :rss_category       => "",
    :rss_comments       => "",
    :rss_enclosure      => "",
    :rss_pubdate        => Dates.Date(1),
    # sitemap
    :sitemap_changefreq => "monthly",
    :sitemap_priority   => 0.5,
    :sitemap_exclude    => false,
    # robots
    :robots_disallow    => false,
    # latex config
    :latex_img_opts     => "width=0.5\\textwidth",
    # footnotes
    :fn_title           => "Notes",
    #
    :_hasmath           => false,
    :_hascode           => false,
    # meta
    :_relative_path     => "",
    :_relative_url      => "",
    :_creation_time     => 0.0,
    :_modification_time => 0.0,
    # mddefs related
    :_setvar            => Set{Symbol}(),
    # set of anchor ids defined on the page (used to check removals)
    :_anchors           => Set{String}(),
    # references (note: headers are part of context, see ctx.headers)
    :_refrefs           => LittleDict{String, String}(),
    :_eqrefs            => LittleDict{String, Int}("__cntr__" => 0),
    :_bibrefs           => LittleDict{String, String}(),
    # cell counter
    :_auto_cell_counter => 0
)
const DefaultLocalVarsAlias = Alias(
    :fd_rpath     => :_relative_path,
    :fd_url       => :_relative_url,
    :fd_ctime     => :_creation_time,
    :fd_mtime     => :_modification_time,
    :reeval       => :ignore_cache,
    :hasmath      => :_hasmath,
    :hascode      => :_hascode,
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
    lc = LocalContext(
            gc,
            deepcopy(DefaultLocalVars),
            LxDefs(),
            alias=copy(DefaultLocalVarsAlias),
            rpath=rpath
         )
    return set_current_local_context(lc)
end

DefaultLocalContext(; kw...) = DefaultLocalContext(DefaultGlobalContext(); kw...)

# for html pages
SimpleLocalContext(gc::GlobalContext; rpath::String="") =
    LocalContext(gc; rpath)

##############################################################################
# These will fail for contexts that haven't been constructed out of Default
# NOTE: anchors is GC so that anchors can be used across pages.

eqrefs(c::LocalContext)   = getvar(c, :_eqrefs,  LittleDict{String, Int}())
bibrefs(c::LocalContext)  = getvar(c, :_bibrefs, LittleDict{String, String}())

eqrefs()  = eqrefs(cur_lc())
bibrefs() = bibrefs(cur_lc())

refrefs(c::Context) = c.vars[:_refrefs]::LittleDict{String, String}
refrefs()           = merge(refrefs(cur_gc()), refrefs(cur_lc()))

relative_url_curpage() = getlvar(:_relative_url, "")
