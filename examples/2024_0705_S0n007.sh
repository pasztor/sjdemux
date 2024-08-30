l_input=( \
	"-ss" "0.72" "-i" "${origdir}/2024_0705_S0x000.mp4" \
	"-ss" "0.32" "-i" "${origdir}/2024_0705_S0x001.mp4" )
l_pre_pre_overlay_filter=( \
	'[2:v]format=rgba,tpad=462:color=black@0:stop=-1,setpts=20*PTS,crop=1600:800:1120:1100[2v]' \
	'[3:v]format=rgba,tpad=632:color=black@0:stop=-1,setpts=20*PTS,crop=1600:800:1120:1100[3v]' )
l_pre_post_overlay_filter=( \
	'[2v]overlay=20:20[2ve];[2ve][3v]overlay=20:20' )
