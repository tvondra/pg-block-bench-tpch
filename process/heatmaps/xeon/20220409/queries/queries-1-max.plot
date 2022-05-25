set terminal postscript eps size 3,2 enhanced color font 'Helvetica,12'
set output 'queries-1-max.eps'

set palette defined (0 "web-green", 0.5 "white", 1 "red")

set key off
set xlabel "data block"
set ylabel "WAL block"

# set labels for x/y axis to block sizes"
XTICS="1 2 4 8 16 32"
YTICS="1 2 4 8 16 32 64"

set for [i=1:words(XTICS)] xtics ( word(XTICS,i) i-1 )
set for [i=1:words(YTICS)] ytics ( word(YTICS,i) i-1 )

# don't show color scale next to the heatmap
unset colorbox

set title "machine: xeon  duration: max  size: 75GB  RAM: 32GB"

plot "queries-1-max.data" matrix using 1:2:3 with image, \
     "queries-1-max.data" matrix using 1:2:(sprintf("%g",$3)) with labels
