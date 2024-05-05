/********1*********2*********3*********4*********5*********6*********7*********8
* File : sys_model.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/04/2023   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
*   System model. Clock generation. reset and useful task to wait N clocks.
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2023
*
*********1*********2*********3*********4*********5*********6*********7*********/

`include "../misc/timescale.v"

module sys_model #(
  parameter CLK_HALFPERIOD = 5,
  parameter DELAY = 2 // delay between clock posedge and check
)(
  output reg Clk,
  output reg Rst_n
);

  //___________________________________________________________________________
  // 100 MHz clock generation
  initial Clk = 1'b0;
  always #CLK_HALFPERIOD Clk = ~Clk;

  // reset initialization
  initial Rst_n = 1'b1;

  task reset;
  // generation of reset pulse
    input [32-1:0] Ncycles;
    begin
      Rst_n = 1'b0;
      wait_cycles(Ncycles);
      Rst_n = 1'b1;
    end
  endtask

  task wait_cycles;
  // wait for N clock cycles
    input [32-1:0] Ncycles;
    begin
      repeat(Ncycles) begin
        @(posedge Clk);
          #DELAY;
      end
    end
  endtask

endmodule
