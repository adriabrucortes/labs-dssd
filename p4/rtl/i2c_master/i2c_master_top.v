/********1*********2*********3*********4*********5*********6*********7*********8
* File : i2c_master_top.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/05/2023   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* I2C master top module
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2023
*
*********1*********2*********3*********4*********5*********6*********7*********/
`include "../misc/timescale.v"
`include "i2c_master_defines.v"

module i2c_master_top #(
  parameter DWIDTH = 8,      // bus data size
  parameter AWIDTH = 3       // bus addres size
)(
  // system bus i/o signals
  input  wire Clk,       // master clock input
  input  wire Rst_n,     // async active low reset
  input  wire [AWIDTH-1:0] Addr,      // lower address bits
  input  wire [DWIDTH-1:0] DataIn,    // databus input
  output wire [DWIDTH-1:0] DataOut,   // databus output
  input  wire Wr,        // write enable input
  output wire Int,       // interrupt request signal output
  // I2C signals
  // i2c clock line
  input  wire SclPadIn,  // SCL-line input
  output wire SclPadOut, // SCL-line output (always 1'b0)
  output wire SclPadEn,  // SCL-line output enable (active low)
  // i2c data line
  input  wire SdaPadIn,  // SDA-line input
  output wire SdaPadOut, // SDA-line output (always 1'b0)
  output wire SdaPadEn   // SDA-line output enable (active low)
);

  wire start, stop, write, read;
  wire tx_ack, rx_ack;
  wire [8-1:0] tx_data, rx_data;
  wire [8-1:0] prescale;
  wire i2c_busy, i2c_done, i2c_en, i2c_al;
  wire [4-1:0] bit_cmd;
  wire bit_ack, bit_txd, bit_rxd;
  wire sr_load, sr_shift, sr_sout;
  wire timerStart, timerStop, timerOut;

  i2c_master_regs #(
    .DWIDTH (DWIDTH),
    .AWIDTH (AWIDTH)
  ) i_regs (
    .Clk           ( Clk          ),
    .Rst_n         ( Rst_n        ),
    .Addr          ( Addr         ),
    .DataIn        ( DataIn       ),
    .DataOut       ( DataOut      ),
    .Wr            ( Wr           ),
    .Int           ( Int          ),
    .Start         ( start        ),
    .Stop          ( stop         ),
    .Read          ( read         ),
    .Write         ( write        ),
    .Tx_ack        ( tx_ack       ),
    .Rx_ack        ( rx_ack       ),
    .Rx_data       ( rx_data      ),
    .Tx_data       ( tx_data      ),
    .Prescale      ( prescale     ),
    .I2C_busy      ( i2c_busy     ),
    .I2C_done      ( i2c_done     ),
    .I2C_en        ( i2c_en       ),
    .I2C_al        ( i2c_al       )
  );

  // hookup byte controller block
  i2c_master_byte_ctrl i_byte (
    .Clk           ( Clk          ),
    .Rst_n         ( Rst_n        ),
    .Start         ( start        ),
    .Stop          ( stop         ),
    .Read          ( read         ),
    .Write         ( write        ),
    .Tx_ack        ( tx_ack       ),
    .Rx_ack        ( rx_ack       ),
    .I2C_done      ( i2c_done     ),
    .I2C_al        ( i2c_al       ),
    .SR_sout       ( sr_sout      ),
    .SR_load       ( sr_load      ),
    .SR_shift      ( sr_shift     ),
    .Bit_cmd       ( bit_cmd      ),
    .Bit_txd       ( bit_txd      ),
    .Bit_ack       ( bit_ack      ),
    .Bit_rxd       ( bit_rxd      )
  );

	// hookup bit_controller
	i2c_master_bit_ctrl i_bit (
		.Clk           ( Clk          ),
		.Rst_n         ( Rst_n        ),
		.Enable        ( i2c_en       ),
    .TimerOut      ( timerOut     ),
    .TimerStart    ( timerStart   ),
    .TimerStop     ( timerStop    ),
		.Cmd           ( bit_cmd      ),
		.Ack           ( bit_ack      ),
		.Txd           ( bit_txd      ),
		.Rxd           ( bit_rxd      ),
    .I2C_busy      ( i2c_busy     ),
		.I2C_al        ( i2c_al       ),
    .Scl_i         ( SclPadIn     ),
    .Scl_o         ( SclPadOut    ),
    .Scl_oen       ( SclPadEn     ),
    .Sda_i         ( SdaPadIn     ),
    .Sda_o         ( SdaPadOut    ),
    .Sda_oen       ( SdaPadEn     )
	);

  shiftreg #(.SIZE(8)) i_sr (
    .Clk           ( Clk          ),
    .Rst_n         ( Rst_n        ),
    .Load          ( sr_load      ),
    .Shift         ( sr_shift     ),
    .SerIn         ( bit_rxd      ),
    .DataIn        ( tx_data      ),
    .SerOut        ( sr_sout      ),
    .DataOut       ( rx_data      )
  );

  i2c_bit_timer #(.SIZE(8)) i_timer (
    .Clk           ( Clk          ),
    .Rst_n         ( Rst_n        ),
    .Start         ( timerStart   ),
    .Stop          ( timerStop    ),
    .Ticks         ( prescale     ),
    .Out           ( timerOut     )
  );

endmodule
