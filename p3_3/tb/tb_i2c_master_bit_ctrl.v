/********1*********2*********3*********4*********5*********6*********7*********8
* File : tb_i2c_master_bit_ctrl.v
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
* Basic test for bit command control module
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2023
*
*********1*********2*********3*********4*********5*********6*********7*********/

`include "../misc/timescale.v"
`include "../rtl/i2c_master_defines.v"

module tb_i2c_master_bit_ctrl(); // module name (same as the file)

  //___________________________________________________________________________
  // input output signals for the DUT
  parameter SIZE = 8;         // timer counter size
  wire            clk;        // system cloc
  wire            rst_n;      // system reset, asynch and active low
  reg             i2c_en;     // bit command control enabled
  wire            timerOut;
  wire            timerStart;
  wire            timerStop;
	reg      [ 3:0] bit_cmd;
	reg             bit_txd;
  wire            bit_ack;
  wire            bit_rxd;
  wire            i2c_busy;
  wire            i2c_al;
  wire            scl;
  wire            sclPadOut;
  wire            sclPadEn;
  wire            sda;
  wire            sdaPadOut;
  wire            sdaPadEn;
  reg  [SIZE-1:0] prescale;

  //___________________________________________________________________________
  // Instantiation of the module to be verified
  i2c_master_bit_ctrl u_dut(
		.Clk           ( clk          ),
		.Rst_n         ( rst_n        ),
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
    .Scl_i         ( scl          ),
    .Scl_o         ( sclPadOut    ),
    .Scl_oen       ( sclPadEn     ),
    .Sda_i         ( sda          ),
    .Sda_o         ( sdaPadOut    ),
    .Sda_oen       ( sdaPadEn     )
	);

  //___________________________________________________________________________
  // hookup system module that generates clock and reset
  parameter CLK_HALFPERIOD = 5;
  sys_model #(
    .CLK_HALFPERIOD ( CLK_HALFPERIOD ), // units depends on timescale
    .DELAY          ( 2 )  // delay between clock posedge and check
  ) u_sys (
    .Clk           ( clk   ),
    .Rst_n         ( rst_n )
  );

  // hookup timer that establish the bit generation timing
  i2c_bit_timer #(.SIZE(SIZE)) i_timer (
    .Clk           ( clk          ),
    .Rst_n         ( rst_n        ),
    .Start         ( timerStart   ),
    .Stop          ( timerStop    ),
    .Ticks         ( prescale     ),
    .Out           ( timerOut     )
  );

  // create i2c lines for each master
	assign scl = sclPadEn ? 1'bz : sclPadOut;
  assign sda = sdaPadEn ? 1'bz : sdaPadOut;

	pullup p1(scl); // pullup scl line
	pullup p2(sda); // pullup sda line

  //___________________________________________________________________________
  // signals and vars initialization
  initial begin
    i2c_en   = 1'b0;
    bit_cmd  = `I2C_CMD_NOP;
    bit_txd  = 1'b1;
    prescale = 8'd20;
  end

  //___________________________________________________________________________
  // Test Vectors
  initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print

    // THIS ONE WORKS FINE
    $display("[Info- %t] Test: Start signal generation", $time);
    u_sys.reset(2);                // puts the DUT in a known stage
    enable_i2c;
    generate_start;
    u_sys.wait_cycles(2);          // waits 2 clock cicles
    disable_i2c;

    // Canvi variables state,next de 3b a 4b
    $display("[Info- %t] Test: Stop signal generation", $time);
    u_sys.reset(2);                // puts the DUT in a known stage
    enable_i2c;
    generate_stop;
    u_sys.wait_cycles(2);          // waits 2 clock cicles
    disable_i2c;

    // Correcció next en WR
    $display("[Info- %t] Test: Write bit", $time);
    u_sys.reset(2);                // puts the DUT in a known stage
    enable_i2c;
    write_bit(1'b0);
    u_sys.wait_cycles(1);
    write_bit(1'b1);
    u_sys.wait_cycles(2);          // waits 2 clock cicles
    disable_i2c;

    $display("[Info- %t] Test: Read bit", $time);
    u_sys.reset(2);                // puts the DUT in a known stage
    enable_i2c;
    force sda = 1'b0;
    read_bit;
    release sda;
    read_bit;
    u_sys.wait_cycles(2);          // waits 2 clock cicles
    disable_i2c;

    $display("[Info- %t] Test: Restart", $time);
    u_sys.reset(2);                // puts the DUT in a known stage
    enable_i2c;
    write_bit(1'b0);
    generate_start;
    u_sys.wait_cycles(2);          // waits 2 clock cicles
    disable_i2c;

    $display("[Info- %t] Test: I2C busy (other master driving bus)", $time);
    // other master generates start and stop signals
    u_sys.reset(2);                // puts the DUT in a known stage
    #1000                          // generate start
    force sda = 1'b0;
    #500
    force scl = 1'b0;
    wait(i2c_busy);                // check busy flag
    #2000                          // generate stop
    release scl;
    #500
    release sda;
    wait(~i2c_busy);

    $display("[Info- %t] Test: I2C busy (own generated)", $time);
    u_sys.reset(2);                // puts the DUT in a known stage
    enable_i2c;
    generate_start;
    wait(i2c_busy);
    generate_stop();
    wait(~i2c_busy);
    disable_i2c;

    $display("[Info- %t] Test: clock streaching", $time);
    u_sys.reset(2);
    enable_i2c;
    generate_start;
    #1000
    force scl = 1'b0;        // slave forces scl low
    #200
    @(posedge clk)           // write bit (sending "0")
    bit_cmd = `I2C_CMD_WRITE;
    bit_txd = 1'b0;
    #1500
    release scl;
    wait(bit_ack);
    disable_i2c;

    $display("[Info- %t] Test: Arbitration Lost (condition1)", $time);
    u_sys.reset(2);
    enable_i2c;
    generate_start;
    #500
    force sda = 1'b0;
    #500
    @(posedge clk)           // write bit (sending "1")
    bit_cmd = `I2C_CMD_WRITE;
    bit_txd = 1'b1;
    wait(i2c_al)
    #200
    disable_i2c;

    $display("[Info- %t] Test: Arbitration Lost (condition2)", $time);
    u_sys.reset(2);
    enable_i2c;
    generate_start;
    wait(u_dut.state == u_dut.IDLE);
    #1000                          // generate stop
    force scl = 1'b1;
    #200
    force sda = 1'b1;
    wait(i2c_al)
    #200
    release sda;
    disable_i2c;

    u_sys.wait_cycles(5); // for easy visualization of the end
    $display("[Info- %t] End of Tests", $time);
    $stop;
  end


  //___________________________________________________________________________
  // Test tasks
  task generate_start;
    begin
      @(posedge clk)
      bit_cmd = `I2C_CMD_START;
      wait(bit_ack)
      @(posedge clk)
      bit_cmd = `I2C_CMD_NOP;
    end
  endtask

  task generate_stop;
    begin
      @(posedge clk)
      bit_cmd = `I2C_CMD_STOP;
      wait(bit_ack)
      @(posedge clk)
      bit_cmd = `I2C_CMD_NOP;
    end
  endtask

  task write_bit (input Txd);
    begin
      @(posedge clk)
      bit_cmd = `I2C_CMD_WRITE;
      bit_txd = Txd;
      wait(bit_ack)
      @(posedge clk)
      bit_cmd = `I2C_CMD_NOP;
    end
  endtask

  task read_bit;
    begin
      @(posedge clk)
      bit_cmd = `I2C_CMD_READ;
      wait(bit_ack)
      @(posedge clk)
      bit_cmd = `I2C_CMD_NOP;
    end
  endtask

  task enable_i2c;
    begin
      @(posedge clk)
        i2c_en = 1'b1;
      @(posedge clk);
    end
  endtask

  task disable_i2c;
    begin
      @(posedge clk)
        i2c_en = 1'b0;
      @(posedge clk);
    end
  endtask

endmodule
