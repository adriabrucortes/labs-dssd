`include "i2c_master_defines.v"

module i2c_master_byte_ctrl(
    input wire      Clk,          // Reloj del sistema
    input wire      Rst_n,        // Reset del sistema
    input wire      Start,        // Comanda de Start - viene del CR[7]
    input wire      Stop,         // Comanda de Stop - viene del CR[6]
    input wire      Read,         // Comanda de Lectura - viene del CR[5]
    input wire      Write,        // Comanda de Escritura - viene del CR[4]
    input wire      Tx_ack,       // Comanda de Acknowledge del MESTRO como receptor 
    output reg      Rx_ack,       // Aknowledge recibido por el MAESTRO como emisor
    input wire      I2C_al,       // I2C arbitration lost 
    output reg      I2C_done,     // I2C done
    input wire      SR_sout,      // Salida serie del Shift Register
    output reg      SR_load,      // Señal de carga de datos en SR
    output reg      SR_shift,     // Señal de desplazamiento de datos en SR
    output reg [3:0]Bit_cmd,      // Salida de Comandos para Bit Control
    output reg      Bit_txd,      // En transmision - bits a enviar
    input wire      Bit_ack,      // Aknowledge comforme ha acabado una operacion
    input wire      Bit_rxd);     // En recepcion - bits recibidos

    reg [4:0] state,next;
    reg [2:0] cnt;
    reg en_cnt;
    
    // Definicion de los estados
    
    localparam IDLE = 4'd0,
               START= 4'd1,
               STOP= 4'd2,
               WRITE_L= 4'd3,
               WRITE_S = 4'd4,
               READ= 4'd5,
               ACK = 4'd6;

    // Contador de desplazamientos SR
    always@(posedge Clk or negedge Rst_n)begin
        if(~Rst_n) cnt <= 3'd7;
        else if (Bit_ack && en_cnt)begin
            cnt <= cnt - 1'b1;
        end
        else cnt <= cnt;
    end

    //Conexion de estados
    always@(*)begin
        case(state)
        IDLE:begin
            if(Start) next = START;
            else if (Read) next = READ;
            else if (Write) next = WRITE_L;
            else if (Stop) next = STOP;
            else next = IDLE;
        end
        START:begin
            if(Bit_ack && Write) next = WRITE_L;
            else if(Bit_ack && Read) next = READ;
            else next = START;
        end
        STOP:begin
            if(Bit_ack) next = IDLE;
            else next = STOP;
        end
        WRITE_L:begin
            next = WRITE_S;
        end
        WRITE_S:begin
            if(Bit_ack && ~|cnt) next = ACK;
            else next = WRITE_S;
        end
        READ:begin
            if(Bit_ack && ~|cnt) next = ACK;
            else next = READ;
        end
        ACK: begin
            if(Bit_ack && Stop) next = STOP;
            else if(Bit_ack) next = IDLE;
            else next = ACK;
        end
        default next = IDLE;
        endcase
    end

    // salidas de estados
    always@(posedge Clk or negedge Rst_n) begin
        SR_load <= 1'b0;
        SR_shift <= 1'b0;
        I2C_done <= 1'b0;

        if(!Rst_n)begin
            SR_load <= 1'b0;
            SR_shift <= 1'b0;
            I2C_done <= 1'b0;
            Bit_cmd <= `I2C_CMD_NOP;
            cnt <= 3'd7;
            en_cnt <= 1'b0;
        end
        else begin
            case(state)
            IDLE:begin
                if(Start) Bit_cmd <= `I2C_CMD_START;
                else if(Read) Bit_cmd <= `I2C_CMD_READ;
                else if(Write) SR_load <= 1'b1;
                else if(Stop) Bit_cmd <= `I2C_CMD_STOP;
                else Bit_cmd <= `I2C_CMD_NOP;
                cnt <= 3'd7;
            end
            START:begin
                if(Bit_ack && Write)begin 
                    SR_load <= 1'b1;
                end
                else if (Bit_ack && Read)begin
                    Bit_cmd <= `I2C_CMD_READ;
                end
            end
            WRITE_L:begin
                Bit_txd <= SR_sout;
                SR_shift <= 1'b1;
                en_cnt <= 1'b1;
            end
            WRITE_S:begin
                if(~|cnt && Bit_ack) begin
                    Bit_cmd <= `I2C_CMD_READ;
                    en_cnt <= 1'b0;
                end
                else if (&(cnt) && !Bit_ack) begin
                    Bit_cmd <= `I2C_CMD_WRITE;
                    Bit_txd <= SR_sout;
                    SR_shift <= 1'b0;
                end
                else if(!Bit_ack)begin
                    SR_shift <= 1'b0;
                end
                else begin
                    Bit_cmd <= `I2C_CMD_WRITE;
                    Bit_txd <= SR_sout;
                    SR_shift <= 1'b1; 
                end
            end
            READ:begin
                if(~|cnt && Bit_ack)begin
                    Bit_txd <= Tx_ack; 
                end
                else if(Bit_ack)begin
                    Bit_cmd <= `I2C_CMD_READ;
                    SR_shift <= 1'b1;
                    en_cnt <= 1'b1;
                end
            end
            ACK:begin
                if(Stop && Read)begin
                    Bit_cmd <= `I2C_CMD_WRITE;
                end
                else if (Stop && Write && Bit_ack) begin
                    Bit_cmd <= `I2C_CMD_STOP;
                    Rx_ack <= Bit_rxd;
                end
                else if(Read)begin
                    Bit_cmd <= `I2C_CMD_WRITE;
                    I2C_done <= 1'b1;
                end
                else if(Bit_ack && Write) begin
                    Rx_ack <= Bit_rxd;
                    I2C_done <= 1'b1;
                end
                else Bit_cmd <= Bit_cmd; 
            end            
            STOP:begin
                if(Write) I2C_done <= 1'b1;
                else begin 
                    Bit_cmd <= `I2C_CMD_STOP;
                    I2C_done <= 1'b1;
                end
            end
            endcase
        end
    end

    // saltos de estados
    always @(posedge Clk or negedge Rst_n)begin
        if(~Rst_n) state <= IDLE;
        else state <= next;
    end


endmodule