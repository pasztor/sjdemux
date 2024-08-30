# CHANGELOG

## 2024.08.30.
* sjmpv - you can pass more than just one file to the "main" player. Distinction: if the first argument is a dir, than it's the soundtrack player, otherwise it will be the main player.
* sjstgen - soundtrack template change to 25fps kdenlive files. Should make it a parameterized thing, but for the time being this will do
* vedit & gpdemux - blank support: see examples/blackgen.sh how to generate a long completely blank black video. That has a small size, fast to copy a stream from. For the gpx2video it doesn't matter if you copy out the real slices, or only provide a blank file, as long as the metadata about the `creation_time` contains the right starting timestamp, and it will generate as many overlay image file, how long the mp4 file is, no matter the content. So, from now on if you provide a `-b blankfile.mp4` to the gpdemux it will rather generate commands to copy that blank file, and only writes input files what you can use to the concat filter's input containing inpoint and outpoint entries. Practically, it's the exact same like you copy out the slices, except you don't have to do that anymore. Less temporary space is needed on the disk. vedit size support also provided: when you run the renderall or the addoverlays functions it will check if the input.txt file is provided. If it is there, it won't consider the mp4 file as the source (that's the small blank file for the gpx2info) but will use the concat filter and that input.txt file as the input video stream.
* added new examples to the examples directory:
  * `mpv.input.conf` - example file for mpv's input.conf. Append that to your ~/.config/mpv/input.conf
  * `examples/2024_0824_S1n001.sh` - another photo display, but this time it has a delay starting from the video slice's starting point as well
  * `examples/blackgen.sh` - example command how to generate a blank file what you can use with the new -b parameter of gpdemux.
  * `examples/imgprep.sh` - playing around with imagemagick to take the picture I've took with my phone: crop, add an overlay text to the photo, and use the exif info's orientation to fix it so ffmpeg will use it the correct orientation as an overlay. The result of this command is used in the `examples/2024_0824_S1n001.sh` param.

## 2024.07.24.
* sjmpv when plays the soundtrack it will append the hwdec=no parameter too to the mpv parameters. Quite useful when the amdgpu driver issues start to hit.
* sjstvol script to change volume on the soundtrack player. With some new input key binding I can change the volume of the soundtrack player from the main player.
* vedit.sh: major improvement on the stream processing/ approach. The fps filter was generating frames with the 4 times speedup like this: 0,1,2, 4, 8, 12, ... This was the reason I could feel some recoil in the videostream at the cutting points. fps filter is completely thrown out from now on. No need to calculate or use the frames anymore for the renderall/addoverlays functions. The new method: use the `select=not(mod(n\,4))` filter expression in the filter chain to drop out 3/4 of the frames in case of a 4 times speedup. Way more efficient, and no more lost frames at the end of the video. Finally ffmpeg now finish the job without an error message. Though no need to calculate, I haven't erased those frame querying parts and to debug print them. But the data is not needed anymore.
* vedit.sh serious improvement on composing the ffmpeg parameter-chain. Uses a bash array to put together the parameters. It's also easier to debug print the used ffmpeg command now before running the actual ffmpeg command. Lot of hooks to provide defaults. So far only the hw-accelerated default-set is transitioned to this new method. But it works just fine with my amdgpu driver. Also, now you can add a video-slice specific or even a video slice/rendering specific sh script to provide defaults. Eg. if you want to overlay in a slow-mo fashion an earlier part of the video, now you can find examples in the example directory. Also there are examples how to display a photo for a few second in case when I stop to take a photo.
  * `examples/2024_0628_S3n000.sh` - example how to overlay a slow-mo part: tpad=... to delay when to display the slomo part, crop to only take a given part of the full picture, than finally the overlay to display that 20 px left and 20 px down from the top left corner.
  * `examples/2024_0628_S3n010.sh` - example to demonstrate to display an image (photo taken at the given time), example to also rescale to fit inside the video
  * `examples/2024_0705_S0n007.sh` - example to add two different slomo into one slice at two different point with two different delay, but cutting the same part of the image (the handlebar)
