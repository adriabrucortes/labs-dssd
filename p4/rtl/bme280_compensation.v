// https://github.com/adafruit/Adafruit_BME280_Library/blob/master/Adafruit_BME280.cpp
// https://electronics.stackexchange.com/questions/328618/declare-signed-numbers-in-verilog
module bme280_compensation(
  input  signed [32-1:0] TempBin, PressBin, HumBin,
  input  signed [32-1:0] DigT1, DigT2, DigT3,
  input         [64-1:0] DigP1,
  input  signed [64-1:0] DigP2, DigP3, DigP4, DigP5, DigP6, DigP7, DigP8, DigP9,
  input         [32-1:0] DigH1, DigH2, DigH3,
  input  signed [32-1:0] DigH4, DigH5, DigH6,
  output signed [32-1:0] Temp,
  output        [32-1:0] Press, Hum
);

  wire signed [32-1:0] tvar1, tvar2, t_fine;
  wire signed [64-1:0] pt_fine, pvar1, pvar2, pvar22, pvar222, pvar11, pvar111, paux0, paux1, pvar1111, pvar2222, paux2, paux3;
  wire signed [32-1:0] paux4;
  wire signed [32-1:0] hvar1, hvar2, hvar3, hvar4, hvar5, hvar22, hvar33, hvar44, hvar222, hvar333, hvar444, hvar55, hvar555, hvar5555;

  // temperature calc
  assign tvar1 = ((TempBin>>3) - (DigT1<<1)) * (DigT2>>11);
  assign tvar2 = (((((TempBin>>4) - DigT1) * ((TempBin>>4) - (DigT1))) >> 12) * DigT3) >> 14;
  assign t_fine = tvar1 + tvar2;
  assign Temp = ((t_fine * 5) + 128) >> 8;

  // pressure calc
  assign pt_fine  = {32'd0, t_fine};
  assign pvar1    = pt_fine - 64'sd128000;
  assign pvar2    = pvar1 * pvar1 * DigP6;
  assign pvar22   = pvar2 + ((pvar1 * DigP5) << 17);
  assign pvar222  = pvar2 + (DigP4 << 35);
  assign pvar11   = ((pvar1 * pvar1 * DigP3) >> 8) + ((pvar1 * DigP2) << 12);
  assign pvar111  = ((64'sh0000800000000000 + pvar11) * DigP1) >> 33;
  assign paux0    = (pvar111==64'd0) ? 64'd0 : 64'sd1048576 - PressBin;
  assign paux1    = (((paux0 << 31) - pvar222) * 64'sd3125) / pvar111;
  assign pvar1111 = (DigP9 * (paux1 >> 13) * (paux1 >> 13)) >> 25;
  assign pvar2222 = (DigP8 * paux1) >> 19;
  assign paux2    = ((paux1 + pvar1111 + pvar2222) >> 8) + (DigP7 << 4);
  assign paux3    = paux2 >> 8;
  assign paux4    = paux3[31:0];
  assign Press    = (pvar111==64'd0) ? 32'd0 : paux4;

  // assign pvar2 = (pvar1 * pvar1 * DigP6) + ((pvar1 * DigP5) << 17) + (DigP4 << 35);
  // assign pvar3 = ((pvar1 * pvar1 * DigP3) >> 8) + ((pvar1 * DigP2)<<12);
  // assign pvar4 = ((64'h0000800000000000 + pvar3) * DigP1) >> 33;
  // assign pvar5 = (pvar4==64'd0) ? 64'd0 : ((((64'd1048576 - PressBin) << 31) - pvar2) * 3125)/pvar4;
  // assign pvar6 = (DigP9 * (pvar5 >> 13) * (pvar5 >> 13)) >> 25;
  // assign pvar7 = (DigP8 * pvar5) >> 19;
  // assign pvar8 = ((pvar5 + pvar6 + pvar7) >> 8) + (DigP7 << 4);
  // assign Press = (pvar4==64'd0) ? 32'd0 : pvar8 >> 8;

  // humidity calc
  assign hvar1   = t_fine - 32'sd76800;
  assign hvar2   = HumBin << 14;
  assign hvar3   = DigH4 << 20;
  assign hvar4   = DigH5 * hvar1;
  assign hvar5   = (((hvar2 - hvar3) - hvar4) + (32'sd16384)) >> 15;
  assign hvar22  = (hvar1 * DigH6) >> 10;
  assign hvar33  = (hvar1 * DigH3) >> 11;
  assign hvar44  = ((hvar22 * (hvar33 + 32'sd32768)) >> 10) + 32'sd2097152;
  assign hvar222 = ((hvar44 * DigH2) + 32'sd8192) >> 14;
  assign hvar333 = hvar5 * hvar222;
  assign hvar444 = ((hvar333 >> 15) * (hvar333 >> 15)) >> 7;
  assign hvar55  = hvar333 - ((hvar444 * DigH1) >> 4);
  assign hvar555 = (hvar55< 32'sd0) ? 32'd0 : hvar55;
  assign hvar5555= (hvar555 > 32'sd419430400) ? 32'sd419430400 : hvar555;
  assign Hum     = (hvar5555 >> 12);

  // assign hvar2 = (((((HumBin << 14) - ((DigH4)<<20) - ((DigH5)*hvar1)) + (32'd16384))>>15) * (((((((hvar1*DigH6)>>10) * (((hvar1*DigH3)>>11) + (32'd32768)))>>10) + (32'd2097152)) * DigH2 + 8192) >> 14));
  // assign hvar3 = (hvar2 - (((((hvar2 >> 15) * (hvar2 >> 15)) >> 17) * (DigH1)) >> 4));
  // assign hvar4 = (hvar3 < 0) ? 32'd0 : hvar3;
  // assign hvar5 = (hvar4 > 32'd419430400) ? 32'd419430400 : hvar4;
  // assign Hum = (hvar5 >> 12) >> 10;

endmodule
