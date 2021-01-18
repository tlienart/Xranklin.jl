function html(parts::Vector{Block}, ctx::Context=EmptyContext)::String
    io = IOBuffer()
    for part in parts
        write(io, html(part, ctx))
    end
    return String(take!(io))
end

html(md::String, a...) = html(default_md_partition(md), a...)
