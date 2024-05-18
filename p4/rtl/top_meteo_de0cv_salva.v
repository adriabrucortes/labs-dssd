
`include "../misc/timescale.v"
`define RTL_LVL

module top_meteo_de0cv_salva (
  input  Clk_i,
  input  Rst_n_i,
  inout  SCL_io,
  inout  SDA_io,
  output SlaveAddr_LSb_o,
  output Enable_i2c_o,
  output Error_o,
  output reg [7-1:0] Hex0_o, Hex1_o, Hex2_o, Hex3_o, Hex4_o, Hex5_o,
  input [9-1:0] Sel_i
);

  localparam DWIDTH = 8;
  localparam AWIDTH = 3;
  localparam SLADDR = 7'b111_0110;

  wire clk100MHz, clk1MHz;
  wire rst_n, sRst_n;

  wire scl_oen, sda_oen;
  wire scl_o, sda_o;
  wire i2c_int;

	wire [AWIDTH-1:0] dbus_addr;
	wire [DWIDTH-1:0] dbus_din, dbus_dout;
  wire dbus_wr;
  wire i2cc_start, i2cc_rdwr, i2cc_last, i2cc_done;
  wire [DWIDTH-1:0] i2cc_addr, i2cc_txd, i2cc_rxd;
  wire timerEn, timerInt, sTimerInt;

  wire [20-1:0] tempBin, pressBin;
  wire [16-1:0] humBin;
  wire [16-1:0] digT1, digT2, digT3;
  wire [16-1:0] digP1, digP2, digP3, digP4, digP5, digP6, digP7, digP8, digP9;
  wire [8-1:0]  digH1, digH3, digH6;
  wire [16-1:0] digH2, digH4, digH5;
  wire [32-1:0] temp, press, hum;
  wire [(32+(32-4)/3):0] tempBcd, pressBcd, humBcd;
  wire [(20+(20-4)/3):0] tBcd, pBcd;
  wire [(16+(16-4)/3):0] hBcd;

  wire [8-1:0] thex5, thex4, thex3, thex2, thex1, thex0;
  wire [8-1:0] phex5, phex4, phex3, phex2, phex1, phex0;
  wire [8-1:0] hhex5, hhex4, hhex3, hhex2, hhex1, hhex0;
  wire [7-1:0] tbcd5, tbcd4, tbcd3, tbcd2, tbcd1, tbcd0;
  wire [7-1:0] pbcd5, pbcd4, pbcd3, pbcd2, pbcd1, pbcd0;
  wire [7-1:0] hbcd5, hbcd4, hbcd3, hbcd2, hbcd1, hbcd0;
  wire [7-1:0] tpbcd5, tpbcd4, tpbcd3, tpbcd2, tpbcd1, tpbcd0;
  wire [7-1:0] prbcd5, prbcd4, prbcd3, prbcd2, prbcd1, prbcd0;
  wire [7-1:0] hubcd5, hubcd4, hubcd3, hubcd2, hubcd1, hubcd0;
  wire [8-1:0] dig3H, dig3L, dig2H, dig2L, dig1H, dig1L;

  assign SlaveAddr_LSb_o = 1'b0;
  assign Enable_i2c_o = 1'b1;

  //select measure to show
  always @(*)
    casex(Sel_i)
      9'bxxxxxxxx1 : begin
        Hex5_o = tbcd5;//~(7'b0000111)
        Hex4_o = tbcd4;
        Hex3_o = tbcd3;
        Hex2_o = tbcd2;
        Hex1_o = tbcd1;
        Hex0_o = tbcd0;
      end
      9'bxxxxxxx10 : begin
        Hex5_o = pbcd5;//~(7'b1110011)
        Hex4_o = pbcd4;
        Hex3_o = pbcd3;
        Hex2_o = pbcd2;
        Hex1_o = pbcd1;
        Hex0_o = pbcd0;
      end
      9'bxxxxxx100 : begin
        Hex5_o = hbcd5;//~(7'b1110110)
        Hex4_o = hbcd4;
        Hex3_o = hbcd3;
        Hex2_o = hbcd2;
        Hex1_o = hbcd1;
        Hex0_o = hbcd0;
      end
      9'bxxxxx1000 : begin
        Hex5_o = thex5[6:0];//~(7'b0000111)
        Hex4_o = thex4[6:0];
        Hex3_o = thex3[6:0];
        Hex2_o = thex2[6:0];
        Hex1_o = thex1[6:0];
        Hex0_o = thex0[6:0];
      end
      9'bxxxx10000 : begin
        Hex5_o = phex5[6:0];//~(7'b1110011)
        Hex4_o = phex4[6:0];
        Hex3_o = phex3[6:0];
        Hex2_o = phex2[6:0];
        Hex1_o = phex1[6:0];
        Hex0_o = phex0[6:0];
      end
      9'bxxx100000 : begin//~(7'b1110110)
        Hex5_o = hhex5[6:0];
        Hex4_o = hhex4[6:0];
        Hex3_o = hhex3[6:0];
        Hex2_o = hhex2[6:0];
        Hex1_o = hhex1[6:0];
        Hex0_o = hhex0[6:0];
      end
      9'bxx1000000 : begin
        Hex5_o = tpbcd5;//~(7'b0000111)
        Hex4_o = tpbcd4;
        Hex3_o = tpbcd3;
        Hex2_o = tpbcd2;
        Hex1_o = tpbcd1;
        Hex0_o = tpbcd0;
      end
      9'bx10000000 : begin
        Hex5_o = prbcd5;//~(7'b1110011)
        Hex4_o = prbcd4;
        Hex3_o = prbcd3;
        Hex2_o = prbcd2;
        Hex1_o = prbcd1;
        Hex0_o = prbcd0;
      end
      9'b100000000 : begin
        Hex5_o = hubcd5;//~(7'b1110110)
        Hex4_o = hubcd4;
        Hex3_o = hubcd3;
        Hex2_o = hubcd2;
        Hex1_o = hubcd1;
        Hex0_o = hubcd0;
      end
      9'b000000000 : begin
        Hex5_o = dig3H[6:0];
        Hex4_o = dig3L[6:0];
        Hex3_o = dig2H[6:0];
        Hex2_o = dig2L[6:0];
        Hex1_o = dig1H[6:0];
        Hex0_o = dig1L[6:0];
      end
    endcase

  hex2seg i_dig3H (4'hF, dig3H);
  hex2seg i_dig3L (4'hF, dig3L);
  hex2seg i_dig2H (digP4[15:12], dig2H);
  hex2seg i_dig2L (digP4[11:8], dig2L);
  hex2seg i_dig1H (digP4[7:4], dig1H);
  hex2seg i_dig1L (digP4[3:0], dig1L);


  bcd2seg i_tpbcd5 ({2'd0,tBcd[25:24]}, tpbcd5);
  bcd2seg i_tpbcd4 (tBcd[23:20], tpbcd4);
  bcd2seg i_tpbcd3 (tBcd[19:16], tpbcd3);
  bcd2seg i_tpbcd2 (tBcd[15:12], tpbcd2);
  bcd2seg i_tpbcd1 (tBcd[11: 8], tpbcd1);
  bcd2seg i_tpbcd0 (tBcd[ 7: 4], tpbcd0);


  bcd2seg i_prbcd5 (pBcd[23:19], prbcd5);
  bcd2seg i_prbcd4 (pBcd[19:16], prbcd4);
  bcd2seg i_prbcd3 (pBcd[15:12], prbcd3);
  bcd2seg i_prbcd2 (pBcd[11: 8], prbcd2);
  bcd2seg i_prbcd1 (pBcd[ 7: 4], prbcd1);
  bcd2seg i_prbcd0 (pBcd[ 3: 0], prbcd0);

  bcd2seg i_hubcd4 (hBcd[19:16], hubcd4);
  bcd2seg i_hubcd3 (hBcd[15:12], hubcd3);
  bcd2seg i_hubcd2 (hBcd[11: 8], hubcd2);
  bcd2seg i_hubcd1 (hBcd[ 7: 4], hubcd1);
  bcd2seg i_hubcd0 (hBcd[ 3: 0], hubcd0);

  bin2bcd #(.W(20)) i_tpbcd (tempBin, tBcd);
  bin2bcd #(.W(20)) i_prbcd (pressBin, pBcd);
  bin2bcd #(.W(16)) i_hubcd (humBin, hBcd);

  hex2seg i_thex5 (4'h0,  thex5);
  hex2seg i_thex4 (tempBin[19:16], thex4);
  hex2seg i_thex3 (tempBin[15:12], thex3);
  hex2seg i_thex2 (tempBin[11: 8], thex2);
  hex2seg i_thex1 (tempBin[ 7: 4], thex1);
  hex2seg i_thex0 (tempBin[ 3: 0], thex0);

  hex2seg i_phex5 (4'h0,  phex5);
  hex2seg i_phex4 (pressBin[19:16], phex4);
  hex2seg i_phex3 (pressBin[15:12], phex3);
  hex2seg i_phex2 (pressBin[11: 8], phex2);
  hex2seg i_phex1 (pressBin[ 7: 4], phex1);
  hex2seg i_phex0 (pressBin[ 3: 0], phex0);

  hex2seg i_hhex5 (4'h0, hhex5);
  hex2seg i_hhex4 (4'h0, hhex4);
  hex2seg i_hhex3 (humBin[15:12], hhex3);
  hex2seg i_hhex2 (humBin[11: 8], hhex2);
  hex2seg i_hhex1 (humBin[ 7: 4], hhex1);
  hex2seg i_hhex0 (humBin[ 3: 0], hhex0);

  bcd2seg i_tbcd5 (tempBcd[23:20], tbcd5);
  bcd2seg i_tbcd4 (tempBcd[19:16], tbcd4);
  bcd2seg i_tbcd3 (tempBcd[15:12], tbcd3);
  bcd2seg i_tbcd2 (tempBcd[11: 8], tbcd2);
  bcd2seg i_tbcd1 (tempBcd[ 7: 4], tbcd1);
  bcd2seg i_tbcd0 (tempBcd[ 3: 0], tbcd0);

  bcd2seg i_pbcd5 (pressBcd[23:20], pbcd5);
  bcd2seg i_pbcd4 (pressBcd[19:16], pbcd4);
  bcd2seg i_pbcd3 (pressBcd[15:12], pbcd3);
  bcd2seg i_pbcd2 (pressBcd[11: 8], pbcd2);
  bcd2seg i_pbcd1 (pressBcd[ 7: 4], pbcd1);
  bcd2seg i_pbcd0 (pressBcd[ 3: 0], pbcd0);


  bcd2seg i_hbcd5 (humBcd[23:20], hbcd5);
  bcd2seg i_hbcd4 (humBcd[19:16], hbcd4);
  bcd2seg i_hbcd3 (humBcd[15:12], hbcd3);
  bcd2seg i_hbcd2 (humBcd[11: 8], hbcd2);
  bcd2seg i_hbcd1 (humBcd[ 7: 4], hbcd1);
  bcd2seg i_hbcd0 (humBcd[ 3: 0], hbcd0);

  bin2bcd #(.W(32)) i_tbcd (tempBin, tempBcd);
  bin2bcd #(.W(32)) i_pbcd (pressBin, pressBcd);
  bin2bcd #(.W(32)) i_hbcd (humBin, humBcd);

                                                                                                                                                                                                                                                                                                                                                                   

  bme280_reader #(
    .DWIDTH     ( DWIDTH     )
  ) i_cu (
    .Clk        ( clk100MHz  ),
    .Rst_n      ( rst_n      ),
    .I2CC_start ( i2cc_start ),
    .I2CC_rdwr  ( i2cc_rdwr  ),
    .I2CC_last  ( i2cc_last  ),
    .I2CC_addr  ( i2cc_addr  ),
    .I2CC_txd   ( i2cc_txd   ),
    .I2CC_rxd   ( i2cc_rxd   ),
    .I2CC_done  ( i2cc_done  ),
    .TempBin    ( tempBin    ),
    .PressBin   ( pressBin   ),
    .HumBin     ( humBin     ),
    .TimerEn    ( timerEn    ),
    .TimerInt   ( timerInt   ),
    .ErrorFlag  ( Error_o    ),
    .DigT1      ( digT1      ),
    .DigT2      ( digT2      ),
    .DigT3      ( digT3      ),
    .DigP1      ( digP1      ),
    .DigP2      ( digP2      ),
    .DigP3      ( digP3      ),
    .DigP4      ( digP4      ),
    .DigP5      ( digP5      ),
    .DigP6      ( digP6      ),
    .DigP7      ( digP7      ),
    .DigP8      ( digP8      ),
    .DigP9      ( digP9      ),
    .DigH1      ( digH1      ),
    .DigH3      ( digH3      ),
    .DigH6      ( digH6      ),
    .DigH2      ( digH2      ),
    .DigH4      ( digH4      ),
    .DigH5      ( digH5      )
  );

  bme280_i2c_ctrl #(
    .DWIDTH     ( DWIDTH ),
    .AWIDTH     ( AWIDTH ),
    .SLADDR     ( SLADDR )
  ) u_i2cc (
    .Clk        ( clk100MHz  ),
    .Rst_n      ( rst_n      ),
    .Dbus_addr  ( dbus_addr  ),
    .Dbus_di    ( dbus_dout  ),
    .Dbus_do    ( dbus_din   ),
    .Dbus_wr    ( dbus_wr    ),
    .I2C_start  ( i2cc_start ),
    .I2C_rdwr   ( i2cc_rdwr  ),
    .I2C_last   ( i2cc_last  ),
    .I2C_addr   ( i2cc_addr  ),
    .I2C_txd    ( i2cc_txd   ),
    .I2C_rxd    ( i2cc_rxd   ),
    .I2C_done   ( i2cc_done  )
  );

	i2c_master_top #(
    .DWIDTH     ( DWIDTH    ),
    .AWIDTH     ( AWIDTH    )
  ) u_i2c (
    .Clk        ( clk100MHz ),  // master clock input
    .Rst_n      ( rst_n     ),  // async active low reset
    .Addr       ( dbus_addr ),  // lower address bits
    .DataIn     ( dbus_din  ),  // databus input
    .DataOut    ( dbus_dout ),  // databus output
    .Wr         ( dbus_wr   ),  // write enable input
    .Int        ( i2c_int   ),  // interrupt request signal output
    .SclPadIn   ( SCL_io    ),  // SCL-line input
    .SclPadOut  ( scl_o     ),  // SCL-line output (always 1'b0)
    .SclPadEn   ( scl_oen   ),  // SCL-line output enable (active low)
    .SdaPadIn   ( SDA_io    ),  // SDA-line input
    .SdaPadOut  ( sda_o     ),  // SDA-line output (always 1'b0)
    .SdaPadEn   ( sda_oen   )   // SDA-line output enable (active low)
	);

  sync_reg #(.NSTAGES(2)) i_sync (
    .Clk        ( clk100MHz ),
    .Rst_n      ( rst_n     ),
    .In         ( sTimerInt ),
    .Out        ( timerInt  )
  );
`ifdef RTL_LVL 
  gray_timer #(.SIZE(8)) i_gtimer (
    .Clk        ( clk1MHz     ),
    .Rst_n      ( sRst_n & timerEn ),
    .Limit      ( 8'b10000000    ),
    .Int        ( sTimerInt   )
  );



`else
  gray_timer #(.SIZE(20)) i_gtimer (
    .Clk        ( clk1MHz     ),
    .Rst_n      ( sRst_n & timerEn ),
    .Limit      ( 20'd1000000    ),
    .Int        ( sTimerInt   )
  );
`endif

  pll_cv i_pll(
    .refclk     ( Clk_i       ),
    .rst        ( 1'b0        ),
    .outclk_0   ( clk100MHz   ),
    .outclk_1   ( clk1MHz     )
  );



  digital_por i_por  (clk100MHz, Rst_n_i, rst_n);
  digital_por i_spor (clk1MHz,   Rst_n_i, sRst_n);

  assign SCL_io = scl_oen ? 1'bz : scl_o;
  assign SDA_io = sda_oen ? 1'bz : sda_o;

endmodule
