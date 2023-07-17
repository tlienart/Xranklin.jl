include(joinpath(@__DIR__, "..", "utils.jl"))

@test_in_dir "_order" "i228" begin
    txt = raw"""
        ```!a
        a = 5
        ```
        A \htmlshow{a}
        ```!b
        b = a + 5
        ```
        B \htmlshow{b}
        ```!c
        a = 7
        ```
        C \htmlshow{c}
        """

    write(FOLDER/"config.md","")
    write(FOLDER/"utils.jl","")
    write(FOLDER/"index.md", txt)

    task = @async serve(FOLDER, launch=false)
    sleep(2)

    for e in ("A 5", "B 10", "C 7")
        @test output_contains(FOLDER, "", e)
    end
    
    println("<>")
    
    # now we only modify the second cell; since the
    # cache is enabled, it's the last value of `a` that
    # is used (see #227)
    txt = replace(txt, "b = a + 5" => "b = a + 1")
    write(FOLDER/"index.md", txt)
    sleep(1)

    for e in ("A 5", "B 8", "C 7")
        @test output_contains(FOLDER, "", e)
    end

    println("<>")

    # finally, we re-do this but with the force caching
    txt = """
        +++
        force_eval_all = true
        +++
        $txt
        """
    write(FOLDER/"index.md", txt)
    sleep(1)
    for e in ("A 5", "B 6", "C 7")
        @test output_contains(FOLDER, "", e)
    end

    schedule(task, InterruptException(), error=true)
    sleep(1)
end

# XXX stopping here for now, need to continue this

