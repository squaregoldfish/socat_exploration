using SQLite
using NCDatasets
using DataStructures
using ProgressMeter
using Statistics

NC_FILE = "time_series_info.nc"
DB_FILE = "socat.sqlite"

"""
Create a netCDF containing a count of the unique days with measurements in
each grid cell from the SOCAT database

Run `make_socat_database.jl` first to extract data from the raw SOCAT data file
into a database for easier interrogation.
"""
function main()
  println("Initialising netCDF...")
  nc = initnetcdf(NC_FILE)

  println("Connecting to database...")
  db = SQLite.DB(DB_FILE)

  rowcount = 0
  countquery = DBInterface.execute(db, "SELECT COUNT(*) AS c FROM socat")
  for cr in countquery
    rowcount = cr[:c]
  end

  timeseriescount(nc, db, rowcount)
  measurementcount(nc, db, rowcount)
  meanR̅(nc, db, rowcount)

  close(nc)
  close(db)
end

"""
Initialise a netCDF file with lon/lat dimensions
"""
function initnetcdf(file::String)::NCDataset
  if ispath(file)
    rm(file)
  end

  nc = Dataset(file, "c")
  nc.attrib["title"] = "Summary of diel biases in the SOCAT dataset"

  defDim(nc, "longitude", 360)
  defDim(nc, "latitude", 180)

  lonvar = defVar(nc, "longitude", Float32, ["longitude"],
    attrib = OrderedDict("units" => "degrees_east"))

  lonvar[:] = collect(0.5:1:359.5)

  latvar = defVar(nc, "latitude", Float32, ["latitude"],
    attrib = OrderedDict("units" => "degrees_north"))

  latvar[:] = collect(-89.5:1:89.5)

  return nc
end

"""
Add a variable to a NetCDF file that has lon/lat dimensions

"""
function addvar(nc::NCDataset, name::String, type::Type)::NCDatasets.CFVariable
  return defVar(nc, name, type, ["longitude", "latitude"],
    attrib = OrderedDict("_FillValue" => convert(type, -999)))
end

"""
Create the time series count stats
"""
function timeseriescount(nc::NCDataset, db::SQLite.DB, rowcount::Int64)
  println("Days Per Cell")
  println("-------------")

  countvar = addvar(nc, "days_with_measurements", Int32)

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

  return nothing
end

"""
Create the measurement count stats
"""
function measurementcount(nc::NCDataset, db::SQLite.DB, rowcount::Int64)
  println("Measurements Per Cell")
  println("---------------------")

  measurementcountvar = addvar(nc, "measurement_count", Int32)

  println("Searching...")
  rows = DBInterface.execute(db,
    "SELECT lonindex, latindex FROM socat ORDER BY lonindex, latindex"
  )

  prog = Progress(rowcount, "Reading:")

  currentlon = -999
  currentlat = -999
  measurements = 0

  for row in rows
    rowlon = row[:lonindex]
    rowlat = row[:latindex]

    if rowlon != currentlon || rowlat != currentlat
      if currentlon != -999
        measurementcountvar[currentlon, currentlat] = measurements
      end

      currentlon = rowlon
      currentlat = rowlat
      measurements = 0
    end

    measurements += 1

    next!(prog)
  end

  measurementcountvar[currentlon, currentlat] = measurements

  finish!(prog)
end

"""
Make the mean and R̅ stats
"""
function meanR̅(nc::NCDataset, db::SQLite.DB, rowcount::Int64)

  println("Minute Mean and R̅")
  println("-----------------")

  meanvar = addvar(nc, "minute_mean", Float64)
  R̅var = addvar(nc, "minute_R̅", Float64)

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
        celldegrees = cellminutes .* 0.25
        meanvar[currentlon, currentlat] = meandegree(celldegrees) * 4
        R̅var[currentlon, currentlat] = R̅(celldegrees)
      end

      currentlon = rowlon
      currentlat = rowlat
      cellminutes = Int64[]
    end

    push!(cellminutes, row[:minuteofday])

    next!(prog)
  end

  # Write last count
  celldegrees = cellminutes .* 0.25
  meanvar[currentlon, currentlat] = meandegree(celldegrees) * 4
  R̅var[currentlon, currentlat] = R̅(celldegrees)

  finish!(prog)
end

"""
Calculate the mean minute of day from a series of minutes
"""
function meandegree(degrees::Vector{Float64})::Float64

  meandegree = rad2deg(atan(mean(sind.(degrees)),
    mean(cosd.(degrees))))

  if meandegree < 0
    meandegree = 360 - abs(meandegree)
  end

  return meandegree
end

"""
Calculate the standard deviation of a series of minutes
"""
function R̅(degrees::Vector{Float64})::Float64

  if length(degrees) == 1
    return 1
  else
    C = sum(cosd.(degrees))
    S = sum(sind.(degrees))
    R = sqrt(C^2 + S^2)
    return R / length(degrees)
  end
end

main()