using SQLite
using NCDatasets
using DataStructures
using DataFrames
using ProgressMeter

NC_FILE = "diel_biases.nc"
DB_FILE = "cell_time_series.sqlite"

"""
Create a netCDF file with basic information about the diel biases present
in the SOCAT dataset.

Run `make_cell_time_series.jl` first to generate time series data from the
raw SOCAT file.
"""
function main()
  println("Initialising netCDF...")
  nc = init_netcdf()

  println("Connecting to database...")
  db = SQLite.DB(DB_FILE)

  println("Extracting time series counts...")
  extract_timeseries_counts(nc, db)

  close(nc)
  close(db)
  return nothing
end

"""
Initialise the netCDF file with dimensions
"""
function init_netcdf()
  rm(NC_FILE)
  nc = Dataset(NC_FILE, "c")
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
Get the count of time series in each grid cell and add them to the netCDF file
"""
function extract_timeseries_counts(nc, db)

  # Create the netCDF variable
  countvar = defVar(nc, "count", Int32, ["longitude", "latitude"],
    attrib = OrderedDict("_FillValue" => -999))

  # Get the counts from the database
  tscounts = DBInterface.execute(db,
      "SELECT lon, lat, COUNT(minuteseries) AS seriescount FROM timeseries " *
      "GROUP BY lon, lat"
    ) |> DataFrame

  for row in eachrow(tscounts)
    countvar[row["lon"], row["lat"]] = row["seriescount"]
  end
end

main()