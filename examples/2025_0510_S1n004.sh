set -x
##########BEGIN Effect

### Params for the effect
local l_eindex=0
local l_ivid=2025_0510_S1x000.mp4
local l_iskip=0
local l_itime=1.12
local l_crop_w=450
local l_crop_h=500
local l_crop_s_x=1650
local l_crop_s_y=620
local l_crop_d_x=2750
local l_crop_d_y=900
local l_rel_slowdown=12
local l_crop_o_x=2900
local l_crop_o_y=620
local l_crop_s_mag=1.6
local l_crop_d_mag=1.2
local -a l_enhance_filters=()

### Loading origds
echo Debug origds: $origds
[ -r "${origds}" ] && . "${origds}"

### Saving original .dsh data
local o_sdiff="$l_sdiff"
local o_blank="$l_blank"
local o_duration="$l_duration"

### Loading current video's dsh data
[ -r "${origdir}/${l_ivid%.*}.dsh" ] && . "${origdir}/${l_ivid%.*}.dsh"

### Calculating filter specific variables
local l_delay="` printf 'scale=3\n%s+%s-%s\n' $l_sdiff $l_iskip $o_sdiff | bc `"
local l_vindex=$[l_eindex+2]

l_delay_fr="($origfr)*$l_delay/${l_rel_slowdown}"

### Calculating per frame input crop position
local l_crop_f_x="($l_crop_s_x+round(clip(pow((t-${l_delay})/${l_rel_slowdown},2),0,${l_itime})*($[l_crop_d_x-l_crop_s_x])))"
local l_crop_f_y="($l_crop_s_y+round(clip(pow((t-${l_delay})/${l_rel_slowdown},2),0,${l_itime})*($[l_crop_d_y-l_crop_s_y])))"
### Calculating per frame overlay position
local l_crop_o_x="($l_crop_s_x+round(clip(pow((t-${l_delay}),2),0,${l_itime})*($[l_crop_o_x-l_crop_s_x])))"
local l_crop_o_y="($l_crop_s_y+round(clip(pow((t-${l_delay}),2),0,${l_itime})*($[l_crop_o_y-l_crop_s_y])))"
### Calculating per frame magnifying factor
local l_crop_f_mag="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),(${l_crop_s_mag}+clip(pow((t-${l_delay})/${l_itime},2),0,1)*(${l_crop_d_mag}-${l_crop_s_mag})),1)"
### Calculating per frame crop inside crop offset
local l_crop_om_x="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),((${l_crop_w})/2*(${l_crop_f_mag}-1)),0)"
local l_crop_om_y="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),((${l_crop_h})/2*(${l_crop_f_mag}-1)),0)"
local l_dbg_o_c="red"
local l_dbg_c_c="white"
local -a l_pre_pre_of_a=()

printf '%s-%s [enter] drawbox c black@0.7,\n    [leave] drawbox c black@0;\n' "${l_delay}" "`printf 'scale=3\n%s+%s*%s\n' $l_delay $l_itime $l_rel_slowdown | bc`" >${l_ivid%.*}_${l_eindex}.cmd
echo Debug: ${l_ivid%.*}_${l_eindex}.cmd
cat ${l_ivid%.*}_${l_eindex}.cmd

### Adding variables to filter chains
l_input+=( "-ss" "$l_iskip" "-t" "$l_itime" "-i" "${origdir}/$l_ivid" )

l_pre_pre_of_a=(
	"format=rgba"
	"tpad=${l_delay_fr}:color=black@0:stop=1"
	"setpts=PTS*${l_rel_slowdown}"
	"crop=${l_crop_w}:${l_crop_h}:'${l_crop_f_x}':'${l_crop_f_y}'"
	"scale='round(iw*${l_crop_f_mag}):round(ih*${l_crop_f_mag}):eval=frame'"
	"crop='${l_crop_w}:${l_crop_h}:${l_crop_om_x}:${l_crop_om_y}'"
	"${l_enhance_filters[@]}"
	"sendcmd=f=${l_ivid%.*}_${l_eindex}.cmd"
	"drawbox=0:0:${l_crop_w}:${l_crop_h}:t=3:c=black@0.8"
#	"drawtext=text='%{frame_num},%{pts},%{e\:t}"$'\n'"%{e\:${l_crop_f_x}},%{e\:${l_crop_f_y}}':fontsize=40:fontcolor=${l_dbg_c_c}:fontfile=/usr/local/share/fonts/Liberation/LiberationSerif-Regular.ttf:x=10:y=10"
)

l_pre_pre_overlay_filter+=( "[$l_vindex:v]`concatarray , "${l_pre_pre_of_a[@]}"`[${l_vindex}v]" )

