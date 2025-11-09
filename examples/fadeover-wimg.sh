local l_nextslice=2025_0412_S2n000

l_input+=( "-r" "1" "-i" "${origfno}-x%04d.tiff" )
l_pre_pre_overlay_filter+=( '[2:v]format=rgba,setpts=3*PTS,fps=25,fade=type=in:alpha=1,setpts=@sup@*PTS[2v]' )
local l_imgwidth=`identify -format %w ${origfno}-x0000.tiff`
local l_xoffset=$[(3840-l_imgwidth)/2]

l_tempfn="`gentemp ${origdir}/${l_nextslice}.dsh $outfn $ovl`"
l_input+=( -i "${l_tempfn}" -r 1 -i "tempdir/${l_nextslice}-${ovl}%05d.${d_ovlext}" )
l_tempfiles+=( "$l_tempfn" )
###
### l_vpad = ( vframes round up to the next l_speedup dividable number ) / frame rate / l_speedup - 1 second
###            1 second = frame rate * l_speedup
### That gives us:
###       (vframes+l_speedup-1)/l_speedup*l_speedup/origfr-origfr*l_speedup
###
local l_vpad=`printf '(%s+%s-1)/%s*%s-(%s)*%s\n' "$vframes" "$l_speedup" "$l_speedup" "$l_speedup" "$origfr" "$l_speedup" | bc`
###
### l_adelay = l_vpad * 1000 / l_speedup / frame rate
###
local l_adelay=`printf '%s*1000/%s/(%s)' "$l_vpad" "$l_speedup" "$origfr" | bc `
l_audio_filter+=( "[${d_audio_filter_out}]apad[a1]" )
l_audio_filter+=( "[3:a]atempo=@sup@,adelay=$l_adelay:all=1[a3]" )
l_audio_filter+=( '[a1][a3]amerge=inputs=2,pan=stereo|c0<c0+c2|c1<c1+c3[af]' )
l_audio_filter_out='af'
l_post_pre_overlay_filter+=( '[3:v]select=not(mod(n\,@sup@))[3v]' )
l_post_pre_overlay_filter+=( "[3v][4:v]overlay,format=rgba,fade=type=in:alpha=1,tpad=${l_vpad}:color=black@0[4v]")
#l_pre_post_overlay_filter+=( 'tpad=stop=-1,[3v]overlay' )
l_pre_post_overlay_filter+=( "[2v]overlay=${l_xoffset}:20[2vf];[2vf][4v]overlay" )
