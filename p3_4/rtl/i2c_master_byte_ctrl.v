/************************************************************************************
 *Controlador a nivell de bit de la UC del mestre I2C.
 ************************************************************************************/

// Inclusió de llibreries externes
`include "../misc/timescale.v"
`include "i2c_master_defines.v"

// Definició del mòdul
module i2c_master_byte_ctrl #(parameter SIZE = 3, NBITS = 3)
(                                   // '*' means this module, '-->' means direction of information transfer
    input               Clk,        // Master clock input 
    input               Rst_n,      // Asynch active low reset
    input               Start,      // Generate start condition
    input               Stop,       // Generate stop condition
    input               Read,       // Read from slave 
    input               Write,      // Write to slave
    input               Tx_ack,     // When master as receiver, send ACK(='0') or NACK(='1') (master regs. --> *)
    input               I2C_al,     // I2C bus arbitration lost (bit controller --> *)
    input               SR_sout,    // Serial output bit from shift register 
    input               Bit_ack,    // Command complete acknowledge (bit level operation from bit controller) (bit controller --> *)
    input               Bit_rxd,    // Received bit (from bit controller, also sent as serial input to shift register)
    output reg          Rx_ack,     // Received acknowledge bit (ACK/NACK from slave) (* --> master regs.)
    output reg          I2C_done,   // Command completed  (* --> master regs.)
    output reg          SR_load,    // Load Tx/Rx data to shift register
    output reg          SR_shift,   // Shift data one position in shift register
    output reg [3:0]    Bit_cmd,    // Command to execute (* --> bit controller)      // Comandes definides a "i2c_master_defines.v"
    output reg          Bit_txd     // Data to transmit (* --> bit controller)
);

reg  [NBITS-1:0] state, next;   // Variables d'estat present i estat futur
reg  en_ack, loadCounter;       // Senyals habilitació Ack i sortida del comptador extern
wire counterOut;                // Sortida del comptador extern

// Decodificador d'estats
localparam  IDLE      = 4'd0, 
            START     = 4'd1,
            STOP      = 4'd2,
            READ_A    = 4'd3,
            READ      = 4'd4,
            WRITE_A   = 4'd5,
            WRITE     = 4'd6,
            ACK       = 4'd7;

// Instanciació del comptador extern
i2c_byte_state_timer #(.SIZE(SIZE)) state_timer ( 
    .Clk    (Clk),
    .Rst_n  (Rst_n),
    .Ack    (ck_ack), // provar amb ck_ack i amb SR_shift
    .Load   (loadCounter),
    .Out    (counterOut)
);

assign ck_ack = Bit_ack & en_ack; // Controlem si deixem que ack passi al comptador

