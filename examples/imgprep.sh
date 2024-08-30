#convert -gravity Center -pointsize 60 -annotate 0 '1 hour later' IMG_20240824_233609.jpg 2024_0824_S1n001-x0000.tiff
#convert -draw 'gravity Center font-size 60 fill White rotate 90 text "1 hour late"' IMG_20240824_233609.jpg 2024_0824_S1n001-x0000.tiff
#convert -crop 3000x1824+1000+0 -rotate 90 -gravity West -fill White -pointsize 160 -annotate 0 '... 1 hour later' -rotate -90 IMG_20240824_233609.jpg 2024_0824_S1n001-x0000.tiff
#convert -crop 3000x1824+1000+0 -draw 'rotate -90 font-size 180 fill White text 1000,50 "1 hour later"' IMG_20240824_233609.jpg 2024_0824_S1n001-x0000.tiff
convert -crop 2500x1824+1000+0 -draw 'rotate -90 font-size 280 fill White text -1700,1800 "1 hour later"' -auto-orient IMG_20240824_233609.jpg 2024_0824_S1n001-x0000.tiff
