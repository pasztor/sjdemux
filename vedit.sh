# The original original way, I've speed up the videos to 4 times faster
# Though, this is already slightly modified, since the `-crf 0` part was not part of this step, nor the keyint.

# Note to self:
# Working hwaccel video encode cmdline:
# ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi -i input.mp4 -c:v hevc_vaapi -c:a copy -crf 23 output.mp4
#encode_options="-hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi"

defaults () {
	d_speedup=4
	d_ac=2
	d_ar=48000
	d_ovlext=tiff
}

hwaccel () {
	declare -a encode_options=( "-vaapi_device" "/dev/dri/renderD128" )
	output_codec="hevc_vaapi"
	post_overlay_filter=",setpts=0.25*PTS,format=yuv420p,hwupload,scale_vaapi=format=nv12"
	#pre_overlay_filter="[0:v]fps=@rfr[0v];[0v][1:v]"
	pre_overlay_filter=""
	quality_param="-qp 22"
	outfr=origfr
	#outfr=''
	#amap='-map [v] -map [a] -ac 2 -ar 48000'
	amap='-an'
}

hwaccelng () {
	encode_options=( "-vaapi_device" "/dev/dri/renderD128" )
	output_codec=( "-c:v" "hevc_vaapi" )
	post_overlay_filter=( "setpts=PTS/@sup@" "format=yuv420p" "hwupload" "scale_vaapi=format=nv12" )
	#pre_overlay_filter="[0:v]fps=@rfr[0v];[0v][1:v]"
	#post_overlay_filter+=( "setpts=PTS/@sup@" "format=yuv420p" "hwupload" "scale_vaapi=format=nv12" )
	pre_overlay_filter='[0:v]select=not(mod(n\,4))[0v]'
	d_overlay_filter_input='0v'
	#pre_overlay_filter+=( 'select=not(mod(n\,@sup@))' )
	quality_param=( "-qp" "22" )
	overlay_filter='overlay'
	outfr=origfr
	#outfr=''
	#amap='-map [v] -map [a] -ac 2 -ar 48000'
	#amap='-an'
	duration_params=( '-frames:v' '@outvframes@' '-t' '@outduration@' )
	d_audio_filter=( '[0:a]atempo=@sup@[a]' )
	audio_map=( "-map" "[a]" '-ac' "$d_ac" "-ar" "$d_ar" )
	fnsuffix='a'
}

nohwaccel () {
	encode_options=""
	output_codec=libx265
	post_overlay_filter=""
	pre_overlay_filter=""
	quality_param="-crf 22"
	outfr='-r 7.5'
	amap='-an'
}

nohwaspeedup () {
	encode_options=""
	output_codec=libx265
	post_overlay_filter=",setpts=0.25*PTS"
	pre_overlay_filter=""
	quality_param="-crf 22"
	outfr=origfr
	amap='-an'
}

# Highly experimental. Not working yet.
# Just for testing the ideas, I've got on ffmpeg-users from Chen, Wenbin
#
fhwaccel () {
	encode_options="-hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi"
	#encode_options="$encode_options -vaapi_device /dev/dri/renderD128"
	output_codec="hevc_vaapi"
	pre_overlay_filter="[0:v]hwdownload[0v];[0v][1:v]"
	post_overlay_filter=",format=yuv420p,hwupload,scale_vaapi=format=nv12"
	quality_param="-qp 22"
	outfr='-r 7.5'
	amap='-an'
}

defaults
hwaccelng

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

speedup4raw265af () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	tempfile=raw.h265
	ffmpeg -i "$orig" -map 0:v -c:v copy -bsf:v hevc_mp4toannexb "$tempfile"
	ffmpeg -fflags +genpts -r 30 -i "$tempfile" -i "$orig" -map 0:v -c:v copy -map 1:a -af atempo=4 -ar 48000 -ac 2 -movflags -faststart "$new"
	rm "$tempfile"
}

