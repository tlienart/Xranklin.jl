@testset begin
    s = "a `b` c" |> html
    @test s // "<p>a<code>b</code>c</p>"
    s = "a `b`" |> html
    @test s // "<p>a<code>b</code></p>"
    s = "`b` c" |> html
    @test s // "<p><code>b</code>c</p>"
    s = "`a` `b`" |> html
    @test s // "<code>a</code><code>b</code>"
    s = "1 `a` `b` `c` 2" |> html
    @test s // "<p>1<code>a</code><code>b</code><code>c</code>2</p>"

    # with line skips
    s = "a\n\n`b` c" |> html
    @test s // "<p>a<p><code>b</code>c</p>"
    s = "a `b`\n\nc" |> html
    @test s // "<p>a<code>b</code></p>c</p>"
    s = "a\n\n`b`\n\nc" |> html
    @test s // "<p>a<code>b</code>c</p>"
end
