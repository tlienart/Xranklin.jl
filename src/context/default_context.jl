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
    :autocode            => true,
    :automath            => true,
    :autosavefigs        => true,
    :autoshowfigs        => true,
    :layout_head         => "_layout/head.html",
    :layout_page_foot    => "_layout/page_foot.html",
    :layout_foot         => "_layout/foot.html",
    :layout_head_lx      => "_layout/latex/head.tex",
    # File management
    :ignore_base      => StringOrRegex[
                               ".DS_Store", ".gitignore", "node_modules/",
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
    :_anchors => LittleDict{String, String}(),
)
const DefaultGlobalVarsAlias = Alias(
    :prepath                => :base_url_prefix,
    :prefix                 => :base_url_prefix,
    :base_path              => :rss_website_url,
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
    :hasmath            => false,
    :hascode            => false,
    :date               => Dates.Date(1),
    :lang               => "julia",
    :reflinks           => true,
    :tags               => String[],
    :prerender          => true,
    :slug               => "",
    # toc
    :mintoclevel        => 1,
    :maxtoclevel        => 10,
    # code
    :reeval             => false,
    :showall            => false,
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
    # meta
    :_relative_path     => "",
    :_relative_url      => "",
    :_creation_time     => 0.0,
    :_modification_time => 0.0,
    # mddefs related
    :_setvar            => Set{Symbol}(),
    # references (note: headers are part of context, see ctx.headers)
    :_eqrefs            => LittleDict{String, Int}("__cntr__" => 0),
    :_bibrefs           => LittleDict{String, String}(),
)
const DefaultLocalVarsAlias = Alias(
    :fd_rpath     => :_relative_path,
    :fd_url       => :_relative_url,
    :fd_ctime     => :_creation_time,
    :fd_mtime     => :_modification_time,
)

##############################################################################

DefaultGlobalContext() = GlobalContext(
    deepcopy(DefaultGlobalVars),
    LxDefs(),
    alias=copy(DefaultGlobalVarsAlias)
) |> set_current_global_context

function DefaultLocalContext(
            gc::GlobalContext=DefaultGlobalContext();
            rpath::String=""
            )
    LocalContext(
        gc,
        deepcopy(DefaultLocalVars),
        LxDefs(),
        alias=copy(DefaultLocalVarsAlias),
        rpath=rpath
    ) |> set_current_local_context
end

# for html pages
SimpleLocalContext(gc::GlobalContext; rpath::String="") =
    LocalContext(gc; rpath)


##############################################################################
# These will fail for contexts that haven't been constructed out of Default

anchors(c=cur_gc()) = gegvar(c, :_anchors, LittleDict{String, String}())
eqrefs(c=cur_lc())  = getvar(c, :_eqrefs,  LittleDict{String, Int}())
bibrefs(c=cur_lc()) = getvar(c, :_bibrefs, LittleDict{String, String}())

relative_url_curpage() = getlvar(:_relative_url, "")
