module NetCDFUtil

using NCDatasets
using DataStructures

export initnetcdf, makevar

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
Initialise a netCDF file with lon/lat dimensions and the specified variable
"""
function initnetcdf(file::String, varname::String,
  vartype::Type)::Tuple{NCDataset, NCDatasets.CFVariable}

  nc = initnetcdf(file)
  var = makevar(nc, varname, vartype)
  return (nc, var)
end

"""
Make a variable using lon/lat dimensions in the specified netCDF file
"""
function makevar(nc::NCDataset, name::String, type::Type)::NCDatasets.CFVariable
  return defVar(nc, name, type, ["longitude", "latitude"],
    attrib = OrderedDict("_FillValue" => -999))
end

end
