create_clock -name clk100MHz -period 10.0 [get_ports Clk]
set_input_delay -clock clk100MHz 2.0 [all_inputs]
set_output_delay -clock clk100MHz 2.0 [all_outputs]