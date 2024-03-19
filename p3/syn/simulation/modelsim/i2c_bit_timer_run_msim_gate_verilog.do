transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {i2c_bit_timer_min_1200mv_0c_fast.vo}

vlog -vlog01compat -work work +incdir+C:/Users/HP/Documents/Universitat/8e/DSSD/pracs/p3/syn/../tb {C:/Users/HP/Documents/Universitat/8e/DSSD/pracs/p3/syn/../tb/tb_timer.v}

vsim -t 1ps +transport_int_delays +transport_path_delays -L altera_ver -L cycloneive_ver -L gate_work -L work -voptargs="+acc"  tb_timer

add wave *
view structure
view signals
run -all
