/********1*********2*********3*********4*********5*********6*********7*********8
* File : tb_i2c_master_regs.v
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
* Testbench to verify the I2C Control and Configuration Registers.
*_______________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2023
*
*********1*********2*********3*********4*********5*********6*********7*********/

`include "../misc/timescale.v"
`include "../rtl/i2c_master_defines.v"
//`include "../misc/sys_model.v"

//`include "../misc/dbus_master_model.v"
//`include "../sdc/i2c_master_regs.sdc"
// verification level: RTL_LVL GATE_LVL
`define GATE_LVL
// delay between clock posedge and check
`define DELAY 2

module tb_i2c_master_regs(); // module name (same as the file)

  parameter AWIDTH = 4;
  parameter DWIDTH = 8;

  //___________________________________________________________________________
  // input output signals for the u_dut
  wire Clk;       // master clock input
  wire Rst_n;     // async active low reset
  wire [AWIDTH-1:0] Addr;      // lower address bits
  wire [DWIDTH-1:0] DataIn;    // databus input
  wire [DWIDTH-1:0] DataOut;

  wire Wr;        // write enable input
  wire  Int;       // interrupt request signal output
  // commands
  wire Start;     // generate (repeated) start condition
  wire Stop;      // generate stop condition
  wire Read;      // read from slave
  wire Write;     // write to slave
  wire Tx_ack;    // when a receiver; sent ACK (Txack='0') or NACK (Txack ='1')
  reg Rx_ack;    // received ack bit
  reg [7:0] Rx_data;   // data received from slave
  wire [7:0] Tx_data;   // data to be transmitted to slave
  wire [7:0] Prescale;  // I2C clock presacel value
  reg I2C_busy;  // bus busy (start signal detected)
  reg I2C_done;  // command completed; used to clear command register
  wire I2C_en;    // enables the i2c core
  reg I2C_al;     // I2C bus arbitration lost

  // test signals
  integer errors;                   // Accumulated errors during the simulation
  integer vExpected;                // expected value
  integer vObtained;                // obtained value
  reg [DWIDTH-1:0] data2write; // data to load in the shift register
  reg [AWIDTH-1:0] addr2write; // data to load in the shift register

  //___________________________________________________________________________
  // Instantiation of the module to be verified
  `ifdef RTL_LVL
  i2c_master_regs #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) u_dut (
  `else
  i2c_master_regs u_dut (
  `endif
    .Clk          (Clk),
    .Rst_n        (Rst_n),
    .Addr         (Addr),
    .DataIn       (DataIn),
    .DataOut      (DataOut),
    .Wr           (Wr),
    .Int          (Int),
    .Start        (Start),
    .Stop         (Stop),
    .Read         (Read),
    .Write        (Write),
    .Tx_ack       (Tx_ack),
    .Rx_ack       (Rx_ack),
    .Rx_data      (Rx_data),
    .Tx_data      (Tx_data),
    .Prescale     (Prescale),
    .I2C_busy     (I2C_busy),
    .I2C_done     (I2C_done),
    .I2C_en       (I2C_en),
    .I2C_al       (I2C_al)
  );

  //__________________________________________________________________________
  // hookup system data bus master
  dbus_master_model u_dbus (
    .Clk          (Clk),
    .Rst_n        (Rst_n),
    .Addr         (Addr),
    .Din          (DataOut),
    .Dout         (DataIn),
    .Wr           (Wr)
  );

  // hookup system module that generates clock and reset
  sys_model u_sys (
    .Clk      (Clk),
    .Rst_n    (Rst_n)
  );

  //___________________________________________________________________________
  // signals and vars initialization
  initial begin
    $display("[Info- %t] Initialization of signals and variables...", $time);
    addr2write = {AWIDTH{1'b0}};
    data2write = {DWIDTH{1'b0}};
    Rx_ack = 1'b0;
    Rx_data = {DWIDTH{1'b0}};
    I2C_busy = 1'b0;
    I2C_done = 1'b0;
    I2C_al = 1'b0;
  end

  //___________________________________________________________________________
  // Test Vectors
  initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print
    errors = 0;                    // initialize the errors counter
    u_sys.reset(3);                // puts the u_dut in a known stage
    u_sys.wait_cycles(5);          // waits 5 clock cicles

    $display("[Info- %t] Test Wr/Rd of registers through System Data Bus", $time);
    begin
      // TODO: open the dbus_master_model and complete the write and read tasks.
      addr2write = {1'b0,`I2C_TXR};
      while(!addr2write[AWIDTH-1]) begin
        data2write = 8'hAA;
        $display("[Info- %t] Test Wr/Rd %h to Reg[%h]", $time, data2write, addr2write);
        u_dbus.write(addr2write[AWIDTH-1:0], data2write);
        u_dbus.read(addr2write[AWIDTH-1:0], vObtained);
        vExpected = data2write;
        sync_check;
        data2write = 8'h55;
        $display("[Info- %t] Test Wr/Rd %h to Reg[%h]", $time, data2write, addr2write);
        u_dbus.write(addr2write[AWIDTH-1:0], data2write);
        u_dbus.read(addr2write[AWIDTH-1:0], vObtained);
        vExpected = data2write;
        sync_check;
        data2write = 8'h00;
        $display("[Info- %t] Test Wr/Rd %h to Reg[%h]", $time, data2write, addr2write);
        u_dbus.write(addr2write[AWIDTH-1:0], data2write);
        u_dbus.read(addr2write[AWIDTH-1:0], vObtained);
        vExpected = data2write;
        sync_check;
        addr2write = addr2write - 1'b1;
        $display("[Info- %t] New address to be written[%h]", $time, addr2write[AWIDTH-1:0]);
      end
      check_errors;
      errors = 0; // reset the errors counter      
    end


    $display("");
    $display("[Info- %t] Test CR autoclear after tranfer ends", $time);
    begin
      u_sys.reset(3);
      u_sys.wait_cycles(5);
      // TODO: Generate the test vectors using the available tasks to check
      // the autoclear of the CR register bits when byte transfer ends
      transer_done(1'b1);   // Simulem la finalitzacio d'una transferencia
      vExpected = 0;        // Els ultims 4 bits del registre cr haurien de ser 0
      u_dbus.read(`I2C_CR, vObtained);        // Llegim el registre i desem les dades a la variable vObtained
      vObtained[3:0] = {4{1'b0}};               // Els ultims 4 bits no ens importen (els volem a 0)
      async_check;  // Comprovacio asincrona

      $display("[Info- %t] Errors CR autoclear: %d", $time, errors);
      check_errors; // Error check

      errors = 0;
    end


    $display("");
    $display("[Info- %t] Test CR autoclear after arbitration is lost", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // the autoclear of the CR register bits when arbitration is lost.
      // Additionaly it should check that the SR's al bit is set, clear it
      // with CR's al_ack bit is automaticaly and check that the al_ack is auto-cleared.

      // Check the autoclear of the CR register bits when arbitration is lost
      u_sys.reset(3);
      u_sys.wait_cycles(5);

      arbitration_lost;                 // Simulem perdua d'arbitratge
      vExpected = 0;                    // El valor esperat es 0
      u_sys.wait_cycles(1);
      u_dbus.read(`I2C_CR, vObtained);  // Llegim el valor de sortida del registre cr
      vObtained[3:0] = {4{1'b0}};  
      sync_check;                       // Error check


      // Second part
      u_dbus.read(`I2C_SR, vObtained); // Llegim el registre sr i desem les dades a la variable vObtained

      if (!vObtained[5]) 
        errors = errors + 1; // Si no s'ha posat el bit AL a 1 hi ha hagut un error

      $display("CR here %d", errors);

      u_dbus.read(`I2C_CR, vObtained);                             // Reassignem el que hi havia anteriorment excepte la flag que toca
      u_dbus.write(`I2C_CTR, 8'b10000000);                         // Habilitem escriptura al CR
      u_dbus.write(`I2C_CR, {vObtained[7:2], 1'b1, vObtained[0]}); // Esborrem la bandera de AL del registre sr (AL_ACK=1)
      u_dbus.read(`I2C_SR, vObtained);         // Llegim el registre sr al seguent cicle

      if (vObtained[5])
        errors = errors + 1;  // Si el bit 5 del registre sr (bit al) segueix a 1, hi ha hagut un error
      
      $display("[Info- %t] Errors AL: %d", $time, errors);
      check_errors; // Error check

      errors = 0;
    end


    $display("");
    $display("[Info- %t] Test TIP flag", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // the correct generation of the Transfer In Progress flag. It must
      // check the TIP assertion and deassertion.
      u_sys.reset(3);
      u_sys.wait_cycles(5);

      vExpected = 8'b00000010;
      u_dbus.write(`I2C_CTR, 8'b10000000);  // Habilitem escriptura
      
      u_dbus.write(`I2C_CR, 8'b00100000);   // Assign control to READ
      u_dbus.read(`I2C_SR, vObtained);      // TIP should be UP
      vObtained = vObtained & vExpected;
      async_check;

      u_dbus.write(`I2C_CR, 8'b00010000); // Assign control to WRITE
      u_dbus.read(`I2C_SR, vObtained);    // TIP should be UP
      vObtained = vObtained & vExpected;
      async_check;

      $display("[Info- %t] Errors TIP: %d", $time, errors);
      check_errors;

      errors = 0;
    end
    

    $display("");
    $display("[Info- %t] Test INT request generation", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // the generation of the interreupt request.
      //    > Test all the posible generation sources
      //    > check the status bit and the interrupt request
      //    > the interrupt clear
      u_sys.reset(3);
      u_sys.wait_cycles(5);
      
      // Transfer done
      u_dbus.write(`I2C_CTR, 8'b01000000);
      transer_done(1'b1);
      u_dbus.write(`I2C_CR, 8'b00000000);
      check_interrupt;
      u_sys.wait_cycles(1);

      u_sys.reset(3);
      u_sys.wait_cycles(5);

      // Arbitration lost
      u_dbus.write(`I2C_CTR, 8'b01000000);
      arbitration_lost;     // Simulem perdua d'arbitratge
      u_dbus.write(`I2C_CR, 8'b00000000);
      check_interrupt;
      u_sys.wait_cycles(1);

      // Interrupt clear
      u_dbus.write(`I2C_CR, 8'b00000001);
      u_sys.wait_cycles(1);
      check_interrupt;

      $display("[Info- %t] Errors INT: %d", $time, errors);
      check_errors;
      errors = 0;
    end


    $display("");
    $display("[Info- %t] Test Prescale, Control, Command and Transmission registers outputs", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // if all the prescale, control and commands signals outputs are correct.

      // PRE
      data2write = 8'h1;
      vExpected = data2write;

      $display("Test Prescale @ %t", $time);
      u_dbus.write(`I2C_PRER, data2write);
      u_sys.wait_cycles(1);
      u_dbus.read(`I2C_PRER, vObtained);
      sync_check;
      $display("[Info- %t] Errors PRE %d", $time, errors);
      check_errors;
      errors = 0;
      u_sys.wait_cycles(1);

      // CTR
      data2write = 8'h2;
      vExpected = data2write;

      $display("Test CTR @ %t", $time);
      u_dbus.write(`I2C_CTR, data2write);
      u_sys.wait_cycles(1);
      u_dbus.read(`I2C_CTR, vObtained);
      sync_check;
      $display("[Info- %t] Errors CTR %d", $time, errors);
      check_errors;
      errors = 0;
      u_sys.wait_cycles(1);

      // CR
      $display("Test CR Outputs @ %t", $time);
      data2write = 8'hFF;
      vExpected = data2write;
      u_dbus.write(`I2C_CTR, 8'b10000000);  // Habilitació escriptura al I2C
      u_dbus.write(`I2C_CR, data2write);    // Escriptura i assignació outputs

      if (~Start | ~Stop | ~Read | ~Write | ~Tx_ack)
        errors = errors + 1;

      $display("[Info- %t] Errors CR Output %d", $time, errors);
      check_errors;
      errors = 0;

      // TX
      data2write = 8'h4;
      vExpected = data2write;

      $display("Test TX @ %t", $time);
      u_dbus.write(`I2C_TXR, data2write);
      u_sys.wait_cycles(1);
      u_dbus.read(`I2C_TXR, vObtained);
      sync_check;
      $display("[Info- %t] Errors TX %d", $time, errors);
      check_errors;
      errors = 0;
      u_sys.wait_cycles(1);
    end


    $display("");
    $display("[Info- %t] Test RXR and the rx_ack flag", $time);
    begin
      // TODO: check that the rx_data is accessible through the RXR,
      // and the rx_ack from bit 7 of SR
      data2write = 8'h5;

      // Check that the rx_data is accessible through the RXR
      vExpected = data2write;
      Rx_data = data2write;
      u_dbus.read(`I2C_RXR, vObtained);
      async_check;

      u_sys.wait_cycles(1);

      // and the rx_ack from bit 7 of SR
      Rx_ack = 1'b1;
      vExpected = 8'b10000000;
      u_dbus.read(`I2C_SR, vObtained);
      vObtained = vObtained & 8'b10000000; // Nomes ens interessa el primer bit
      async_check;

      $display("[Info- %t] Errors RXR: %d", $time, errors);
      check_errors;
      errors = 0;
    end      

    $display("");
    $display("[Info- %t] End of test", $time);
    $stop;
  end

  initial begin
    $monitor("[Info- %t] Status=%b", $time, u_dut.sr);
  end

  //___________________________________________________________________________
  // Test tasks and functions

  task check_interrupt;
    // TODO: This task checks the interrupt status for a detemined period of
    // time (=3 clock cycles). After that, if the interrupt has been asseted,
    // a successful message is displayed. If not, after the the three clocks,
    // an error message is displayed and the error counter increases.
    // It should be implemented using the fork statment : f label  join and  disable f label;
    fork:interrupt
      // Thread 1
      begin
        u_sys.wait_cycles(3);
        errors = errors + 1;
        $display("[Info- %t] Error Interrupt", $time);
        disable interrupt;
      end 

      // Thread 2
      begin
        wait(Int);
        $display("[Info- %t] Okay Interrupt", $time);
        disable interrupt;
      end
    join
  endtask


  task transer_done(input Ack);
    // TODO: This task generates an I2C_done pulse signal indicating that
    // a byte transfer is done, and set the rx_ack depending on the input
    begin
      I2C_done = 1'b1;
      Rx_ack = Ack;
      u_sys.wait_cycles(1);
      I2C_done = 1'b0;
    end
  endtask

  task arbitration_lost;
    // TODO: this task generates a I2C_al pulse simulating the arbitration lost
    // signal from the core.
    begin
      I2C_al = 1'b1;
      u_sys.wait_cycles(1);
      I2C_al = 1'b0;
    end
  endtask


  //___________________________________________________________________________
  // Basic tasks

  task sync_check;
  // Synchronous errors check
    begin
      u_sys.wait_cycles(1);
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin
        $display("[Info- %t] Successful check at time", $time);
      end
  end
  endtask

  task async_check;
  // Asynchronous errors check
    begin
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin
        $display("[Info- %t] Successful check", $time);
      end
    end
  endtask

  task check_errors;
  // Check for errors during the simulation
    begin
      if (errors==0) begin
        $display("********** TEST PASSED **********");
      end else begin
        $display("********** TEST FAILED **********");
      end
    end
  endtask


  task wait_cycles;
    // wait for N clock cycles
    input [32-1:0] Ncycles;
    begin
        repeat(Ncycles) begin
        @(posedge Clk);
            #`DELAY;
        end
    end
  endtask

endmodule
