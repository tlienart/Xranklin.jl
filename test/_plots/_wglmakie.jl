using WGLMakie, JSServe
WGLMakie.activate!()

<|(io, o) = show(io, MIME("text/html"), o)

io = IOBuffer()
io <| Page(exportable=true, offline=true)
io <| scatter(1:4)
io <| surface(rand(4,4))
io <| Slider(1:3)

String(take!(io))