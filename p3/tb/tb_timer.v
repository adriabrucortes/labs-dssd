`include "../misc/timescale.v"
// delay between clock posedge and check
`define DELAY 2
// verification level: RTL_LVL GATE_LVL
`define RTL_LVL

module tb_timer(); // module name (same as the file)

//___________________________________________________________________________
// input output signals for the DUT
parameter SIZE = 8;         // data size of the shift register
reg             clk;        // rellotge del sistema
reg             rst_n;      // reset del sistema asíncorn i actiu nivell baix
reg             start;      // condició de start (posa Ticks al comptador)
reg             stop;       // condició de stop (fa que el comptador mantingui el valor)
reg [SIZE-1:0]  ticks;      // valor màxim/inicial del comptador
wire            timerOut;   // pols de sortida del comptador

// test signals
integer         errors;     // Accumulated errors during the simulation
integer         bitCntr;    // used to count bits
integer         parades;
integer         cicles;
reg  [SIZE-1:0] data2load;  // data to load in the shift register
reg             vExpected;  // expected value
reg             vObtained;  // obtained value

`ifdef RTL_LVL
i2c_bit_timer #(.SIZE(8)) DUT(
`else
i2c_bit_timer DUT( // used by post-síntesis verification
`endif
    .Clk           (clk),
    .Rst_n         (rst_n),
    .Start         (start),
    .Stop          (stop),
    .Ticks         (ticks),
    .Out           (timerOut)
);

//___________________________________________________________________________
// 100 MHz clock generation
initial clk = 1'b0;
always #5 clk = ~ clk;

//___________________________________________________________________________
// signals and vars initialization
initial begin
    rst_n = 1'b1;
    start = 1'b1;
    stop  = 1'b1;
    ticks = {SIZE{1'b0}};
end

//___________________________________________________________________________
// Test
initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print
    errors = 0;                    // initialize the errors counter
    reset;                         // puts the DUT in a known stage
    wait_cycles(5);                // waits 5 clock cicles

    // Test
    $display("[Info- %t] Test counter", $time);
    data2load = 8'hAA;
    parades = 4;
    cicles = 8;
    stop = 1'b1;

    test_counter(data2load, parades, cicles);
    check_errors;

    wait_cycles(5); // for easy visualization of the end
    $stop;
end

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

//___________________________________________________________________________
// Test tasks
task load_ticks;
    input [SIZE-1:0] data;
    begin
        ticks = data;
        start = 1'b1;
        wait_cycles(1);
        
        start = 1'b0;
        wait_cycles(1);
    end
endtask

task test_counter;
    input ticks_in, ndiv, Ncycles;
    begin
        bitCntr = ticks_in; // dafuq
        vExpected = 0;
        load_ticks(ticks_in);
        stop = 1'b0;
        wait_cycles(1);

        repeat(Ncycles) begin

            // Això representa un "Cicle" de comptador (una sola pujada)
            repeat(ndiv+1) begin

                // S'aturarà cada Ncycles
                repeat(ticks_in/(ndiv+1)) begin
                    wait_cycles(1);

                    // Comptador artificial
                    if (bitCntr == 0) begin
                        vExpected = 1;
                        bitCntr = ticks_in;

                    end else begin
                        vExpected = 0;
                        bitCntr = bitCntr - 1;
                    end

                    vObtained = timerOut;
                    async_check;
                end

                // Parada
                stop = 1'b1;
                wait_cycles(1);
                stop = 1'b0;
            end
        end
    end
endtask

endmodule