set terminal postscript eps size 3,2 enhanced color font 'Helvetica,12'
set output 'load-pkey-512-wal-segment.eps'

set palette defined (0 "web-green", 0.5 "white", 1 "red")

set key off

# set labels for x/y axis to block sizes"
XTICS="1 2 4 8 16 32"
YTICS="1 2 4 8 16 32 64"

set for [i=1:words(XTICS)] xtics ( word(XTICS,i) i-1 )
set for [i=1:words(YTICS)] ytics ( word(YTICS,i) i-1 )

# don't show color scale next to the heatmap
unset colorbox

set title "machine: i5 run: 20220329 WAL: 512MB (pkey)"

plot "load-pkey-512-wal-segment.data" matrix using 1:2:3 with image, \
     "load-pkey-512-wal-segment.data" matrix using 1:2:(sprintf("%g",$3)) with labels
