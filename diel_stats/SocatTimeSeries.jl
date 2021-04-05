module SocatTimeSeries

using Dates

export SeriesEntry

struct SeriesEntry
  second::Int64
  fco2::Float64

  function SeriesEntry(date::DateTime, fco2::Float64)
    return new(secondofday(date), fco2)
  end
end

function secondofday(date)
  return hour(date) * 3600 + minute(date) * 60 + second(date)
end

end