* added in some earlier developments I used to generate grid videos. Check out the `Healy passs` videos:
  * https://youtu.be/jPNVnNBA_Cw
  * https://youtu.be/iHhHi59tdHI

## 2024.04.17.
* Maybe gopro firmware update changed, but the timestamp in the gopro is gmt, so the Z at the and of the iso8601 timestamp is accurate, but for some reason, gpx2video expects that to be localtime, no matter what is the GMT offset is telling. But the GPX file is still has GMT timestamps. Solution: gpdemux now applies the current timezone's offset to the generated ffmpeg commands.
* sjmpv wrapper takes into consideration, that a file name might reflects that there was no a separate speedup4raw stage
* vedit.sh vedithelp updates
* vedit.sh more verbose on origfr extraction
* vedit.sh nohwaspeedup presets: similar result what you would get with hardware accelerated encoding, but without the hardware acceleration: do the speedup during the encoding phase. Both might need further finetunes. Cuts seems to edgy. With recode first to smaller (expected/4) framerate, the end-result looked more smooth earlier.

## 2024.04.01.
* speedup4hw256re shell function, to speed up the video 4 times faster, but using hw re-encoding. This is just for test. Deprecated, since it reencodes the video stream without doing any useful touch on it, which leads quality decrease. That's 
* hwaccel settings changed: now it does the speed up to 4 times faster, and keeps the original framerate
* ngpfixallvideo shell function to add back the soundtrack to the videos, but it takes into consideration, that the video stream is already 4 times faster, so the audio needs to be speed up as well, not just verbatim copy of the frames. Hence, after the concatall f command, you have a final result, you don't need one more step.

## 2024.03.30.
* hw accelerated encoding: by default the render will now encode the video using hardware accelerated video encode
* Earlier, I found that some frames were missing from the result on the border of the GoPro camera segments. Now that problem is even worse with the hw accelerated render, since that leaves out a few extra more frames from the end of the video. For that, I implemented a workaround in the gpdemux script, so it will concatenate the videos which are on segment borders

## 2024.03.16.
* Removed legacy code from vedit.sh
* Where a function has an sjcam and a gopro specific version as well, the function name now consistently starts with either sj or gp
* vedithelp function updated accordingly

## 2024.02.25.
* gpscan won't fail just print the error when `creation_time` differs between the segments.

## 2024.02.24.
* Speed up editing by adding the LRV file to the avidemux project file, if all the MP4 files in the session have their LRV counterpart
* Also, on the generation of the final result, the gpdemux must replace back the MP4 file in the generated ffmpeg commands

## 2024.02.11.
* A first version of `gpdemux`, which is very similar to the sjdemux, except for the gopro videos. There are a few minor differences how the two should be handled.
* First version of `gpscan`. Same idea here, what I had with sjscan.
* vedit.sh was also updated, so now it has functions for gp-specific things
* sjmpv now only needs one argument. Either the mp4 file, and than the soundtrack's text file name will be derived from that filename, or the dir for the soundtrack media. Because of this change, the alt-p will only work from the main player

## 2024.01.23
* sjscan creates the destination directory if it wasn't pre-existing
* Added stgen to generate a starting project for kdenlive. For documentation, see README.md

