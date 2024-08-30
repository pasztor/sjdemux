l_input=( "-r" "1" "-i" "2024_0824_S1n001-x%04d.tiff" )
l_pre_pre_overlay_filter=( '[2:v]format=rgba,tpad=3:color=black@0:stop=-1,setpts=16*PTS,scale=-1:2120[2v]' )
#l_post_pre_overlay_filter='[0:v][1:v]'
#l_pre_post_overlay_filter='[1v];[1v][2v]overlay=20:20'
l_pre_post_overlay_filter=( '[2v]overlay=1000:20' )
