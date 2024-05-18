module sync_reg #(
  parameter NSTAGES = 2
)(
  input Clk,
  input Rst_n,
  input In,
  output Out
);

  reg [NSTAGES-1:0] registers;

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) registers <= {NSTAGES{1'b0}};
    else       registers <= {registers[NSTAGES-2:0],In};

  assign Out = registers[NSTAGES-1];

endmodule
