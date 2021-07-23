#=
title_links    -- make headers into links
keep_path      -- don't insert `index.html` at the end of the path for these files
                  e.g. ["foo/bar.md", "foo/bar.html", "foo/"]
layout         -- head * (<tag>content * pg_foot<tag>) * foot
=#
const DefaultGlobalVars = Vars(
    # General
    :author             => "The Author",
    :base_url_prefix    => "",
    # Layout
    :title_links        => true,
    :content_tag        => "div",
    :content_class      => "franklin-content",
    :content_id         => "",
    :autocode           => true,
    :automath           => true,
    :layout_head        => "_layout/head.html",
    :layout_page_foot   => "_layout/page_foot.html",
    :layout_foot        => "_layout/foot.html",
    # File management
    :ignore_base        => StringOrRegex[
                               ".DS_Store", ".gitignore", "node_modules/",
                               "LICENSE.md", "README.md"
                               ],
    :ignore             => StringOrRegex[],
    :keep_path          => String[],
    :robots_disallow    => String[],
    :generate_robots    => true,
    :generate_sitemap   => true,
    # Dates
    :date_format        => "U dd, yyyy",
    :date_days          => String[],
    :date_shortdays     => String[],
    :date_months        => String[],
    :date_shortmonths   => String[],
    # RSS
    :generate_rss       => false,
    :rss_website_title  => "",
    :rss_website_url    => "",
    :rss_feed_url       => "",      # generated
    :rss_website_descr  => "",
    :rss_file           => "feed",
    :rss_full_content   => false,
    # Tags
    :tag_page_path      => "tag",
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
    # header
    :header_class       => "",
    :header_link        => true,
    :header_link_class  => "",
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
)
const DefaultLocalVarsAlias = Alias(
    :fd_rpath     => :_relative_path,
    :fd_url       => :_relative_url,
    :fd_ctime     => :_creation_time,
    :fd_mtime     => :_modification_time,
)


const DefaultGlobalLxDefs = LxDefs(
)

const DefaultLocalLxDefs = LxDefs()


##############################################################################

DefaultGlobalContext() = GlobalContext(
    copy(DefaultGlobalVars),
    copy(DefaultGlobalLxDefs),
    alias=copy(DefaultGlobalVarsAlias)
) |> set_current_global_context

DefaultLocalContext(g=DefaultGlobalContext(); id="") = LocalContext(
    g,
    copy(DefaultLocalVars),
    copy(DefaultLocalLxDefs),
    alias=copy(DefaultLocalVarsAlias),
    id=id
) |> set_current_local_context
