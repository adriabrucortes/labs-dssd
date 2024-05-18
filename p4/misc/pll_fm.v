`include "../misc/timescale.v"

module pll_cv(input refclk, input rst, output reg outclk_0, output reg outclk_1);
  initial begin
    outclk_1 = 0;
    #2 outclk_0 = 0;
  end

  always #5 outclk_0 = ~outclk_0;
  assign #500 outclk_1 = ~outclk_1;

endmodule
