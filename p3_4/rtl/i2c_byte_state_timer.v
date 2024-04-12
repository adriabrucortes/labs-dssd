module i2c_byte_state_timer #(parameter SIZE = 8)
(
    input Clk, Rst_n, Ack, Load,
    output wire Out
);

reg [SIZE-1:0] Cnt;

// Lògica de comptador
always @(posedge Clk or negedge Rst_n) begin

    // Reset
    if (!Rst_n)         Cnt <= {SIZE{1'b0}};

    else if (Load)      Cnt <= 3'd7;
    else if (Ack)       Cnt <= Cnt - 1'b1; // Compta cap avall
    else                Cnt <= Cnt;
end

assign Out = ~|Cnt

/* Lògica de sortida
always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n)         Out <= 1'b1;
    else                Out <= ~|Cnt;
end
*/

endmodule