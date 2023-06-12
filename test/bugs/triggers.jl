include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "config trigger" begin
	# testing trigger with config is a bit annoying
	# because we'd need to simulate a full pass.

	d, gc = testdir(; tag=false)

	r0 = "config.md"
	r1 = "pg1.md"
	r2 = "pg2.md"
	i1 = (d => r1)
	i2 = (d => r2)
	o1 = d / "__site" / splitext(r1)[1] / "index.html"
	o2 = d / "__site" / splitext(r2)[1] / "index.html"

	write(d / r0, """
		+++
		a = 5
		b = 7
		+++
		""")
	write(d / r1, """
		{{a}}
		""")
	write(d / r2, """
		{{a}}{{b}}
		""")

	X.process_config(gc)
	X.process_file(gc, i1, :md)
	X.process_file(gc, i2, :md)

	@test read(o1, String) // "5"
	@test read(o2, String) // "57"
end

@testset "getvarfrom" begin
	d, gc = testdir(; tag=false)

	r1 = "pg1.md"
	r2 = "pg2.md"
	i1 = (d => r1)
	i2 = (d => r2)
	o1 = d / "__site" / splitext(r1)[1] / "index.html"
	o2 = d / "__site" / splitext(r2)[1] / "index.html"

	write(d / r1, """
		+++
		a = 5
		+++
		{{a}}
		""")
	write(d / r2, """
		{{fill a pg1.md}}
		""")

	X.process_file(gc, i1, :md)
	X.process_file(gc, i2, :md)

	p1 = read(o1, String) |> strip
	p2 = read(o2, String) |> strip

	@test p1 == "5"
	@test p2 == "5"

	lc1 = gc.children_contexts[r1]
	lc2 = gc.children_contexts[r2]

	@test "pg2.md" in keys(lc1.req_vars)
	@test :a in lc1.req_vars["pg2.md"]

	# Change in pg1 followed by process, should trigger process of pg2
	write(joinpath(i1...), """
		+++
		a = 7
		+++
		{{a}}
		""")

	X.process_file(gc, i1, :md)

	p1 = read(o1, String) |> strip
	p2 = read(o2, String) |> strip

	@test p1 == "7"
	@test p2 == "7"

	@test isempty(lc1.to_trigger)
	@test isempty(lc2.to_trigger)
end
