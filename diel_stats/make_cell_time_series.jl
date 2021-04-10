using ProgressMeter
using SQLite
using Tables
using Dates

include("SocatTimeSeries.jl")
using .SocatTimeSeries

SQLITE_FILE = "cell_time_series.sqlite"

function main()
  db = init_db()

  # Open the file and skip the header
  infile = open("SOCATv2020.tsv", "r")

  prog = ProgressUnknown("Lines read:")
  colheadersfound = false

  while !colheadersfound
    line = readline(infile)
    ProgressMeter.next!(prog)
    colheadersfound = startswith(line, "Expocode\tversion\tSource_DOI")
  end

  # Start a transaction
  SQLite.transaction(db)

  # Cell time series details
  lon = 999
  lat = 999
  expocode = ""
  year = 999
  doy = 999
  series = SeriesEntry[]

  # Loop until we fall off the end of the file
  eof = false
  while !eof

    # Read the next line
    line = readline(infile)
    if line == ""
      # If there's no next line, we've finished. Write the last series
      eof = true
      writeseries(db, lon, lat, expocode, year, doy, series)
    else
      # Extract line fields
      fields = split(line, "\t")

      linelon = floor(parse(Float64, fields[11])) + 1
      if linelon == 361
        linelon = 360
      end

      linelat = floor(parse(Float64, fields[12]) + 90) + 1
      if linelat == 181
        linelat = 180
      end

      lineexpocode = fields[1]
      lineyear = parse(UInt16, fields[5])
      linemonth = parse(UInt8, fields[6])
      lineday = parse(UInt8, fields[7])
      linehour = parse(UInt8, fields[8])
      lineminute = parse(UInt8, fields[9])
      linesecond = floor(parse(Float64, fields[10]))
      if linesecond == 60
        linesecond = 59
      end

      linetime = Dates.DateTime(
        lineyear,
        linemonth,
        lineday,
        linehour,
        lineminute,
        linesecond,
      )
      linedoy = dayofyear(linetime)
      fco2 = parse(Float64, fields[30])

      if linelon != lon ||
         linelat != lat ||
         lineexpocode != expocode ||
         lineyear != year ||
         linedoy != doy

        # Write the current series
        writeseries(db, lon, lat, expocode, year, doy, series)

        # Reset main variables
        lon = linelon
        lat = linelat
        expocode = lineexpocode
        year = lineyear
        doy = linedoy
        series = [SeriesEntry(linetime, fco2)]
      else
        # Add the fco2 to the current series
        push!(series, SeriesEntry(linetime, fco2))
      end
    end

    ProgressMeter.next!(prog)
  end

  # End the transaction and tidy up
  SQLite.commit(db)
  ProgressMeter.finish!(prog)
  close(infile)
  close(db)
  return nothing
end

function dayofyear(date)
  dayofyear = Dates.dayofyear(date)

  if Dates.isleapyear(date)
    if (month(date) == 2 && day(date) == 29) || month(date) > 2
      dayofyear -= 1
    end
  end

  return dayofyear
end

function writeseries(db, lon, lat, expocode, year, doy, series)
  if lon != 999

    minuteseries = makeminuteseries(series)

    SQLite.execute(
      db,
      "INSERT INTO timeseries VALUES " *
      "($(lon), $(lat), '$(expocode)', $(year), $(doy), '$(tostring(series))', " *
      "'$(tostring(minuteseries))')"
    )
  end
  return nothing
end

function init_db()
  if ispath(SQLITE_FILE)
    rm(SQLITE_FILE)
  end

  db = SQLite.DB(SQLITE_FILE)

  timeseriestable = Tables.Schema(
    (:lon, :lat, :expocode, :year, :doy, :secondseries, :minuteseries),
    Tuple{Int64,Int64,String,Int64,Int64,String,String},
  )

  SQLite.createtable!(db, "timeseries", timeseriestable)

  return db
end

main()
