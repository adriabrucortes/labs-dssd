`include "../misc/timescale.v"
`include "i2c_master_defines.v"

module i2c_master_byte_ctrl #(parameter SIZE = 3)
(
    input               Clk,
    input               Rst_n,
    input               Start,
    input               Read,
    input               Write,
    input               Tx_ack,
    input               I2C_al,
    input               SR_sout,
    input               Bit_ack,
    input               Bit_rxd,
    output reg          Rx_ack,
    output reg          I2C_done,
    output reg          SR_load,
    output reg          SR_shift,
    output [3:0] reg    Bit_cmd,
    output reg          Bit_txd
);

reg [NSTATE-1:0]    state, next;
// reg [SIZE-1:0]      Ticks;
reg  en_ack, load;
wire cnt;

localparam  IDLE    = 4'd0,
            START   = 4'd1,
            STOP    = 4'd2,
            READ    = 4'd3,
            WRITE   = 4'd4;

i2c_byte_state_timer state_timer #(SIZE) (
    .Clk    (Clk),
    .Rst_n  (Rst_n),
    .Ack    (SR_shift),
    .Load   (load),
    .Out    (cnt)
);

assign ck_ack = ack && en_ack; // Controlem si deixem que ack passi al comptador

always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n)     state = {NBITS{1'b0}};
    else            state = next;
end

always @(posedge Clk) begin
    case (state)
        IDLE: begin
            if      (CR[3]) next = START;  // 7è bit dicta START
            else if (CR[2]) next = STOP;   // 6è bit dicta STOP
            else if (CR[1]) next = READ;   // 5è bit dicta READ
            else if (CR[0]) next = WRITE;  // 4t bit dicta WRITE
            else            next = IDLE;
        end

        START: begin
            if (ack)        next = IDLE;
            else            next = START;
        end

        STOP: begin
            if (ack)        next = IDLE;
            else            next = STOP; 
        end

        READ: begin
            if (cnt)        next = IDLE;
            else            next = READ;
        end

        WRITE: begin
            if (cnt)        next = IDLE;
            else            next = WRITE; 
        end

        default:            next = IDLE;
    endcase 
end

always @(*) begin
    case (state)
        IDLE: begin
            en_ack = 1'b0; // Deshabilitem ack al counter
    
        end
        READ: begin
            // Això ens estalvia bits
            if (cnt && ack)     load <= 1'b1;
            else                load <= 1'b0;

            en_ack = 1'b1; // Habilitem ack al counter

            // Comandes

        end
        WRITE: begin
            if (cnt && ack)     load <= 1'b1;
            else                load <= 1'b0;

            en_ack = 1'b1; // Habilitem ack al counter

            // Comandes

        end
        default: begin
            
        end
    endcase
end

endmodule