/************************************************************************************
 *Controlador a nivell de bit de la UC del mestre I2C.
 ************************************************************************************/

// Inclusió de llibreries externes
`include "../misc/timescale.v"
`include "i2c_master_defines.v"

// Definició del mòdul
module i2c_master_byte_ctrl #(parameter SIZE = 3, NBITS = 4)
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

reg  [NBITS-1:0] state, next;           // Variables d'estat present i estat futur
reg  en_ack, loadCounter, SR_shift_en;  // Senyals habilitació Ack, sortida del comptador extern i habilitació de desplaçament
wire counterOut, ck_ack;                // Sortida del comptador extern i habilitació de recepció de bits d'Acknowledge

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
    .Ack    (ck_ack), 
    .Load   (loadCounter),
    .Out    (counterOut)
);

assign ck_ack = Bit_ack & en_ack; // Controlem si deixem que el bit d'Acknowledge passi al comptador
always @(*) begin
    SR_shift = Bit_ack & SR_shift_en; // Controlem l'habilitació de desplaçaments al registre de desplaçament
end

// Lògica seqüencial per al canvi d'estat
always @(posedge Clk or negedge Rst_n) begin
    if (!Rst_n)     state <= {NBITS{1'b0}}; // Posem tots els bits d'estat a 0 quan es fa reset
    else            state <= next;          // Passem a l'estat següent en cas contrari
end

// Lògica d'estat futur
always @(*) begin
    case (state)
        IDLE: begin
            if      (Start)                 next = START;   // En cas de que es detecti Start (CR[7]), passa a l'estat START
            else if (Read)                  next = READ_A;  // En cas de que es detecti Read (CR[5]), passa a l'estat STOP
            else if (Write)                 next = WRITE_A; // En cas de que es detecti Write (CR[4]), passa a l'estat WRITE_A
            else if (Stop)                  next = STOP;    // En cas de que es detecti Stop (CR[6]), passa a l'estat STOP
            else                            next = IDLE;    // En qualsevol altre cas, roman en IDLE
        end

        START: begin
            if      (Bit_ack && Read)       next = READ_A;  // En cas de que s'hagi donat una condició de Start i es detecti Read, passa a l'estat READ_A
            else if (Bit_ack && Write)      next = WRITE_A; // En cas de que s'hagi donat una condició de Start i es detecti Write, passa a l'estat WRITE_A
            else                            next = START;   // En qualsevol altre cas, roman en START
        end

        STOP: begin
            if (Bit_ack)                    next = IDLE;    // Quan s'acabi la fase de Stop passa a l'estat IDLE
            else                            next = STOP;    // En cas contrari, roman en STOP
        end

        READ_A: begin
            if (Bit_ack)                    next = READ;    // En cas de que s'acabi l'inici d'una lectura (estat READ_A), passa a l'estat READ
            else                            next = READ_A;  // En cas contrari roman en READ_A
        end

        READ: begin
            if (Bit_ack & counterOut)       next = ACK;     // En cas de que s'acabi una lectura (comptador arriba a zero), passa l'estat ACK
            else                            next = READ;    // En cas contrari, espera a acabar la lectura (roman en READ)
        end

        WRITE_A: begin
            if (Bit_ack)                    next = WRITE;   // En cas de que s'acabi l'inici d'una escriptura, passa a l'estat WRITE
            else                            next = WRITE_A; // En cas contrari roman en WRITE_A
        end

        WRITE: begin
            if (Bit_ack & counterOut)       next = ACK;     // En cas de que s'acabi una escriptura (comptador arriba a zero), passa a l'estat ACK
            else                            next = WRITE;   // En cas contrari, espera a que s'acabi l'escriptura (roman en WRITE)
        end

        ACK: begin
            if (Bit_ack & Stop)             next = STOP;    // En cas de que estant a l'estat ACK es rebi una condició de Stop, passa a l'estat STOP
            else if (Bit_ack)               next = IDLE;    // En cas de que no es rebi condició de Stop, passa l'estat IDLE
            else                            next = ACK;     // Roman en ACK si encara no ha acabat aquesta fase
        end

        default:                            next = IDLE;    // Per defecte l'estat futur és IDLE
    endcase 
end

// Lògica de sortida
always @(posedge Clk or negedge Rst_n) begin
    if(!Rst_n) begin // Quan es produeix un reset
        en_ack      <= 1'b0; // Deshabilita la recepció de bits d'Acknowledge
        loadCounter <= 1'b0; // Deshabilita la càrrega del comptador
        Bit_cmd     <= `I2C_CMD_NOP; // Envia com a següent comanda a executar l'operació nul·la
        Rx_ack      <= 1'b0; // Elimina els bits d'Acknowledge rebuts
        Bit_txd     <= 1'b0; // Elimina els bits a transmetre
        I2C_done    <= 1'b1; // Dona senyal de finalització de comunicació
        SR_load     <= 1'b0; // Deshabilita la càrrega de dades al registre de desplaçament
        SR_shift_en <= 1'b0; // així com la funció de desplaçament 
    end else if(I2C_al) begin // Quan es produeixi una pèrdua d'arbitratge
        en_ack      <= 1'b0; // Deshabilita la recepció de bits d'Acknowledge
        loadCounter <= 1'b0; // Deshabilita la càrrega al comptador
        Bit_cmd     <= `I2C_CMD_NOP; // Envia com a següent comanda a executar l'operació nul·la
        Rx_ack      <= 1'b0; // Elimina els bits d'Acknowledge rebuts
        Bit_txd     <= 1'b0; // Elimina els bits a transmetre
        I2C_done    <= 1'b1; // Dona senyal de finalització de comunicació
        SR_load     <= 1'b0; // Deshabilita la càrrega de dades al registre de desplaçament
        SR_shift_en <= 1'b0; // així com la funció de desplaçament
    end else begin // Altrament
        case (state) 
            IDLE: begin // A l'estat IDLE
                en_ack      <= 1'b0; // Deshabilita el comptador
                I2C_done    <= 1'b0; // Manté la comunicació oberta
                loadCounter <= 1'b1; // Carrega el comptador
                SR_shift_en <= 1'b0; // Deshabilita la funció de desplaçament del shift register

                if      (Start) Bit_cmd <= `I2C_CMD_START; // Si es rep una condició de Start, envia la comanda corresponent a executar
                else if (Read) begin            // Si es rep una solicitud de lectura
                    Bit_cmd <= `I2C_CMD_READ;   // Envia la comanda de lectura a executar
                    SR_load <= 1'b0;            // Deshabilita la càrrega al registre de desplaçament
                end
                else if (Write) begin           // Si es rep una solicitud de lectura
                    Bit_cmd <= `I2C_CMD_WRITE;  // Envia la comanda corresponent a executar
                    SR_load <= 1'b1;            // Habilita la càrrega al registre de desplaçament per al següent flanc
                end
                else if (Stop)  Bit_cmd <= `I2C_CMD_STOP; // En cas de rebre una condició de Stop, envia la comanda d'aturada
                else            Bit_cmd <= `I2C_CMD_NOP;  // En qualsevol altre cas, envia la comanda d'operació nul·la
            end

            START: begin // A l'estat START
                loadCounter <= 1'b1; // Carrega el comptador
                en_ack      <= 1'b0; // Habilita el comptador
                SR_load     <= 1'b1; // Carrega les dades al registre de desplaçament en qualsevol cas (tant en lectura com en escriptura)

                if (Bit_ack && Read)        Bit_cmd <= `I2C_CMD_READ;   // En cas de rebre una solicitud de lectura, envia la comanda de lectura
                else if (Bit_ack && Write)  Bit_cmd <= `I2C_CMD_WRITE;  // En cas de rebre una solicitud d'escriptura, envia la comanda d'escriptura
                else                        Bit_cmd <= `I2C_CMD_START;  // En qualsevol altre cas, envia la comanda de Start
            end

            READ_A: begin // A l'estat READ_A
                loadCounter <= 1'b0; // Deshabilita la càrrega al comptador

                SR_load     <= 1'b0; // Deshabilita la càrrega al shift register
                en_ack      <= 1'b1; // Habilita la recepció de bits d'Acknowledge
                Bit_cmd     <= `I2C_CMD_READ; // Envia la comanda de lectura
                SR_shift_en <= 1'b1; // Habilita el desplaçament de dades al registre de desplaçament
            end

            READ: begin // A l'estat READ
                SR_load     <= 1'b0; // Deshabilita al càrrega al shift register
                loadCounter <= 1'b0; // Deshabilita la càrrega al comptador

                // L'últim cop q es passa per aquest estat es posa el mode d'escriptura per enviar ACK
                if (counterOut & Bit_ack) begin
                   Bit_cmd      <= `I2C_CMD_WRITE;
                   SR_shift_en  <= 1'b0; // Deshabilita el desplaçament al registre de desplaçament
                end else begin // En cas de no haver acabat la lectura encara
                    Bit_cmd     <= `I2C_CMD_READ; // Segueix enviant la comanda de lectura
                    SR_shift_en <= 1'b1;          // Habilita el desplaçament de dades al shift register
                end
            end

            WRITE_A: begin // A l'estat WRITE_A
                loadCounter <= 1'b0; // Deshabilita el comptador
                SR_load     <= 1'b0; // i la càrrega al registre de desplaçament

                en_ack      <= 1'b1; // Habilita la recepció de bits d'Acknowledge
                Bit_cmd     <= `I2C_CMD_WRITE; // Envia la comanda d'escriptura
                Bit_txd     <= SR_sout; // Passa en sèrie al shift register el bit a escriure
                SR_shift_en <= 1'b1;    // Fes desplaçament de dades al shift register
            end

            WRITE: begin // A l'estat WRITE
                loadCounter <= 1'b0; // Deshabilita la càrrega al comptador
                SR_load <= 1'b0;     // i al registre de desplaçament
                en_ack      <= 1'b1; // Habilita la recepció de bits d'Acknowledge
                Bit_txd  <= SR_sout; // Passa en sèrie al shift register el bit a escriure

                // L'últim cop q passem per aquest estat posem mode lectura per rebre ACK
                if (counterOut & Bit_ack) begin
                   Bit_cmd      <= `I2C_CMD_READ; // Envia la comanda de lectura
                   SR_shift_en  <= 1'b0;          // Deshabilita el desplaçament de dades al registre de desplaçament
                end else begin // En cas de no haver acabat la escriptura encara
                    Bit_cmd     <= `I2C_CMD_WRITE; // Envia la comanda d'escriptura
                    SR_shift_en <= 1'b1;           // Fes desplaçament de dades al shift register
                end
            end
            
            STOP: begin // A l'estat STOP
                loadCounter <= 1'b1; // Habilita la càrrega al comptador
                en_ack      <= 1'b0; // Deshabilita la recepció de bits d'Acknowledge
                SR_load     <= 1'b0; // així com la càrrega de dades al shift register
                SR_shift_en <= 1'b0; // i els desplaçaments
                I2C_done    <= 1'b1; // Envia senyal de finalització de comunicació

                if (Bit_ack)        Bit_cmd <= `I2C_CMD_NOP;    // Quan s'acabi la fase de Stop, envia la comanda d'operació nul·la
                else                Bit_cmd <= `I2C_CMD_STOP;   // Si no, espera a que acabi la fase de Stop
            end

            ACK: begin // A l'estat ACK
                SR_load     <= 1'b0; // Deshabilita la càrrega al registre de desplaçament
                loadCounter <= 1'b0; // així com la càrrega al comptador
                SR_shift_en <= 1'b0; // i també els desplaçaments de dades

                if (Bit_ack) begin // Quan acabi la fase d'ACK
                    I2C_done <= 1'b1; // Envia senyal de finalització de comunicació en qualsevol cas

                    if (Stop)           Bit_cmd <= `I2C_CMD_STOP; // Si es rep una condició de Stop, envia la comanda corresponent
                    else                Bit_cmd <= `I2C_CMD_NOP;  // En cas contrari, envia la comanda d'operació nul·la

                    if (Read)           Rx_ack  <= ~Bit_rxd; // En cas de que s'estigui llegint, envia un bit d'ACK (=0) si s'ha llegit correctament o NACK (=1) si s'ha llegit incorrectament
                    else if (Write)     Bit_txd <= Tx_ack;   // En cas de que s'estigui escrivint, envia un ACK/NACK en funció del bit d'Acknowledge a transmetre
                    else                Rx_ack  <= Rx_ack;   // En cas contrari, no fer canvis sobre el bit d'Acknowledge

                end else begin
                    I2C_done <= I2C_done; // En cas de que no s'hagi acaba la fase d'ACK (encara), manté el valor de "I2C_done"
                end
            end
        endcase
    end
end

endmodule