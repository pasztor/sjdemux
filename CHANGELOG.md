# CHANGELOG
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
