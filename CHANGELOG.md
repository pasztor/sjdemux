# CHANGELOG

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
