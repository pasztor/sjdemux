# The original original way, I've speed up the videos to 4 times faster
# Though, this is already slightly modified, since the `-crf 0` part was not part of this step, nor the keyint.

# Note to self:
# Working hwaccel video encode cmdline:
# ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi -i input.mp4 -c:v hevc_vaapi -c:a copy -crf 23 output.mp4
#encode_options="-hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi"

hwaccel () {
	encode_options="-vaapi_device /dev/dri/renderD128"
	output_codec="hevc_vaapi"
	post_overlay_filter=",format=yuv420p,hwupload,scale_vaapi=format=nv12"
	quality_param="-qp 22"
}

nohwaccel () {
	encode_options=""
	output_codec=libx265
	post_overlay_filter=""
	quality_param="-crf 22"
}

hwaccel

# Timing comparison for hwaccel encode of a slice:
# real	1m54.532s
# user	20m37.154s
# sys	0m15.613s
# 
# Same file encodced with nohwaccel:
# real	6m1.411s
# user	89m28.432s
# sys	0m10.091s

#ovlext=png
ovlext=tiff

speedup4raw265af () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	tempfile=raw.h265
	ffmpeg -i "$orig" -map 0:v -c:v copy -bsf:v hevc_mp4toannexb "$tempfile"
	ffmpeg -fflags +genpts -r 30 -i "$tempfile" -i "$orig" -map 0:v -c:v copy -map 1:a -af atempo=4 -ar 48000 -ac 2 -movflags -faststart "$new"
	rm "$tempfile"
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

# This is actually a separate script file in the build directory of gpx2video.
# In the build directory I keep a symlink named wk pointing to the directory
# I am actually working with.
sjrender () {
	for i in wk/202*.mp4 ; do
		if [ -r /srv/work/$i ]; then
			:
		else
			TZ=Europe/Dublin ./gpx2video -v -m $i -g ${i%n???.mp4} -l layout.xml -o /srv/work/$i  video
		fi
	done
}

#
# Newest version of things as of 2023-09-26
# NB: SJFILTER is now empty again, simple copy happens during sjdemux runs.
#
sjrenderimg () {
for i in wk/202*.mp4 ; do
	fn="${i##*/}"
	if [ -r wko/${fn%.mp4}-f0000.$ovlext ]; then
		:
	else
		gpx="`(ls -1 ${i:0:15}*.gpx ; ls -1 wk/*.gpx ) | head -1 `"
		echo prcessing $i - $gpx
		echo " ./gpx2video -v -m $i -g $gpx -l layout.xml -o wko/${fn%.*}-fXXXX.png image"
		TZ=Europe/Dublin ./gpx2video -v -m $i -g $gpx -l layout.xml -o wko/${fn%.*}-fXXXX.png image
	fi
done
}

# And the magic happens here:
addoverlay () {
	orig="$1"
	ovl="$2"
	origffn="${orig##*/}"
	origfno="${origffn%.*}"
	ffmpeg -i "$orig" \
		-r 1 -i "${origfno}-${ovl}%04d.$ovlext" \
		-filter_complex '[0:v]fps=7.5[bg];[1:v]fps=7.5[ovl];[bg][ovl]overlay[ov];[ov]setpts=0.25*PTS[v];[0:a]atempo=4[a]' \
		-r 30 -map '[v]' -map '[a]' -c:v libx265 -crf 22 \
		-ac 2 -ar 48000 \
		-force_key_frames 'expr:gte(t,n_forced*10)' \
		"${origfno}${ovl}.mp4"
}

# So, practically, I just needs to go into wko dir, and run
# for i in ../wk/*.mp4 ; do addoverlay $i f ; done
# Than concat all the pieces together: concatvideo 2023_MMDD_FOs4.mp4 2023_MMDD_S?n???f.mp4
# And finally, the soundtrack can came.
# This is now uses the least amount of cpu, the best codecs, the less amount of intermediate steps and storing intermediate files, etc.
# With this trick, I probably won't even need to separate the wk and wko dir anymore as the mp4 segments won't overlap, and no more audio fixing is needed.

# ^ This approach wasn't exactly precise with the audio. Somehow it always caused some skew, so I went back to the basics:
# Render the video and the audio in separate streams, so here comes add overlay simplified

