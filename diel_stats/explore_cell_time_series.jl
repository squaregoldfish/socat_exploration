### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 84e8ecfc-f90d-45e9-b14a-f74d09a5e3ad
begin
	using PlutoUI
	using SQLite
  	using DataFrames
  	using Plots
  	plotly()

  	db = SQLite.DB("cell_time_series.sqlite")
end

# ╔═╡ 05f60082-9554-11eb-18b0-c1e9d5ba8d3b
md"""
# SOCAT Cell Time Series
This notebook explores various aspects of the time series for grid cells in the SOCAT dataset.

Before running this notebook, you must run `make_time_series_cells.jl`. This creates an SQLite database containing extracted time series for grid cells. Each time series represents at most one voyage (identified by its Expo Code) and covers one day. Where a voyage passes through multiple cells and/or multiple days, separate records for each are created.

## Introduction

### Database Structure
The database contains one record for each extracted time series. Each record contains the following fields:

| Field    | Description                                                          |
|:---------|:---------------------------------------------------------------------|
| lon      | The cell longitude, from 1 to 360 (0.5° to 359.5°)                   |
| lat      | The cell latitude, from 1 to 180 (-89.5° to 89.5°)                   |
| expocode | The Expo Code of the voyage from which the time series was extracted |
| year     | The year of the time series                                          |
| doy      | The day of year of the time series                                   |
| series   | The time series data                                                 |

The day of year (`doy`) ignores leap years - dates on or after 29th February in leap years are decremented by 1 to align them with other years. This may lead to multiple time series for 28th February in a given year, but this shouldn't be a problem.

The time series is a JSON string of the form:
```
[
  {
    "second":72203,
    "fco2":357.842
  },
  {
    "second":72213,
    "fco2":357.969
  }
]
```
where `seconds` is the time of day in seconds (1 - 86,400), and `fco2` is the fCO_2_ measurement at that time.

## Exploring the time series
There are a lot of things for us to look at. First, let's set up all the packages we'll need and get a connection to the database.
"""

# ╔═╡ 6653866e-2af2-490a-bb59-5f0097ad8fc3
md"""
### Explore time series
Choose a latitude and longitude to see what time series the corresponding grid cell contains.

Longitude (0:360):
$(@bind lon NumberField(0:360))

Latitude (-90:90):
$(@bind lat NumberField(-90.0:90.0))

"""

# ╔═╡ cf328521-8217-4b47-885a-6592f4560591
begin
	lonindex = lon +  1
	if lonindex > 359
		lonindex = 359
	end
	
	latindex = lat + 91
	if latindex > 180
		latindex = 180
	end

	cellseries = DataFrame(
		DBInterface.execute(db,
			"SELECT expocode, year, doy, series FROM timeseries " *
			"WHERE lon = $(lonindex) AND lat = $(latindex)")
		)
end

# ╔═╡ f59113ea-ded2-4af2-a72e-9c561db0e729
matchedseries = nrow(cellseries)

# ╔═╡ Cell order:
# ╟─05f60082-9554-11eb-18b0-c1e9d5ba8d3b
# ╠═84e8ecfc-f90d-45e9-b14a-f74d09a5e3ad
# ╟─6653866e-2af2-490a-bb59-5f0097ad8fc3
# ╠═cf328521-8217-4b47-885a-6592f4560591
# ╠═f59113ea-ded2-4af2-a72e-9c561db0e729
