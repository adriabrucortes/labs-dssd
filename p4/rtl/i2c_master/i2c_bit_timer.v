/********1*********2*********3*********4*********5*********6*********7*********8
* File : timer.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/05/2023   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* Cyclic timer based on a backwards counter.
* It generates an interrupt pulse every N clock cycle.
*
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2023
*
*********1*********2*********3*********4*********5*********6*********7*********/
`include "../misc/timescale.v"

module i2c_bit_timer #(
  parameter SIZE = 8
)(
  input Clk,
  input Rst_n,
  input Start,
  input Stop,
  input [SIZE-1:0] Ticks,
  output reg Out
);

  reg [SIZE-1:0] counter;

  // counts the timer ticks
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      counter <= {SIZE{1'b0}};
    else if(Start || ~|counter)
      counter <= Ticks;
    else if(Stop)
      counter <= counter;
    else
      counter <= counter - 1'b1;

  // generats the interrupt pulse
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      Out <= 1'b0;
    else if(Start || ~|counter)
      Out <= 1'b1;
    else if(Stop)
      Out <= 1'b0;
    else
      Out <= 1'b0;

endmodule
