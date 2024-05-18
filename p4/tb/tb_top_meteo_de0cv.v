`include "../misc/timescale.v"
`include "../rtl/i2c_master/i2c_master_defines.v"

module tb_top_meteo_de0cv();

wire scl, sda, clk, rst_n;
reg [2:0] sel;
wire errorFlag;
wire Enable_i2c_o;
wire ErrFlag_o;
wire [7-1:0] Dec0_o, Dec1_o, Dec2_o, Dec3_o, Dec4_o, Dec5_o;

parameter CLK_HALFPERIOD = 5;

pullup p1(scl); // pullup scl line
pullup p2(sda); // pullup sda line

sys_model #(
  .CLK_HALFPERIOD   (CLK_HALFPERIOD), // units depends on timescale
  .DELAY            (2)  // delay between clock posedge and check
) u_sys (
  .Clk              (clk),
  .Rst_n            (rst_n)
);

top_meteo_de0cv DUT (
  .Clk_i            (clk),
  .Rst_n_i          (rst_n),
  .SCL_io           (scl),
  .SDA_io           (sda),
  .Sel_i            (sel),
  .ErrFlag_o        (errorFlag),
  .SlaveAddr_LSb_o  (SlaveAddr_LSb_o),
  .Enable_i2c_o     (Enable_i2c_o),
  .Dec0_o           (Dec0_o),
  .Dec1_o           (Dec1_o),
  .Dec2_o           (Dec2_o),
  .Dec3_o           (Dec3_o),
  .Dec4_o           (Dec4_o),
  .Dec5_o           (Dec5_o)
);

i2c_slave_model #(
  .MEM_INIT_FILE("../misc/bme280_regs.mem"),
  .MEM_SIZE(256),
  .I2C_ADDR(7'b111_0110),
  .RD_BURST(1'b1)
) i2c_slave (
  .Scl              (scl),
  .Sda              (sda)
);

//___________________________________________________________________________
// Signals and vars initialization
initial begin
  sel = 3'b001;
end

//___________________________________________________________________________
// Test Vectors
initial begin
  $timeformat(-9, 2, " ns", 10); // format for the time print

  // Initial reset
  u_sys.reset(2); // Així ens assegurem que detecti el flanc de baixada
  u_sys.wait_cycles(3);
  u_sys.reset(2);
  u_sys.wait_cycles(200000);
  //wait(DUT.timerInt);

  sel = 3'b010;
  u_sys.wait_cycles(2000);

  sel = 3'b100;
  u_sys.wait_cycles(2000);

  $stop;
end

endmodule
