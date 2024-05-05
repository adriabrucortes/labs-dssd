#********1*********2*********3*********4*********5*********6*********7*********8
# File : top_meteo_de0cv.sdc
#_______________________________________________________________________________
#
# Revision history
#
# Name          Date        Observations
# ------------------------------------------------------------------------------
# -            01/02/2022   First version.
# ------------------------------------------------------------------------------
#_______________________________________________________________________________
#
# Description
# Synopsys Design Constraints for the Meteostation based on BME280 and DE0-CV
#_______________________________________________________________________________
#
# (c) Copyright Universitat de Barcelona, 2022
#
#********1*********2*********3*********4*********5*********6*********7*********/

create_clock -name clk50MHz -period 20.0 [get_ports Clk_i]
derive_pll_clocks -create_base_clocks
set_clock_groups -asynchronous -group [get_clocks {clk50MHz}] -group [get_clocks {i_PLL|pll_cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -group [get_clocks {{i_PLL|pll_cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}}]

set_input_delay -clock clk50MHz 7.0 [all_inputs]
set_output_delay -clock clk50MHz 5.0 [all_outputs]
set_false_path -from [get_ports {Rst_n_i}] -to [all_registers]