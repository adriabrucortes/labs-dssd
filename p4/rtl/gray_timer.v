//-----------------------------------------------------------------------------
// Title         : Timer using a Gray Counter
// Project       : Test TOPFEB2016-C2
//-----------------------------------------------------------------------------
// File          : gray_timer.v
// Author        : Joan Canals  <jcanals@el.ub.edu>
// Created       : 2016/05/09
// Last modified : 2016/05/09
//-----------------------------------------------------------------------------
// Description :
// The Gray timer counts until Limit value, and it is achieved set high the
// Interrupt output. To start again it must be reset.
//
//-----------------------------------------------------------------------------
// Copyright (c) 2016 by University of Barcelona This model is the confidential
// and proprietary property of University of Barcelona and the possession or use
// of this file requires a written license from University of Barcelona.
//-----------------------------------------------------------------------------
// Modification history :
// 2016/05/09: Created
// 03/10/2016: Add registers and mod FSM to perform the Decay and upslope tests
//             to characterize each bin of circuit 2.
//-----------------------------------------------------------------------------

`include "../misc/timescale.v"

module gray_timer #(parameter SIZE = 8) (Clk, Rst_n, Limit, Int);

input            Clk;             // Clock reference for the timer
input            Rst_n;           // Resets the timer. Active low
input [SIZE-1:0] Limit;           // Timer ticks limit

output           Int;

reg              Int;
reg   [SIZE-1:0] gray_code;
reg   [SIZE-1:0] tog;
wire  [SIZE-1:0] gray_code_comp;

integer i,j,k;

assign gray_code_comp = (Limit>>1) ^ Limit;

always @(posedge Clk or negedge Rst_n)
  if(Rst_n==1'b0) begin
    gray_code <= 0;
    Int <= 1'b0;
  end
  else begin //sequential update
      if (gray_code_comp==gray_code) begin
        Int  <= 1'b1;
      end
      else begin //enabled
        tog = 0;
        for (i=0; i<=SIZE-1; i=i+1) begin  //i loop
          //
          // Toggle bit if number of bits set in [SIZE-1:i] is even
          // XNOR current bit up to MSB bit
          //
          for (j=i; j<=SIZE-1; j=j+1) tog[i] = tog[i] ^ gray_code[j];
          tog[i] = !tog[i];
          //
          // Disable tog[i] if a lower bit is toggling
          //
          for (k=0; k<=i-1; k=k+1) tog[i] = tog[i] && !tog[k];
        end //i loop
        //
        //Toggle MSB if no lower bits set (covers code wrap case)
        //
        if (tog[SIZE-2:0]==0) tog[SIZE-1] = 1;
        //
        //Apply the toggle mask
        //
        gray_code <= gray_code ^ tog;
      end //enabled
  end //sequential update
endmodule
