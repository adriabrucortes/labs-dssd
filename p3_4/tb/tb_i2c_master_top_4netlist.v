/********1*********2*********3*********4*********5*********6*********7*********8
* File : tb_i2c_master_top.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/06/2023   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* Testbench to verify the proper operation of the I2C master.
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2023
*
*********1*********2*********3*********4*********5*********6*********7*********/

`include "../misc/timescale.v"
`include "../rtl/i2c_master_defines.v"
`include "C:/Users/HP/Documents/Universitat/8e/DSSD/pracs/p3_4/misc/i2c_slave_model.v"
`include "C:/Users/HP/Documents/Universitat/8e/DSSD/pracs/p3_4/misc/dbus_master_model.v"

module tb_i2c_master_top(); // module name (same as the file)
  //___________________________________________________________________________
  // defines
  `define DELAY 2

  //___________________________________________________________________________
  // DUT & system signals
  parameter DWIDTH = 8; // system bus data size
  parameter AWIDTH = 3; // system bus addres size

	reg  clk;   // system clock
	reg  rst_n; // system asynchronous reset. ative low

  // system data bus signals
	wire [AWIDTH-1:0] bus_addr;
	wire [DWIDTH-1:0] bus_din;
  wire [DWIDTH-1:0] bus_dout;
  wire              bus_wr;

  // i2c singals
	wire scl, scl0_o, scl0_oen;
	wire sda, sda0_o, sda0_oen;

  wire i2c0_int;

  //___________________________________________________________________________
  // test signals
  integer         errors;    // Accumulated errors during the simulation
  integer         vExpected; // expected value
  integer         vObtained; // obtained value

	reg [7:0] q, qq;

	parameter RD       = 1'b1;
	parameter WR       = 1'b0;
	parameter SADR     = 7'b0010_000;
  parameter WR_BURST = 1'b0;
  parameter RD_BURST = 1'b1;


  //___________________________________________________________________________
  // instances of DUT and modules

  // hookup system data bus master
  dbus_master_model #(
    .DATA_WIDTH (DWIDTH),
    .ADDR_WIDTH (AWIDTH)
  ) u_dbus0 (
    .Clk       ( clk       ),
    .Rst_n     ( rst_n     ),
    .Addr      ( bus_addr  ),
    .Dout      ( bus_din   ),
    .Din       ( bus_dout  ),
    .Wr        ( bus_wr    )
  );

	// hookup i2c master core: the DUT
	i2c_master_top u_dut0(
	// i2c_master_top #(
	//    .DWIDTH (DWIDTH),
	//    .AWIDTH (AWIDTH)
	//  ) u_dut0(
    .Clk       ( clk       ),  // master clock input
    .Rst_n     ( rst_n     ),  // async active low reset
    .Addr      ( bus_addr  ),  // lower address bits
    .DataIn    ( bus_din   ),  // databus input
    .DataOut   ( bus_dout  ),  // databus output
    .Wr        ( bus_wr    ),  // write enable input
    .Int       ( i2c0_int  ),  // interrupt request signal output
    .SclPadIn  ( scl       ),  // SCL-line input
    .SclPadOut ( scl0_o    ),  // SCL-line output (always 1'b0)
    .SclPadEn  ( scl0_oen  ),  // SCL-line output enable (active low)
    .SdaPadIn  ( sda       ),  // SDA-line input
    .SdaPadOut ( sda0_o    ),  // SDA-line output (always 1'b0)
    .SdaPadEn  ( sda0_oen  )   // SDA-line output enable (active low)
	);

	// hookup i2c slave model
	i2c_slave_model #(
    .I2C_ADDR  ( SADR      ),
    .WR_BURST  ( WR_BURST  ),  // 0: disabled
    .RD_BURST  ( RD_BURST  )   // 0: disabled
  ) u_slave0(
		.Scl       ( scl       ),
    .Sda       ( sda       )
	);

  // create i2c lines for each master
	delay m0_scl (scl0_oen ? 1'bz : scl0_o, scl),
	      m0_sda (sda0_oen ? 1'bz : sda0_o, sda);

	pullup p1(scl); // pullup scl line
	pullup p2(sda); // pullup sda line

  //___________________________________________________________________________
	// generate clock
  `define CLK_HALFPERIOD 5
  initial clk = 1'b0;
	always #`CLK_HALFPERIOD clk = ~clk;

  // signals and vars initialization
  initial begin
    rst_n  = 1'b1; // init the reset signal to unasserted
    errors = 0;    // init the errors counter
	  // force I2C_SLAVE.debug = 1'b1; // enable i2c_slave debug information
	  force u_slave0.debug = 1'b0; // disable i2c_slave debug information
  end

  //___________________________________________________________________________
  // Test Vectors
	initial
	  begin
      $timeformat(-9, 2, " ns", 10); // format for the time print
	    $display("\nstatus: %t Testbench started\n\n", $time);
      reset(130);                         // puts the DUT in a known stage
	    $display("status: %t done reset", $time);
      waitCycles(5);                 // waits 5 clock cicles

	    // program internal registers
	    u_dbus0.write(`I2C_PRER, 8'hF9); // 100k load prescaler lo-byte
	    u_dbus0.write(`I2C_PRER, 8'h3D); // 400k load prescaler lo-byte
	    u_dbus0.write(`I2C_PRER, 8'h07); // 3.3MHz load prescaler lo-byte
	    $display("status: %t programmed registers", $time);
      waitCycles(30);
	    $display("status: %t verified registers", $time);

	    u_dbus0.write(`I2C_CTR, 8'h80); // enable core
	    $display("status: %t core enabled", $time);

	    //
	    // access slave (write)
	    //

	    $display("status: %t Write Access", $time);
	    // drive slave address
	    u_dbus0.write(`I2C_TXR  , {SADR,WR} ); // present slave address, set write-bit
	    u_dbus0.write(`I2C_CR   ,     8'h90 ); // set command (start, write)
	    $display("status: %t generate 'start', write cmd %0h (slave address+write)", $time, {SADR,WR} );

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // send memory address
	    u_dbus0.write(`I2C_TXR,     8'h01); // present slave's memory address
	    u_dbus0.write(`I2C_CR,      8'h10); // set command (write)
	    $display("status: %t write slave memory address 01", $time);

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // send memory contents
	    u_dbus0.write(`I2C_TXR,     8'ha5); // present data
	    u_dbus0.write(`I2C_CR,      8'h10); // set command (write)
	    $display("status: %t write data a5", $time);

      // test clock streching
      while (scl) #1;
      $display("status: %t clock streching starts", $time);
      force scl= 1'b0;
      #1100;
      release scl;
      $display("status: %t clock streching ends", $time);

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

      if(WR_BURST == 1'b0) begin
        // send memory address
        u_dbus0.write(`I2C_TXR,     8'h02); // present slave's memory address
        u_dbus0.write(`I2C_CR,      8'h10); // set command (write)
        $display("status: %t write slave memory address 02", $time);

        // check tip bit
        u_dbus0.read(`I2C_SR, q);
        while(q[1])
          u_dbus0.read(`I2C_SR, q); // poll it until it is zero
        $display("status: %t tip==0", $time);
      end

  		// send memory contents for next memory address (auto_inc in if WR_BURST==1)
	    u_dbus0.write(`I2C_TXR,     8'h5a); // present data
	    u_dbus0.write(`I2C_CR,      8'h50); // set command (stop, write)
	    $display("status: %t write next data 5a, generate 'stop'", $time);

	    // check busy & tip bits
	    u_dbus0.read(`I2C_SR, q);
	    while(q[6] | q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0, busy==0", $time);


	    //
	    // access slave (read)
	    //

	    $display("status: %t Read Access", $time);
	    // drive slave address
	    u_dbus0.write(`I2C_TXR,{SADR,WR} ); // present slave address, set write-bit
	    u_dbus0.write(`I2C_CR,     8'h90 ); // set command (start, write)
	    $display("status: %t generate 'start', write cmd %0h (slave address+write)", $time, {SADR,WR} );

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // send memory address
	    u_dbus0.write(`I2C_TXR,     8'h01); // present slave's memory address
	    u_dbus0.write(`I2C_CR,      8'h10); // set command (write)
	    $display("status: %t write slave address 01", $time);

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // drive slave address
	    u_dbus0.write(`I2C_TXR, {SADR,RD} ); // present slave's address, set read-bit
	    u_dbus0.write(`I2C_CR,      8'h90 ); // set command (start, write)
	    $display("status: %t generate 'repeated start', write cmd %0h (slave address+read)", $time, {SADR,RD} );

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // read data from slave
	    u_dbus0.write(`I2C_CR,      8'h20); // set command (read, ack_read)
	    $display("status: %t read + ack", $time);

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // check data just received
	    u_dbus0.read(`I2C_RXR, qq);
	    if(qq !== 8'ha5)
	      $display("\nERROR: Expected a5, received %x at time %t", qq, $time);
	    else
	      $display("status: %t received %x", $time, qq);

	    // read data from slave
	    u_dbus0.write(`I2C_CR,      8'h20); // set command (read, Nack_read)
	    $display("status: %t read + ack", $time);

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // check data just received
	    u_dbus0.read(`I2C_RXR, qq);
	    if(qq !== 8'h5a)
	      $display("\nERROR: Expected 5a, received %x at time %t", qq, $time);
	    else
	      $display("status: %t received %x", $time, qq);

	    // // read data from slave
	    // u_dbus0.write(`I2C_CR,      8'h20); // set command (read, ack_read)
	    // $display("status: %t read + ack", $time);
	    //
	    // // check tip bit
	    // u_dbus0.read(`I2C_SR, q);
	    // while(q[1])
	    //   u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    // $display("status: %t tip==0", $time);
	    //
	    // // check data just received
	    // u_dbus0.read(`I2C_RXR, qq);
	    // $display("status: %t received %x from 3rd read address", $time, qq);
	    //
	    // // read data from slave
	    // u_dbus0.write(`I2C_CR,      8'h28); // set command (read, nack_read)
	    // $display("status: %t read + nack", $time);
	    //
	    // // check tip bit
	    // u_dbus0.read(`I2C_SR, q);
	    // while(q[1])
	    //   u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    // $display("status: %t tip==0", $time);
	    //
	    // // check data just received
	    // u_dbus0.read(`I2C_RXR, qq);
	    // $display("status: %t received %x from 4th read address", $time, qq);

	    //
	    // check invalid slave memory address
	    //

	    // drive slave address
	    u_dbus0.write(`I2C_TXR, {SADR,WR} ); // present slave address, set write-bit
	    u_dbus0.write(`I2C_CR,      8'h90 ); // set command (start, write)
	    $display("status: %t generate 'start', write cmd %0h (slave address+write). Check invalid address", $time, {SADR,WR} );

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // send memory address
	    u_dbus0.write(`I2C_TXR,     8'h10); // present slave's memory address
	    u_dbus0.write(`I2C_CR,      8'h10); // set command (write)
	    $display("status: %t write slave memory address 10", $time);

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

	    // slave should have send NACK
	    $display("status: %t Check for nack", $time);
	    if(!q[7])
	      $display("\nERROR: Expected NACK, received ACK\n");

	    // generate stop 
	    u_dbus0.write(`I2C_CR,      8'h40); // set command (stop)
	    $display("status: %t generate 'stop'", $time);

	    // check tip bit
	    u_dbus0.read(`I2C_SR, q);
	    while(q[1])
	      u_dbus0.read(`I2C_SR, q); // poll it until it is zero
	    $display("status: %t tip==0", $time);

      waitCycles(1000);
	    $display("\n\nstatus: %t Testbench done", $time);
	    $stop;
	 end

   //___________________________________________________________________________
   // Basic tasks
   // check for errors during the simulation
   task checkErrors;
     begin
       if (errors==0) begin
         $display("********** TEST PASSED **********");
       end else begin
         $display("********** TEST FAILED **********");
       end
     end
   endtask

   // synchronous output check
   task syncCheck;
     begin
       waitClk;
       if (vExpected != vObtained) begin
         $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
         errors = errors + 1;
       end else begin
         $display("[Info- %t] Successful check at time", $time);
       end
     end
   endtask

   // asynchronous output check
   task asyncCheck;
     begin
       #`DELAY;
       if (vExpected != vObtained) begin
         $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
         errors = errors + 1;
       end else begin
         $display("[Info- %t] Successful check (%h) ", $time, vObtained);
       end
     end
   endtask

   // generation of reset pulse
   task reset;
     input [32-1:0] Ncycles;
     begin
       $display("[Info- %t] Reset", $time);
       rst_n = 1'b0;
       waitCycles(Ncycles);
       rst_n = 1'b1;
     end
   endtask

   // wait for N clock cycles
   task waitCycles;
     input [32-1:0] Ncycles;
     begin
       repeat(Ncycles) begin
         waitClk;
       end
     end
   endtask

   // wait the next posedge clock
   task waitClk;
     begin
       @(posedge clk);
         #`DELAY;
     end //begin
   endtask

endmodule

module delay (in, out);
  input  in;
  output out;

  assign out = in;

  specify
    (in => out) = (00,00);
  endspecify
endmodule


