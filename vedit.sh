# The original original way, I've speed up the videos to 4 times faster
# Though, this is already slightly modified, since the `-crf 0` part was not part of this step, nor the keyint.

# Working hwaccel video encode cmdline:
# ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi -i input.mp4 -c:v hevc_vaapi -c:a copy -crf 23 output.mp4
#encode_options="-hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi"

defaults () {
	d_speedup=4
	d_ac=2
	d_ar=48000
	d_ovlext=tiff
	ovlsrcdir=fsrc
	ovldstdir=fovl
	uncutprefix=u
}

preview_on() {
	post_scale='w=1280:h=720:'
}

preview_off() {
	post_scale=''
}

denoise_on() {
       pre_overlay_filter='[0:v]select=not(mod(n\,@sup@)),hqdn3d[0v]'
}

denoise_off() {
       pre_overlay_filter='[0:v]select=not(mod(n\,@sup@))[0v]'
}

hwaccelng () {
	encode_options=( "-vaapi_device" "/dev/dri/renderD128" )
	output_codec=( "-c:v" "hevc_vaapi" )
	post_scale=''
	post_overlay_filter=( "setpts=PTS/@sup@" "format=yuv420p" "hwupload" "scale_vaapi=@psc@format=nv12" )
	post_overlay_filter_psc=( )
	pre_overlay_filter='[0:v]select=not(mod(n\,@sup@))[0v]'
	d_overlay_filter_input='0v'
	quality_param=( "-qp" "22" )
	overlay_filter='overlay'
	outfr=origfr
	#duration_params=( )
	d_audio_filter=( '[0:a]atempo=@sup@[a]' )
	d_audio_filter_out='a'
	d_audio_map=( "-map" "[@afa@]" '-ac' "$d_ac" "-ar" "$d_ar" )
	fnsuffix='a'
}