## 2023.10.29
* sjplaylist update, so it can generate the playlist from the mlt7 v7.16 based kdenlive files as well
* Several vedit.sh improvements:
  * speedup4raw now has a hevc/h265 version
  * readability improvement in the sjrenderimg() and gentimesh() function
  * new telltimediff function: to query every timediff cut, the time difference: Whenever I am at a point in my ride to replace battery, I start the new session with opening the gpslog app, and filming the gps clock on my phone's display. So if I make a few small cuts from the `YYYY_MMDD_S?u???.py` files, which only contains this few seconds while I'm filming the gps clock, I generate the timediff.sh using the gentimesh function. Than I edit the metadata time, to be the exact same I see on the first frame. Or if the clock change in the first 14 frame, than, whatever timestamp I see in the 15th frame. (Considering 30 fps, and that the ...S?t???.py cut starts at an integer second, and not at a half-second.) Than I run this modified (and not the original generated) timediff.sh. Than I can run the telltimediff, to find out what was the exact difference between the calculated time (which assumes, that the camera's clock are correct), and the corrected gps time. So later, I can use these as the -d parameter for the given segment's diff parameter.
  * new renderallvideo function: A simple for loop to render every fragment video after the images are already rendered. The only parameter it requires, that if I want to render the f series files (or any other).
  * new fixallvideo function: A simple forloop to add the original mp4 files sound stream to the newly rendered video-only files. The only parameter it requires, that if I want to fix the f series files (or any other).
  * new concatall function, to concat all the rendered-fixed videos. The only parameter it requires, that I want to concat the f series of files (or any other).


## 2023.10.22
* Followup with Avidemux 2.8.1, new stub methods was needed to the fake Avidemux class
* Media length is calculated based on video stream's length, not the "format" metadata length. Basing it on the format caused a regression.
* Simplified addoverlay function. After the videos are generated I can still run the replaceaudio on the streams.

## 2023.09.25
* Another redesign of the usage:
  This time, not much change in the tooling, just the way it's used. I do not use gpx2video anymore to render the images onto the video files, I just render the overlay image files, than use ffmpeg to add the overlay onto the video. This way, I can do everything in just one filter_complex session: setting the proper fps on the input so, the unneded frames are dropped early in the chain of filters. Than I can do the overlay. Than the speedup of the video and audio in the same ffmpeg step.
  Running ffmpeg this way takes - give or take - about the same amount of time, what it took previously just to run it to recode the original input stream to drop 3/4 of the frames. Except now there is no extra step needed. The full process is much more simpler now:
  * render the image files
  * add the overlay (and do the dropping, overlay and speedup of video and audio at the same time)
  * concat the fragments
  * add soundtrack

## 2023.08.23
* source option added to sjdemux:
  When the recode to 7.5 fps is done, but the diff between the camera time and the estimated actual time wasn't good enough, I need to recalibrate the metadata of the files, but whole recode is not needed to be done again

## 2023.08.21
* sjplaylist added:
  This tool takes a kdenlive filename, than process its entries, and print them in a canonicalized format, so I could use the output in the description of the uploaded youtube content.
  To be honest, this one saves me a lot of time, and I was kind of lazy to do this development. But after some discussion with a friend called Peter, I decided that I won't procastrinate it any longer.

## 2023.08.14.
* filter option & SJFILTER envvar added:
  With this option, instead of the -codec copy, you can provide a custom filter to be applied on the files.
  My use-case here is: Instead of speeding up the video to 4 times faster later, I just drop the 3/4 of the frames early, so later the gpx2video have to render less frames.
  I already added to my .bashrc this two lines:
  ```
  export SJTZ=Europe/Dublin
  export SJFILTER='-r 7.5 -crf 17'
  ```
* diff-mode added:
  I often forget what was the diff I provided when I ran the sjdemux earlier.
  Using sjdemux in diff-mode will parse the file, but instead printing ffmpeg commads, it presumes the files are already there, just compares the metadata and calulates what -d option was provided for the certain slices. eg. ```sjdemux -D 2023_0814_S0n.py```
* start-time calculation fix:
  Most of the time the start time calculation seems correct. But I found a rather annoying behaviour with SJCam: The last segment of a session which is shorter than the loop time is often not a round second long. In other words its length is not an integer but a float in seconds. But SJCam marks it quite innacurately, according to my calculations. No matter if I run round() or what approximation I try to use, there will be always a video, where a simple formula just doesn't work for a last segment. So I decided to implement a workaround: When a video is not the first in a session, I check if it's calculated start time (creation_time - duration) is before the previous segment's endtime (creation time, as sjcam stores... and approximates). If it is, I just assume, because of the overlap, the length of the overlap is one exact second, and I just substract that one second from the previous segment's endtime. That always gives the exact expected result. When the actual value is overriden, the code will let you know. In theory, you should see this message once per every session, that the override mechanism was applied on the last session.
* CHANGELOG and TODO list added
* help formatting now keeps the linebreaks.
