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
integer         stop_cycles;
integer         n_tests;

reg             vExpected;  // expected value
reg             vObtained;  // obtained value

realtime        time_mark;
realtime        diff_time;

integer         diff_cnt;
integer         first;

/* Unused vars
integer         mod;
integer         step;
*/

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
// Static logic for test
always @(posedge clk) begin
    vObtained <= timerOut;
end

always @(posedge clk) begin
    if (!bitCntr)
        vExpected <= 1;
    else
        vExpected <= 0;
end

//___________________________________________________________________________
// Test
initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print                      // puts the DUT in a known stage
    wait_cycles(5);                // waits 5 clock cycles

    // Test
    $display("[Info- %t] Test counter", $time);
    stop_cycles = 8;
    stop = 1'b1;

    test_and_result(0,  stop_cycles);
    test_and_result(1,  stop_cycles);
    test_and_result(8,  stop_cycles);
    test_and_result(15, stop_cycles);

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

task test_and_result;
    input [SIZE-1:0] ticks_in, stop_cycles;
    begin
        $display();
        $display("---------------------------------------------------------------------------------------------");
        errors = 0;                    // initialize the errors counter
        reset;
        test_hold(ticks_in, stop_cycles);

        $display("---------------------------------------------------------------------------------------------");

        if (errors == 0) begin
            $display("** TEST PASSED **");
        end else begin
            $display("** TEST FAILED **");
        end

        $display("[Results @ %d] Errors = %d | TimeGap = %t | CyclesGap = %d", ticks_in, errors, diff_time, diff_cnt);
        $display("---------------------------------------------------------------------------------------------");
        $display();
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

/*
task test_spread;
    input [SIZE-1:0] ticks_in, n_stop;
    begin
        stop = 1'b1;
        bitCntr = ticks_in;
        mod = 1;

        vExpected = 0;
        vObtained = 0;
        load_ticks(ticks_in);
        stop = 1'b0;

        // Cada "step" cicles fem una parada
        if (n_stop == 0)
            step = 1;
        else
            step = (ticks_in / n_stop);

        // Residu
        mod = bitCntr % (ticks_in / n_stop);

        repeat(ticks_in) begin

            // Es para el comptador durant un cicle de clock
            if (mod == 0) begin
                stop = 1'b1;

                vExpected = 0;
                bitCntr = bitCntr;
                mod = 1;

                wait_cycles(1);
                stop = 1'b0;

            end else begin
                mod = bitCntr % (ticks_in / n_stop);
                vExpected = 0;
                vObtained = timerOut;
            end

            wait_cycles(1);
            bitCntr = bitCntr - 1;
        end

        //vExpected = 1;
        vObtained = timerOut;
        async_check;
        stop = 1'b1;
    end
endtask
*/

task test_hold;
    input [SIZE-1:0] ticks_in, n_cycles;
    begin
        stop = 1'b0;    
        load_ticks(ticks_in);
        first = 1;
        diff_cnt = 0;

        if (ticks_in == 0) begin
            $display("No ticks!");

        end else begin
            repeat(2) begin
                // Carreguem valor corresponent al comptador "software"
                bitCntr = ticks_in;
                wait_cycles(1);

                repeat(ticks_in) begin
                    // Es para el comptador durant tants cicles de clock a la meitat del comptatge
                    if (bitCntr == (ticks_in / 2)) begin

                        // Quan arriba a la meitat, para i espera n_cycles
                        stop = 1'b1;                    
                        wait_cycles(n_cycles);

                        // Comprovem si es primer comptatge
                        if (!(first)) begin
                            diff_cnt = diff_cnt + n_cycles;
                        end

                        // Torna a comptar
                        stop = 1'b0; 
                    end

                    if (!(first)) begin
                        diff_cnt = diff_cnt + 1;
                    end

                    // Evolució del comptador i comprovem si funciona correctament
                    // Valor esperat = 0
                    bitCntr = bitCntr - 1;
                    wait_cycles(1);
                    async_check;
                end

                // Comprovem que funciona
                // Valor esperat = 1
                async_check;

                // Al final del primer comptatge marquem el temps
                if ((vObtained) && (first)) begin
                    time_mark = $realtime;
                    first = 0;
                // Al final del segon comptatge calculem la diferència de temps
                end else begin
                    diff_time = $realtime - time_mark;
                    stop = 1'b1;
                end
            end
        end
    end
endtask

endmodule