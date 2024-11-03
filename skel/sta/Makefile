# Makefile for running STA with a specified TCL script

# Variables
STA_CMD = sta
TCL_SCRIPT = starun.tcl
LOG_FILE = sta_report.txt
SDF_FILE = gcd.mapped.sdf
TCL_SCRIPT_ALU = starun_alu.tcl
LOG_FILE_ALU = sta_report_alu.txt
SDF_FILE_ALU = alu.mapped.sdf

JSON1 = ../build/syn-rundir/syn-output.json
JSON2 = ../build/syn-rundir/syn-output-full.json


# Default target
.PHONY: runsta
runsta:
	$(STA_CMD) -exit $(TCL_SCRIPT) | tee $(LOG_FILE)
	@if [ -f "$(SDF_FILE)" ]; then \
		jq --arg path "$(shell realpath $(SDF_FILE))" '."synthesis.outputs.sdf_file" = $$path' $(JSON1) > tmp.json; \
		mv tmp.json $(JSON1); \
		jq --arg path "$(shell realpath $(SDF_FILE))" '."synthesis.outputs.sdf_file" = $$path' $(JSON2) > tmp.json; \
		mv tmp.json $(JSON2); \
	else \
		echo "SDF file not found"; \
	fi

.PHONY: runsta_alu
runsta_alu:
	$(STA_CMD) -exit $(TCL_SCRIPT_ALU) | tee $(LOG_FILE_ALU)
	@if [ -f "$(SDF_FILE_ALU)" ]; then \
		jq --arg path "$(shell realpath $(SDF_FILE_ALU))" '."synthesis.outputs.sdf_file" = $$path' $(JSON1) > tmp.json; \
		mv tmp.json $(JSON1); \
		jq --arg path "$(shell realpath $(SDF_FILE_ALU))" '."synthesis.outputs.sdf_file" = $$path' $(JSON2) > tmp.json; \
		mv tmp.json $(JSON2); \
	else \
		echo "SDF file not found"; \
	fi

# Clean target
.PHONY: clean
clean:
	rm -f *.txt *.out
