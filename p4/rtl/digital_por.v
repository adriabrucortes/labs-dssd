/*
* reset synchronizer logic is designed to take afavent of hte bes to both
* asynchronous synchornous reset styles.
* An external reset signal asynchronously resets a pair of master reset flip-flops, which in turn
drive the master reset signal asynchronously through the reset buffer tree to the rest of the flipflops in the design. The entire design will be asynchronously reset.
Reset removal is accomplished by de-asserting the reset signal, which then permits the d-input of
the first master reset flip-flop (which is tied high) to be clocked through a reset synchronizer. It
typically takes two rising clock edges after reset removal to synchronize removal of the master
reset.
*/

`include "../misc/timescale.v"

module digital_por(
  input Clk,
  input Asyncrst_n,
  output reg Rst_n
);

reg rff1;

always @(posedge Clk or negedge Asyncrst_n)
  if(!Asyncrst_n) {Rst_n,rff1} <= 2'b0;
  else            {Rst_n,rff1} <= {rff1,1'b1};


endmodule
