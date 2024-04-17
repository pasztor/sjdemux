# sjdemux
SJCam/GoPro &amp; Avidemux related things

## Overview
Open your SJCam recordings in avidemux.
Set both audio and video codec to copy.
You can append segments freely.

Also please Note that, if you set loop time to 10 minutes in your SJCam, than recordings will be 601 seconds long.
There will be one second overlap between your segments. You can easily  remove them in avidemux.
Also, if you start the new scene/cuts on a keyframe, you can remove any parts from your recordings.

Once you are done with editing your project just save your project as a script. It will create a python script.
That python script will be the input of this script.

## Prerequisites
* ffmpeg
* avidemux
* python
* kdenlive

Suggested:

* [gpx2video](https://github.com/progweb/gpx2video)
* [gpslog](https://play.google.com/store/apps/details?id=eu.basicairdata.graziano.gpslogger&authuser=0)

## Usage
This python code emulates a dummy Avidemux class, so you can run that python script using as an argument to the sjdemux command.
Let's say, your camera's clock is 3 seconds in the future, you call the script like this:
```
sjdemux -d -3 -p 2023_0101_S0n script0.py
```
This will print you a set of ffmpeg commands.
That set of ffmpeg commands will result the segments, what you can just simply append with a simple shell function like this:
```
concatvideo () {
        out="$1"
        shift
        tempfile=`TMPDIR=. mktemp`
        for i in "$@" ; do
                echo "file '$i'" >>$tempfile
        done
        cat $tempfile
        ffmpeg -f concat -safe 0 -i $tempfile -c copy "$out"
        rm $tempfile
}

```
Or you can use those segments as input for the [gpx2video](https://github.com/progweb/gpx2video) command.

Note that, gpx2video expects the `creation_time` to point to the timestamp where the video starts.
SJCam set the `creation_time` to the time when the recording of the segment finished.
This script will fix the `creation_time` of the segments too, by subtracting the cut's starting point time difference to the end of the SJCam segment, and also apply your local --diff parameter. (It will always round the microseconds to 0. As far as I've seen, gpx2video doesn't care with that.)

Using this script on your sjcam recordings and with your gpx data eg. from [gpslog](https://play.google.com/store/apps/details?id=eu.basicairdata.graziano.gpslogger&authuser=0), you can make your gps related info as an overlay onto your SJCam recordings.

I've added the [shell functions](vedit.sh) I usually use to the editing steps, with some explanation in there.

# sjscan

I found out recently, that the camera has a loop setting.

If it's turned off, it records 4GiB segments, and usually a 3 second is missing from between the segments.
I guess, the buffering or whatever takes some time and during this there's no more memory to record the new frames.

On the other hand, if I turn on the loop, and set it to 10 minutes, it records segments 10 minutes and 1 second long.
But these 601 second long segments have an overlapping second. Which I haven't even noticed in the first few video. Until my friend Dennis warned me about this overlap.

Than later, I started to append the segments. Jump forward 10 minutes. Cut out the overlapping second. How luck is that, the SJCam makes every 15th frame as a keyframe in the recording, so you can cut out the exact overlapping second.

But that was still an awful lot of work, and needed a lot of attention to append the segments into the sessions, than cut out the overlapping, while it's pretty much a problem which screams for automation. I can do mistakes. The code I wrote won't loose focus.

So, here it is, the new script: sjscan.

I made it flexible as much I felt, any parameters or felxibility might be required, but pretty much, just needs one mandatory argument:
Point it to a directory, where the given recordings are, and it will generate you a bunch of .py scripts, what you can open in avidemux as a project script file, than you can do the editing on it. Save it under some different name. Than you can process the resulted .py file with the sjdemux script, as written above.

So, the program's logic in a nutshell: If the current file's length is shorter than the defined default lenght (600 seconds), than I assume that's the end of the session.
That is the point, where I stopped to drink some water, or at a petrol station, or to wipe off the bugs from my visor.

Now this piece of script generated me the exact results in just a fragment of a second, what I was working on yesterday for at least an hour or half hour long.
And that's just one day's video recording!

# stgen

Another improvement in automating away manual parts of the creative process was that I watched the resulted video, but have to choose what soundtrack goes with the mood.
So, I watched the video, and also, in another tab, I start a tmux where in one window, I run `mpv /soundtrackdir -shuffle -vo null` , helping me suggesting good soundtrack.
If one track ends or about to end, I stop the video, and press enter in the mpv window. If the next song could be a good candidate, than `ctrl-a [` for tmux, put the `Playing: /soundtrackdir/file.webm` line to the clipboard with `ctrl-k`, than switch to the other window, and paste it there into the running `vim YYYY_MMDD_soundtrack.txt`. Than I can switch back, and let the video play resume.
This was the *simple* part.
The boring part part which I amed to automate with this script was when I had to open a new project in kdenlive and add each files to the project bin.

Now just pass the resulting videofile and the `YYYY_MMDD_soundtrack.txt` and it will generate a `YYYY_MMDD_soundtrack.kdenlive`.
In the template / resulting xml, I leave many of the file's metainfo attribute undefined, and let kdenlive deal with it when I open the resulted file.
So, example command I run in my work directory (assuming, that I have a copy of the *sound(track)less* version already in the /store/foto share.
`stgen /store/foto/2023/2023-12-09-Eventname/Work/2023_1209_FNs4.mp4 2023_1209_soundtrack.txt`

Than it will generate the `2023_1209_soundtrack.kdenlive` which I can now open with kdenlive, and I only have to do the creative process by pulling the files from the project bin to the timeline area. (Or whatever is the name of that thing.)

# Overall

The Overall process as of this commit is the following:
- Prerequisites:
  - SJCam recorded files in a given directory, let's call it `/foo`
  - SJCam file naming: `YYYY_MMDD_HHMMSS_NNN.MP4`
  - gpslog recorded file, where the file name looks like as `YYYYMMDD-whatever.gpx`
- Run sjscan:
  - Usually, I do this step directly on the nas.
  - `mkdir /foo/work`
  - `cd /foo/work`
  - My system default on almost every host is the TZ is set to GMT. But in the EU we still have Daylight Saving, so in case of certain command, this default needs to be overriden:
  - `TZ=Europe/Dublin sjscan /foo`
- Open all the `YYYY_MMDD_SNu.py` files one by one in avidemux, and do the editing. The final cut is going to `YYYY_MMDD_SNn.py`
- Try to find out what's the clock difference between the camera and the realtime clock. That's a nasty one. I just default assume, it's 0. I generate the first file, than render it, and try to find out based on the rednered overlay when the speed changes from 0, and when I see the actual movement. As I said, it's a nasty one. Let's say, it's 18 seconds. Now let's create all the fragments for gpx2video: `for i in *.py ; do . <( sjdemux -d 18 $i ) ; done`
- Now go to the VM where I have gpx2video, and start rendering the results:
  - `ssh gpx2videohost`
  - `cd ~/gpx2video/build`
  - In this directory I have the `wk` symlink pointing to the /foo/work directory mounted via nfs from the nas.
  - `. sjrender.sh` - This file's content will go to vedit.sh into the sjrender function
- Now go to my work directory (This steps runs on my desktop with the badass ryzen cpu), and collect gpx2video's results than fix the audio what the gpx2video messed up:
  - `cd ~/Videos/Work-MM-DD-Desc`
  - `rsync -PaHx gpx2videohost:/srv/work/wk .`
  - `cd wk`
  - `for i in *S?n???.mp4 ; do replaceaudio $i /foo/work/$i ; done`
- Now I can do the post-processing:
  - Concatenate the files:
    - `concatvideo YYYY_MMDD_F.mp4 wk/*a.mp4`
  - Speedup to 4 times faster:
    - `speedup4q YYYY_MMDD_F.mp4`
  - Do the soundtrack editing in kdenlive, and export the audio into an mka file.
  - Add the soundtrack to the result:
    - `addsoundtrack YYYY_MMDD_Fs4.mp4 *.mka`
  - Enjoy!
