# The original original way, I've speed up the videos to 4 times faster
# Though, this is already slightly modified, since the `-crf 0` part was not part of this step, nor the keyint.

speedup4o () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	ffmpeg -i "$orig" -filter_complex '[0:v]setpts=0.25*PTS[v];[0:a]atempo=4[a]' -crf 0 -x264-params keyint=30 -map '[v]' -map '[a]' -ac 2 -ar 48000 "$new"
}

# The way I've did the speedup until recently, when the previous steps were this way:
# 1. metadatafix
# 2. gpx2video
# 2/b. fix audio with replaceaudio: After the gpx2video step, the last few seconds in the sounds disappears from the resulted files, so I have to replace the
#      audio channel of the resulted mp4 file with the original mp4 file's audio channel.
# 3. speedup4
# 4. avidemux editing (this is why the keyint is needed. Originally the raw mp4 files from the sjcam every 15th frame is a keyframe, so I could cut at every half second.
#    But with the gpx2video in the line, the keyint was 250, which meant a bit more than 8 seconds between the keyframes, so I tried to compensate this way.
#    But this also wasn't optimal, since this resulted 100+ Gig temporary files.
# 5. smooth30fps
# 6. concat - Because of the large temporary files, I had to process the ride in segments, and do the editing work on the segments. Once I was done with a segment
#    I've deleted the temporary files, and could move to the next segment. (I only have a 1TB nvme ssd in my PN50) And finally, I've could concatenate the segments.
# 7. addsoundtrack

speedup4 () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	ffmpeg -i "$orig" -filter_complex '[0:v]setpts=0.25*PTS[v];[0:a]atempo=4[a]' -r 120 -crf 0 -x264-params keyint=30 -map '[v]' -map '[a]' -ac 2 -ar 48000 "$new"
}


# The speedup4gp is the go-pro version of the speedup4o command. The reason is, the SJcam creates 30fps videos, the GoPro creates 29.97 fps videos.

speedup4gp () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	ffmpeg -i "$orig" -filter_complex '[0:v]setpts=0.25*PTS[v];[0:a]atempo=4[a]' -r 119.88 -crf 0 -x264-params keyint=30 -map '[v]' -map '[a]' "$new"
}

# One of the ideas to improve the processing was to make the speedup and the smoothening in one step.
# For this, I have to do the avidemux cut part first.
# In order to do that, I have to have the gazillion little mp4 chunks (called segments in the avidemux .py scripts) with fixed metadata
# That's why I have the sjdemux command. The improved way:
# 1. avidemux (I still do segments, since the camera's datetime could be different after a battery replacement, which needs a the -d parameter
#    to be adjusted in the sjdemux command
# 2. sjdemux to fix the metadata
# 3. gpx2video
# 3/b. replaceaudio (to fix the gpx2video's result's audio channel)
# 4. speedup4i
# 5. concatvideo
# 6. addsoundtrack

speedup4i () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	ffmpeg -i "$orig" -filter_complex "[0:v]setpts=0.25*PTS,minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=30'[v];[0:a]atempo=4[a]" -crf 18 -map '[v]' -map '[a]' -ac 2 -ar 48000 "$new"
}

# Another idea to improve the processing was to leave out the interpolate filter, just like it was in the old ways, BUT
# This time I also use the -crf parameter, making sure the resulting video quality is good enough.
# I called this speedup4q, because it's much quicker than the speedup4 or the speedup4i approach.
# This way, the processing means the following:
# 1. avidemux To get the .py files
# 2. sjdemux To get the gazillion .mp4 files with their metadata fixed
# 3. gpx2video
# 3/b. replaceaudio (to fix the gpx2video's result's audio channel)
# 4. seedup4q
# 5. concatvideo
# 6. addsoundtrack

speedup4q () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	ffmpeg -i "$orig" -filter_complex "[0:v]setpts=0.25*PTS[v];[0:a]atempo=4[a]" -r 30 -crf 18 -map '[v]' -map '[a]' -ac 2 -ar 48000 "$new"
}

# Originally, when the speedup resulted a 120 or 119.88 fps video, I've smoothened it down to only 60fps. But YouTube tries to fit the videos into a certain bandwidth.
# If the bandwith is the same, but you have 60fps video, that means, you have half the amount of data to store information about a frame compared to a 30fps video.
# So, finally, I've decided to upload 30fps videos to youtube.

smooth60fps () {
	orig="$1"
	new="${orig%.mp4}s60.mp4"
	ffmpeg -i "$orig" -c:a copy -filter:v "minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=60'" -crf 18 "$new"
}

smooth30fps () {
	orig="$1"
	new="${orig%.mp4}s30.mp4"
	ffmpeg -i "$orig" -c:a copy -filter:v "minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=30'" -crf 18 "$new"
}

addsoundtrack () {
	orig="$1"
	strack="$2"
	new="${orig%.mp4}f.mp4"
	ffmpeg -i "$orig" -i "$strack" -c:v copy -map 0:v:0 -filter_complex "[0:a][1:a]amerge=inputs=2,pan=stereo|c0<c0+c2|c1<c1+c3[a]" -map "[a]" "$new"
}

extractaudio () {
	orig="$1"
	if [ $# -gt 1 ] ; then
		dest="$2"
	else
		dest="${orig%.*}.aac"
	fi
	ffmpeg -i "$orig" -vn -acodec copy "$dest"
}

replaceaudio () {
	orig="$1"
	if [ $# -gt 1 ] ; then
		audio="$2"
	else
		audio="${orig%.*}.aac"
	fi
	if [ $# -gt 2 ] ; then
		dest="$3"
	else
		dest="${orig%.*}a.${orig##*.}"
	fi
	ffmpeg -i "$orig" -i "$audio" -c:v copy -c:a copy -map 0:v:0 -map 1:a:0 "$dest"
}

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
