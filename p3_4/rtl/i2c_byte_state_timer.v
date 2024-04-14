/***********************************************************************************
 * Comptador extern de tipus count-down per a la correspondència entre estats del 
 * controlador a nivell de bit i el controlador a nivell de byte de la UC del con- 
 * trolador del mestre I2C.
 **********************************************************************************/

`include "../misc/timescale.v"

module i2c_byte_state_timer #(parameter SIZE = 3)
(
    input Clk, Rst_n, Ack, Load,
    output wire Out
);

reg [SIZE-1:0] Cnt;

// Lògica de comptador
always @(posedge Clk or negedge Rst_n) begin

    // Reset
    if (!Rst_n)         Cnt <= {SIZE{1'b0}};    // Posar tots els bits de cnt a 0

    else if (Load)      Cnt <= {SIZE{1'b1}};    // Posar tots els bits de cnt a 1 si es detecta càrrega
    else if (Ack)       Cnt <= Cnt - 1'b1;      // Compta cap avall
    else                Cnt <= Cnt;             // Manté el valor si no es dóna cap cas anterior
end

assign Out = ~|Cnt;                             // Posa la sortida a 1 quan el comptador arriba a 0

/* Lògica de sortida
always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n)         Out <= 1'b1;
    else                Out <= ~|Cnt;
end
*/

endmodule