### If pre_post_overlay_filter chain wasn't empty, than we need to chain our filterchain to the last one for a proper overlay
local l_pre_post_overlay_filter_input
local l_pre_post_overlay_filter_lastindex
if [ ${#l_pre_post_overlay_filter[@]} -gt 0 ]; then
	l_pre_post_overlay_filter_input="[${l_vindex}i]"
	l_pre_post_overlay_filter_lastindex=${#l_pre_post_overlay_filter[@]}
	l_pre_post_overlay_filter_lastindex=$[l_pre_post_overlay_filter_lastindex-1]
	l_pre_post_overlay_filter[l_pre_post_overlay_filter_lastindex]+="${l_pre_post_overlay_filter_input}"
else
	l_pre_post_overlay_filter_input=''
fi

l_pre_post_overlay_filter+=(
	"${l_pre_post_overlay_filter_input}[${l_vindex}v]overlay='${l_crop_o_x}':'${l_crop_o_y}'"
#	"drawtext=text='%{frame_num},%{pts},%{e\:t},%{e\:${l_crop_o_x}},%{e\:${l_crop_o_y}}':fontsize=64:fontcolor=${l_dbg_o_c}:fontfile=/usr/local/share/fonts/Liberation/LiberationSerif-Regular.ttf:x=10:y=110"
#	"setpts=PTS-STARTPTS"
)

### Restore variables
l_sdiff="$o_sdiff"
l_blank="$o_blank"
l_duration="$o_duration"

##########END Effect
##########BEGIN Effect

### Params for the effect
local l_eindex=1
local l_ivid=2025_0510_S1x000.mp4
local l_iskip=1.52
local l_itime=1.2
local l_crop_w=410
local l_crop_h=120
local l_crop_s_x=1420
local l_crop_s_y=820
local l_crop_d_x=1540
local l_crop_d_y=880
local l_rel_slowdown=8
local l_crop_o_x=2400
local l_crop_o_y=620
local l_crop_s_mag=2
local l_crop_e_mag=1.5
local -a l_enhance_filters=( "eq=brightness=0.1" )

### Loading origds
echo Debug origds: $origds
[ -r "${origds}" ] && . "${origds}"

### Saving original .dsh data
local o_sdiff="$l_sdiff"
local o_blank="$l_blank"
local o_duration="$l_duration"

### Loading current video's dsh data
[ -r "${origdir}/${l_ivid%.*}.dsh" ] && . "${origdir}/${l_ivid%.*}.dsh"

### Calculating filter specific variables
local l_delay="` printf 'scale=3\n%s+%s-%s\n' $l_sdiff $l_iskip $o_sdiff | bc `"
local l_vindex=$[l_eindex+2]

l_delay_fr="($origfr)*$l_delay/${l_rel_slowdown}"

### Calculating per frame input crop position
local l_crop_f_x="($l_crop_s_x+round(clip(pow((t-${l_delay})/${l_rel_slowdown},2),0,${l_itime})*($[l_crop_d_x-l_crop_s_x])))"
local l_crop_f_y="($l_crop_s_y+round(clip(pow((t-${l_delay})/${l_rel_slowdown},2),0,${l_itime})*($[l_crop_d_y-l_crop_s_y])))"
### Calculating per frame overlay position
local l_crop_o_x="($l_crop_s_x+round(clip(pow((t-${l_delay}),2),0,${l_itime})*($[l_crop_o_x-l_crop_s_x])))"
local l_crop_o_y="($l_crop_s_y+round(clip(pow((t-${l_delay}),2),0,${l_itime})*($[l_crop_o_y-l_crop_s_y])))"
### Calculating per frame magnifying factor
local l_crop_f_mag="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),(${l_crop_s_mag}+clip(pow((t-${l_delay})/${l_itime},2),0,1)*(${l_crop_d_mag}-${l_crop_s_mag})),1)"
### Calculating per frame crop inside crop offset
local l_crop_om_x="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),((${l_crop_w})/2*(${l_crop_f_mag}-1)),0)"
local l_crop_om_y="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),((${l_crop_h})/2*(${l_crop_f_mag}-1)),0)"
local l_dbg_o_c="red"
local l_dbg_c_c="white"
local -a l_pre_pre_of_a=()

printf '%s-%s [enter] drawbox c black@0.7,\n    [leave] drawbox c black@0;\n' "${l_delay}" "`printf 'scale=3\n%s+%s*%s\n' $l_delay $l_itime $l_rel_slowdown | bc`" >${l_ivid%.*}_${l_eindex}.cmd
echo Debug: ${l_ivid%.*}_${l_eindex}.cmd
cat ${l_ivid%.*}_${l_eindex}.cmd

### Adding variables to filter chains
l_input+=( "-ss" "$l_iskip" "-t" "$l_itime" "-i" "${origdir}/$l_ivid" )

l_pre_pre_of_a=(
	"format=rgba"
	"tpad=${l_delay_fr}:color=black@0:stop=1"
	"setpts=PTS*${l_rel_slowdown}"
	"crop=${l_crop_w}:${l_crop_h}:'${l_crop_f_x}':'${l_crop_f_y}'"
	"scale='round(iw*${l_crop_f_mag}):round(ih*${l_crop_f_mag}):eval=frame'"
	"crop='${l_crop_w}:${l_crop_h}:${l_crop_om_x}:${l_crop_om_y}'"
	"${l_enhance_filters[@]}"
	"sendcmd=f=${l_ivid%.*}_${l_eindex}.cmd"
	"drawbox=0:0:${l_crop_w}:${l_crop_h}:t=3:c=black@0.8"
#	"drawtext=text='%{frame_num},%{pts},%{e\:t}"$'\n'"%{e\:${l_crop_f_x}},%{e\:${l_crop_f_y}}':fontsize=40:fontcolor=${l_dbg_c_c}:fontfile=/usr/local/share/fonts/Liberation/LiberationSerif-Regular.ttf:x=10:y=10"
)

l_pre_pre_overlay_filter+=( "[$l_vindex:v]`concatarray , "${l_pre_pre_of_a[@]}"`[${l_vindex}v]" )

### If pre_post_overlay_filter chain wasn't empty, than we need to chain our filterchain to the last one for a proper overlay
local l_pre_post_overlay_filter_input
local l_pre_post_overlay_filter_lastindex
if [ ${#l_pre_post_overlay_filter[@]} -gt 0 ]; then
	l_pre_post_overlay_filter_input="[${l_vindex}i]"
	l_pre_post_overlay_filter_lastindex=${#l_pre_post_overlay_filter[@]}
	l_pre_post_overlay_filter_lastindex=$[l_pre_post_overlay_filter_lastindex-1]
	l_pre_post_overlay_filter[l_pre_post_overlay_filter_lastindex]+="${l_pre_post_overlay_filter_input}"
else
	l_pre_post_overlay_filter_input=''
fi

l_pre_post_overlay_filter+=(
	"${l_pre_post_overlay_filter_input}[${l_vindex}v]overlay='${l_crop_o_x}':'${l_crop_o_y}'"
#	"drawtext=text='%{frame_num},%{pts},%{e\:t},%{e\:${l_crop_o_x}},%{e\:${l_crop_o_y}}':fontsize=64:fontcolor=${l_dbg_o_c}:fontfile=/usr/local/share/fonts/Liberation/LiberationSerif-Regular.ttf:x=10:y=110"
#	"setpts=PTS-STARTPTS"
)

### Restore variables
l_sdiff="$o_sdiff"
l_blank="$o_blank"
l_duration="$o_duration"

##########END Effect
##########BEGIN Effect

### Params for the effect
local l_eindex=2
local l_ivid=2025_0510_S1y000.mp4
local l_iskip=0
local l_itime=1
local l_crop_w=300
local l_crop_h=200
local l_crop_s_x=1870
local l_crop_s_y=650
local l_crop_d_x=1780
local l_crop_d_y=650
local l_rel_slowdown=12
local l_crop_o_x=2200
local l_crop_o_y=600
local l_crop_s_mag=2.5
local l_crop_e_mag=2.0
local -a l_enhance_filters=()

### Loading origds
echo Debug origds: $origds
[ -r "${origds}" ] && . "${origds}"

### Saving original .dsh data
local o_sdiff="$l_sdiff"
local o_blank="$l_blank"
local o_duration="$l_duration"

### Loading current video's dsh data
[ -r "${origdir}/${l_ivid%.*}.dsh" ] && . "${origdir}/${l_ivid%.*}.dsh"

### Calculating filter specific variables
local l_delay="` printf 'scale=3\n%s+%s-%s\n' $l_sdiff $l_iskip $o_sdiff | bc `"
local l_vindex=$[l_eindex+2]

l_delay_fr="($origfr)*$l_delay/${l_rel_slowdown}"

### Calculating per frame input crop position
local l_crop_f_x="($l_crop_s_x+round(clip(pow((t-${l_delay})/${l_rel_slowdown},2),0,${l_itime})*($[l_crop_d_x-l_crop_s_x])))"
local l_crop_f_y="($l_crop_s_y+round(clip(pow((t-${l_delay})/${l_rel_slowdown},2),0,${l_itime})*($[l_crop_d_y-l_crop_s_y])))"
### Calculating per frame overlay position
local l_crop_o_x="($l_crop_s_x+round(clip(pow((t-${l_delay}),2),0,${l_itime})*($[l_crop_o_x-l_crop_s_x])))"
local l_crop_o_y="($l_crop_s_y+round(clip(pow((t-${l_delay}),2),0,${l_itime})*($[l_crop_o_y-l_crop_s_y])))"
### Calculating per frame magnifying factor
local l_crop_f_mag="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),(${l_crop_s_mag}+clip(pow((t-${l_delay})/${l_itime},2),0,1)*(${l_crop_d_mag}-${l_crop_s_mag})),1)"
### Calculating per frame crop inside crop offset
local l_crop_om_x="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),((${l_crop_w})/2*(${l_crop_f_mag}-1)),0)"
local l_crop_om_y="if(between(t,${l_delay}, ${l_delay} + ${l_itime}*${l_rel_slowdown}),((${l_crop_h})/2*(${l_crop_f_mag}-1)),0)"
local l_dbg_o_c="red"
local l_dbg_c_c="white"
local -a l_pre_pre_of_a=()

printf '%s-%s [enter] drawbox c black@0.7,\n    [leave] drawbox c black@0;\n' "${l_delay}" "`printf 'scale=3\n%s+%s*%s\n' $l_delay $l_itime $l_rel_slowdown | bc`" >${l_ivid%.*}_${l_eindex}.cmd
echo Debug: ${l_ivid%.*}_${l_eindex}.cmd
cat ${l_ivid%.*}_${l_eindex}.cmd

### Adding variables to filter chains
l_input+=( "-ss" "$l_iskip" "-t" "$l_itime" "-i" "${origdir}/$l_ivid" )

l_pre_pre_of_a=(
	"format=rgba"
	"tpad=${l_delay_fr}:color=black@0:stop=1"
	"setpts=PTS*${l_rel_slowdown}"
	"crop=${l_crop_w}:${l_crop_h}:'${l_crop_f_x}':'${l_crop_f_y}'"
	"scale='round(iw*${l_crop_f_mag}):round(ih*${l_crop_f_mag}):eval=frame'"
	"crop='${l_crop_w}:${l_crop_h}:${l_crop_om_x}:${l_crop_om_y}'"
	"${l_enhance_filters[@]}"
	"sendcmd=f=${l_ivid%.*}_${l_eindex}.cmd"
	"drawbox=0:0:${l_crop_w}:${l_crop_h}:t=3:c=black@0.8"
#	"drawtext=text='%{frame_num},%{pts},%{e\:t}"$'\n'"%{e\:${l_crop_f_x}},%{e\:${l_crop_f_y}}':fontsize=40:fontcolor=${l_dbg_c_c}:fontfile=/usr/local/share/fonts/Liberation/LiberationSerif-Regular.ttf:x=10:y=10"
)

l_pre_pre_overlay_filter+=( "[$l_vindex:v]`concatarray , "${l_pre_pre_of_a[@]}"`[${l_vindex}v]" )

### If pre_post_overlay_filter chain wasn't empty, than we need to chain our filterchain to the last one for a proper overlay
local l_pre_post_overlay_filter_input
local l_pre_post_overlay_filter_lastindex
if [ ${#l_pre_post_overlay_filter[@]} -gt 0 ]; then
	l_pre_post_overlay_filter_input="[${l_vindex}i]"
	l_pre_post_overlay_filter_lastindex=${#l_pre_post_overlay_filter[@]}
	l_pre_post_overlay_filter_lastindex=$[l_pre_post_overlay_filter_lastindex-1]
	l_pre_post_overlay_filter[l_pre_post_overlay_filter_lastindex]+="${l_pre_post_overlay_filter_input}"
else
	l_pre_post_overlay_filter_input=''
fi

l_pre_post_overlay_filter+=(
	"${l_pre_post_overlay_filter_input}[${l_vindex}v]overlay='${l_crop_o_x}':'${l_crop_o_y}'"
#	"drawtext=text='%{frame_num},%{pts},%{e\:t},%{e\:${l_crop_o_x}},%{e\:${l_crop_o_y}}':fontsize=64:fontcolor=${l_dbg_o_c}:fontfile=/usr/local/share/fonts/Liberation/LiberationSerif-Regular.ttf:x=10:y=110"
#	"setpts=PTS-STARTPTS"
)

### Restore variables
l_sdiff="$o_sdiff"
l_blank="$o_blank"
l_duration="$o_duration"

##########END Effect
set +x
