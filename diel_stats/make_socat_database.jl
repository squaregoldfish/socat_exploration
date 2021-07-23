using ProgressMeter
using SQLite
using Tables
using Dates

SQLITE_FILE = "socat.sqlite"

function main()
  db = initdb()

  # Open the file and skip the header
  infile = open("SOCATv2021.tsv", "r")
  prog = ProgressUnknown("Lines read:")

  # Skip headers
  colheadersfound = false
  while !colheadersfound
    line = readline(infile)
    ProgressMeter.next!(prog)
    colheadersfound = startswith(line, "Expocode\tversion\tSource_DOI")
  end

  # Start a transaction
  SQLite.transaction(db)

  eof = false
  while !eof

    # Read the next line
    line = readline(infile)
    if line == ""
      # If there's no next line, we've finished. Write the last series
      eof = true
    else

      fields = split(line, "\t")

      lonindex = floor(parse(Float64, fields[11])) + 1
      if lonindex == 361
        lonindex = 360
      end

      latindex = floor(parse(Float64, fields[12]) + 90) + 1
      if latindex == 181
        latindex = 180
      end

      expocode = fields[1]
      year = parse(UInt16, fields[5])
      month = parse(UInt8, fields[6])
      day = parse(UInt8, fields[7])
      hour = parse(UInt8, fields[8])
      minute = parse(UInt8, fields[9])
      second = floor(parse(Float64, fields[10]))
      if second == 60
        second = 59
      end

      linetime = Dates.DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
      )

      doy = dayofyear(linetime)

      if isleapyear(linetime) && ((month == 2 && day == 29) || month > 2)
        doy -= 1
      end

      minofday = minuteofday(linetime)

      sst = parse(Float64, fields[15])
      sss = parse(Float64, fields[14])
      fco2 = parse(Float64, fields[30])

      SQLite.execute(db,
      "INSERT INTO socat VALUES " *
      "($lonindex, $latindex, $year, $doy, $minofday, '$expocode', " *
      "$(isnan(sst) ? "NULL" : sst), $(isnan(sss) ? "NULL" : sss), " *
      "$(isnan(fco2) ? "NULL" : fco2))"
    )

    end

    ProgressMeter.next!(prog)
  end


  # End the transaction and tidy up
  SQLite.commit(db)
  ProgressMeter.finish!(prog)
  close(infile)

  println("Creating index...")
  SQLite.execute(db,
    "CREATE INDEX cellidx ON socat(lonindex, latindex)"
  )

  close(db)

  return nothing
end

function initdb()::SQLite.DB
  if ispath(SQLITE_FILE)
    rm(SQLITE_FILE)
  end

  db = SQLite.DB(SQLITE_FILE)

  timeseriestable = Tables.Schema(
    (:lonindex, :latindex, :year, :dayofyear, :minuteofday,
     :expocode, :sst, :sss, :fco2),
    Tuple{Int64,Int64,Int64,Int64,Int64,
      String,Union{Missing,Float64},Union{Missing,Float64},Union{Missing,Float64}}
  )

  SQLite.createtable!(db, "socat", timeseriestable)

  return db
end

function minuteofday(date::DateTime)::Int64
  return hour(date) * 60 + minute(date)
end

main()
