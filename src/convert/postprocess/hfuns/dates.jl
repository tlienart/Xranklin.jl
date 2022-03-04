"""
    format_date()

Convenience function taking a `DateTime` object and returning the corresponding
formatted string with the format contained in `LOCAL_VARS["date_format"]` and
with the locale data provided in `date_months`, `date_shortmonths`, `date_days`,
and `date_shortdays` local variables. If `short` variations are not provided,
automatically construct them using the first three letters of the names in
`date_months` and `date_days`.
"""
function format_date(d::Dates.DateTime)
    # aliases for locale data and format from local variables
    gc = cur_gc()
    format      = getvar(gc, :date_format,      "U d, yyyy")
    months      = getvar(gc, :date_months,      String[])
    shortmonths = getvar(gc, :date_shortmonths, String[])
    days        = getvar(gc, :date_days,        String[])
    shortdays   = getvar(gc, :date_shortdays,   String[])
    # if vectors are empty, user has not defined custom locale,
    # defaults to english
    if all(isempty.((months, shortmonths, days, shortdays)))
        return Dates.format(d, format, locale="english")
    end
    # if shortdays or shortmonths are undefined,
    # automatically construct them from other lists
    if !isempty(days) && isempty(shortdays)
        shortdays = first.(days, 3)
    end
    if !isempty(months) && isempty(shortmonths)
        shortmonths = first.(months, 3)
    end
    # set locale for this page
    Dates.LOCALES["date_locale"] = Dates.DateLocale(
        months, shortmonths, days, shortdays
    )
    return Dates.format(d, format, locale="date_locale")
end
format_date(u::Float64) = format_date(Dates.unix2datetime(u))


"""
    {{last_modification_date}}

"""
hfun_last_modification_date() = format_date(getlvar(:_modification_time))


"""
    {{creation_date}}

Note: this may not always be reliable depending as it depends on the file
stats which may not always reflect the exact creation time.
"""
hfun_creation_date() = format_date(getlvar(:_creation_time))
