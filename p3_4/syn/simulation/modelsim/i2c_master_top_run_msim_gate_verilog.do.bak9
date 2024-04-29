transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {i2c_master_top.vo}

vlog -vlog01compat -work work +incdir+C:/Users/HP/Documents/Universitat/8e/DSSD/pracs/p3_4/syn/../tb {C:/Users/HP/Documents/Universitat/8e/DSSD/pracs/p3_4/syn/../tb/tb_i2c_master_top_4netlist.v}

vsim -t 1ps +transport_int_delays +transport_path_delays -L altera_ver -L cycloneive_ver -L gate_work -L work -voptargs="+acc"  tb_i2c_master_top

add wave *
view structure
view signals
run -all
