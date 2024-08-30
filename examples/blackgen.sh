ffmpeg -vaapi_device /dev/dri/renderD128 -f lavfi -i color=color=black:size=3840x2160:rate=25 -t 7200 -filter_complex 'hwupload,scale_vaapi=format=nv12'  -c:v hevc_vaapi -qp 45 testblack.mp4
