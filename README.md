# CompleteDung

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.org/yakir12/CompleteDung.jl.svg?branch=master)](https://travis-ci.org/yakir12/CompleteDung.jl)
[![codecov.io](http://codecov.io/github/yakir12/CompleteDung.jl/coverage.svg?branch=master)](http://codecov.io/github/yakir12/CompleteDung.jl?branch=master)

This is a `Julia` script for registering the raw data into a long lasting and coherent data base. 

## How to install
1. If you haven't already, install the current release of [Julia](https://julialang.org/downloads/) -> you should be able to launch it (some icon on the Desktop or some such).
2. Start Julia -> a Julia-terminal popped up.
3. type closed-square-bracket `]` once, you'll see the promt changing from `julia>` to `(v1.1) pkg>`
3. Copy: 
   ```julia
   add https://github.com/yakir12/CompleteDung.jl
   ```
   and paste it in the newly opened Julia-terminal (make sure you ), press Enter (this may take some time), and when it's done press BackSpace (or Delete) until the promt changes back to `julia>`.

## Definitions
- **video-file**: literally a video-file (e.g. `file_name.avi`)
- **fragmented-video**: a video recording that got split into multiple video-files -- it got fragmented. This can happen when the size of the video-file exceeds some set limit and the recording camera decides to split into parts. For example, file "name.MTS" starts at 2018-01-01T12:00:00 and is 10 minutes long, and file "other name.MTS" starts at 2018-01-01T12:10:00. Additionally, you can tell that the video is obviously a continuation of the video in the previous file, "name.MTS", because the stuff that happens in the first file ends abruptly and continues in the next file.
- **whole-video**: a video recording that *did not* get split into multiple video-files -- this is just a single and complete video-file.
- **disjoint-video**: a video recording made of multiple video-files. There can be temporal gaps between each of the takes. This can happen if one run is recorded, then there is a pause where no video is being recorded (the camera might even be off), and then another recording is made. During all this period the camera was not moved and therefore a single calibration is enough. 
- **whole-calibration**: the experimenters recorded one or more runs from one or more experiments, calibrated the camera at some point during that recording, and moved the camera at the end (either without stopping the camera, or after pressing pause/stop). 

## How to run
1. Locate the original videos: Find all of the original `.MTS` video-files if possible.
2. Identify all the video-files (whole, segmented, or disjoint) containing at least one whole-calibration with all of the POIs it is calibrating.

3. Copy the found file/s to the source folder: A new folder was created for you in your home directory (type `homedir()` in the Julia terminal if you're uncertain where your "home directory" is) when you installed this package. The name of this folder is `coffeesource`. Copy the file/s you found in the previous step into this folder. **Always copy one file at a time. If you identified a few files all connected to each other (fragmented- or disjoint-files), then copy all of them together**.
4. Start Julia -> a Julia-terminal popped up.
5. Copy: 
   ```julia
   using CompleteDung
   ```
   and paste it in the newly opened Julia-terminal, press Enter
6. Creation date & time: The program will ask you for the original creation date & time of the video-file (if you copied a few fragmented-files, it will ask only about the first of them; if you copied a disjoint-video then it will ask you about each and every one of them). Determine what the real creation date & time is for the video you copied over. Discovering the creation date & time can be done by either looking at the notes, listening to what people say in the video, looking at the video-file's meta-data, or a combination of all of these methods. 
7. copy-paste `register_video()` into the Julia-terminal: this will guide the registration of all of these video-files you just moved to the source folder.
8. next, copy-paste `register_calibration()` into the Julia-terminal: this will guide you through the registration of each of the whole-calibrations in these newly registered videos.
9. last, copy-paste `register_poi()`: here, we will want to associate each of these calibrations with the POIs they calibrate (note: there is no direct association between a calibration and a run, the calibration is calibrating individual POIs, and the POIs are the ones that are associated with the runs). To help identify which POIs are calibrated by the newly registered calibration, we narrow down the possible POIs by asking you to *first* identify which experiments, and the which runs, contain POIs that are calibrated by this calibration, and *then* to register each of the POIs in the associated runs that are calibrated by that calibration. This will involve specifying *when* in the video-files did each POI occur. So the newly registered video-files contained calibrations we have registered, these calibrations calibrated specific POIs in the video-files, we want to know when in those video-files these POIs occurred.

Note: one option for the `register_poi()` function is to narrow the presented options by specifying which person the data relates to. To include only experiments by, for example, Therese, use this:
```
register_poi(person = "therese")
```


That's basically it. Just repeat the process every time you need to register more videos: copy whole-calibration videos to the `coffeesource` folder → `register_video()` → `register_calibration()` → `register_poi()`.




## Possible configurations of runs, videos, POIs, and calibrations
1. ones run, one video, multiple POIs, and one calibration
```
rrrrrrr 
vvvvvvv 
p ppp p 
ccccccc 
```

2. ones run, segmented video, multiple POIs, and one calibration
```
rrrrrrrr
vvv vvvv
p pppp p
cccccccc
```

3. ones run, segmented video, multiple POIs, and multiple calibrations
```
rrrrrrrrrrrr
vvv vvvvvvvv
p pppp p p p
cccccc ccccc
```

4. multiple runs, segmented video, multiple POIs, and multiple calibrations
```
rrrrrrrrrr rrrrrr
vvv vvvvvv vvv vv
p pppp p p p pppp
cccccc cccccccccc
```

