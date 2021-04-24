using SQLite
using NCDatasets
using DataStructures
using ProgressMeter
using Statistics

include("NetCDFUtil.jl")
using .NetCDFUtil

NC_FILE = "mean_sd_minute.nc"
DB_FILE = "socat.sqlite"

"""
Create a netCDF containing the mean and standard deviation of the minute of the
day that measurements were taken in each grid cell from the SOCAT database.

Run `make_socat_database.jl` first to extract data from the raw SOCAT data file
into a database for easier interrogation.
"""
function main()
  println("Initialising netCDF...")
  nc, meanvar = initnetcdf(NC_FILE, "minute_mean", Float64)
  #sdvar = makevar(nc, "minute_stdev", Float64)

  println("Connecting to database...")
  db = SQLite.DB(DB_FILE)

  rowcount = 0
  countquery = DBInterface.execute(db, "SELECT COUNT(*) AS c FROM socat")
  for cr in countquery
    rowcount = cr[:c]
  end

  println("Searching...")
  rows = DBInterface.execute(db,
    "SELECT lonindex, latindex, minuteofday FROM socat " *
    "ORDER BY lonindex, latindex"
  )

  prog = Progress(rowcount, "Reading:")

  currentlon = -999
  currentlat = -999
  cellminutes = Int64[]

  for row in rows

    rowlon = row[:lonindex]
    rowlat = row[:latindex]

    if rowlon != currentlon || rowlat != currentlat
      if currentlon != -999
        meanvar[currentlon, currentlat] = meanminute(cellminutes)
      end

      currentlon = rowlon
      currentlat = rowlat
      cellminutes = Int64[]
    end

    push!(cellminutes, row[:minuteofday])

    next!(prog)
  end

  # Write last count
  meanvar[currentlon, currentlat] = meanminute(cellminutes)

  finish!(prog)
  close(nc)
  close(db)
  return nothing
end

"""
Calculate the mean minute of day from a series of minutes
"""
function meanminute(minutes::Vector{Int64})::Float64

  # Convert all minutes to degrees
  inputdegrees = minutes .* 0.25
  meandegree = rad2deg(atan(mean(sind.(inputdegrees)),
    mean(cosd.(inputdegrees))))

  if meandegree < 0
    meandegree = 360 - abs(meandegree)
  end

  return meandegree * 4
end

main()