speedup4hw265re () {
	orig="$1"
	new="${orig%.*}s4.mp4"
	ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi \
		-i "$orig" \
		-filter_complex '[0:v]setpts=0.25*PTS[v];[0:a]atempo=4[a]' \
		-map '[v]' -map '[a]' \
		-r 30 -c:v hevc_vaapi -qp 22 "$new"
	#ffmpeg -vaapi_device /dev/dri/renderD128 -i "$orig" -filter_complex '[0:v]setpts=0.25*PTS,hwupload,scale_vaapi=format=nv12[v];[0:a]atempo=4[a]' -r 30 -map '[v]' -map '[a]' -c:v hevc_vaapi -qp 22 "$new"
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
	if [ -r wko/${fn%.mp4}-f0000.$d_ovlext ]; then
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
		-r 1 -i "${origfno}-${ovl}%04d.$d_ovlext" \
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
	local orig="$1"
	local ovl="$2"
	local origffn="${orig##*/}"
	local origfno="${origffn%.*}"
	local origit="${orig%.*}.input.txt"
	local l_speedup="${d_speedup}"
	local -a l_input
	local -a l_pre_pre_overlay_filter
	local -a l_post_pre_overlay_filter
	local -a l_pre_post_overlay_filter
	local -a l_post_post_overlay_filter
	local -a l_duration_params=( "${duration_params[@]}" )
	local l_overlay_filter_input="$d_overlay_filter_input"
	local l_ovlext="$d_ovlext"
	local -a ffmpeg_params
	local -a ffmpeg_filters
	local -a l_post_overlay_chain
	local l_post_overlay_filter_input='1v'
	local -a l_outfr=( "${d_outfr[@]}" )
	local -a l_audio_filter=( "${d_audio_filter[@]}" )
	local vframes=`ffprobe -of json -show_entries stream "$orig" 2>/dev/null | jq '.streams[0].nb_frames' | tr -d '"' `
	local aframes=`ffprobe -of json -show_entries stream "$orig" 2>/dev/null | jq '.streams[1].nb_frames' | tr -d '"' `
	echo orgfr cmd: ffprobe -of json -show_entries stream "$orig" 2>/dev/null \| jq '.streams[0].r_frame_rate' \| tr -d '"'
	local origfr=`ffprobe -of json -show_entries stream "$orig" 2>/dev/null | jq '.streams[0].r_frame_rate' | tr -d '"' `
	echo "origfr: $origfr"
	local origdir="${orig%/*}"
	local rfr=`printf 'scale=4\n%s/4\n' "$origfr" | bc `
		#-frames:a $aframes -frames:v $[(vframes+3)/4] \
		#-filter_complex '[0:v][1:v]overlay[vo];[0:a]apad[ao]' \
		#-r 7.5  -map '[vo]' -map '[ao]' -c:v libx265 -crf 22 \
		#-frames:v $[(vframes+3)/4] \
	[ "$l_outfr" = 'origfr' ] && l_outfr="$origfr"
	if [ -r "${origfno}.sh" ]; then
		. "${origfno}.sh"
	fi
	if [ -r "${origfno}-${ovl}.sh" ]; then
		. "${origfno}-${ovl}.sh"
	fi
	local outvframes=$[(vframes+l_speedup-1)/l_speedup]
	local outduration=`printf 'scale=3\n%s/(%s)\n' "$outvframes" "$origfr" | bc `
	[ "${outduration:0:1}" == "." ] && outduration="0$outduration"
	echo vframes: $vframes aframes: $aframes outtvframes: $outvframes outduration: $outduration
	l_duration_params=( "${l_duration_params[@]//@outvframes@/$outvframes}" )
	l_duration_params=( "${l_duration_params[@]//@outduration@/$outduration}" )
	local outfn="${origfno}${ovl}${fnsuffix}.mp4"
	ffmpeg_params+=( "${encode_options[@]}" )
	if [ -r "$origit" ];
	then
		[ -r "$outfn" ] || ffmpeg -f concat -safe 0 -i "$origit" -c copy temp.mp4
		#ffmpeg_params+=( "-f" "concat" "-safe" "0" "-i" "$origit" )
		ffmpeg_params+=( "-i" "temp.mp4" )
	else
		ffmpeg_params+=( "-i" "$orig" )
	fi
	ffmpeg_params+=( "-r" "1" "-i" "${origfno}-${ovl}%04d.${d_ovlext}" )
	ffmpeg_params+=( "${l_input[@]}" )
	ffmpeg_filters+=( "${l_pre_pre_overlay_filter[@]}" )
	ffmpeg_filters+=( "${pre_overlay_filter}" )
	ffmpeg_filters+=( "${l_post_pre_overlay_filter[@]}" )
	ffmpeg_filters+=( "[${l_overlay_filter_input}][1:v]${overlay_filter}[1v]" )
	l_post_overlay_chain+=( "${l_pre_post_overlay_filter[@]}" )
	l_post_overlay_chain+=( "${post_overlay_filter[@]}" )
	l_post_overlay_chain+=( "${l_post_post_overlay_filter[@]}" )
	local l_post_overlay_filter=''
	for i in "${!l_post_overlay_chain[@]}" ; do
		if [ "$i" == "0" ]; then
			l_post_overlay_filter+='[1v]'
		else
			l_post_overlay_filter+=','
		fi
		l_post_overlay_filter+="${l_post_overlay_chain[i]}"
	done
	ffmpeg_filters+=( "${l_post_overlay_filter}" )
	ffmpeg_filters+=( "${l_audio_filter[@]}" )
	local ffmpeg_filter_expression=''
	for i in "${!ffmpeg_filters[@]}" ; do
		[ "$i" != "0" ] && ffmpeg_filter_expression+=';'
		ffmpeg_filter_expression+="${ffmpeg_filters[i]}"
	done
	ffmpeg_filter_expression="${ffmpeg_filter_expression//@sup@/$l_speedup}"
	ffmpeg_params+=( "-filter_complex" "$ffmpeg_filter_expression" )
	ffmpeg_params+=( "${l_outfr[@]}" )
	ffmpeg_params+=( "${audio_map[@]}" )
	ffmpeg_params+=( "${l_duration_params[@]}" )
	ffmpeg_params+=( "${output_codec[@]}" )
	ffmpeg_params+=( "${quality_param[@]}" )
	ffmpeg_params+=( "${outfn}" )

	echo ffmpeg "${ffmpeg_params[@]}"
	[ -r "${outfn}" ] || time ffmpeg "${ffmpeg_params[@]}"

	if [ -r "$origit" ];
	then
		rm temp.mp4
	fi
#	echo ffmpeg $encode_options -i "$orig" \
#		-r 1 -i "${origfno}-${ovl}%04d.$ovlext" \
#		$l_input \
#		-filter_complex "${l_pre_pre_overlay_filter}${pre_overlay_filter//@rfr/$rfr}${l_post_pre_overlay_filter}overlay${l_pre_post_overlay_filter}${post_overlay_filter}${l_post_post_overlay_filter}" \
#		${outfr}  $amap -c:v $output_codec $quality_param \
#		"${origfno}${ovl}.mp4"
#	[ -r "${origfno}${ovl}.mp4" ] || time ffmpeg $encode_options -i "$orig" \
#		-r 1 -i "${origfno}-${ovl}%04d.$ovlext" \
#		$l_input \
#		-filter_complex "${l_pre_pre_overlay_filter}${pre_overlay_filter//@rfr/$rfr}${l_post_pre_overlay_filter}overlay${l_pre_post_overlay_filter}${post_overlay_filter}${l_post_post_overlay_filter}" \
#		${outfr}  $amap -c:v $output_codec $quality_param \
#		"${origfno}${ovl}.mp4"
}

