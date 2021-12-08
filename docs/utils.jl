function hfun_rm_headers(ps::Vector{String})
    c = Xranklin.cur_lc()
    for h in ps
        if h in keys(c.headers)
            delete!(c.headers, h)
        end
    end
    return
end
