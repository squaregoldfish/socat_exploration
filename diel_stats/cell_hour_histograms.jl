using ProgressMeter

function main()
  # Open the file and skip the header
  in::IOStream = open("SOCATv2020.tsv", "r")

  prog = ProgressUnknown("Lines read:")
  colheadersfound::Bool = false

  while !colheadersfound
    line::String = readline(in)
    ProgressMeter.next!(prog)
    colheadersfound = startswith(line, "Expocode\tversion\tSource_DOI")
  end

  cellhours::Array{Int64, 3} = zeros(Int64, (360, 180, 24))
  eof::Bool = false
  while !eof
    line::String = readline(in)
    if line == ""
      eof = true
    else
      fields::Vector{String} = split(line, "\t")
      hour::UInt8 = parse(UInt8, fields[8])
      lonbin::UInt16 = floor(parse(Float64, fields[11])) + 1
      if lonbin == 361
        lonbin = 360
      end
      latbin::UInt16 = floor(parse(Float64, fields[12]) + 90) + 1
      if latbin == 181
        latbin = 180
      end
      cellhours[lonbin, latbin, hour + 1] += 1
    end

    ProgressMeter.next!(prog)
  end

  close(in)

end

#main()

