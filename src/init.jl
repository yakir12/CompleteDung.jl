function __init__()
    ENV["DATADEPS_ALWAYS_ACCEPT"] = true
    register(DataDep("coffeebeetle", "The coffee beetle database", "https://s3.eu-central-1.amazonaws.com/vision-group-file-sharing/Data%20backup%20and%20storage/Yakir/coffee%20beetles/database.zip", "1d82fbbebad76c3c3a0735e9d181cc208119b136903bb73e085c6683a3d1ff2f", post_fetch_method = unpack))

    if !isdir(sourcefolder)
        @info "creating the source folder" coffeesource
        mkpath(sourcefolder)
    end


    file2columns = Dict(video_file_name => (:video,:comment), videofile_file_name => (:file_name,:video,:date_time,:duration,:index), board_file_name => (:designation,:checker_width_cm,:checker_per_width,:checker_per_height,:board_description), calibration_file_name => (:calibration,:intrinsic,:extrinsic,:board,:comment), new_interval_file_name => (:interval,:video,:start,:stop,:comment), complete_interval_file_name => (:interval,:video,:start,:stop,:comment), complete_poi_file_name => (:poi,:type,:run,:calibration,:interval))

    for (file, colnames) in file2columns
        if !isfile(file)
            open(file, "w") do io
                println(io, join(colnames, ','))
            end
        end
    end


end