nohwaccel () {
	encode_options=( )
	output_codec=( "-c:v" "libx265" )
	post_scale=''
	post_overlay_filter=( "setpts=PTS/@sup@" )
	post_overlay_filter_psc=( "scale=@psc@" )
	pre_overlay_filter='[0:v]select=not(mod(n\,@sup@))[0v]'
	d_overlay_filter_input='0v'
	quality_param=( "-crf" "22" )
	overlay_filter='overlay'
	outfr=origfr
	#duration_params=( )
	d_audio_filter=( '[0:a]atempo=@sup@[a]' )
	d_audio_filter_out='a'
	d_audio_map=( "-map" "[@afa@]" '-ac' "$d_ac" "-ar" "$d_ar" )
	fnsuffix='a'
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
nohwaccel

addsoundtrack () {
	orig="$1"
	strack="$2"
	new="${orig%.mp4}f.mp4"
	ffmpeg -i "$orig" -i "$strack" -c:v copy -map 0:v:0 -filter_complex "[0:a][1:a]amerge=inputs=2,pan=stereo|c0<c0+c2|c1<c1+c3[a]" -map "[a]" "$new"
}

copymetadata () {
	orig="$1"
	meta="$2"
	ffmpeg -i "$orig" -i "$meta" -map_metadata 1 -map 0 -c copy "${orig%.mp4}m.mp4"
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

concatarray () {
	local delim="$1"
	shift
	local ret="$1"
	shift
	local i
	for i in "$@" ; do
		ret+="$delim$i"
	done
	printf "%s" "$ret"
}

#
# Newest version of things as of 2024-12-31
#
sjrenderimg () {
	layout="$1"
	renderext="$2"
	for i in wk/${ovlsrcdir}/*.mp4 ; do
		fn="${i##*/}"
		[ -d wk/${ovldstdir} ] || mkdir wk/${ovldstdir}
		if [ -r wk/${ovldstdir}/${fn%.mp4}-${renderext}0000.${d_ovlext} ]; then
			:
		else
			gpx="`(ls -1 wk/${i:8:12}*.gpx ; ls -1 wk/*.gpx ) | head -1 `"
			echo prcessing $i - $gpx
			echo " ./gpx2video -m $i -g $gpx -l layout-${layout}.xml -o wk/${ovldstdir}/${fn%.*}-${renderext}XXXXX.${d_ovlext} image"
			TZ="$SJTZ" ./gpx2video -m $i -g $gpx -l layout-${layout}.xml -o wk/${ovldstdir}/${fn%.*}-${renderext}XXXXX.${d_ovlext} image
		fi
	done
}

# So, practically, I just needs to go into wko dir, and run
# for i in ../wk/*.mp4 ; do addoverlay $i f ; done
# Than concat all the pieces together: concatvideo 2023_MMDD_FOs4.mp4 2023_MMDD_S?n???f.mp4
# And finally, the soundtrack can came.
# This is now uses the least amount of cpu, the best codecs, the less amount of intermediate steps and storing intermediate files, etc.
# With this trick, I probably won't even need to separate the wk and wko dir anymore as the mp4 segments won't overlap, and no more audio fixing is needed.

# ^ This approach wasn't exactly precise with the audio. Somehow it always caused some skew, so I went back to the basics:
# Render the video and the audio in separate streams, so here comes add overlay simplified

gentemp () {
	local origds="$1"
	local outfn="$2"
	local ovl="$3"
	if [ -r "$outfn" ]; then
		printf "PLACE-%s-HOLDER" "$origds"
		return
	fi
	[ -d tempdir ] || mkdir tempdir
	local tempfile="`mktemp -up tempdir`.mp4"
	local origit="${origds%.dsh}.input.txt"
	local origffn="${origds##*/}"
	local origfno="${origffn%.*}"
	local date_prefix="${origfno%S*}"
	local segment_ref=''
	local slice_ref="${origfno#*S}"
	local l_blank
	local l_sdiff
	local l_duration
	[ -r "$origds" ] && . "$origds"
	while [ "$slice_ref" != "${slice_ref#[0-9]}" ] ; do
		segment_ref="$segment_ref${slice_ref:0:1}"
		slice_ref="${slice_ref:1}"
	done
	local sovlprefix="../${ovldstdir}/${date_prefix}S${segment_ref}${uncutprefix}000-$ovl"
	local dovlprefix="tempdir/${origfno}-$ovl"
	l_sdiff="${l_sdiff%.*}"
	[ -n "$sdiff_override" ] && l_sdiff="${sdiff_override}"
	for (( i=0 ; i<${l_duration%.*} ; i++ )) ; do
		x=$[100000+i]
		y=$[100000+i+l_sdiff]
		ln -s "${sovlprefix}${y:1}.${d_ovlext}" "${dovlprefix}${x:1}.${d_ovlext}"
	done
	if [ "$l_blank" = "no" ]; then
		ln -s "${origds%.dsh}.mp4" "$tempfile"
	else
		ffmpeg -f concat -safe 0 -i "$origit" -c copy "$tempfile"
	fi
	printf "%s" "$tempfile"
}

addoverlays () {
	local orig="$1"
	local ovl="$2"
	local origffn="${orig##*/}"
	local origfno="${origffn%.*}"
	local origds="${orig%.*}.dsh"
	local l_speedup="${d_speedup}"
	local -a l_tempfiles
	local l_tempfn
	local -a l_input
	local -a l_pre_pre_overlay_filter
	local -a l_post_pre_overlay_filter
	local -a l_pre_post_overlay_filter
	local -a l_post_post_overlay_filter
	#local -a l_duration_params=( "${duration_params[@]}" )
	local l_overlay_filter_input="$d_overlay_filter_input"
	local l_ovlext="$d_ovlext"
	local -a ffmpeg_params
	local -a ffmpeg_filters
	local -a l_post_overlay_chain
	local l_post_overlay_filter_input='1v'
	local -a l_outfr=( "${d_outfr[@]}" )
	local -a l_audio_filter=( "${d_audio_filter[@]}" )
	local l_audio_map=( "${d_audio_map[@]}" )
	local l_audio_filter_out="$d_audio_filter_out"
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
	[ -d "rout" ] || mkdir rout
	local outfn="rout/${origfno}${ovl}${fnsuffix}.mp4"
	if [ -r "${origdir}/${origfno}.sh" ]; then
		echo reading "${origdir}/${origfno}.sh"
		. "${origdir}/${origfno}.sh"
		if [ -r "${outfn}" ]; then
			[ "${origdir}/${origfno}.sh" -nt "${outfn}" ] && rm "${outfn}"
		fi
	fi
	if [ -r "${origdir}/${origfno}-${ovl}.sh" ]; then
		echo reading "${origdir}/${origfno}-${ovl}.sh"
		. "${origdir}/${origfno}-${ovl}.sh"
		if [ -r "${outfn}" ]; then
			[ "${origdir}/${origfno}-${ovl}.sh" -nt "${outfn}" ] && rm "${outfn}"
		fi
	fi
	#local outvframes=$[(vframes+l_speedup-1)/l_speedup]
	#echo "Calculating outduration"
	#local outduration=`printf 'scale=3\n%s/(%s)\n' "$outvframes" "$origfr" | bc `
	#echo "Checking if outduration starts with a dot"
	#[ "${outduration:0:1}" == "." ] && outduration="0$outduration"
	#echo vframes: $vframes aframes: $aframes outtvframes: $outvframes outduration: $outduration
	#l_duration_params=( "${l_duration_params[@]//@outvframes@/$outvframes}" )
	#l_duration_params=( "${l_duration_params[@]//@outduration@/$outduration}" )
	ffmpeg_params+=( "${encode_options[@]}" )
	if [ -r "$origds" ];
	then
		if [ -r "$outfn" ]; then
			echo "$outfn exists, just dry-run assembling the final command line"
			ffmpeg_params+=( "-i" "PLACE-${origds}-HOLDER" )
		else
			echo Calling gentemp
			l_tempfn="`gentemp $origds $outfn $ovl`"
			echo "returned filename=$l_tempfn"
			l_tempfiles+=( "$l_tempfn" )
			ffmpeg_params+=( "-i" "$l_tempfn" )
		fi
	else
		ffmpeg_params+=( "-i" "$orig" )
	fi
	ffmpeg_params+=( "-r" "1" "-i" "tempdir/${origfno}-${ovl}%05d.${d_ovlext}" )
	ffmpeg_params+=( "${l_input[@]}" )
	ffmpeg_filters+=( "${l_pre_pre_overlay_filter[@]}" )
	ffmpeg_filters+=( "${pre_overlay_filter}" )
	ffmpeg_filters+=( "${l_post_pre_overlay_filter[@]}" )
	ffmpeg_filters+=( "[${l_overlay_filter_input}][1:v]${overlay_filter}[1v]" )
	l_post_overlay_chain+=( "${l_pre_post_overlay_filter[@]}" )
	l_post_overlay_chain+=( "${post_overlay_filter[@]}" )
	[ -n "$post_scale" ] && l_post_overlay_chain+=( "${post_overlay_filter_psc[@]}" )
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
	ffmpeg_filter_expression="${ffmpeg_filter_expression//@psc@/$post_scale}"
	ffmpeg_params+=( "-filter_complex" "$ffmpeg_filter_expression" )
	ffmpeg_params+=( "${l_outfr[@]}" )
	l_audio_map=( "${l_audio_map[@]//@afa@/$l_audio_filter_out}" )
	ffmpeg_params+=( "${l_audio_map[@]}" )
	#ffmpeg_params+=( "${l_duration_params[@]}" )
	ffmpeg_params+=( "${output_codec[@]}" )
	ffmpeg_params+=( "${quality_param[@]}" )
	ffmpeg_params+=( "${outfn}" )

	echo ffmpeg "${ffmpeg_params[@]}"
	[ -r "${outfn}" ] || time ffmpeg "${ffmpeg_params[@]}"

#	if [ -r "$origit" ];
#	then
#		[ -r "${l_tempfiles[0]}" ] && rm "${l_tempfiles[@]}"
#	fi
	[ -d tempdir ] && rm -r tempdir
}

sjgentimesh () {
	for i in 202?_????_S?t.py ; do
		sjdemux -d 0 $i ;
	done >timediff.sh
}

gpgentimesh () {
	for i in 202?_????_S?u.py ; do
		gpdemux -d 0 $i ;
	done >timediff.sh
}

sjtelltimediffs () {
	for i in 202?_????_S??.py ; do sjdemux -D $i ; done
}

gptelltimediffs () {
	for i in 202?_????_S?u.py ; do gpdemux -D $i ; done | sed -e 's/u\.py /n.py /' | tee work.sh
}

renderallvideo () {
	# So, if the work dir, where the images were generated is /store/vedit/WKO.0903
	# Than sourcedir is /store/vedit/WK.0903
	renderext="$1"
	#sourcedir="${PWD%?.*}.${PWD##*.}"
	sourcedir="rsrc"
	for i in ${sourcedir}/*.mp4 ; do
		addoverlays "$i" "$renderext"
	done
}

addoverlaysgrid () {
	vin="$1"
	vfn="${vin##*/}"
	ovl="${vfn%.mp4}"
	vout="${vfn%.mp4}f.mp4"
	echo ffmpeg -vaapi_device /dev/dri/renderD128 -i $vin -r 1 -i "${ovl}"-f%05d.tiff -filter_complex '[0:v]select=not(mod(n\,4))[0v];[0v][1:v]overlay,setpts=0.25*PTS,format=yuv420p,hwupload,scale_vaapi=w=1920:h=1080:format=nv12;[0:a]atempo=4[a]' -map '[a]' -ac 2 -ar 48000 -c:v hevc_vaapi -qp 22 "$vout"
	[ -r "$vout" ] || ffmpeg -vaapi_device /dev/dri/renderD128 -i $vin -r 1 -i "${ovl}"-f%05d.tiff -filter_complex '[0:v]select=not(mod(n\,4))[0v];[0v][1:v]overlay,setpts=0.25*PTS,format=yuv420p,hwupload,scale_vaapi=w=1920:h=1080:format=nv12;[0:a]atempo=4[a]' -map '[a]' -ac 2 -ar 48000 -c:v hevc_vaapi -qp 22 "$vout"
}

