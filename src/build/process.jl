function process_config(gc::GlobalContext)
    config_path = path(:folder) / "config.md"
    if isfile(config_path)
        html(read(config_path, String), gc)
    else
        @warn "No config.md file found."
    end
    if value(gc, :generate_rss, false)
        # :website_url must be given
        url = value(gc, :rss_website_url, "")
        if isempty(url)
            @warn """
                When `generate_rss=true`, `rss_website_url` must be given.
                Setting `generate_rss=false` in the meantime.
                """
            setvar!(gc, :generate_rss, false)
        else
            endswith(url, '/') || (url *= '/')
            full_url =  url * value(gc, :rss_file, "feed") * ".xml"
            setvar!(gc, :rss_feed_url, full_url)
        end
    end
    return
end
