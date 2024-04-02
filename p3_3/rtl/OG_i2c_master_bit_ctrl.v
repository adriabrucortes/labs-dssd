/********1*********2*********3*********4*********5*********6*********7*********8
* File : i2c_master_bit_ctrl.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            15/06/2023   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* Bit Command Control
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2023
*
*********1*********2*********3*********4*********5*********6*********7*********/

`include "../misc/timescale.v"
`include "i2c_master_defines.v"

module i2c_master_bit_ctrl (
  input             Clk,        // system clock
  input             Rst_n,      // asynchronous active low reset
  input             Enable,     // core enable signal

  input             TimerOut,   // SCL timer output
  output            TimerStart, // SCL timer set
  output            TimerStop,  // SCL timer stop

  input      [ 3:0] Cmd,        // command (from byte controller)
  output reg        Ack,        // command complete acknowledge
  input             Txd,        // data to transmit
  output reg        Rxd,        // data received
  output reg        I2C_busy,   // i2c bus busy
  output reg        I2C_al,     // i2c bus arbitration lost

  input             Scl_i,      // i2c clock line input
  output            Scl_o,      // i2c clock line output
  output reg        Scl_oen,    // i2c clock line output enable (active low)
  input             Sda_i,      // i2c data line input
  output            Sda_o,      // i2c data line output
  output            Sda_oen     // i2c data line output enable (active low)
);

  reg sSCL, sSDA;        // filtered and synchronized SCL and SDA inputs
  reg dSCL, dSDA;        // delayed versions of sSCL and sSDA
  reg dScl_oen;          // delayed Scl_oen
  reg sda_chk;           // check SDA output (Multi-master arbitration)
  reg slave_wait;        // slave inserts wait states (clock streaching)
  reg sta_condition;     // start condition detected flag
  reg sto_condition;     // stop condition detected flag
  reg cmd_stop;          // used in bus arbitration

  reg [3-1:0] state, next; // state machine variable

  // whenever the slave is not ready it can delay the cycle by pulling SCL low
  // delay Scl_oen
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) dScl_oen <= 1'b1;
    else       dScl_oen <= Scl_oen;

  // slave_wait is asserted when master wants to drive SCL high, but the slave pulls it low
  // slave_wait remains asserted until the slave releases SCL
  always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) slave_wait <= 1'b0;
    else        slave_wait <= (dScl_oen & ~sSCL) | (slave_wait & ~sSCL);

  // master drives SCL high, but another master pulls it low
  // master start counting down its low cycle now (clock synchronization)
  wire scl_sync = dSCL & ~sSCL & Scl_oen;

  // generate clk_en signal
  wire clk_en = TimerOut;
  assign TimerStart = !Enable | scl_sync;
  assign TimerStop = slave_wait;


  // generate bus status controller
  // capture SDA and SCL
  // reduce metastability risk
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) begin
      sSCL <= 1'b1;
      sSDA <= 1'b1;
      dSCL <= 1'b1;
      dSDA <= 1'b1;
    end else begin
      sSCL <= Scl_i;
      sSDA <= Sda_i;
      dSCL <= sSCL;
      dSDA <= sSDA;
    end

  // detect start condition => detect falling edge on SDA while SCL is high
  // detect stop condition => detect rising edge on SDA while SCL is high
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) begin
      sta_condition <= 1'b0;
      sto_condition <= 1'b0;
    end else begin
      sta_condition <= ~sSDA &  dSDA & ~sSCL;
      sto_condition <=  sSDA & ~dSDA & sSCL;
    end


  // generate i2c bus I2C_busy signal
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) I2C_busy <= 1'b0;
    else       I2C_busy <= (sta_condition | I2C_busy) & ~sto_condition;


  // generate arbitration lost signal
  // aribitration lost when:
  // 1) master drives SDA high, but the i2c bus is low
  // 2) stop detected while not requested
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)      cmd_stop <= 1'b0;
    else if(clk_en) cmd_stop <= Cmd == `I2C_CMD_STOP;
    else            cmd_stop <= cmd_stop;

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) I2C_al <= 1'b0;
    else       I2C_al <= (sda_chk & ~sSDA & Sda_oen) | (sto_condition & ~cmd_stop);


  // generate Rxd signal (store SDA on rising edge of SCL)
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)            Rxd <= 1'b1;
    else if(sSCL & ~dSCL) Rxd <= sSDA;
    else                  Rxd <= Rxd;

  // state decoder
  localparam IDLE    = 4'd0,
             START_B = 4'd1,
             START_C = 4'd2,
             START_D = 4'd3,
             START_E = 4'd4,
             START_F = 4'd5,
             STOP_B  = 4'd6,
             STOP_C  = 4'd7,
             STOP_D  = 4'd8,
             RD_B    = 4'd9,
             RD_C    = 4'd10,
             RD_D    = 4'd11,
             WR_B    = 4'd12,
             WR_C    = 4'd13,
             WR_D    = 4'd14;

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) state <= IDLE;
    else       state <= next;

  always @(*)
    case(state)
      IDLE : if(clk_en)
               case (Cmd)
                 `I2C_CMD_START: next = START_B;
                 `I2C_CMD_STOP : next = STOP_B;
                 `I2C_CMD_READ : next = RD_B;
                 `I2C_CMD_WRITE: next = WR_B;
                 default       : next = IDLE;
               endcase
              else               next = IDLE;

      START_B: if(clk_en) next = START_C;
               else       next = START_B;
      START_C: if(clk_en) next = START_D;
               else       next = START_C;
      START_D: if(clk_en) next = START_E;
               else       next = START_D;
      START_E: if(clk_en) next = START_F;
               else       next = START_E;
      START_F: if(clk_en) next = IDLE;
               else       next = START_F;

      STOP_B : if(clk_en) next = STOP_C;
               else       next = STOP_B;
      STOP_C : if(clk_en) next = STOP_D;
               else       next = STOP_C;
      STOP_D : if(clk_en) next = IDLE;
               else       next = STOP_D;

      RD_B   : if(clk_en) next = RD_C;
               else       next = RD_B;
      RD_C   : if(clk_en) next = RD_D;
               else       next = RD_C;
      RD_D   : if(clk_en) next = IDLE;
               else       next = RD_D;

      WR_B   : if(clk_en) next = WR_D;
               else       next = WR_B;
      WR_C   : if(clk_en) next = WR_D;
               else       next = WR_C;
      WR_D   : if(clk_en) next = IDLE;
               else       next = WR_B;

      default: next = IDLE;
    endcase

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) begin
      Ack <= 1'b0;
      Scl_oen <= 1'b1;
      Sda_oen <= 1'b1;
      sda_chk <= 1'b0;
    end else if(I2C_al) begin
      Ack <= 1'b0;
      Scl_oen <= 1'b1;
      Sda_oen <= 1'b1;
      sda_chk <= 1'b0;
    end else if(clk_en) begin
      Ack <= 1'b0;
      case(state)
        IDLE : begin
          sda_chk <= 1'b0;    // don't check SDA output
          case (Cmd)
            `I2C_CMD_START: begin Scl_oen <= Scl_oen; Sda_oen <= 1'b1; end // START_A
            `I2C_CMD_STOP : begin Scl_oen <= 1'b0;    Sda_oen <= 1'b0; end // STOP_A
            `I2C_CMD_READ : begin Scl_oen <= 1'b0;    Sda_oen <= 1'b1; end // RD_A
            `I2C_CMD_WRITE: begin Scl_oen <= 1'b0;    Sda_oen <= Txd; end  // WR_A
            default       : begin Scl_oen <= Scl_oen; Sda_oen <= Sda_oen; end // TRUE IDLE
          endcase
        end

        START_B : begin
          Scl_oen <= 1'b1; // keep SCL high
          Sda_oen <= 1'b0; // keep SDA high
          sda_chk <= 1'b0; // don't check SDA output
        end
        START_C : begin
          Scl_oen <= 1'b1; // keep SCL high
          Sda_oen <= 1'b1; // keep SDA high
          sda_chk <= 1'b0; // don't check SDA output
        end
        START_D : begin
          Scl_oen <= 1'b1; // set SCL low
          Sda_oen <= 1'b0; // set SDA low
          sda_chk <= 1'b0; // don't check SDA output
        end
        START_E : begin
          Scl_oen <= 1'b1; // keep SCL low
          Sda_oen <= 1'b0; // keep SDA low
          sda_chk <= 1'b0; // don't check SDA output
        end
        START_F : begin
          Ack <= 1'b1;
          Scl_oen <= 1'b0; // set SCL low
          Sda_oen <= 1'b0; // keep SDA low
          sda_chk <= 1'b0; // don't check SDA output
        end

        STOP_B : begin
          Scl_oen <= 1'b1; // set SCL high
          Sda_oen <= 1'b0; // keep SDA low
          sda_chk <= 1'b0; // don't check SDA output
        end
        STOP_C : begin
          Scl_oen <= 1'b1; // keep SCL high
          Sda_oen <= 1'b0; // keep SDA low
          sda_chk <= 1'b0; // don't check SDA output
        end
        STOP_D : begin
          Ack <= 1'b1;
          Scl_oen <= 1'b1; // keep SCL high
          Sda_oen <= 1'b1; // set SDA high
          sda_chk <= 1'b0; // don't check SDA output
        end

        RD_B : begin
          Scl_oen <= 1'b1; // set SCL high
          Sda_oen <= 1'b1; // keep SDA tri-stated
          sda_chk <= 1'b0; // don't check SDA output
        end
        RD_C : begin
          Scl_oen <= 1'b1; // keep SCL high
          Sda_oen <= 1'b1; // keep SDA tri-stated
          sda_chk <= 1'b0; // don't check SDA output
        end
        RD_D : begin
          Ack <= 1'b1;
          Scl_oen <= 1'b0; // set SCL low
          Sda_oen <= 1'b1; // keep SDA tri-stated
          sda_chk <= 1'b0; // don't check SDA output
        end

        WR_B : begin
          Scl_oen <= 1'b1; // set SCL high
          Sda_oen <= Txd;  // keep SDA
          sda_chk <= 1'b0; // don't check SDA output yet
        end                // allow some time for SDA and SCL to settle
        WR_C : begin
          Scl_oen <= 1'b1; // keep SCL high
          Sda_oen <= Txd;
          sda_chk <= 1'b1; // check SDA output
        end
        WR_D : begin
          Ack <= 1'b1;
          Scl_oen <= 1'b0; // set SCL low
          Sda_oen <= Txd;
          sda_chk <= 1'b0; // don't check SDA output (SCL low)
        end
        default: ;
      endcase
    end else begin
      Ack <= 1'b0;        // default no command acknowledge + assert Ack only 1clk cycle
      Scl_oen <= Scl_oen; // keep SCL in same state
      Sda_oen <= Sda_oen; // keep SDA in same state
      sda_chk <= 1'b0;    // don't check SDA output
   end

  // assign scl and sda output (always gnd)
  assign Scl_o = 1'b0;
  assign Sda_o = 1'b0;

endmodule