gridrender () {
	vout="$1"
	# TopLeft
	v0="$2"
	# BottomLeft
	v1="$3"
	# TopRight
	v2="$4"
	# BottomRight
	v3="$5"
	#ffmpeg -i "$v0" -i "$v1" -i "$v2" -i "$v3" -vaapi_device /dev/dri/renderD128 -filter_complex '[0:a][1:a][2:a][3:a]amerge=inputs=4,pan=stereo|c0<c0+c2|c1<c4+c6[a];[0:v]crop=h=1080:y=0[0v];[1:v]crop=h=1080:y=0[1v];[2:v]crop=h=1080:y=0[2v];[3:v]crop=h=1080:y=0[3v];[0v][1v][2v][3v]xstack=inputs=4:layout=0_0|0_h0|w0_0|w0_h0,format=yuv420p,hwupload,scale_vaapi=format=nv12' -c:v hevc_vaapi -map '[a]' -qp 22 "$vout"
	ffmpeg -i "$v0" -i "$v1" -i "$v2" -i "$v3" -filter_complex '[0:a][1:a][2:a][3:a]amerge=inputs=4,pan=stereo|c0<c0+c2|c1<c4+c6[a];[0:v]scale=w=1920:h=1080[0v];[1:v]scale=w=1920:h=1080[1v];[2:v]scale=w=1920:h=1080[2v];[3:v]scale=w=1920:h=1080[3v];[0v][1v][2v][3v]xstack=inputs=4:layout=0_0|0_h0|w0_0|w0_h0' -c:v libx265 -map '[a]' -crf 22 "$vout"
}

