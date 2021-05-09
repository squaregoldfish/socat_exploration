### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 9c288f31-bf08-4817-b467-19cde8a9d2b6
using PlutoUI

# ╔═╡ e7955031-cf60-44a9-8f5f-1162862ecbc8
md"""
# SOCAT Cell Time Series
This notebook explores various aspects of the time series for grid cells in the SOCAT dataset.

Before running this notebook, you must run the following three scripts:
- `make_socat_database.jl` (needs a copy of the main SOCAT tsv file in the current directory)
- `make_timeseries_count.jl`
- `mean_sd_minute.jl`

These scripts create the database and netCDF files used by this notebook.

## Introduction

### Database Structure
`make_socat_database.jl` creates `socat.sqlite` which contains a simplified version of the SOCAT dataset. It contains one table (`socat`) with a record for each SOCAT observation. The table contains the following fields:

| Field       | Description                                                          |
|:------------|:---------------------------------------------------------------------|
| lonindex    | The longitude cell index†                                            |
| latindex    | The latitude cell index†                                             |
| year        | The year in which the measurement was taken                          |
| dayofyear   | The day of the year on which the measurement was taken‡              |
| minuteofday | The minute of the day on which the measurement was taken             |
| expocode    | The Expo Code of the voyage during which the measurement was taken   |
| sst         | The measured sea surface temperature                                 |
| sss         | The measured sea surface salinity                                    |
| fco2        | The measured fCO₂                                                    |

†The index represents a 1° cell, ranging from `1 = 0.5°` through `360 = 359.5°` for longitude and `1 = -89.5°` to `180 = 89.5°` for latitude.

‡The `dayofyear` ignores leap years - dates on or after 29th February in leap years are decremented by 1 to align them with other years. This may lead to multiple time series for 28th February in a given year, but this shouldn't be a problem.

## Data Summary
`make_time_series_count.jl` and `mean_sd_minute.jl` compute statistics of the cells' time series. You can look at these in detail below, but for now here is a summary.

### Number of time series
The map below shows the number of days containing observations in each 1° grid cell, taken from the SOCATv2020 dataset.
$(LocalResource("./time_series_count.png"))

### Mean minute
This map shows the mean minute of the day in which observations wjere taken in each grid cell across the entire SOCAT dataset. The lack of a clear pattern indicates that there is no systematic bias across the dataset regarding observation time, which is expected.
$(LocalResource("./mean_minute.png"))

### R̅
The R̅ computed for a grid cell is a measure of how widely distributed the measurements are throughout the day. R̅ is a value between 0 and 1, where 0 indicates a wide distribution throughout the day and 1 indicating that measurements are concentrated around a particular time. The map below shows the R̅ for each grid cell.
$(LocalResource("./Rbar.png"))
"""

# ╔═╡ Cell order:
# ╠═9c288f31-bf08-4817-b467-19cde8a9d2b6
# ╟─e7955031-cf60-44a9-8f5f-1162862ecbc8
