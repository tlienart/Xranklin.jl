
const FRANKLIN_ENV = LittleDict{Symbol, Any}(
    :STRICT_PARSING => false,          # if true, fail on any parsing issue
    :SHOW_WARNINGS  => true,
    :OFFSET_LXDEFS  => -typemax(Int),  # helps keep track of order in lxcoms/envs
)
