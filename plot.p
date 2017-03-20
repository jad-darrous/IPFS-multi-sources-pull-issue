file_name = 'stats.csv'

set datafile separator ","

set multiplot layout 1,2 title "With 50ms latency" font ",14"
#set multiplot layout 1,2 title "With no latency" font ",14"

set xtics (`for i in $(seq $(cat stats.csv | tail -n +2 | wc -l)); do echo -n \"node-$i\" $i, ; done`)
set xrange [0:5]
set boxwidth 0.5
set style fill solid  0.25 border -1

set title 'Total time'
set xlabel 'Nodes'
set ylabel 'Time (sec)'
set yrange [0:500]
set ytics 0,50
plot file_name using 1:2 notitle with boxes linecolor rgb "#00FF00"

set title 'Received data'
set xlabel 'Nodes'
set ylabel 'Received data (GB)'
set yrange [0:4]
set ytics 0,0.5
plot file_name using 1:3 notitle with boxes linecolor rgb "red"

unset multiplot
