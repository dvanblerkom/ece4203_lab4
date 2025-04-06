###############################################################
current_design alu
set file [open "../design_alu.yml" r]
set content [read $file]
close $file
if {[regexp {CLK_PERIOD "([0-9]+(?:\.[0-9]+)?)ns"} $content match value]} {
# found
} else {
    puts "Error: Could not find a valid CLK_PERIOD value in the source file."
    exit 1
}
set half_value [expr {$value / 2.0}]

# create_clock [get_ports {clk}]  -name clk -period 20.000000 -waveform {0.000000 10.000000}
create_clock [get_ports {clk}]  -name clk -period $value -waveform [list 0.000000 $half_value]
set_propagated_clock  [get_ports {clk}]
set_clock_uncertainty 0.1 [get_clocks {clk}]
set_output_delay 0 -clock clk [all_outputs]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 [all_inputs]
set_load .005 [all_outputs]
