module CompleteDung

using DataDeps, CSV, Dates

const coffeesource = joinpath(homedir(), "coffeesource")
const sourcefolder = joinpath(coffeesource, "database")

const video_file_name = joinpath(sourcefolder, "video.csv")
const videofile_file_name = joinpath(sourcefolder, "videofile.csv")
const board_file_name = joinpath(sourcefolder, "board.csv")
const calibration_file_name = joinpath(sourcefolder, "calibration.csv")
const new_interval_file_name = joinpath(sourcefolder, "new_interval.csv") # calibration intervals (intrinsic and extrinsic intervals)
const complete_interval_file_name = joinpath(sourcefolder, "complete_interval.csv") # existing intervals that need to be completed with video, start, stop, and comment data
const complete_poi_file_name = joinpath(sourcefolder, "complete_poi.csv")

include("init.jl")

export register_video, register_calibration, register_poi

global defaults = Dict{Symbol, Any}(:datetime => now(),
                                    :videocomment => "",
                                    :videofile => "---",
                                    :startstop => Nanosecond(0),
                                    :interval_comment => "",
                                    :checker_width_cm => 4.0,
                                    :checker_per_width => 7,
                                    :checker_per_height => 9,
                                    :calibration_comment => "")

include("videos.jl")
include("intervals.jl")
# include("/home/yakir/dungProject/CompleteDung/src/videos.jl")
# include("/home/yakir/dungProject/CompleteDung/src/intervals.jl")

function _formatrow(t) 
    ks = colnames(t)
    [join([string(k, ": ", getfield(r, k)) for k in ks], ", ") for r in t]
end

function register_board(board)
    @label desig
    println("Give a designation (already existing designations: ", select(board, :designation), ") for this new board:")
    designation = strip(readline(stdin)) 
    if designation ∈ select(board, :designation) 
        @warn "designation $designation is already taken, try again…" 
        @goto desig 
    end
    isempty(designation) && @goto desig
    @label width
    println("What is the width (same as height) of the checkers in cm?\n[Enter: ", defaults[:checker_width_cm] ,"]")
    _checker_width_cm = strip(readline(stdin))
    if isempty(_checker_width_cm)
        checker_width_cm = defaults[:checker_width_cm]
    else
        if !all(isnumeric, filter(!isequal('.'), _checker_width_cm))
            @warn "width $_checker_width_cm is not a number, try again…"
            @goto width
        end
        checker_width_cm = parse(Float64, _checker_width_cm)
        defaults[:checker_width_cm] = checker_width_cm
    end
    @label perwidth
    println("How many checkers are there across the width of the board?\n[Enter: ", defaults[:checker_per_width] ,"]")
    _checker_per_width = strip(readline(stdin))
    if isempty(_checker_per_width)
        checker_per_width = defaults[:checker_per_width]
    else
        if !all(isnumeric, _checker_per_width)
            @warn "$_checker_per_width is not an integer, try again…"
            @goto perwidth
        end
        checker_per_width = parse(Float64, _checker_per_width)
        defaults[:checker_per_width] = checker_per_width
    end
    @label perheight
    println("How many checkers are there across the height of the board?\n[Enter: ", defaults[:checker_per_height] ,"]")
    _checker_per_height = strip(readline(stdin))
    if isempty(_checker_per_height)
        checker_per_height = defaults[:checker_per_height]
    else
        if !all(isnumeric, _checker_per_height)
            @warn "$_checker_per_height is not an integer, try again…"
            @goto perheight
        end
        checker_per_height = parse(Float64, _checker_per_height)
        defaults[:checker_per_height] = checker_per_height
    end
    println("""Describe the board to facilitate recognizing it in the future (e.g. "a small board, black tape framming it on the long side, cardboard on the short"):""")
    @label describe
    board_description = strip(readline(stdin))
    if isempty(board_description)
        @warn "you must give some minimal description. Think about the future generations!"
        @goto describe
    end
    [(designation = designation, checker_width_cm = checker_width_cm, checker_per_width = checker_per_width, checker_per_height = checker_per_height, board_description = board_description)] |> CSV.write(board_file_name, append = true)
    # addrow((designation = designation, checker_width_cm = checker_width_cm, checker_per_width = checker_per_width, checker_per_height = checker_per_height, board_description = board_description), board_file_name)
    designation
end

oldornew(x) = occursin(datadep"coffeebeetle", x) ? :old : :new

function getboard()
    files = [joinpath(datadep"coffeebeetle", "board.csv"), board_file_name]
    loadtable(files, indexcols = (:designation))
