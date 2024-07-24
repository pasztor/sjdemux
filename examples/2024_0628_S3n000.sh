l_input=( "-ss" "0.2" "-i" "${origdir}/2024_0628_S3x000.mp4" )
l_pre_pre_overlay_filter=( '[2:v]format=rgba,tpad=106:color=black@0:stop=-1,setpts=30*PTS,crop=1600:800:100:350[2v]' )
#l_post_pre_overlay_filter='[0:v][1:v]'
l_pre_post_overlay_filter=( '[2v]overlay=20:20' )
