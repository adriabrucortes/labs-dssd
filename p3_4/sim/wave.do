onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider SLAVE
add wave -noupdate /tb_i2c_master_top/u_slave0/I2C_ADDR
add wave -noupdate /tb_i2c_master_top/u_slave0/WR_BURST
add wave -noupdate /tb_i2c_master_top/u_slave0/RD_BURST
add wave -noupdate /tb_i2c_master_top/u_slave0/MEM_SIZE
add wave -noupdate /tb_i2c_master_top/u_slave0/MEM_INIT_FILE
add wave -noupdate /tb_i2c_master_top/u_slave0/IDLE
add wave -noupdate /tb_i2c_master_top/u_slave0/SLAVE_ACK
add wave -noupdate /tb_i2c_master_top/u_slave0/GET_MEM_ADDR
add wave -noupdate /tb_i2c_master_top/u_slave0/GMA_ACK
add wave -noupdate /tb_i2c_master_top/u_slave0/DATA
add wave -noupdate /tb_i2c_master_top/u_slave0/DATA_ACK
add wave -noupdate /tb_i2c_master_top/u_slave0/Scl
add wave -noupdate /tb_i2c_master_top/u_slave0/Sda
add wave -noupdate /tb_i2c_master_top/u_slave0/debug
add wave -noupdate /tb_i2c_master_top/u_slave0/mem
add wave -noupdate /tb_i2c_master_top/u_slave0/mem_adr
add wave -noupdate /tb_i2c_master_top/u_slave0/mem_do
add wave -noupdate /tb_i2c_master_top/u_slave0/sta
add wave -noupdate /tb_i2c_master_top/u_slave0/d_sta
add wave -noupdate /tb_i2c_master_top/u_slave0/sto
add wave -noupdate /tb_i2c_master_top/u_slave0/sr
add wave -noupdate /tb_i2c_master_top/u_slave0/rw
add wave -noupdate /tb_i2c_master_top/u_slave0/my_adr
add wave -noupdate /tb_i2c_master_top/u_slave0/i2c_reset
add wave -noupdate /tb_i2c_master_top/u_slave0/bit_cnt
add wave -noupdate /tb_i2c_master_top/u_slave0/acc_done
add wave -noupdate /tb_i2c_master_top/u_slave0/ld
add wave -noupdate /tb_i2c_master_top/u_slave0/sda_o
add wave -noupdate /tb_i2c_master_top/u_slave0/sda_dly
add wave -noupdate /tb_i2c_master_top/u_slave0/state
add wave -noupdate /tb_i2c_master_top/u_slave0/tst_sto
add wave -noupdate /tb_i2c_master_top/u_slave0/tst_sta
add wave -noupdate -divider BYTE
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/Clk
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/Rst_n
add wave -noupdate -color Magenta /tb_i2c_master_top/u_dut0/i_byte/Start
add wave -noupdate -color Magenta /tb_i2c_master_top/u_dut0/i_byte/Stop
add wave -noupdate -color Magenta /tb_i2c_master_top/u_dut0/i_byte/Read
add wave -noupdate -color Magenta /tb_i2c_master_top/u_dut0/i_byte/Write
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/Tx_ack
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/I2C_al
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/SR_sout
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/Bit_rxd
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/Rx_ack
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/I2C_done
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/SR_load
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/SR_shift
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/Bit_txd
add wave -noupdate -color Cyan /tb_i2c_master_top/u_dut0/i_byte/Bit_ack
add wave -noupdate -color Khaki /tb_i2c_master_top/u_dut0/i_byte/Bit_cmd
add wave -noupdate -color White -radix unsigned /tb_i2c_master_top/u_dut0/i_byte/state
add wave -noupdate -color White -radix unsigned /tb_i2c_master_top/u_dut0/i_byte/next
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/en_ack
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/loadCounter
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/counterOut
add wave -noupdate /tb_i2c_master_top/u_dut0/i_byte/ck_ack
add wave -noupdate -divider SR
add wave -noupdate -radix unsigned /tb_i2c_master_top/u_dut0/i_sr/Load
add wave -noupdate -radix unsigned /tb_i2c_master_top/u_dut0/i_sr/Shift
add wave -noupdate -radix unsigned /tb_i2c_master_top/u_dut0/i_sr/SerIn
add wave -noupdate -radix unsigned /tb_i2c_master_top/u_dut0/i_sr/DataIn
add wave -noupdate -radix unsigned /tb_i2c_master_top/u_dut0/i_sr/SerOut
add wave -noupdate -radix binary -childformat {{{/tb_i2c_master_top/u_dut0/i_sr/DataOut[7]} -radix unsigned} {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[6]} -radix unsigned} {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[5]} -radix unsigned} {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[4]} -radix unsigned} {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[3]} -radix unsigned} {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[2]} -radix unsigned} {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[1]} -radix unsigned} {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[0]} -radix unsigned}} -subitemconfig {{/tb_i2c_master_top/u_dut0/i_sr/DataOut[7]} {-radix unsigned} {/tb_i2c_master_top/u_dut0/i_sr/DataOut[6]} {-radix unsigned} {/tb_i2c_master_top/u_dut0/i_sr/DataOut[5]} {-radix unsigned} {/tb_i2c_master_top/u_dut0/i_sr/DataOut[4]} {-radix unsigned} {/tb_i2c_master_top/u_dut0/i_sr/DataOut[3]} {-radix unsigned} {/tb_i2c_master_top/u_dut0/i_sr/DataOut[2]} {-radix unsigned} {/tb_i2c_master_top/u_dut0/i_sr/DataOut[1]} {-radix unsigned} {/tb_i2c_master_top/u_dut0/i_sr/DataOut[0]} {-radix unsigned}} /tb_i2c_master_top/u_dut0/i_sr/DataOut
add wave -noupdate -radix unsigned /tb_i2c_master_top/u_dut0/i_sr/register
add wave -noupdate -divider TESTBENCH
add wave -noupdate /tb_i2c_master_top/bus_addr
add wave -noupdate /tb_i2c_master_top/bus_din
add wave -noupdate /tb_i2c_master_top/bus_dout
add wave -noupdate /tb_i2c_master_top/bus_wr
add wave -noupdate /tb_i2c_master_top/scl
add wave -noupdate /tb_i2c_master_top/scl0_o
add wave -noupdate /tb_i2c_master_top/scl0_oen
add wave -noupdate /tb_i2c_master_top/sda
add wave -noupdate /tb_i2c_master_top/sda0_o
add wave -noupdate /tb_i2c_master_top/sda0_oen
add wave -noupdate /tb_i2c_master_top/i2c0_int
add wave -noupdate /tb_i2c_master_top/errors
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {25955000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {23170630 ps} {30828050 ps}