sjgentimesh () {
	for i in 202?_????_S?t.py ; do
		sjdemux -d 0 $i ;
	done >timediff.sh
}

gpgentimesh () {
	for i in 202?_????_S?t.py ; do
		SJBLANK= gpdemux -d 0 $i ;
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

speedup4hwrender () {
	vin="$1"
	vfn="${vin##*/}"
	vout="${vfn%.mp4}f.mp4"
	ffmpeg -vaapi_device /dev/dri/renderD128 -i $vin -filter_complex setpts=0.25*PTS,format=yuv420p,hwupload,scale_vaapi=format=nv12 -r 30/1 -an -c:v hevc_vaapi -qp 22 $vout
}

addoverlaysgrid () {
	vin="$1"
	vfn="${vin##*/}"
	ovl="${vfn%.mp4}"
	vout="${vfn%.mp4}f.mp4"
	ffmpeg -vaapi_device /dev/dri/renderD128 -i $vin -r 1 -i "${ovl}"-f%04d.tiff -filter_complex overlay,setpts=0.25*PTS,format=yuv420p,hwupload,scale_vaapi=w=1920:h=1080:format=nv12 -r 30/1 -an -c:v hevc_vaapi -qp 22 "$vout"
}

gridrender () {
	vout="$1"
	v0="$2"
	v1="$3"
	v2="$4"
	v3="$5"
	ffmpeg -i "$v0" -i "$v1" -i "$v2" -i "$v3" -vaapi_device /dev/dri/renderD128 -filter_complex '[0:a][1:a][2:a][3:a]amerge=inputs=4,pan=stereo|c0<c0+c2|c1<c4+c6[a];[0:v]crop=h=1080:y=0[0v];[1:v]crop=h=1080:y=0[1v];[2:v]crop=h=1080:y=0[2v];[3:v]crop=h=1080:y=0[3v];[0v][1v][2v][3v]xstack=inputs=4:layout=0_0|0_h0|w0_0|w0_h0,format=yuv420p,hwupload,scale_vaapi=format=nv12' -c:v hevc_vaapi -map '[a]' -qp 22 "$vout"
}

gridrenderallvideo () {
	# So, if the work dir, where the images were generated is /store/vedit/WKO.0903
	# Than sourcedir is /store/vedit/WK.0903
	gvout="$1"
	sourcedir="${PWD%?.*}.${PWD##*.}"
	for i in ${sourcedir}/*.mp4 ; do
		vfn="${i##*/}"
		if [ -r "${vfn%.mp4}-f0000.$ovlext" ]; then
			addoverlaysgrid "$i"
		else
			speedup4hwrender "$i"
		fi
	done
	ngpfixallvideo f
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

ngpfixallvideo () {
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
			ffmpeg -i "$vidf" -i "$i" -c:v copy -map 0:v:0 -af atempo=4 -ar 48000 -ac 2 -map 1:a:0 -t $vduration "$destfn"
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
[ sjfixallvideo f | gpfixallvideo f | ngpfixallvideo f ]

concatall f
speedup4raw265af 1970_0101_FN.mp4 # Skip this with hwaccel generated defaults
sjmpv 1970_0101_??.mp4 & sjmpv /path/to/your/soundtrack/dir
sjstgen 1970_0101_??.mp4 1970_0101_soundtrack.txt
# here comes the soundtrack composition work in kdenlive
addsoundtrack 1970_0101_FNs4.mp4 *mka
sjplaylist *kdenlive >>1970_0101_description.txt
END
}
