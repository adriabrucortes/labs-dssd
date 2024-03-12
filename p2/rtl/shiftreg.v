module shiftreg #(parameter SIZE = 8) (
    input Clk, Rst_n, Load, En,
    input SerIn,
    input [SIZE-1:0] DataIn,
    output wire SerOut,
    output reg [SIZE-1:0] DataOut
);

// Sortida serial
assign SerOut = DataOut[SIZE-1];

// Càrrega i desplaçament
always @(posedge Clk or negedge Rst_n) begin

    // Reset
    if (!Rst_n)
        DataOut <= {SIZE{1'b0}};

    // Càrrega
    else if (Load)
        DataOut <= DataIn;

    // Desplaçament
    else if (En)
        DataOut <= {DataOut[SIZE-2:0], SerIn};

    // Mantenir
    else
        DataOut <= DataOut;
end

endmodule