end

function getcalibration()
    calibration = loadtable(calibration_file_name, indexcols = (:calibration))
    setcol(calibration, :calibration => :calibration => UUID, :extrinsic => :extrinsic => x -> ismissing(x) || isempty(x) ? missing : UUID(x), :intrinsic => :intrinsic => x -> ismissing(x) || isempty(x) ? missing : UUID(x))
    # files = [joinpath(datadep"coffeebeetle", "calibration.csv"), calibration_file_name]
    # calibration = loadtable(files, indexcols = (:calibration), filenamecol = :source => oldornew)
    # setcol(calibration, :calibration => :calibration => UUID, :extrinsic => :extrinsic => x -> ismissing(x) || isempty(x) ? missing : UUID(x), :intrinsic => :intrinsic => x -> ismissing(x) || isempty(x) ? missing : UUID(x))
end

function register_calibration()

    board = getboard()
    options = _formatrow(board)
    pushfirst!(options, "Register a new board")
    menu = RadioMenu(options)
    i = request("Which board was used?", menu)

    boardID = i == 1 ?  register_board(board) : board[i - 1].designation

    menu = RadioMenu(["Stationary", "Moving"])
    i = request("Which type of calibration is it?", menu)

    intrinsic = if i == 1 
        missing
    else
        println("Registrating the intrinsic calibration POI (waving the checkerboard around)")
        register_interval(true)
    end
    println("Registrating the extrinsic calibration POI (the checkerboard on the ground)")
    extrinsic = register_interval(false)

    println("Any comments about this calibration?\n[Enter: ", defaults[:calibration_comment],"]")
    _comment = strip(readline(stdin))
    if !isempty(_comment)
        defaults[:calibration_comment] = _comment
    end
    comment = defaults[:calibration_comment]

    calibrationID = uuid4()
    # calibration = getcalibration()
    # while calibrationID ∈ select(calibration, :calibration)
        # calibrationID = uuid4()
    # end

    [(calibration = calibrationID, intrinsic = intrinsic, extrinsic = extrinsic, board = boardID, comment = comment)] |> CSV.write(calibration_file_name, append = true)
    # addrow((calibration = calibrationID, intrinsic = intrinsic, extrinsic = extrinsic, board = boardID, comment = comment), calibration_file_name)
    nothing

end

function getrun()
    run = loadtable(joinpath(datadep"coffeebeetle", "run.csv"), indexcols = (:run))
    for col in colnames(run)
        run = setcol(run, col, col => x -> isempty(x) ? missing : x)
    end
    setcol(run, :run => :run => UUID, :date => :date => Date)
end

function getpoi()
    poi = if length(CSV.File(complete_poi_file_name)) > 0
        poi = loadndsparse(joinpath(datadep"coffeebeetle", "poi.csv"), indexcols = [:poi])
        cpoi = loadndsparse(complete_poi_file_name, indexcols = [:poi])
        table(merge(poi, cpoi, agg = (x,y) -> y))
    else
        loadtable(joinpath(datadep"coffeebeetle", "poi.csv"), indexcols = [:poi])
    end
    setcol(poi, :poi => :poi => UUID, :run => :run => UUID, :calibration => :calibration => x -> isempty(x) ? missing : UUID(x), :interval => :interval => UUID)
end

const corners = ["rightdowninitial", "leftdowninitial", "rightupinitial", "leftupinitial", "rightdownfinal", "leftdownfinal", "rightupfinal", "leftupfinal"]

