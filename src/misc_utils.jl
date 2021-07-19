printyb(msg) = printstyled(msg, color=:yellow, bold=true)

function print_warning(msg)
    FRANKLIN_ENV[:SHOW_WARNINGS] || return
    printyb("┌ Franklin Warning: ")
    for line in split(strip(msg), '\n')
        printyb("│ ")
        println(line)
    end
    printyb("└\n")
    return
end
