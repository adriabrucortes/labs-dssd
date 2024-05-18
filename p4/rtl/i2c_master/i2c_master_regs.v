/********1*********2*********3*********4*********5*********6*********7*********8
* File : i2c_master_regs.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/05/2023   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
* Description
* Configuration and Status Registers for I2C Bus.
*
* ==============================================================================
*  PRER:  Clock prescale register low-byte
*          (Write/Read) Default: 0x00
*                       Addr   : 0x00
* ------------------------------------------------------------------------------
*    bit[7:0]: Used to prescale the bit time (SCL clock).
*
* ==============================================================================
*  CTR  :  Control register
*          (Write/Read) Default: 0x00
*                       Addr   : 0x02
* ------------------------------------------------------------------------------
*    bit[7]  : EN ? I2C enable bit
*                 1 = I2C core is enabled.
*                 0 = I2C core is disabled.
*    bit[6]  : IEN ? I2C interrupt enable bit.
*                1 = Interrupt is enabled.
*                0 = Interrupt is disabled.
*    bit[5:0]: Reserved bits.
*
* ==============================================================================
*  TXR  :  Transmit register
*          (Write/Read) Default: 0x00
*                       Addr   : 0x03
* ------------------------------------------------------------------------------
*    bit[7:1]: Next byte to transmit via I2C.
*    bit[0]  : In case of a data transfer this bit represents the data's LSB.
*              In case of a slave address transfer this bit represents de RW bit.
*                0 = writing to slave
*                1 = reading from slave
*
* ==============================================================================
*  RXR  :  Receive register
*              (Read) Default: 0x00
*                     Addr   : 0x03
* ------------------------------------------------------------------------------
*    bit[7:0]: Last byte received via I2C.
*
* ==============================================================================
*  CR   :  Command register
*              (Write/Read) Default: 0xFF
*                           Addr   : 0x04
* ------------------------------------------------------------------------------
*    bit[7]  : STA, generate (repeated) start condition.
*    bit[6]  : STO, generate stop condition.
*    bit[5]  : RD,  read from slave.
*    bit[4]  : WR,  write to slave.
*    bit[3]  : ACK, when master as receiver, sent ACK(=0) or NACK(=1).
*    bit[2]  : Reserved.
*    bit[1]  : AL_ACK, arbitration lost acknowledge. When set, clears the SR's AL flag.
*    bit[0]  : IACK, interrupt acknowledge. When set, clears a pending interrupt.
*
*  The STA, STO, RD, WR, AL_ACK and IACK bits are cleared automatically.
*  These bits are always read as zeros.
*
* ==============================================================================
*  SR  :  Status register
*              (Read) Default: 0x00
*                     Addr   : 0x04
*_______________________________________________________________________________
*    bit[7]  : RxACK ? Received acknowledge from addressed slave
*                 1 = No acknowledge received.
*                 0 = Acknowledge received.
*    bit[6]  : Busy ? I2C bus busy
*                 1 = after START signal detected.
*                 0 = after STOP signal detected.
*    bit[5]  : AL ? Arbitration lost
*              This bit is set when the core lost arbitration. Arbitration
*              is lost when:
*                 > a STOP signal is detected, but not requested.
*                 > the master drives SDA high but SDA is low.
*    bit[4:2]: Reserved.
*    bit[1]  : TIP ? Transfer in progress.
*                 1 = when transfering data.
*                 0 =  when transfer complete.
*    bit[0]  : IF ? interrupt flag. This bit is set when an interrupt is
*              pending, which will cause a processor interrupt request if the
*              IEN bit is set. The interrupt flag is set when:
*                 > one byte tranfer has been completed
*                 > arbitration is lost.
*
* ==============================================================================
*
* http://www.opencores.org/projects/i2c/
* Copyright (C) 2001 Richard Herveille
* Modified by Joan Canals
*
*********1*********2*********3*********4*********5*********6*********7*********/
`include "../misc/timescale.v"
`include "i2c_master_defines.v"

