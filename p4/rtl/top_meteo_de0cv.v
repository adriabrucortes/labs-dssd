
`include "../misc/timescale.v"

module top_meteo_de0cv(
  input  Clk_i,
  input  Clk_slow_i,
  input  Rst_n_i,
  inout  SCL_io,
  inout  SDA_io,
  input  timerLim,
);

// Vars
wire Rst_n;
wire sclPadEn, sclPadIn, sclPadOut;
wire sdaPadEn, sdaPadIn, sdaPadOut;
wire DataIn, DataOut;
wire timerInt, timerInt_sync;
wire dbus_wr, i2c_wr;
wire dbus_addr;
wire i2c_start, i2c_rdwr, i2c_last, i2c_addr, i2c_txd, i2c_rxd, i2c_done;
wire TempBin;
wire PressBin;
wire HumBin;
wire DigT1;
wire DigT2;
wire DigT3;
wire DigP1;
wire DigP2;
wire DigP3;
wire DigP4;
wire DigP5;
wire DigP6;
wire DigP7;
wire DigP8;
wire DigP9;
wire DigH1;
wire DigH2;
wire DigH3;
wire DigH4;
wire DigH5;
wire DigH6;
wire Temp;
wire Press;
wire Hum;

// Connections
assign SCL_io = sclPadEn ? 1’bz : sclPadOut;
assign SDA_io = sdaPadEn ? 1’bz : sdaPadOut;
assign sclPadIn = SCL_io;
assign sdaPadIn = SDA_io;

// Instances
digital_por pwr_on_reset (
  .Clk              (Clk_i),
  .Asyncrst_n       (Rst_n_i),
  .Rst_n            (Rst_n)
);

i2c_master_top i2c_master (
  .Clk              (Clk_i),
  .Rst_n            (Rst_n),
  .Addr             (dbus_addr),
  .DataIn           (DataOut),
  .DataOut          (DataIn),
  .Wr               (dbus_wr),
  .Int              (),
  .SclPadIn         (sclPadIn),
  .SclPadOut        (sclPadOut),
  .SclPadEn         (sclPadEn),
  .SdaPadIn         (sdaPadIn),
  .SdaPadOut        (sdaPadOut),
  .SdaPadEn         (sdaPadEn)
);

bme280_i2c_ctrl i_ctrl (
  .Clk              (Clk_i),
  .Rst_n            (Rst_n),
  .Dbus_addr        (dbus_addr),
  .Dbus_di          (DataIn),
  .Dbus_do          (DataOut),
  .Dbus_wr          (dbus_wr),
  .I2C_start        (i2c_start),
  .I2C_rdwr         (i2c_rdwr),
  .I2C_last         (i2c_last),
  .I2C_addr         (i2c_addr),
  .I2C_txd          (i2c_txd),
  .I2C_rxd          (i2c_rxd),
  .I2C_done         (i2c_done), 
);

sync_reg sync (
  .Clk              (Clk_i),
  .Rst_n            (Rst_n),
  .In               (timerInt),
  .Out              (timerInt_sync)
);

gray_timer gtimer (
  .Clk              (Clk_slow_i),
  .Rst_n            (Rst_n),
  .Limit            (timerLim),
  .Int              (timerInt)
);

bme280_reader i_reader (
  .Clk              (Clk_i),
  .Rst_n            (Rst_n),
  .I2CC_start       (i2c_start),
  .I2CC_rdwr        (i2c_rdwr),
  .I2CC_last        (i2c_last),
  .I2CC_addr        (i2c_addr),
  .I2CC_txd         (i2c_txd),
  .I2CC_rxd         (i2c_rxd),
  .I2CC_done        (i2c_done),
  .TempBin          (),
  .PressBin         (),
  .HumBin           (),
  .TimerEn          (),
  .TimerInt         (timerInt_sync),
  .ErrorFlag        (),
  .DigT1            (),
  .DigT2            (),
  .DigT3            (),
  .DigP1            (),
  .DigP2            (),
  .DigP3            (),
  .DigP4            (),
  .DigP5            (),
  .DigP6            (),
  .DigP7            (),
  .DigP8            (),
  .DigP9            (),
  .DigH1            (),
  .DigH2            (),
  .DigH3            (),
  .DigH4            (),
  .DigH5            (),
  .DigH6            ()
);

bme280_compensation i_comp (
  .TempBin          (),
  .PressBin         (),
  .HumBin           (),
  .DigT1            (),
  .DigT2            (),
  .DigT3            (),
  .DigP1            (),
  .DigP2            (),
  .DigP3            (),
  .DigP4            (),
  .DigP5            (),
  .DigP6            (),
  .DigP7            (),
  .DigP8            (),
  .DigP9            (),
  .DigH1            (),
  .DigH2            (),
  .DigH3            (),
  .DigH4            (),
  .DigH5            (),
  .DigH6            (),
  .Temp             (),
  .Press            (),
  .Hum              ()
);

bin2bcd bin2bcd (
  .Bin              (),
  .Bcd              ()
);

bcd2seg bcd2seg (
  .Bcd              (),
  .Seg              ()
)

endmodule
