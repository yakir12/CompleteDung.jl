tonanosecond(x) = Nanosecond(round(Int, parse(Float64, x)*1e9))

function parsetime(x)
    xs = split(x, ':')
    n = length(xs)
    if n == 1
        tonanosecond(x)
    elseif n == 2
        Nanosecond(Minute(xs[1])) + tonanosecond(xs[2])
    else
        Nanosecond(Hour(xs[1])) + Nanosecond(Minute(xs[2])) + tonanosecond(xs[3])
    end
end

function goodtime(x)
    try
        return parsetime(x)
    catch
        return nothing
    end
end

function getstart_video_i(video_menu, videofile)
    i = request("In which video file did this POI start?", video_menu)
    if i == 1
        i = findlast(isequal(video_menu.options[1]), video_menu.options)
    end
    i - 1
end

function get_time(videofile, vf, type)
    @label beginning
    println("When in this video file did this POI ", type,"?\n[Enter: ", Time(0) + defaults[:startstop], "]")
    __time = strip(readline())
    if !isempty(__time)
        tmp = goodtime(__time)
        if tmp ≡ nothing
            println("Malformed time. Try again…")
            @goto beginning
        end
        if tmp > vf.duration
            println("Specified time is longer than the duration of this video file (", Time(0) + vf.duration, "). Try again…")
            @goto beginning
        end
        defaults[:startstop] = tmp
    end
    _time = defaults[:startstop]
    reduce(+, [x.duration for x in videofile if x.video == vf.video && x.index < vf.index], init = _time) 
end

function getstop(videofile, start_video, start)
    videos = filter(x -> x.video == start_video.video && x.index ≥ start_video.index, videofile, select = (:video, :index))
    stop_video = if length(videos) > 1
        options = string.(select(videos, :file_name))
        pushfirst!(options, defaults[:videofile])
        video_menu = RadioMenu(options)
        # @label stop_poi
        i = request("In which video file did this POI stop?", video_menu)
        if i == 1
            i = findlast(isequal(video_menu.options[1]), video_menu.options)
        end
        videos[i - 1]
        #=if videoID ≠ stop_video.video
            v1 = select(filter(isequal(videoID), videofile, select = :video), :file_name)
            v2 = select(filter(isequal(stop_video.video), videofile, select = :video), :file_name)
            println("These two videos do not belong to the same group. Videos related to the starting video are:")
            println.(v1)
            println("and videos related to the stoping one are:")
            println.(v2)
            println("Choose again…")
            @goto stop_poi
        end=#
    else
        videos[1]
    end
    @label stop_time
    stop = get_time(videofile, stop_video, "stop")
    if stop < start
        println("Stoping time cannot come before starting time. Try again…")
        @goto stop_time
    end
    stop
end

function getinterval()
    files = [joinpath(datadep"coffeebeetle", "interval.csv"), new_interval_file_name]
    interval = if length(CSV.File(complete_interval_file_name)) > 0
        interval = loadndsparse(files, indexcols = [:interval])
        complete_interval = loadndsparse(complete_interval_file_name, indexcols = [:interval])
        table(merge(interval, complete_interval, agg = (l,r) -> r))
    else
        loadtable(files, indexcols = [:interval])
    end
    setcol(interval, :interval => :interval => UUID, :video => :video => x -> isempty(x) ? missing : UUID(x), :start => :start => x -> ismissing(x) ? missing : Nanosecond(x), :stop => :stop => x -> ismissing(x) ? missing : Nanosecond(x), :comment => :comment => x -> ismissing(x) ? "" : x)
end

function _register_interval(ask_stop::Bool)
    _, videofile = getvideodb()
    defaults[:videofile] = videofile[1].file_name
    options = string.(select(videofile, :file_name))
    pushfirst!(options, defaults[:videofile])
    video_menu = RadioMenu(options)

    # @label start_point
    start_video_i = getstart_video_i(video_menu, videofile)
    start_video = videofile[start_video_i]
    defaults[:videofile] = start_video.file_name
    start = get_time(videofile, start_video, "start")
    videoID = start_video.video
    stop = ask_stop ? getstop(videofile, start_video, start) : start

    println("Comments about this specific time interval?\n[Enter: ", defaults[:interval_comment], " ]")
    _comment = strip(readline(stdin))
    if !isempty(_comment)
        defaults[:interval_comment] = _comment
    end
    comment = defaults[:interval_comment]
    (video = videoID, start = start, stop = stop, comment = comment)
end

function register_interval(ask_stop::Bool)
    intervalID = uuid4()
    interval = getinterval()
    while intervalID ∈ select(interval, :interval)
        intervalID = uuid4()
    end
    videoID, start, stop, comment = _register_interval(ask_stop)
    [(interval = intervalID, video = videoID, start = Dates.value(start), stop = Dates.value(stop), comment = comment)] |> CSV.write(new_interval_file_name, append = true)
    intervalID
end

function register_interval(ask_stop::Bool, intervalID::UUID)
    videoID, start, stop, comment = _register_interval(ask_stop)
    [(interval = intervalID, video = videoID, start = Dates.value(start), stop = Dates.value(stop), comment = comment)] |> CSV.write(complete_interval_file_name, append = true)
    intervalID
end