// Lògica seqüencial per al canvi d'estat
always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n)     state <= {NBITS{1'b0}}; // Posem tots els bits d'estat a 0 quan es fa reset
    else            state <= next;          // Passem a l'estat següent en cas contrari
end

// Lògica d'estat futur
always @(*) begin
    case (state)
        IDLE: begin
            if      (Start) next = START;      // 7è bit dicta START 
            else if  (Stop) next = STOP;       // 6è bit dicta STOP 
            else if  (Read) next = READ_INI;   // 5è bit dicta READ 
            else if (Write) next = WRITE_INI;  // 4t bit dicta WRITE 
            else            next = IDLE;
        end

        START: begin
            if (Bit_ack || Stop) next = IDLE;
            else                 next = START;
        end

        STOP: begin
            if (Bit_ack) next = IDLE;
            else         next = STOP; 
        end

        READ_INI: begin
            if         (Stop) next = IDLE;
            else if (Bit_ack) next = READ;
            else              next = READ_INI;
        end

        READ: begin
            if            (Stop) next = IDLE;
            else if (counterOut) next = IDLE;
            else                 next = READ;
        end

        WRITE_INI: begin
            if         (Stop) next = IDLE;
            else if (Bit_ack) next = WRITE;
            else              next = WRITE_INI; 
        end

        WRITE: begin
            if            (Stop) next = IDLE;
            else if (counterOut) next = IDLE;
            else                 next = READ;
        end

        default:                 next = IDLE;
    endcase 
end

// Lògica de sortida
always @(posedge Clk or negedge Rst_n) begin
    if(!Rst_n) begin
        en_ack      <= 1'b0;
        loadCounter <= 1'b0;
        Bit_cmd     <= `I2C_CMD_NOP;
        Rx_ack      <= 1'b0;
        Bit_txd     <= 1'b0;
        I2C_done    <= 1'b1;
        SR_load     <= 1'b0;
        SR_shift    <= 1'b0;
    end else if(I2C_al) begin
        en_ack      <= 1'b0;
        loadCounter <= 1'b0;
        Bit_cmd     <= `I2C_CMD_NOP;
        Rx_ack      <= 1'b0;
        Bit_txd     <= 1'b0;
        I2C_done    <= 1'b1;
        SR_load     <= 1'b0;
        SR_shift    <= 1'b0;
    end else
        case (state)
            IDLE: begin
                en_ack <= 1'b0; // Deshabilitem el comptador
                Bit_cmd  <= `I2C_CMD_NOP;
                Rx_ack   <= Rx_ack;
                Bit_txd  <= Bit_txd;
                I2C_done <= 1'b1;
                SR_load  <= 1'b0;
                SR_shift <= 1'b0;
            end

            START: begin
                loadCounter <= 1'b1;
                en_ack  <= 1'b0; // Habilitem el comptador
                Bit_cmd <= `I2C_CMD_START; // Enviem la comanda de START
                Rx_ack   <= Rx_ack; 
                Bit_txd  <= Bit_txd;
                I2C_done <= 1'b0;
                SR_load  <= 1'b0; 
                SR_shift <= 1'b0;
            end

            READ_INI: begin   // Lectura primer bit i habilitació del ack al counter
                // Això ens estalvia bits
                Bit_cmd  <= `I2C_CMD_READ;   // Enviem comanda de lectura
                if (counterOut && Bit_ack)  loadCounter <= 1'b1; // Carreguem el comptador si el comptador ha arribat a 0 i rebem un Ack
                else                        loadCounter <= 1'b0;
                en_ack   <= 1'b1;            // Habilitem el comptador
                SR_shift <= Bit_rxd;         // Passem en sèrie al shift register el bit rebut
            end

            READ: begin
                Bit_cmd  <= `I2C_CMD_READ;
                en_ack   <= en_ack;
                SR_shift <= 1'b1;
                if (Tx_ack)     Bit_txd <= 1'b0; // Envia ACK si s'han rebut correctament les dades de l'esclau
                else            Bit_txd <= 1'b1; // Envia NACK si no s'han rebut correctament les dades de l'esclau
            end
            
            WRITE_INI: begin
                Bit_cmd  <= `I2C_CMD_WRITE;  // Enviem comanda d'escriptura
                if (counterOut && Bit_ack)  loadCounter <= 1'b1;
                else                        loadCounter <= 1'b0;
                en_ack   <= 1'b1;            // Habilitem ack al counter
                Bit_txd  <= SR_sout;         // Passem en sèrie al shift register el bit a escriure
                SR_shift <= 1'b1;            // Fem desplaçament de dades al shift register
            end

            WRITE: begin
                en_ack   <= en_ack;
                Bit_cmd  <= `I2C_CMD_WRITE;
                Bit_txd  <= SR_sout;    // Passem en sèrie al shift register el bit a escriure
                SR_shift <= 1'b1;       // Fem desplaçament de dades al shift register
            end
            
            default: begin
                Bit_cmd  <= `I2C_CMD_NOP;
                loadCounter <= 1'b0;
                en_ack      <= 1'b0;
                Rx_ack   <= Rx_ack;
                Bit_txd  <= Bit_txd;
                I2C_done <= I2C_done;
                SR_load  <= 1'b0;
                SR_shift <= 1'b0;
            end

            ACK: begin
                if  (Read) begin
                    Rx_ack <= 1'b1;
                    
                end
                else if (Write) begin
                    
                end else begin
                    Bit_cmd <= `I2C_CMD_NOP;
                end

                if stop
            end
        endcase
end

endmodule