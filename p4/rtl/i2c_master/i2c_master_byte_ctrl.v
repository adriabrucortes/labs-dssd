`include "../misc/timescale.v"
`include "i2c_master_defines.v"

module i2c_master_byte_ctrl (
	input  wire        Clk,
  input  wire        Rst_n,
  // commands
  input  wire        Start,
  input  wire        Stop,
  input  wire        Read,
  input  wire        Write,
  // data
  input  wire        Tx_ack,
  output reg         Rx_ack,
  // status flags
  output reg         I2C_done,
  input  wire        I2C_al,
  // signals for shift registers
  input  wire        SR_sout,
  output reg         SR_load,
  output reg         SR_shift,
	// signals for bit_controller
	output reg  [ 3:0] Bit_cmd,
	output reg         Bit_txd,
  input  wire        Bit_ack,
  input  wire        Bit_rxd
);

	// signals for state machine
	wire         go;        // start transmission flag
	reg  [3-1:0] dcnt;      // data bit coutner
  wire         cnt_done;  // counter end flag

	// generate go-signal
	assign go = (Read | Write | Stop) & ~I2C_done;
	// always @(posedge Clk or negedge Rst_n)
	//   if (!Rst_n) go <= 1'b0;
  //   else        go <= (Read | Write | Stop) & ~I2C_done;

	// generate data bit counter
	always @(posedge Clk or negedge Rst_n)
	  if (!Rst_n)
	    dcnt <= 3'h0;
	  else if (SR_load)
	    dcnt <= 3'h7;
	  else if (SR_shift)
	    dcnt <= dcnt - 3'h1;

	assign cnt_done = ~(|dcnt);

	// state machine
	localparam ST_IDLE  = 3'd0,
	           ST_START = 3'd1,
						 ST_READ  = 3'd2,
	           ST_WRITE = 3'd3,
	           ST_ACK   = 3'd4,
					   ST_STOP  = 3'd5;

	reg [3-1:0] state, next;

	always @(posedge Clk or negedge Rst_n)
	  if (!Rst_n) state <= ST_IDLE;
	  else        state <= next;

	always @(*)
	  case(state)
		  ST_IDLE : if(go & Start)           next = ST_START;
            		else if(go & Read)       next = ST_READ;
            		else if(go & Write)      next = ST_WRITE;
            		else if(go & Stop)       next = ST_STOP;
								else                     next = ST_IDLE;

		  ST_START: if(Bit_ack & Read)       next = ST_READ;
                else if(Bit_ack & Write) next = ST_WRITE;
		            else                     next = ST_START;

      ST_READ : if(Bit_ack & cnt_done)   next = ST_ACK;
		            else                     next = ST_READ;

      ST_WRITE: if(Bit_ack & cnt_done)   next = ST_ACK;
		            else                     next = ST_WRITE;

      ST_ACK  : if(Bit_ack & Stop)       next = ST_STOP;
                else if(Bit_ack & !Stop) next = ST_IDLE;
                else                     next = ST_ACK;

      ST_STOP : if(Bit_ack)              next = ST_IDLE;
                else                     next = ST_STOP;
      default : next = ST_IDLE;
		endcase

	always @(posedge Clk or negedge Rst_n)
	  if(!Rst_n) begin
		  Bit_cmd  <= `I2C_CMD_NOP;
	    Bit_txd  <= 1'b0;
	    SR_shift <= 1'b0;
	    SR_load  <= 1'b0;
	    I2C_done <= 1'b0;
	    Rx_ack   <= 1'b0;
	  end else if(I2C_al) begin
	    Bit_cmd  <= `I2C_CMD_NOP;
	    Bit_txd  <= 1'b0;
	    SR_shift <= 1'b0;
	    SR_load  <= 1'b0;
	    I2C_done <= 1'b0;
	    Rx_ack   <= 1'b0;
	  end else begin
		  Bit_cmd  <= Bit_cmd;
	    Bit_txd  <= SR_sout;
	    SR_shift <= 1'b0;
	    SR_load  <= 1'b0;
	    I2C_done <= 1'b0;
      Rx_ack   <= Rx_ack;
	    case(state)
			  ST_IDLE: begin
	        if(go) begin
	          SR_load <= 1'b1;
					  if(Start)       Bit_cmd <= `I2C_CMD_START;
	          else if (Read)  Bit_cmd <= `I2C_CMD_READ;
	          else if (Write) Bit_cmd <= `I2C_CMD_WRITE;
	          else            Bit_cmd <= `I2C_CMD_STOP;
					end else begin
            Bit_cmd <= `I2C_CMD_NOP;
					end
				end

				ST_START: begin
	        if(Bit_ack) begin
	          SR_load <= 1'b1;
					  if(Read) Bit_cmd <= `I2C_CMD_READ;
	          else     Bit_cmd <= `I2C_CMD_WRITE;
					end
	      end

  			ST_WRITE: begin
          if(Bit_ack) begin
  					if(cnt_done) begin
						  Bit_cmd <= `I2C_CMD_READ;
				    end else begin
	            Bit_cmd <= `I2C_CMD_WRITE; // write next bit
	            SR_shift <= 1'b1;
	          end
			    end
				end

        ST_READ: begin
	        if(Bit_ack) begin
	          SR_shift <= 1'b1;
	          Bit_txd <= Tx_ack;
	          if(cnt_done) Bit_cmd <= `I2C_CMD_WRITE;
	          else         Bit_cmd <= `I2C_CMD_READ; // read next bit
	        end
				end

        ST_ACK: begin
	        if(Bit_ack) begin
					  if(Stop) begin
						  Bit_cmd <= `I2C_CMD_STOP;
						end else begin
	            Bit_cmd <= `I2C_CMD_NOP;
	            // generate done signal
	            I2C_done  <= 1'b1;
	          end
	          // assign Rx_ack output to Bit_controller_rxd (contains last received bit)
	          Rx_ack <= Bit_rxd;
	          Bit_txd <= 1'b1;
					end else begin
	          Bit_txd <= Tx_ack;
					end
				end

        ST_STOP: begin
	        if(Bit_ack) begin
	          Bit_cmd <= `I2C_CMD_NOP;
	          // generate done signal
	          I2C_done  <= 1'b1;
	        end
				end

        default : ;
      endcase
	  end

endmodule

