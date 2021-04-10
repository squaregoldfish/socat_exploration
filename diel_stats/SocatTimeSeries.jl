module SocatTimeSeries

using Dates

export SeriesEntry, tostring, makeminuteseries

struct SeriesEntry
  timeindex::Int64
  fco2::Float64

  function SeriesEntry(date::DateTime, fco2::Float64)
    return new(secondofday(date), fco2)
  end

  function SeriesEntry(index::Int64, fco2::Float64)
    return new(index, fco2)
  end
end

function secondofday(date)
  return hour(date) * 3600 + minute(date) * 60 + second(date)
end

function tostring(series::Vector{SeriesEntry})::String
  json = IOBuffer()

  for entry in series
    print(json, "$(entry.timeindex),$(entry.fco2);")
  end

  result = String(take!(json))
  close(json)
  return result
end

function makeminuteseries(secondseries::Vector{SeriesEntry})

  minuteseries = SeriesEntry[]

  sum = 0.0
  count = 0
  currentminute = -1

  for secondentry in secondseries

    entryminute = floor(Int64, secondentry.timeindex / 60)
    if entryminute != currentminute
      if count > 0
        push!(minuteseries, SeriesEntry(currentminute, sum / count))
      end

      sum = 0
      count = 0
      currentminute = entryminute
    end

    sum += secondentry.fco2
    count += 1
  end

  if count > 0
    push!(minuteseries, SeriesEntry(currentminute, sum / count))
  end

  return minuteseries
end

end