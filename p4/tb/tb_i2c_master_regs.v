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
// verification level: RTL_LVL GATE_LVL
`define RTL_LVL

module tb_i2c_master_regs(); // module name (same as the file)

  integer AWIDTH;
  integer DWIDTH;

  //___________________________________________________________________________
  // input output signals for the DUT
  wire Clk,       // master clock input
  wire Rst_n,     // async active low reset
  wire [AWIDTH-1:0] addr2write,      // lower address bits
  wire [DWIDTH-1:0] data2write,    // databus input

  wire Wr,        // write enable input
  reg  Int,       // interrupt request signal output
  // commands
  wire Start,     // generate (repeated) start condition
  wire Stop,      // generate stop condition
  wire Read,      // read from slave
  wire Write,     // write to slave
  wire Tx_ack,    // when a receiver, sent ACK (Txack='0') or NACK (Txack ='1')
  wire Rx_ack,    // received ack bit
  wire [7:0] Rx_data,   // data received from slave
  wire [7:0] Tx_data,   // data to be transmitted to slave
  wire [7:0] Prescale,  // I2C clock presacel value
  wire I2C_busy,  // bus busy (start signal detected)
  wire I2C_done,  // command completed, used to clear command register
  wire I2C_en,    // enables the i2c core
  wire I2C_al     // I2C bus arbitration lost

  // test signals
  integer errors;                   // Accumulated errors during the simulation
  integer vExpected;                // expected value
  integer vObtained;                // obtained value
  reg  [DATA_WIDTH-1:0] data2write; // data to load in the shift register
  reg  [ADDR_WIDTH-1:0] addr2write; // data to load in the shift register

  //___________________________________________________________________________
  // Instantiation of the module to be verified
  i2c_master_regs DUT (
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
    .Rst_n        (Rst_n)
  );

  // hookup system module that generates clock and reset
  sys_model u_sys (
    .Clk      (Clk),
    .Rst_n    (Rst_n)
  );

  //___________________________________________________________________________
  // 100 MHz clock generation
  initial Clk = 1'b0;
  always #5 Clk = ~ Clk;

  //___________________________________________________________________________
  // signals and vars initialization
  initial begin
    $display("[Info- %t] Initialization of signals and variables...", $time);
    addr2write = {AWIDTH{1'b0}};
    rst_n = 1'b1;
    start = 1'b1;
    stop  = 1'b1;
  end

  //___________________________________________________________________________
  // Test Vectors
  initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print
    errors = 0;                    // initialize the errors counter
    u_sys.reset(3);                // puts the DUT in a known stage
    u_sys.wait_cycles(5);          // waits 5 clock cicles

    $display("[Info- %t] Test Wr/Rd of registers through System Data Bus", $time);
    begin
      // TODO: open the dbus_master_model and complete the write and read tasks.
      addr2write = {1'b0,`I2C_TXR};
      while(!addr2write[ADDR_WIDTH]) begin
        data2write = 8'hAA;
        $display("[Info- %t] Test Wr/Rd %h to Reg[%h]", $time, data2write, addr2write);
        u_dbus.write(addr2write[ADDR_WIDTH-1:0], data2write);
        u_dbus.read(addr2write[ADDR_WIDTH-1:0], vObtained);
        vExpected = data2write;
        sync_check;
        data2write = 8'h55;
        $display("[Info- %t] Test Wr/Rd %h to Reg[%h]", $time, data2write, addr2write);
        u_dbus.write(addr2write[ADDR_WIDTH-1:0], data2write);
        u_dbus.read(addr2write[ADDR_WIDTH-1:0], vObtained);
        vExpected = data2write;
        sync_check;
        data2write = 8'h00;
        $display("[Info- %t] Test Wr/Rd %h to Reg[%h]", $time, data2write, addr2write);
        u_dbus.write(addr2write[ADDR_WIDTH-1:0], data2write);
        u_dbus.read(addr2write[ADDR_WIDTH-1:0], vObtained);
        vExpected = data2write;
        sync_check;
        addr2write = addr2write - 1'b1;
        $display("[Info- %t] New address to be writted[%h]", $time, addr2write[ADDR_WIDTH-1:0]);
      end
      check_errors;
      errors = 0; // reset the errors counter      
    end


    $display("[Info- %t] Test CR autoclear after tranfer ends", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // the autoclear of the CR register bits when byte transfer ends
      transer_done(1'b1);   // Simulem la finalitzacio d'una transferencia
      u_sys.wait_cycles(1); // Esperem al seguent cicle de rellotge
      vExpected = 0;        // Els ultims 4 bits del registre cr haurien de ser 0
      u_dbus.read(`I2C_CR, vObtained);        // Llegim el registre i desem les dades a la variable vObtained
      vObtained[3:0] = 4{1b'0};               // Els ultims 4 bits no ens importen (els volem a 0)
      // vObtained = {vObtained[31:4],4{1b'0}};  // Assignem el valor de vObtained al valor anterior desplaçat 4 bits a l'esquerra i concatenat amb 0
      async_check;  // Comprovacio asincrona
      check_errors; // Error check
      $display("[Info- %t] Errors CR autoclear: %d", $time, errors);

      errors = 0;
    end


    $display("[Info- %t] Test CR autoclear after arbitration is lost", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // the autoclear of the CR register bits when arbitration is lost.
      // Additionaly it should check that the SR's al bit is set, clear it
      // with CR's al_ack bit is automaticaly and check that the al_ack is auto-cleared.
      arbitration_lost;     // Simulem perdua d'arbitratge
      u_sys.wait_cycles(1); // Esperem un cicle de clk
      vExpected = 0;                  // El valor esperat es 0
      u_dbus.read(`I2C_CR, vObtained); // Llegim el valor de sortida del registre cr
      vObtained[3:0] = 4{1b'0};  
      // vObtained = {vObtained[31:4],4{1b'0}};  // Assignem el valor de vObtained al valor anterior desplaçat 4 bits a l'esquerra i concatenat amb 0
      async_check;  // Error check

      // Second part
      u_dbus.read(`I2C_SR, vObtained); // Llegim el registre sr i desem les dades a la variable vObtained

      if (!vObtained[5]) 
        errors = errors + 1; // Si no s'ha posat el bit AL a 1 hi ha hagut un error

      u_dbus.read(`I2C_CR, vObtained);
      u_dbus.write(`I2C_CR, {vObtained[7:2], 1b'1, vObtained[0]}); // Esborrem la bandera de AL del registre sr (AL_ACK=1)
      u_dbus.read(`I2C_SR, vObtained);         // Llegim el registre sr al seguent cicle

      if (vObtained[5])
        errors = errors + 1;  // Si el bit 5 del registre sr (bit al) segueix a 1, hi ha hagut un error
      
      check_errors; // Error check
      $display("[Info- %t] Errors AL: %d", $time, errors);

      errors = 0;
    end


    $display("[Info- %t] Test TIP flag", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // the correct generation of the Transfer In Progress flag. It must
      // check the TIP assertion and deassertion.
      vExpected = 8'b00000010;
      u_dbus.write(`I2C_CR, 8'b00100000); // Assign control to READ
      u_dbus.read(`I2C_SR, vObtained);    // TIP should be UP
      async_check;

      u_dbus.write(`I2C_CR, 8'b00010000); // Assign control to WRITE
      u_dbus.read(`I2C_SR, vObtained);    // TIP should be UP
      async_check;
      check_errors;

      $display("[Info- %t] Errors TIP: %d", $time, errors);

      errors = 0;
    end
    

    $display("[Info- %t] Test INT request generation", $time);
    begin
      // TODO: Generate the test vectors using the available tasks to check
      // the generation of the interreupt request.
      //    > Test all the posible generation sources
      //    > check the status bit and the interrupt request
      //    > the interrupt clear
            
    end

      

    $display("[Info- %t] Test Prescale, Control, Command and Transmission registers outputs", $time);
    // TODO: Generate the test vectors using the available tasks to check
    // if all the prescale, control and commands signals outputs are correct.
    TO BE COMPLETED BY THE STUDENT

    $display("[Info- %t] Test RXR and the rx_ack flag", $time);
    // TODO: check that the rx_data is acceccible through the RXR,
    // and the rx_ack from bit 7 of SR
    TO BE COMPLETED BY THE STUDENT

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
    i2c_done = 1'b1;
    rx_ack = Ack;
    u_sys.wait_cycles(1);
    i2c_done = 1'b1;
  endtask

  task arbitration_lost;
  // TODO: this task generates a I2C_al pulse simulating the arbitration lost
  // signal from the core.
    i2c_al = 1'b1;
    u_sys.wait_cycles(1);
    i2c_al = 1'b1;
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
endmodule
