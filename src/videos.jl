import REPL
using REPL.TerminalMenus
using UUIDs, Random, VideoIO, JuliaDB, Combinatorics #TimeZones, 

#=function gettz()
tz = timezone_names()
menu = RadioMenu(tz)
i = request("Which time zone was the video taken in? (use PgUp & PgDn for quicker scrolling, or Home & End)", menu)
TimeZone(tz[i], TimeZones.Class(:LEGACY))
end=#

function tryparsedatetime(x)
    try
        dt = DateTime(x)
        return dt
    catch
        return nothing
    end
end

function getdatetime(file, minimum_dt)
    # tz = gettz()
    @label askdatetime
    println("Specify a creation date & time for: $file\n[Enter: $(defaults[:datetime])]")
    _dt = strip(readline(stdin))
    dt = isempty(_dt) ? defaults[:datetime] : tryparsedatetime(_dt)
    if dt ≡ nothing
        @warn "the format of the date or time is wrong, try something like:" now()
        @goto askdatetime
    end
    if dt < minimum_dt
        @warn "the date & time should be come after the end of the previous video segment" minimum_dt
        @goto askdatetime
    end
    defaults[:datetime] = dt
    # ZonedDateTime(dt, tz)
    dt
end

function getorder(_files)
    length(_files) ≤ 1 && return _files
    @label order
    println("Is this the correct chronological order of the video files?\n[Enter: no, Other: yes]")
    for files in permutations(_files)
        println(join([string(i, ". ", f) for (i,f) in enumerate(files)], '\n'))
        a = strip(readline(stdin))
        if a == "y"
            return files
        else
            println("this, then?")
            continue
        end
    end
    @warn "you have to choose one configuration, try again…"
    @goto order
end

function registervideos!(files)
    sunregistered = getorder(files)
    durations = [VideoIO.get_duration(joinpath(coffeesource, file_name)) for file_name in sunregistered]
    videoID = uuid4(MersenneTwister(hash(join(sunregistered))))
    nfiles = length(files)
    if nfiles == 1
        date_times = getdatetime.(sunregistered, Date(0))
    else
        options = ["segmented: multiple segments with no temporal gaps", "disjointed: video files with temppral gaps between them"]
        menu = RadioMenu(options)
        i = request("Is this video segmented or disjointed?", menu)
        date_times = Vector{DateTime}(undef, nfiles)
        if i == 1
            date_times[1] = getdatetime(sunregistered[1], Date(0))
            for i in 2:nfiles
                date_times[i] = date_times[i - 1] + durations[i - 1] + Nanosecond(1)
            end
        else
            last_dt = DateTime(0)
            for (i, file_name) in enumerate(sunregistered)
                date_times[i] = getdatetime(file_name, last_dt)
                last_dt = date_times[i] + durations[i]
            end
        end
    end
    println("Any comments about this video?\n[Enter: ", defaults[:videocomment], "]")
    _comment = strip(readline(stdin))
    if !isempty(_comment)
        defaults[:videocomment] = _comment
    end
    comment = defaults[:videocomment]
    [(video = videoID, comment = comment)] |> CSV.write(video_file_name, append = true)
    for (i, file_name) in enumerate(sunregistered)
        [(file_name = file_name, video = videoID, date_time = date_times[i], duration = Dates.value(Nanosecond(durations[i])), index = i)] |> CSV.write(videofile_file_name, append = true)
    end
end

function selectfiles(files)
    length(files) == 1 && return files
    menu = MultiSelectMenu(files)
    i = request("Select the file, or multiple files in case of a segmented video, that constitute/s a single video:", menu)
    files[sort(collect(i))]
end

function getvideodb()
    files = [joinpath(datadep"coffeebeetle", "video.csv"), video_file_name]
    video = loadtable(files, indexcols = (:video))
    files = [joinpath(datadep"coffeebeetle", "videofile.csv"), videofile_file_name]
    videofile = loadtable(files, indexcols = (:file_name))
    video = setcol(video, :video => :video => UUID, :comment => :comment => x -> ismissing(x) ? "" : String(x))
    videofile = setcol(videofile, :video => :video => UUID, :duration => :duration => Nanosecond)
    video, videofile
end

goodvideo(file) = first(file) ≠ '.' && occursin(r"mts|mp4|avi|mpg|mov|mkv"i, last(splitext(file))) && isfile(joinpath(coffeesource, file))

function register_video()
    video, videofile = getvideodb()
    files = String[file for file in readdir(coffeesource) if file ∉ select(videofile, :file_name) && goodvideo(file)]
    if isempty(files) 
        @warn "found no new unregistered video files…"
        return nothing
    end
    files = selectfiles(files)
    if isempty(files) 
        @warn "no files were selected for registration…"
        return nothing
    end
    registervideos!(files)
    nothing
end
