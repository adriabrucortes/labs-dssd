transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {i2c_master_byte_ctrl_min_1200mv_0c_fast.vo}

vlog -vlog01compat -work work +incdir+/home/aidar/Documents/labs-dssd/p3_4/syn/../tb {/home/aidar/Documents/labs-dssd/p3_4/syn/../tb/tb_i2c_master_top_(4netlist).v}

vsim -t 1ps +transport_int_delays +transport_path_delays -L altera_ver -L cycloneive_ver -L gate_work -L work -voptargs="+acc"  tb_i2c_master_top_(4netlist)

add wave *
view structure
view signals
run -all
