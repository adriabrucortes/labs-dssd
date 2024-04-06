`include "../misc/timescale.v"
`include "i2c_master_defines.v"

module i2c_master_byte_ctrl (
    input       Clk,
    input       Rst_n,
    input [4:0] CR,
    input       Shr,
    output reg  i2c_done,
    output reg  ack,
    output reg  Shr_serin,
    output reg  Shr_load,
    output reg  Shr_
);
    
endmodule