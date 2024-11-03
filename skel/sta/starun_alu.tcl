
read_liberty /data02/ECE4203/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog ../build/syn-rundir/alu.mapped.v
link_design alu
read_sdc alu_constraint.sdc
report_checks -format full_clock_expanded
write_sdf alu.mapped.sdf
