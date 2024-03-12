/********1*********2*********3*********4*********5*********6*********7*********8
* File : tb_shiftreg.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/02/2022   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
*
* Description
* Testbench for a complet non cyclic shift register.
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2022
*
*********1*********2*********3*********4*********5*********6*********7*********/

`include "../misc/timescale.v"
// delay between clock posedge and check
`define DELAY 2
// verification level: RTL_LVL GATE_LVL
`define RTL_LVL

module tb_shiftreg(); // module name (same as the file)

  //___________________________________________________________________________
  // input output signals for the DUT
  parameter SIZE = 8;      // data size of the shift register
  reg             clk;     // rellotge del sistema
  reg             rst_n;   // reset del sistema asíncorn i actiu nivell baix
  reg             shift;   // when high shift bits
  reg             load;    // shift register load data
  reg  [SIZE-1:0] dataIn;  // shift register parallel data input
  wire [SIZE-1:0] dataOut; // shift register parallel data output
  reg             serIn;   // shift register serial data input
  wire            serOut;  // shift register serial data output

  // test signals
  integer         errors;    // Accumulated errors during the simulation
  integer         bitCntr;   // used to count bits
  reg  [SIZE-1:0] data2load; // data to load in the shift register
  reg  [SIZE-1:0] vExpected;  // expected value
  reg  [SIZE-1:0] vObtained; // obtained value

  //___________________________________________________________________________
  // Instantiation of the module to be verified
  `ifdef RTL_LVL
  shiftreg #(.SIZE(8)) DUT(
  `else
  shiftreg DUT( // used by post-síntesis verification
  `endif
    .Clk           (clk),
    .Rst_n         (rst_n),
    .Load          (load),
    .En            (shift),
    .SerIn         (serIn),
    .DataIn        (dataIn),
    .SerOut        (serOut),
    .DataOut       (dataOut)
  );

  //___________________________________________________________________________
  // 100 MHz clock generation
  initial clk = 1'b0;
  always #5 clk = ~ clk;

  //___________________________________________________________________________
  // signals and vars initialization
  initial begin
    rst_n  = 1'b1;
    shift  = 1'b0;
    load   = 1'b0;
    dataIn = {SIZE{1'b0}};
    serIn  = 1'b0;
  end

  //___________________________________________________________________________
  // Test Vectors
  initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print
    errors = 0;                    // initialize the errors counter
    reset;                         // puts the DUT in a known stage
    wait_cycles(5);                // waits 5 clock cicles

    $display("[Info- %t] Test parallel data loading", $time);
    data2load = 8'hAA;
    load_shiftreg(data2load);
    vExpected = data2load;
    vObtained = dataOut;
    async_check;
    check_errors;
    errors = 0;                    // initialize the errors counter

    $display("[Info- %t] Test serial output", $time);
    data2load = 8'hAA;
    test_serout(data2load);
    check_errors;
    errors = 0;                    // initialize the errors counter

    $display("[Info- %t] Test serial input", $time);
    reset;                      // puts the DUT in a known stage
    test_serin(data2load);
    check_errors;
    errors = 0;

    wait_cycles(5); // for easy visualization of the end
    $stop;
  end

  initial begin
    $monitor("[Info- %t] En=%h DataIn=%h DataOut=%h SerIn=%h SerOut=%b",
             $time, shift, dataIn, dataOut, serIn, serOut);
  end

  //___________________________________________________________________________
  // Test tasks

  task test_serin;
    // check serial input
    input [SIZE-1:0] data;

    begin
      bitCntr = SIZE-1; 
      shift = 1'b1;
      wait_cycles(1);

      repeat(SIZE) begin
        serIn = data[bitCntr];
        wait_cycles(1);

        bitCntr = bitCntr - 1;
      end

      vExpected = data;
      vObtained = dataOut;

      async_check;

      /* 
      // Manera pocha
      repeat(SIZE) begin
        // Comencem pel més significatiu
        serIn = data[bitCntr];
        wait_cycles(1);

        // vExpected serà la concatenació de zeros més les dades que hagin entrat
        vExpected = serIn;
        vObtained = dataOut[0];

        async_check;
        bitCntr = bitCntr - 1;
      end
      */

      shift = 1'b0;
      wait_cycles(1);

    end
  endtask

  task test_serout;
    // check the serial output
    input [SIZE-1:0] data;
    begin
      bitCntr = 0;
      load_shiftreg(data);
      shift = 1'b1;
      repeat(SIZE) begin
        vExpected = data[SIZE-1-bitCntr];
        vObtained = serOut;
        async_check;
        bitCntr = bitCntr + 1;
        wait_cycles(1);
      end
      shift = 1'b0;
      wait_cycles(1);
    end
  endtask

  task load_shiftreg;
    // check the paralle data input
    input [SIZE-1:0] data;
    begin
      dataIn = data;
      load = 1'b1;
      wait_cycles(1);
      load = 1'b0;
      dataIn = 8'h00;
      wait_cycles(1);
    end
  endtask

  //___________________________________________________________________________
  // Basic tasks

  task reset;
    // generation of reset pulse
    begin
      $display("[Info- %t] Reset", $time);
      rst_n = 1'b0;
      wait_cycles(3);
      rst_n = 1'b1;
    end
  endtask

  task wait_cycles;
    // wait for N clock cycles
    input [32-1:0] Ncycles;
    begin
      repeat(Ncycles) begin
        @(posedge clk);
          #`DELAY;
      end
    end
  endtask

  task sync_check;
    // synchronous output check
    begin
      wait_cycles(1);
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin
        $display("[Info- %t] Successful check at time", $time);
      end
    end
  endtask

  task async_check;
    // asynchronous output check
    begin
      #`DELAY;
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin
        $display("[Info- %t] Successful check at time", $time);
      end
    end
  endtask

  task check_errors;
    // check for errors during the simulation
    begin
      if (errors==0) begin
        $display("********** TEST PASSED **********");
      end else begin
        $display("********** TEST FAILED **********");
      end
    end
  endtask

endmodule