function register_poi(; person = nothing)

    video, videofile = getvideodb()
    interval = getinterval()
    calibration = getcalibration()
    x = join(video, videofile, rkey = :video)
    x = join(x, interval, rkey = :video)
    x = join(x, calibration, lkey = :interval, rkey = :extrinsic)
    y = groupby(x, :calibration, usekey = true) do k, r
        (calibration = k.calibration, file_name = r[1].file_name, start = r[1].start)
    end

    i = if length(y) > 1
        options = _formatrow(y)
        menu = RadioMenu(options)
        request("Which calibration will the POIs be calibrated by?", menu)
    else
        1
    end
    calibrationID = y[i].calibration


    # calibrationID = calibration[end].calibration
    # i = findfirst(isequal(calibrationID), select(y, :calibration))
    println("Registration of the calibration found in ", y[i].file_name, " at ", Time(0) + y[i].start)

    experiment = loadtable(joinpath(datadep"coffeebeetle", "experiment.csv"), indexcols = (:experiment))
    runs = getrun()
    poi = getpoi()

    data = join(experiment, runs, rkey = :experiment, lselect = :experiment, rselect = (:run, :id, :date, :person))
    data = join(data, poi, lkey = :run, rkey = :run)
    data = filter(ismissing, data, select = :calibration)
    if person ≢ nothing
        data = filter(isequal(person), data, select = :person)
    end
    options = unique(select(data, :experiment))

    menu = MultiSelectMenu(options)
    i = request("Which experiment/s contained run/s calibrated by the last calibration?", menu)

    data = filter(x -> x ∈ options[sort(collect(i))], data, select = :experiment)
    data = pushcol(data, :runlabel => _formatrow(select(data, (:experiment, :id, :date))))

    options = unique(select(data, :runlabel))

    menu = MultiSelectMenu(options)
    i = request("Which run/s contained POI/s calibrated by the last calibration?", menu)

    data = filter(x -> x ∈ options[sort(collect(i))], data, select = :runlabel)

    groupby(data, :experiment, usekey = true) do experimentID, es
        println("In experiment: ", experimentID)
        groupby(table(es), :run, usekey = true) do runID, rs
            y = [findfirst(isequal(corners[i]), rs.type) for i in 1:length(rs)]
            rs = if any(isnothing, y)
                rs
            else
                append!(y, setdiff(1:length(rs), y))
                rs[y]
            end
            println("In run ID: ", rs[1].id, "; date: ", rs[1].date)
            for r in rs
                println("Is the ", r.type, " POI calibrated by the last calibration?\n[Enter: yes, other: no]")
                choice = strip(readline())
                if isempty(choice)
                    println("Please specify when this POI occured.")
                    register_interval(false, r.interval)
                    [(poi = r.poi, type = r.type, run = runID.run, calibration = calibrationID, interval = r.interval)] |> CSV.write(complete_poi_file_name, append = true)
                end
            end
        end
    end
    nothing
end


# [todo]
# maybe control the order of the lists
# add some counter shwoing what's done and what's left
# it would be sweet if I could test the generated data to see it merges well with existing data to make sure all the parts are there.







#=
# function getdata()
repo = datadep"coffeebeetle"
videofile = loadtable(joinpath(repo, "videofile.csv"), indexcols = [1])
videofile = setcol(videofile, :video => :video => UUID, :duration => :duration => tonanosecond)
video = loadtable(joinpath(repo, "video.csv"), indexcols = [1])
video = setcol(video, :video, :video => UUID)
interval = loadtable(joinpath(repo, "interval.csv"), indexcols = [1])
interval = setcol(interval, :interval => :interval => UUID, :video => :video => x -> isempty(x) ? missing : UUID(x), :start => :start => x -> isempty(x) ? missing : tonanosecond(x), :stop => :stop => x -> isempty(x) ? missing : tonanosecond(x))
poi = loadtable(joinpath(repo, "poi.csv"), indexcols = [1])
poi = setcol(poi, :poi => :poi => UUID, :run => :run => UUID, :calibration => :calibration => x -> isempty(x) ? missing : UUID(x), :interval => :interval => UUID)
board = loadtable(joinpath(repo, "board.csv"), indexcols = [1])
calibration = loadtable(joinpath(repo, "calibration.csv"), indexcols = [1])
calibration = setcol(calibration, :calibration => :calibration => UUID, :extrinsic => :extrinsic => UUID, :intrinsic => :intrinsic => x -> isempty(x) ? missing : UUID(x))
runs = loadtable(joinpath(repo, "runs.csv"), indexcols = [1], type_detect_rows = 140, nastrings = [""])
for col in colnames(runs)
global runs
runs = setcol(runs, col, col => x -> isempty(x) ? missing : x)
end
runs = setcol(runs, :run => :run => UUID, :date => :date => Date)
experiment = loadtable(joinpath(repo, "experiment.csv"), indexcols = [1])
files = joinpath.(repo, "pixel", readdir(joinpath(repo, "pixel")))
pixel_coord = loadtable(files, delim = '\t', filenamecol = :interval => x -> UUID(first(splitext(basename(x)))), header_exists = false, colnames = ["x", "y", "t"], colparsers = [Float64, Float64, Float64], indexcols = 1)



todo = filter(isequal("belen"), runs, select = :person)
todo = join(todo, poi, rkey = :run)
todo = join(todo, interval, lkey = :interval, rkey = :interval)

groupby(todo, :run) do r
groupby(table(r), :poi) do p
@show p
end
end
=#



end # module
