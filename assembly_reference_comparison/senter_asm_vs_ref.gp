set terminal png tiny size 800,800
set output "senter_asm_vs_ref.png"
set xtics rotate ( \
 "NC_003197.2" 1, \
 "NC_003277.2" 4857450, \
 "" 4951383 \
)
set ytics ( \
 "*disjointig_2" 1, \
 "*disjointig_3" 3333397, \
 "disjointig_1" 5012637, \
 "" 5151063 \
)
set size 1,1
set grid
unset key
set border 0
set tics scale 0
set xlabel "REF"
set ylabel "QRY"
set format "%.0f"
set mouse format "%.0f"
set mouse mouseformat "[%.0f, %.0f]"
if(GPVAL_VERSION < 5) set mouse clipboardformat "[%.0f, %.0f]"
set xrange [1:4951383]
set yrange [1:5151063]
set style line 1  lt 1 lw 3 pt 6 ps 1
set style line 2  lt 3 lw 3 pt 6 ps 1
set style line 3  lt 2 lw 3 pt 6 ps 1
plot \
 "senter_asm_vs_ref.fplot" title "FWD" w lp ls 1, \
 "senter_asm_vs_ref.rplot" title "REV" w lp ls 2
