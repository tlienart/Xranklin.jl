include(joinpath(@__DIR__, "..", "utils.jl"))

@test_in_dir "_for-estr" "for and estring" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", raw"""
        +++
        team = [
        (name="Alice", role="CEO"),
        (name="Bob", role="CTO"),
        (name="Jon", role="Eng")
        ]
        +++
        ~~~
        <ul>
        {{for person in team}}
        <li><strong>{{> $person.name}}</strong>: {{> $person.role}}</li>
        {{end}}
        </ul>
        ~~~
        """)
    serve(FOLDER, single=true)
    for (name, role) in [
            ("Alice", "CEO"),
            ("Bob", "CTO"),
            ("Jon", "Eng")
        ]
        @test output_contains(FOLDER, "", "<li><strong>$name</strong>: $role</li>")
    end
end
