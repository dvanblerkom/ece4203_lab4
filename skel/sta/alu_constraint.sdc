###############################################################
current_design alu
create_clock [get_ports {clk}]  -name clk -period 20.000000 -waveform {0.000000 10.000000}
set_propagated_clock  [get_ports {clk}]
set_clock_uncertainty 0.1 [get_clocks {clk}]
set_output_delay 0 -clock clk [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 [all_inputs]
set_load .005 [all_outputs]
