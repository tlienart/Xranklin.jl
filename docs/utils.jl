function hfun_rm_headers(ps::Vector{String})
    c = Xranklin.cur_lc()
    for h in ps
        if h in keys(c.headers)
            delete!(c.headers, h)
        end
    end
    return
end

# used in syntax/vars+funs #e-strings demonstrating that e-strings are
# evaluated in the Utils module
bar(x) = "hello from foo <$x>"
