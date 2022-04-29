"""
    _env_dmath(...)

Helper function to abstract the different math environments.
"""
function _env_dmath(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true,
            pre::String="",
            post::String="",
            nonumber=false
        )

    dd  = "\n" * raw"$$" * "\n"
    tmp = dd * pre * p[1] * post * dd
    tmp = ifelse(nonumber,
        "\\nonumber{" * tmp * "}",
        tmp
    )
    tohtml && return rhtml(tmp, lc; nop=false)
    return rlatex(tmp, lc; nop=false)
end


"""
    \\begin{equation} ... \\end{equation}

Equation environment (equivalent to `\$\$...\$\$`)
"""
function env_equation(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true,
            nonumber::Bool=false
        )::String

    c = _env_check_nargs(:equation, p, 0)
    isempty(c) || return c
    return _env_dmath(lc, p; tohtml, nonumber)
end
env_equation_star(lc, p; kw...) = env_equation(lc, p; nonumber=true, kw...)


"""
    \\begin{aligned} ... \end{aligned}

Aligned equation environment. Same as `\\begin{align}`.
"""
function env_aligned(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true,
            nonumber::Bool=false
        )::String

    c = _env_check_nargs(:equation, p, 0)
    isempty(c) || return c
    return _env_dmath(lc, p; tohtml, nonumber,
                      pre="\\begin{aligned}", post="\\end{aligned}")
end
env_aligned_star(lc, p; kw...) = env_aligned(lc, p; nonumber=true, kw...)

env_align      = env_aligned
env_align_star = env_aligned_star


"""
    \\begin{eqnarray} ... \end{eqnarray}

Equation array environment.
"""
function env_eqnarray(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true,
            nonumber::Bool=false
        )::String

    c = _env_check_nargs(:equation, p, 0)
    isempty(c) || return c
    return _env_dmath(lc, p; tohtml, nonumber,
                      pre="\\begin{array}{rcl}", post="\\end{array}")
end
env_eqnarray_star(lc, p; kw...) = env_eqnarray(lc, p; nonumber=true, kw...)
