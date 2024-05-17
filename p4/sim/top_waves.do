onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/DWIDTH
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/AWIDTH
add wave -noupdate -radix binary /tb_top_meteo_de0cv/DUT/SLAVE_ADDR
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/TIMERLIM
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Clk_i
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Rst_n_i
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Sel_i
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/SCL_io
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/SDA_io
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/SlaveAddr_LSb_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Enable_i2c_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/ErrFlag_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Dec0_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Dec1_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Dec2_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Dec3_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Dec4_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Dec5_o
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/clk100MHz
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/clk1MHz
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Rst_n
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/Rst_n_slow
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/sclPadEn
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/sclPadOut
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/sdaPadEn
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/sdaPadOut
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/timerEn
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/timerInt
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/TimerInt_sync
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2c_int
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/dbus_wr
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/dbus_addr
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/dbus_di
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/dbus_do
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2cc_start
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2cc_rdwr
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2cc_last
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2cc_done
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2cc_addr
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2cc_txd
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/i2cc_rxd
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/tempBin
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/pressBin
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/humBin
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digT1
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digT2
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digT3
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP1
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP2
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP3
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP4
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP5
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP6
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP7
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP8
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digP9
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digH1
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digH3
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digH6
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digH2
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digH4
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/digH5
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/temp
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/press
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/hum
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/t_bcd
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/p_bcd
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/h_bcd
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/t_bcd5
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/t_bcd4
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/t_bcd3
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/t_bcd2
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/t_bcd1
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/t_bcd0
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/p_bcd5
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/p_bcd4
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/p_bcd3
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/p_bcd2
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/p_bcd1
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/p_bcd0
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/h_bcd5
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/h_bcd4
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/h_bcd3
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/h_bcd2
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/h_bcd1
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/h_bcd0
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/SclPadOut
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/SclPadEn
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/SdaPadOut
add wave -noupdate -radix unsigned /tb_top_meteo_de0cv/DUT/SdaPadEn
add wave -noupdate -divider BME_READER
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/Clk
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/Rst_n
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/I2CC_start
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/I2CC_rdwr
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/I2CC_last
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/I2CC_addr
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/I2CC_txd
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/I2CC_rxd
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/I2CC_done
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/TempBin
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/PressBin
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/HumBin
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/TimerEn
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/TimerInt
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/ErrorFlag
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigT1
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigT2
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigT3
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP1
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP2
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP3
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP4
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP5
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP6
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP7
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP8
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigP9
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigH1
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigH3
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigH6
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigH2
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigH4
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/DigH5
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/byteCnt
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/state
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/next
add wave -noupdate /tb_top_meteo_de0cv/DUT/i_reader/last
add wave -noupdate -radix ascii /tb_top_meteo_de0cv/DUT/i_reader/stateName
add wave -noupdate -radix ascii /tb_top_meteo_de0cv/DUT/i_reader/nextName
add wave -noupdate -radix ascii /tb_top_meteo_de0cv/DUT/i_reader/lastName
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {78166230 ps} 0}
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
WaveRestoreZoom {0 ps} {105070350 ps}
