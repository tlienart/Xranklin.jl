#
# very coarse timings logger to allow digging into what is most expensive.
# will probably either be completely removed or replaced by a stand-alone module
#

const TIMER  = Vector{NamedTuple{(:depth,:label,:duration), Tuple{Int64,String,Float64}}}()
const TIMERN = Ref(0)

reset_timer() = (empty!(TIMER); TIMERN[] = 0;)

save_timer() = begin
    if isfile(path(:cache) / "timer")
        open(path(:cache) / "timer", "w") do outf
            serialize(outf, TIMER)
        end
    end
end

nest()  = (TIMERN[] += 1;)
dnest() = (TIMERN[] -= 1;)

if env(:log_times)
    tic() = begin
        nest()
        return time()
    end
    toc(t0, label) = begin
        depth     = dnest()
        duration  = time() - t0
        push!(TIMER, (; depth, label, duration))
        return
    end
else
    tic()     = nothing
    toc(a...) = nothing
end

function topk(timer, a=1, b=length(timer), depth=0, k=3)
    durations = Vector{Tuple{Int64, Float64, String}}()
    for i in a:b
        if timer[i].depth == depth
            push!(durations, (i, timer[i].duration, timer[i].label))
        end
    end
    sort!(durations, by = t -> t[2], rev=true)
    return durations[1:min(k, length(durations))]
end

function inspect(timer, i, k=3)
    # backtrack to find the last index j < i such that depth is just one above
    ini_depth = timer[i].depth
    j = i-1
    rge = []
    top = []
    while j >= 1
        if timer[j].depth == ini_depth
            rge = j+1:i-1
            top = topk(timer, j+1, i-1, ini_depth+1, k)
            break
        end
        j -= 1
    end
    if isnothing(top)
        throw(ErrorException("Should not happen"))
    end
    total = timer[i].duration
    if isempty(top)
        println("Node")
    else
        frac = sum(timer[t[1]].duration for t in top) / total
        gen  = (t.duration for t in timer[rge])
        n    = length(rge)
        avg  = sum(gen) / n
        mn, mx = extrema(gen)
        println("Accounted for: $(round(frac * 100, sigdigits=3))%")
        if frac < 0.5
            println("Avg (n=$n): $(round(avg, sigdigits=3))s")
            println("Ext (n=$n): ($(round(mn, sigdigits=3))s, $(round(mx, sigdigits=3))s)")
        end
    end
    return top
end

function quick(timer, maxdepth=4)
    top = topk(timer)
    ins = inspect(timer, top[1][1])
    for _ in 1:maxdepth-1
        ins = inspect(timer, ins[1][1])
    end
    return ins
end