module i2c_master_regs #(
  parameter DWIDTH = 8,      // bus data size
  parameter AWIDTH = 3       // bus addres size
)(
  // bus
  input  wire Clk,       // master clock input
  input  wire Rst_n,     // async active low reset
  input  wire [AWIDTH-1:0] Addr,      // lower address bits
  input  wire [DWIDTH-1:0] DataIn,    // databus input
  output reg  [DWIDTH-1:0] DataOut,   // databus output
  input  wire Wr,        // write enable input
  output reg  Int,       // interrupt request signal output
  // commands
  output wire Start,     // generate (repeated) start condition
  output wire Stop,      // generate stop condition
  output wire Read,      // read from slave
  output wire Write,     // write to slave
  output wire Tx_ack,    // when a receiver, sent ACK (Txack='0') or NACK (Txack ='1')
  input  wire Rx_ack,    // received ack bit
  input  wire [7:0] Rx_data,   // data received from slave
  output wire [7:0] Tx_data,   // data to be transmitted to slave
  output wire [7:0] Prescale,  // I2C clock prescale value
  input  wire I2C_busy,  // bus busy (start signal detected)
  input  wire I2C_done,  // command completed, used to clear command register
  output wire I2C_en,    // enables the i2c core
  input  wire I2C_al     // I2C bus arbitration lost
);

  // registers
  reg  [7:0] prer; // clock prescale register
  reg  [7:0] ctr;  // control register
  reg  [7:0] txr;  // transmit register
  wire [7:0] rxr;  // receive register
  reg  [7:0] cr;   // command register
  wire [7:0] sr;   // status register

  // I2C core enable signal
  wire ien;         // interrupt enable bit

  // status register signals
  reg  rxack;       // received aknowledge from slave
  reg  tip;         // transfer in progress
  reg  irq_flag;    // interrupt pending flag
  reg  al;          // status register arbitration lost bit

  // command signals
  wire al_ack;
  wire iack;        // interrupt acknlowledge, when set, clears a pending interrupt

  // assign input/outputs
  assign rxr      = Rx_data;
  assign Tx_data  = txr;
  assign Prescale = prer;

  // asynchronous read
  // Lògica combinacional de selecció d'output
  always @(Addr or prer or ctr or rxr or sr or txr or cr)
    case (Addr)
      `I2C_PRER : DataOut = prer;
      `I2C_CTR  : DataOut = ctr;
      `I2C_TXR  : DataOut = txr;
      `I2C_CR   : DataOut = cr;
      `I2C_RXR  : DataOut = rxr;
      `I2C_SR   : DataOut = sr;
      default   : DataOut = 8'h00;
    endcase

  // generate registers write logic
  always @(negedge Clk or negedge Rst_n)
    // Reset del sistema
    if(!Rst_n) begin
      prer <= 8'h00;
      ctr  <= 8'h0;
      txr  <= 8'h0;
    // En altre cas, avaluem escriptura/lectura (1: escriptura)
    end else if (Wr)
      // Decidim *on* escribim
      case (Addr)
        `I2C_PRER : prer <= DataIn;
        `I2C_CTR  : ctr  <= DataIn;
        `I2C_TXR  : txr  <= DataIn;
        default   : ;
      endcase
    // Si no fem res, mantenim els valors (realimentació als registres)
    else begin
      prer <= prer;
      ctr  <= ctr;
      txr  <= txr;
    end

  // generate command register (special case)
  always @(negedge Clk or negedge Rst_n)
    if (!Rst_n)
      cr <= 8'h0;
    else if (Wr)
      // Carreguem a I2C Command register
      if(I2C_en & (Addr == `I2C_CR))
        cr <= DataIn;
      else
        cr <= cr;
    else begin
      if (I2C_done | I2C_al)
        cr[7:4] <= 4'h0; // clear command bits when done or when aribitration lost
      else
        cr[7:4] <= cr[7:4];
        cr[3] <= cr[3];  // no clear
        cr[2] <= 1'b0;   // reserved bits
        cr[1] <= 1'b0;   // clear AL bit
        cr[0] <= 1'b0;   // clear IRQ_ACK bit
    end


  // decode command register
  assign Start  = cr[7];
  assign Stop   = cr[6];
  assign Read   = cr[5];
  assign Write  = cr[4];
  assign Tx_ack = cr[3];
  assign al_ack = cr[1];
  assign iack   = cr[0];

  // decode control register
  assign I2C_en = ctr[7];
  assign ien    = ctr[6];

  // status register block + interrupt request signal
  always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) begin
      al       <= 1'b0;
      rxack    <= 1'b0;
      tip      <= 1'b0;
      irq_flag <= 1'b0;
    end else begin
      al       <= (I2C_al | (al & ~Start)) & ~al_ack;
      rxack    <= Rx_ack;
      tip      <= (Read | Write);
      irq_flag <= (I2C_done | I2C_al | irq_flag) & ~iack; // interrupt request flag is always generated
    end

  // generate interrupt request signals
  always @(posedge Clk or negedge Rst_n)
    if (!Rst_n)
      Int <= 1'b0;
    else
      Int <= irq_flag && ien; // interrupt signal is only generated when IEN (interrupt enable bit is set)

  // assign status register bits
  assign sr[7]   = rxack;
  assign sr[6]   = I2C_busy;
  assign sr[5]   = al;
  assign sr[4:2] = 3'h0; // reserved
  assign sr[1]   = tip;
  assign sr[0]   = irq_flag;

endmodule