gridrenderall () {
	local ovldstdir=govl
	local uncutprefix=g
	local sdiffoverride=0
	renderallvideo g
}


concatall () {

	renderext="$1"
	ucrenderext="$( echo -n $renderext | tr a-z A-Z )"
	if [ -d rout ]; then
		fnprefix="$( ls -1 rout/*mp4 | head -1 | cut -c 1-14 )"
	else
		fnprefix="$( ls -1 *mp4 | head -1 | cut -c 1-9 )"
	fi
	concatvideo ${fnprefix#*/}_${ucrenderext}N.mp4 ${fnprefix}_S?n???${renderext}a.mp4
}

vedithelp () {
	cat <<END
# generates timediff.sh
[ sjgentimesh | gpgentimesh ]

# Update the timestamp to the time in the clock on the video
vim timediff.sh

# Generates the timeing files
. timediff.sh

# To find out the differences
[ sjtelltimediffs | gptelltimediffs ]

#### Now, run these in the gpx2video build dir:
# The example sjrenderimg function uses the "f" renderext.
sjrenderimg 4k f

# Generate the src videos
. work.sh

# Now render those segments
renderallvideo f

concatall f
sjmpv 1970_0101_??.mp4 & sjmpv /path/to/your/soundtrack/dir
sjstgen 1970_0101_??.mp4 1970_0101_soundtrack.txt
# here comes the soundtrack composition work in kdenlive
addsoundtrack 1970_0101_FNs4.mp4 *mka
sjplaylist *kdenlive >>1970_0101_description.txt
END
}
