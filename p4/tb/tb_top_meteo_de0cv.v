`include "../misc/timescale.v"
`include "../rtl/i2c_master/i2c_master_defines.v"

module tb_top_meteo_de0cv();

top_meteo_de0cv top_meteo (
  .Clk_i            (),
  .Clk_slow_i       (),
  .Rst_n_i          (),
  .SCL_io           (),
  .SDA_io           (),
  .timerLim         (),
  .sel              (),
  .ErrorFlag        (),
  .seg              ()
);

endmodule
