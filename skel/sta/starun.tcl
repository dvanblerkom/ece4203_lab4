
read_liberty /data02/ECE4203/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog ../build/syn-rundir/gcd.mapped.v
link_design gcd
read_sdc gcd_constraint.sdc
report_checks -format full_clock_expanded
write_sdf gcd.mapped.sdf
