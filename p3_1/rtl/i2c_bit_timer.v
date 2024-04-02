module i2c_bit_timer #(parameter SIZE = 8)
(
    input Clk, Rst_n, Start, Stop,
    input [SIZE-1:0] Ticks,
    output reg Out
);

reg [SIZE-1:0] cnt;

// Lògica de comptador
always @(posedge Clk or negedge Rst_n) begin

    // Reset
    if (!Rst_n)                 cnt <= {SIZE{1'b0}};

    else
        if (Start)              cnt <= Ticks; // Renici forçat o auto-reinici
        else if (Stop)          cnt <= cnt;   // Parada
        else if (~|cnt)         cnt <= Ticks; // Start i Stop tenen prioritat respecte això
        else                    cnt <= cnt - 1'b1; // Compta cap avall
end

// Lògica de sortida
always @(posedge Clk or negedge Rst_n) begin

    // Reset
    if (!Rst_n)                 Out <= 1'b0;

    else
        if (Start || ~|cnt)     Out <= 1'b1; // Reinici forçat o auto-reinici
        else                    Out <= 1'b0;
end
    
endmodule