/********1*********2*********3*********4*********5*********6*********7*********8
* File : shiftreg.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/02/2022   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* Complet non-cyclic shift register.
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2022
*
*********1*********2*********3*********4*********5*********6*********7*********/
`include "../misc/timescale.v"

module shiftreg #(parameter SIZE = 8)(
  input Clk,
  input Rst_n,
  input Load,
  input Shift,
  input SerIn,
  input [SIZE-1:0] DataIn,
  output SerOut,
  output [SIZE-1:0] DataOut
);

  reg [SIZE-1:0] register;
  // shift register
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
      register <= {SIZE{1'b0}};
    else if(Load)
      register <= DataIn;
    else if(Shift)
      register <= {register[SIZE-2:0], SerIn};
    else
      register <= register;

   // outputs
   assign SerOut = register[SIZE-1];
   assign DataOut = register;

endmodule
