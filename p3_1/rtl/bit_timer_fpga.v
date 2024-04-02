module bit_timer_fpga (
    input Clk, Rst_n, Start, Stop,
    input [7:0] Ticks,
    output wire Out
);

i2c_bit_timer timer (
    .Clk           (~Clk),
    .Rst_n         (Rst_n),
    .Start         (~Start),
    .Stop          (~Stop),
    .Ticks         (Ticks),
    .Out           (Out)
);

endmodule