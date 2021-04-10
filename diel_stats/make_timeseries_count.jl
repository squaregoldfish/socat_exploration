using SQLite
using NCDatasets
using DataStructures
using ProgressMeter

include("NetCDFUtil.jl")
using .NetCDFUtil

NC_FILE = "time_series_count.nc"
DB_FILE = "socat.sqlite"

"""
Create a netCDF file with basic information about the diel biases present
in the SOCAT dataset.

Run `make_socat_database.jl` first to extract data from the raw SOCAT data file
into a database for easier interrogation.
"""
function main()
  println("Initialising netCDF...")
  nc, countvar = initnetcdf(NC_FILE, "count", Int32)

  println("Connecting to database...")
  db = SQLite.DB(DB_FILE)

  rowcount = 0
  countquery = DBInterface.execute(db, "SELECT COUNT(*) AS c FROM socat")
  for cr in countquery
    rowcount = cr[:c]
  end

  println("Searching...")
  rows = DBInterface.execute(db,
    "SELECT lonindex, latindex, year||dayofyear AS ydoy FROM socat " *
    "ORDER BY lonindex, latindex, ydoy"
  )

  prog = Progress(rowcount, "Reading:")

  currentlon = -999
  currentlat = -999
  seriescount = 0
  currentydoy = nothing

  for row in rows

    rowlon = row[:lonindex]
    rowlat = row[:latindex]
    rowydoy = row[:ydoy]

    if rowlon != currentlon || rowlat != currentlat
      if currentlon != -999
        countvar[currentlon, currentlat] = seriescount
      end

      currentlon = rowlon
      currentlat = rowlat
      seriescount = 0
      currentydoy = nothing
    end

    if rowydoy != currentydoy
      seriescount += 1
      currentydoy = rowydoy
    end

    next!(prog)
  end

  # Write last count
  countvar[currentlon, currentlat] = seriescount

  finish!(prog)
  close(nc)
  close(db)
  return nothing
end

main()