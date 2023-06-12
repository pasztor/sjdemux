# sjdemux
SJCam &amp; Avidemux related things

## OVerview
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
