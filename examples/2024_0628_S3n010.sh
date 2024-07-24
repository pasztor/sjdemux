l_input=( "-r" "1" "-i" "2024_0628_S3n010-x%04d.tiff" )
l_pre_pre_overlay_filter=( '[2:v]format=rgba,tpad=color=black@0:stop=-1,setpts=4*PTS,scale=3800:-1[2v]' )
#l_post_pre_overlay_filter='[0:v][1:v]'
#l_pre_post_overlay_filter='[1v];[1v][2v]overlay=20:20'
l_pre_post_overlay_filter=( '[2v]overlay=20:20' )
