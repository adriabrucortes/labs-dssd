
`include "../misc/timescale.v"

module top_meteo_de0cv (
  input  Clk_i,
  input  Rst_n_i,
  input  [3-1:0] Sel_i,
  inout  SCL_io,
  inout  SDA_io,
  output SlaveAddr_LSb_o,
  output Enable_i2c_o,
  output ErrFlag_o,
  output reg [7-1:0] Dec0_o, Dec1_o, Dec2_o, Dec3_o, Dec4_o, Dec5_o
);

// Params
localparam SLAVE_ADDR = 7'b111_0110;
localparam DWIDTH = 8;
localparam AWIDTH = 3;
localparam TIMERLIM = 32'd1000000;

// Clks & Rsts
wire clk100MHz, clk1MHz;
wire Rst_n, Rst_n_slow;

// SDA i SCL
wire sclPadEn, sclPadIn, sclPadOut;
wire sdaPadEn, sdaPadIn, sdaPadOut;

assign SCL_io = sclPadEn ? 1'bz : sclPadOut;
assign SDA_io = sdaPadEn ? 1'bz : sdaPadOut;
assign sclPadIn = SCL_io;
assign sdaPadIn = SDA_io;

// Arbitrary outputs
assign SlaveAddr_LSb_o = 1'b0;
assign Enable_i2c_o = 1'b1;

// Misc connections
wire i2c_int;
wire [AWIDTH-1:0] dbus_addr;
wire [DWIDTH-1:0] dbus_di, dbus_do;
wire dbus_wr;
wire i2cc_start, i2cc_rdwr, i2cc_last, i2cc_done;
wire [DWIDTH-1:0] i2cc_addr, i2cc_txd, i2cc_rxd;
wire timerEn, timerInt, TimerInt_sync;

wire [20-1:0] tempBin, pressBin;
wire [16-1:0] humBin;
wire [16-1:0] digT1, digT2, digT3;
wire [16-1:0] digP1, digP2, digP3, digP4, digP5, digP6, digP7, digP8, digP9;
wire [ 8-1:0]  digH1, digH3, digH6;
wire [16-1:0] digH2, digH4, digH5;
wire [32-1:0] temp, press, hum;

wire [(32+(32-4)/3):0] t_bcd, p_bcd, h_bcd;
wire [ 7-1:0] t_bcd5, t_bcd4, t_bcd3, t_bcd2, t_bcd1, t_bcd0;
wire [ 7-1:0] p_bcd5, p_bcd4, p_bcd3, p_bcd2, p_bcd1, p_bcd0;
wire [ 7-1:0] h_bcd5, h_bcd4, h_bcd3, h_bcd2, h_bcd1, h_bcd0;

// Selector
always @(*) begin
  casex(Sel_i)
    3'bxx1 : begin
      Dec0_o = t_bcd0;
      Dec1_o = t_bcd1;
      Dec2_o = t_bcd2;
      Dec3_o = t_bcd3;
      Dec4_o = t_bcd4;
      Dec5_o = t_bcd5;
    end
    3'bx10 : begin
      Dec0_o = p_bcd0;
      Dec1_o = p_bcd1;
      Dec2_o = p_bcd2;
      Dec3_o = p_bcd3;
      Dec4_o = p_bcd4;
      Dec5_o = p_bcd5;
    end
    3'b100 : begin
      Dec0_o = h_bcd0;
      Dec1_o = h_bcd1;
      Dec2_o = h_bcd2;
      Dec3_o = h_bcd3;
      Dec4_o = h_bcd4;
      Dec5_o = h_bcd5;
    end
  endcase
end

// Instances
pll_cv pll(
  .refclk           (Clk_i),
  .rst              (1'b0),
  .outclk_0         (clk100MHz),
  .outclk_1         (clk1MHz)
);

digital_por por_100MHz (
  .Clk              (clk100MHz),
  .Asyncrst_n       (Rst_n_i),
  .Rst_n            (Rst_n)
);

digital_por por_1MHz (
  .Clk              (clk1MHz),
  .Asyncrst_n       (Rst_n_i),
  .Rst_n            (Rst_n_slow)
);

i2c_master_top #(.DWIDTH(DWIDTH),
                 .AWIDTH(AWIDTH)
) i2c_master (
  .Clk              (clk100MHz),
  .Rst_n            (Rst_n),
  .Addr             (dbus_addr),
  .DataIn           (dbus_di),
  .DataOut          (dbus_do),
  .Wr               (dbus_wr),
  .Int              (i2c_int),
  .SclPadIn         (SCL_io),
  .SclPadOut        (SclPadOut),
  .SclPadEn         (SclPadEn),
  .SdaPadIn         (SDA_io),
  .SdaPadOut        (SdaPadOut),
  .SdaPadEn         (SdaPadEn)
);

bme280_i2c_ctrl #(.DWIDTH(DWIDTH),
                  .AWIDTH(AWIDTH),
                  .SLADDR(SLAVE_ADDR)
) bme280_i2c_ctrl (
  .Clk              (clk100MHz),
  .Rst_n            (Rst_n),
  .Dbus_addr        (dbus_addr),
  .Dbus_di          (dbus_do),
  .Dbus_do          (dbus_di),
  .Dbus_wr          (dbus_wr),
  .I2C_start        (i2cc_start),
  .I2C_rdwr         (i2cc_rdwr),
  .I2C_last         (i2cc_last),
  .I2C_addr         (i2cc_addr),
  .I2C_txd          (i2cc_txd),
  .I2C_rxd          (i2cc_rxd),
  .I2C_done         (i2cc_done)
);

sync_reg #(.NSTAGES(2)) sync (
  .Clk              (clk100MHz),
  .Rst_n            (Rst_n),
  .In               (TimerInt_sync),
  .Out              (timerInt)
);

gray_timer #(.SIZE(32)) gtimer (
  .Clk              (clk1MHz),
  .Rst_n            (Rst_n_slow & timerEn),
  .Limit            (TIMERLIM),
  .Int              (TimerInt_sync)
);

bme280_reader #(.DWIDTH(DWIDTH)) i_reader (
  .Clk              (clk100MHz),
  .Rst_n            (Rst_n),
  .I2CC_start       (i2cc_start),
  .I2CC_rdwr        (i2cc_rdwr),
  .I2CC_last        (i2cc_last),
  .I2CC_addr        (i2cc_addr),
  .I2CC_txd         (i2cc_txd),
  .I2CC_rxd         (i2cc_rxd),
  .I2CC_done        (i2cc_done),
  .TempBin          (tempBin),
  .PressBin         (pressBin),
  .HumBin           (humBin),
  .TimerEn          (timerEn),
  .TimerInt         (timerInt),
  .ErrorFlag        (ErrFlag_o),
  .DigT1            (digT1),
  .DigT2            (digT2),
  .DigT3            (digT3),
  .DigP1            (digP1),
  .DigP2            (digP2),
  .DigP3            (digP3),
  .DigP4            (digP4),
  .DigP5            (digP5),
  .DigP6            (digP6),
  .DigP7            (digP7),
  .DigP8            (digP8),
  .DigP9            (digP9),
  .DigH1            (digH1),
  .DigH2            (digH2),
  .DigH3            (digH3),
  .DigH4            (digH4),
  .DigH5            (digH5),
  .DigH6            (digH6)
);

bme280_compensation i_comp (
  .TempBin          (tempBin),
  .PressBin         (pressBin),
  .HumBin           (humBin),
  .DigT1            (digT1),
  .DigT2            (digT2),
  .DigT3            (digT3),
  .DigP1            (digP1),
  .DigP2            (digP2),
  .DigP3            (digP3),
  .DigP4            (digP4),
  .DigP5            (digP5),
  .DigP6            (digP6),
  .DigP7            (digP7),
  .DigP8            (digP8),
  .DigP9            (digP9),
  .DigH1            (digH1),
  .DigH2            (digH2),
  .DigH3            (digH3),
  .DigH4            (digH4),
  .DigH5            (digH5),
  .DigH6            (digH6),
  .Temp             (temp),
  .Press            (press),
  .Hum              (hum)
);

bin2bcd #(.W(32)) i_t_bcd (temp, t_bcd);
bin2bcd #(.W(32)) i_p_bcd (press, p_bcd);
bin2bcd #(.W(32)) i_h_bcd (hum, h_bcd);

bcd2seg i_t_bcd0 (t_bcd[ 3: 0], t_bcd0);
bcd2seg i_t_bcd1 (t_bcd[ 7: 4], t_bcd1);
bcd2seg i_t_bcd2 (t_bcd[11: 8], t_bcd2);
bcd2seg i_t_bcd3 (t_bcd[15:12], t_bcd3);
bcd2seg i_t_bcd4 (t_bcd[19:16], t_bcd4);
bcd2seg i_t_bcd5 (t_bcd[23:20], t_bcd5);

bcd2seg i_p_bcd0 (p_bcd[ 3: 0], p_bcd0);
bcd2seg i_p_bcd1 (p_bcd[ 7: 4], p_bcd1);
bcd2seg i_p_bcd2 (p_bcd[11: 8], p_bcd2);
bcd2seg i_p_bcd3 (p_bcd[15:12], p_bcd3);
bcd2seg i_p_bcd4 (p_bcd[19:16], p_bcd4);
bcd2seg i_p_bcd5 (p_bcd[23:20], p_bcd5);

bcd2seg i_h_bcd0 (h_bcd[ 3: 0], h_bcd0);
bcd2seg i_h_bcd1 (h_bcd[ 7: 4], h_bcd1);
bcd2seg i_h_bcd2 (h_bcd[11: 8], h_bcd2);
bcd2seg i_h_bcd3 (h_bcd[15:12], h_bcd3);
bcd2seg i_h_bcd4 (h_bcd[19:16], h_bcd4);
bcd2seg i_h_bcd5 (h_bcd[23:20], h_bcd5);

endmodule