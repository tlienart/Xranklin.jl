struct AAA
    x::Int
end

html_show(x::AAA) = "AAA: $(x.x)"

struct BBB
    x::Int
end

html_show(x::BBB) = "BBB: $(x.x)"

struct CCC
    x::Int
end

html_show(x::CCC) = "CCC: $(x.x)"

struct DDD
    x::Int
end

html_show(x::DDD) = "DDD: $(x.x)"