addoverlays () {
	orig="$1"
	ovl="$2"
	origffn="${orig##*/}"
	origfno="${origffn%.*}"
	vframes=`ffprobe -of json -show_entries stream "$orig" 2>/dev/null | jq '.streams[0].nb_frames' | tr -d '"' `
	aframes=`ffprobe -of json -show_entries stream "$orig" 2>/dev/null | jq '.streams[1].nb_frames' | tr -d '"' `
		#-frames:a $aframes -frames:v $[(vframes+3)/4] \
		#-filter_complex '[0:v][1:v]overlay[vo];[0:a]apad[ao]' \
		#-r 7.5  -map '[vo]' -map '[ao]' -c:v libx265 -crf 22 \
	time ffmpeg $encode_options -i "$orig" \
		-r 1 -i "${origfno}-${ovl}%04d.$ovlext" \
		-filter_complex "overlay${post_overlay_filter}" \
		-r 7.5  -an -c:v $output_codec $quality_param \
		"${origfno}${ovl}.mp4"
		#-frames:v $[(vframes+3)/4] \
}

sjgentimesh () {
	for i in 202?_????_S?t.py ; do
		sjdemux -d 0 $i ;
	done >timediff.sh
}

gpgentimesh () {
	for i in 202?_????_S?t.py ; do
		gpdemux -d 0 $i ;
	done >timediff.sh
}

sjtelltimediffs () {
	for i in 202?_????_S??.py ; do sjdemux -D $i ; done
}

gptelltimediffs () {
	for i in 202?_????_S??.py ; do gpdemux -D $i ; done
}

renderallvideo () {
	# So, if the work dir, where the images were generated is /store/vedit/WKO.0903
	# Than sourcedir is /store/vedit/WK.0903
	renderext="$1"
	sourcedir="${PWD%?.*}.${PWD##*.}"
	for i in ${sourcedir}/*.mp4 ; do
		addoverlays "$i" "$renderext"
	done
}

sjfixallvideo () {
	sourcedir="${PWD%?.*}.${PWD##*.}"
	renderext="$1"
	for i in ${sourcedir}/*.mp4 ; do
		fn="${i##*/}"
		if [ -r "${fn%.mp4}${renderext}a.mp4" ] ; then
			:
		else
			replaceaudio "${fn%.mp4}${renderext}.mp4" $i
		fi
	done
}

gpfixallvideo () {
	sourcedir="${PWD%?.*}.${PWD##*.}"
	renderext="$1"
	for i in ${sourcedir}/*.mp4 ; do
		fn="${i##*/}"
		destfn="${fn%.mp4}${renderext}a.mp4"
		vidf="${fn%.mp4}${renderext}.mp4"
		vduration=`ffprobe -of json -show_entries stream "$vidf" 2>/dev/null | jq '.streams[0].duration' | tr -d '"' `
		if [ -r "$destfn" ] ; then
			:
		else
			ffmpeg -i "$vidf" -i "$i" -c:v copy -c:a copy -map 0:v:0 -map 1:a:0 -t $vduration "$destfn"
		fi
	done
}

concatall () {
	renderext="$1"
	ucrenderext="$( echo -n $renderext | tr a-z A-Z )"
	fnprefix="$( ls -1 *mp4 | head -1 | cut -c 1-9 )"
	concatvideo ${fnprefix}_${ucrenderext}N.mp4 ${fnprefix}_S?n???${renderext}a.mp4
}

cleanupallvids () {
	rm *mp4 *png *tiff
}

vedithelp () {
	cat <<END
# generates timediff.sh
[ sjgentimesh | gpgentimesh ]

# Generates the timeing files
. timediff.sh

# Update the timestamp to the time in the clock on the video
vim timediff.sh

# Rerun timediff.sh
. timediff.sh

# To find out the differences
[ sjtelltimediffs | gptelltimediffs ]

# Create work.sh, update the i's, the diff (-d) and the date accordingly
echo 'for i in 0 1 2 ; do . <( sjdemux -d -XX 1970_0101_S0n.py )' >>work.sh
echo 'for i in 0 1 2 ; do . <( gpdemux -d -XX 1970_0101_S0n.py )' >>work.sh

# Generate the of videos
. work.sh

#### Now, run these in the gpx2video build dir:
# The example sjrenderimg function uses the "f" renderext.
# Now go to the wko dir:
sjrenderimg

# Now go to your "wko" directory:
renderallvideo f
[ sjfixallvideo f | gpfixallvideo f ]

concatall f
speedup4raw265af 1970_0101_FN.mp4
addsoundtrack 1970_0101_FNs4.mp4 *mka
END
}
