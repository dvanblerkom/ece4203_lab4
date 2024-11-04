# ASIC Lab 4: Logic Synthesis
<p align="center">
Prof. Daniel Van Blerkom
</p>
<p align="center">
Department of Electrical and Computer Engineering, Cal Poly Pomona
</p>
(Modified from original UCB EECS 150 lab)

## Table of contents
- [ASIC Lab 4: Logic Synthesis](#asic-lab-3-logic-synthesis)
  - [Table of contents](#table-of-contents)
  - [Overview](#overview)
  - [What is Synthesis?](#what-is-synthesis)
    - [Introduction to Static Timing Analysis](#introduction-to-static-timing-analysis)
  - [Synthesis Environment](#synthesis-environment)
    - [Interpreting the YAML files](#interpreting-the-yaml-files)
      - [Interpreting the YAML: *design.yml*](#interpreting-the-yaml-designyml)
      - [Interpreting the YAML: *sim-rtl.yml*](#interpreting-the-yaml-sim-rtlyml)
  - [Handshaking](#handshaking)
  - [The Example Design: GCD](#the-example-design-gcd)
  - [RTL-Simulation](#rtl-simulation)
  - [Synthesize An Example Design: GCD](#synthesize-an-example-design-gcd)
    - [Hammer and Genus Relationship](#hammer-and-genus-relationship)
    - [TCL?](#tcl)
    - [Reports](#reports)
  - [Post-Synthesis Simulation](#post-synthesis-simulation)
  - [Build A Parameterized ALU](#build-a-parameterized-divider)
    - [Write the Design](#write-the-design)
    - [Verify functionality with a RTL simulation](#verify-functionality-with-a-rtl-simulation)
    - [Synthesize Your Design](#synthesize-your-design)
  - [Questions](#questions)
    - [Question 1: Understanding the algorithm](#question-1-understanding-the-algorithm)
    - [Question 2: GCD Reports Questions](#question-2-gcd-reports-questions)
    - [Question 3: GCD Synthesis Questions](#question-3-gcd-synthesis-questions)
    - [Question 4: Delay Questions](#question-4-delay-questions)
    - [Question 5: Synthesized ALU](#question-5-synthesized-divder)
  - [Acknowledgement](#acknowledgement)


## Overview
**Setup:**
Pull lab4 from the Github Classroom into your home directory:
   ```
   cd 
   git clone ssh://git@ssh.github.com:443/dvb-ece-cpp/lab4-fa24-4203-(your github id).git
   ```

Don't forget to activate the conda environment every time you log in:
```
conda activate ece4203
```
**Objective:** 
This lab will cover logic synthesis. You were briefly introduced to the concept in Lab 3, but were given all the output products and asked to analyze them. In this lab, you will complete synthesis yourself for two small designs: (1) an example design provided to you and (2) a design you create yourself. The steps and skills learned to synthesize these designs can be applied to larger more complex designs (i.e. accelerators, or full SoCs).

**Topics Covered**
- Logic Synthesis
- CAD Tools (emphasis on Synthesis)
- Hammer
- Skywater 130mm PDK
- Behavorial RTL Simulation
- Reading Reports

**Recommended Reading**
- [Verilog Primer](https://courses.csail.mit.edu/6.111/f2004/handouts/L04.pdf)
- [Hammer-Flow](https://hammer-vlsi.readthedocs.io/en/latest/Hammer-Flow/index.html)
- [Ready-Valid Interface](https://www.eecs151.org/files/verilog/ready_valid_interface.pdf)


## What is Synthesis?

Synthesis is the transformation of RTL, typically Verilog or VHDL, into a gate-level netlist. A synthesized gate-level Verilog netlist only contains cells! These cells are from the PDK which provides for each cell: a transistor-level schematic with transistor sizes provided, a physical layout containing information necessary for fabrication, timing libraries providing performance specifications, etc. 

Yosys is the tool used to perform synthesis in this class.
The first step in this process is the compilation and elaboration of RTL [1].
From [IEEE Std 1800-2017](https://ieeexplore.ieee.org/document/8299595), **compilation** is the process of reading RTL and analyzing it for syntax and semantic errors.
**Elaboration** is the subsequent process of expanding instantiations and hierarchies, parsing parameter values, and establishing netlist connectivity.
Elaboration returns a generic netlist formed from generic gates.
"Generic" in this context means that the design is represented structurally in terms of gates such as `CDN_flop` and `CDN_mux2` and that these gates have no physical correlation to the gates provided in the standard cell library associated with a technology.


### Introduction to Static Timing Analysis

**Static Timing Analysis (STA)** is the validation of timing performance through the analysis of timing arcs for violations.
Broadly, this involves identifying timing arcs, calculating propagation delays, and checking for setup and hold time violations.
In this section, basic delay considerations are discussed through the inspection of file fragments, and rudimentary timing analysis is introduced in accompanying exercises.

Now, two classes of delays, **cell delays** and **net delays**, are presented.
First, consider a fragment of the cell delay model for a simple inverter buffer (`A` is the input, `Y` is the output) taken from the [ASAP7](https://github.com/The-OpenROAD-Project/asap7) instructional PDK timing library.
Inspect the fragment starting from `pin(Y)`. Examining the `timing()` relation reveals a table detailing the `cell_rise` based on a template `delay_template_7x7_x1`.
That is to say, the **cell rise time** (delay through a cell) is given by a 2D-lookup of **input net transition** and cell **output capacitance**.
Additionally, observe that the `timing_sense` is defined as **positive unate**.
That is, the timing arc is defined from rising input to rising (or non-changing) output.
While it is impossible to describe the complete capabilities of timing libraries short of copying entire standards, readers should be able to perform inspection and analysis on such files as needed.

    lu_table_template (delay_template_7x7_x1) {
      variable_1 : input_net_transition;
      variable_2 : total_output_net_capacitance;
      index_1 ("5, 10, 20, 40, 80, 160, 320");
      index_2 ("0.72, 1.44, 2.88, 5.76, 11.52, 23.04, 46.08");
    }
    
    ....
      pin (Y) {
        direction : output;
        function : "A";
        power_down_function : "(!VDD) + (VSS)";
        related_ground_pin : VSS;
        related_power_pin : VDD;
        max_capacitance : 368.64;
        output_voltage : default_VDD_VSS_output;
        timing () {
          related_pin : "A";
          timing_sense : positive_unate;
          timing_type : combinational;
          cell_rise (delay_template_7x7_x1) {
            index_1 ("5, 10, 20, 40, 80, 160, 320");
            index_2 ("5.76, 11.52, 23.04, 46.08, 92.16, 184.32, 368.64");
            values ( \
              "16.3122, 18.9302, 23.4928, 31.8294, 47.9742, 80.0606, 144.088", \
              "17.7082, 20.3463, 24.858, 33.2468, 49.3778, 81.4822, 145.567", \
              "20.3545, 22.9433, 27.4932, 35.8118, 51.9385, 84.0089, 148.036", \
              "24.3952, 27.0398, 31.6149, 39.9636, 56.036, 88.0888, 152.111", \
              "29.3454, 32.0006, 36.6138, 45.0047, 61.1147, 93.221, 156.998", \
              "35.5151, 38.3592, 43.2204, 51.6798, 67.7266, 99.5716, 163.503", \
              "41.9998, 45.0837, 50.305, 59.1205, 75.1338, 107.432, 171.049" \
            );
          }

Now consider **wire delays**.
The following fragment is fabricated for instructional purposes.
Despite being fictional, this model is in fact instructive.
Based on the enclosure area of a net, a `wire_load` macro model is chosen.
Multipliers from the macro model are used to scale resistance values (ohms) and capacitance values (fF) based on cell fanout.
Combining this information allows RC delays to be determined.
Because wireload modeling is statistically driven, use of such models often yields pessimistic results.
To improve results, some companies have replaced wireload models from the foundry with wireload models derived from their own designs and observed activities.

    wire_load(10X10) {
      resistance : 6.00 ;
      capacitance : 1.30 ;
      area : 0.08 ;
      slope : 0.05 ;
      fanout_length(1, 2.0000);
      fanout_length(2, 3.2000);
      fanout_length(3, 3.4000);
      fanout_length(4, 4.1000);
      fanout_length(5, 4.6000);
      fanout_length(6, 5.1000);
    }
    default_wire_load_mode : enclosed ;

<!-- With this new information, consider how timing analysis from EECS 151/251A may now be performed using real data.
Specifically, timing analysis was previously done largely with cell and wire delays provided as context in exercises.
Correlate the above inspections to the delays that were provided in previous course material, and understand that you can now derive those delays by looking at PDK documents.
Beyond this, there are a slew of other STA topics, including correlated clocks, jitter, insertion delays, etc., but these are ignored for now. -->


<a id="task-2-putting-it-all-together"></a>

## Synthesis Environment
To perform synthesis, we will be using Yosys. However, we will not be interfacing with
Yosys directly, we will rather use Hammer. Just like in Lab 3, we have set up the basic Hammer flow for your lab exercises using a Makefile.

In this lab repository, you will see two sets of input files for Hammer:
1. Source code in the *skel* direction
2. YAML files used for Hammer inputs
   - *inst-env.yml* - Configures environment with paths to Cadence tools and their respective licenses
   - *sky130.yml* - Configures Hammer wide settings for design flow
   - *design.yml* - Settings for this particular design
   - *sim-rtl.yml* - Settings for simulating an RTL simulation this design
   - *sim-gl-syn.yml* - Settings for simulating a gate-level simulation this design

<!-- The first set of files are
the source codes for our design that you will explore in the next section. 
The second set of files are
some YAML files (`inst-env.yml`, `sky130.yml`, `design.yml`, `sim-rtl.yml`, `sim-gl-syn.yml`) that
configure the Hammer flow.  -->

<span style="color:red"> 
Of these YAML files, you should only need to modify <i>design.yml</i>, <i>sim-rtl.yml</i>, and <i>sim-gl-syn.yml</i> in order to configure the synthesis and simulation for your
design.
</span> 


### Interpreting the YAML files
For this lab, it is important to realize the differences and similarities between the YAML files supporting synthesis and simulation, *design.yml* and *sim-rtl.yml* respectively. 

#### Interpreting the YAML: *design.yml*
---
Let's examine the details of the *design.yml* file.
<br />

When you synthesize a design, you tell the tools the expected clock frequency which you anticipate the design will be run at, or the *target frequency*. The line below creates the variable `CLK_PERIOD` to be used within the YAML file and assigns to it the target clock period (which indirectly specifies the frequency) for our design (20ns). 


```yaml
gcd.clockPeriod: &CLK_PERIOD "20ns"
```

The target clock frequency directly impacts the effort of the synthesis tools. Targetting higher clock frequencies will make the tool work harder and force it to use higher-power gates to meet the constraints. A lower target clock frequency allows the tool to focus on reducing area and/or power.

<br/>

Next, we create the variable `VERILOG_SRC` for all the source files that contain the design.
```yaml
gcd.verilogSrc: &VERILOG_SRC
  - "src/gcd.v"
  - "src/gcd_datapath.v"
  - "src/gcd_control.v"
  - "src/EECS151.v"
```




This is where we specify to Hammer that we intend on using the `CLK_PERIOD` we defined earlier
as the constraint for our design. We will see more detailed constraints in later labs.

```yaml
vlsi.inputs.clocks: [
  {name: "clk", period: *CLK_PERIOD, uncertainty: "0.1ns"}
]
```

#### Interpreting the YAML: *sim-rtl.yml*
---
The *sim-rtl.yml* is used only for simulation. However, it provides similar settings as *design.yml* did for synthesis.

The snippet below sets the target frequency only for simulation. It is generally useful to separate the two as you might want to see how the circuit performs under different clock frequencies without changing
the design constraints.
```yaml
defines:
  - "CLOCK_PERIOD=20.00"
```


The snippet below shows where we list the the input files for simulation. What's different between this lists and the list in *design.yml*?
```yaml
sim.inputs:
  input_files:
    - "src/gcd.v"
    - "src/gcd_datapath.v"
    - "src/gcd_control.v"
    - "src/gcd_testbench.v"
    - "src/EECS151.v"
```

## Handshaking
A critical aspect of designing complex circuits with Verilog is the inter-module synchronization between a producer and a consumer.
"Handshaking" describes the negoitiation process two between modules to exchange information; one module (producer) initiates a transaction and the another module (consumer) agrees to continue with it or indicates it's ready to continue with another transaction. Handshake protocols have varying levels of complexity, however the most in digital logic design is a ready-valid interface. Below we describe the simplest ready-valid interface:
<center> 

| Signal 	| Description                                                                                               	|
|:------:	|-----------------------------------------------------------------------------------------------------------	|
|  ready 	| signal asserted by consumer indicating it is '*ready*' to received data on the *data* signal                  |
|  valid 	| signal asserted by the producer indciating data on the *data* signal is '*valid*' and should be consumed 	|
|  data  	| the data exchanged between the two modules                                                                	|

</center> 

The exact implementation of a ready-valid interface may vary, however the key idea is that data is only exchange when both *ready* and *valid* are asserted. This condition specifies an agreement or the 'handshake'. **A module can be both a producer and a consumer.** It is important to note that no exchange happens unless both *ready* and *valid* are asserted. Look [here](https://www.eecs151.org/files/verilog/ready_valid_interface.pdf) for more background.

## The Example Design: GCD

We have provided a circuit described in Verilog that computes the greatest common divisor (GCD) of two numbers. The implementation consists of the three modules presented in the table below:

<center> 

| Module 	| Description                                                                                               	|
|:------:	|-----------------------------------------------------------------------------------------------------------	|
| *gcd*           | The top-level module which instantiates *gcd_control* and *gcd_datapath* |
| *gcd_control*   | A FSM that handles the ready-valid interface and controls the mux selects in the datapath |
| *gcd_datapath*  | All logic to perform computation (subtraction and comparison) |

</center> 

Unlike the FIR filter from the last lab, in which the testbench constantly provided
stimuli, the GCD algorithm has a variable latency. In other words, the number of cycles for the module to compute the output is **not** constant. This is common for many modules, therefore they must indicate when the output is valid and when they are ready to receive new inputs. This is accomplished through a ready-valid interface. A block diagram and moduel declaration of the GCD top level are presented below:

<p align="center">
<img src="figs/block-diagram.png" width="600" />
</p>


```v
module gcd#( parameter W = 16 )
(
  input clk, reset,
  input [W-1:0] operands_bits_A,    // Operand A
  input [W-1:0] operands_bits_B,    // Operand B
  input operands_val,               // Are operands valid?
  output operands_rdy,              // ready to take operands

  output [W-1:0] result_bits_data,  // GCD
  output result_val,                // Is the result valid?
  input result_rdy                  // ready to take the result
);
```




 On the `operands` boundary, nothing will happen until GCD is ready to receive data (`operands_rdy`).
When this happens, the testbench will place data on the operands (`operands_bits_A` and `operands_bits_B`),
but GCD will not start until the testbench declares that these operands are valid (`operands_val`).
Then GCD will start.

The testbench needs to know that GCD is not done. This will be true as long as `result_val` is 0
(the results are not valid). Also, even if GCD is finished, it will hold the result until the testbench is
prepared to receive the data (`result_rdy`). The testbench will check the data when GCD declares
the results are valid by setting `result_val` to 1.

The contract is that if the interface declares it is ready while the other side declares it is valid, the
information must be transferred.



 Open `src/gcd.v`. This is the top-level of GCD and just i.
Separating files into control and datapath is generally a good idea. Open `src/gcd_datapath.v`.
This file stores the operands, and contains the logic necessary to implement the algorithm (subtraction and comparison). Open `src/gcd_control.v`. This file contains a state machine that handles
the ready-valid interface and controls the mux selects in the datapath. Open `src/gcd_testbench.v`.
This file sends different operands to GCD, and checks to see if the correct GCD was found. Make
sure you understand how this file works. Note that the inputs are changed on the negative edge
of the clock. This will prevent hold time violations for gate-level simulation, because once a clock
tree has been added, the input flops will register data at a time later than the testbench’s rising
edge of the clock.

## RTL-Simulation

Now simulate the design by running 

`make sim-rtl`

 The waveform is located under `build/sim-rundir/`.
Open the waveform in GTKwave (`gtkwave --dump=verilog.dump &`). You may need to scroll down to find the testbench and try
to understand how the code works by comparing the waveforms with the Verilog code. It might
help to sketch out a state machine diagram and draw the datapath.

> ### Checkoff 1: Understanding Ready-Valid Handshake
> 1. Examine how the testbench uses the `operands_rdy` and `operands_val` signals to orchestrate the simulation.
> 2. How does *gcd_control* interact with *gcd_datapath*?
> &nbsp;

## Synthesize An Example Design: GCD
In this section, we will look at the steps Hammer takes to get from RTL Verilog to all the outputs we saw in the last section. By default, Hammer places output products of VLSI flow in the *build* subdirectory. 

### Hammer and Yosys Relationship

Hammer abstracts some details of the synthesis process. 
Each step of synthesis is a seperate step executed when `make syn` is run and represents a step or sequence of step Yosys takes for the full synthesis process.  Now, synthesize the design:


1. Generate the *hammer.d* supplement Makefile. This was also the first step in Lab 2, but in this lab we'll learn what this file is. The *hammer.d* file contains a list of design-specific targets based upon the constraints we have provided inside the YAML files, in our case the GCD. Any of these targets can be run to execute different stages of the VLSI flow (we will take advatange of more targets in future labs). Visit the Hammer Read-The-Docs for more information on the [Hammer-Flow](https://hammer-vlsi.readthedocs.io/en/latest/Hammer-Flow/index.html).

    ```
    make buildfile
    ```
    Running the target also copies and extracts a tarball of the SKY130 PDK to your local workspace. It will take a while to finish if you run this command first time. The extracted PDK is not deleted when you do `make clean` to avoid unnecessarily rebuilding the PDK. To explicitly remove it, you need to remove the build folder (and you should do it once you finish the lab to save your allocated disk space since the PDK is huge). 

2. To synthesize the GCD, call `make` using the synthesis target:

    ```
    make syn
    ```

    This runs through all the steps of synthesis. The generated netlist is located at: *skel/build/syn-rundir/gcd.mapped.v*. In the file, there will be instantiation of cells from the PDK. It should look very different from the behavorial Verilog in the source files, but it functions the same. Attempt to follow an input through these gates to see the path it takes until the output. These files can be useful for debugging and evaluating your design.


### TCL?
It should be apparent by now, that Hammer isn't a tool itself, but a layer of abstraction which makes utilizing the tools easier. But how does Hammer instruct the tool what to do? It does this by generating a TCL file which contains explicit, and verbose, commands Yosys understands. This is how Hammer operates with all CAD tools, through scripts!

Let's see what's behind the curtain and analyze the TCL script Hammer generated for synthesis with Yosys. Open the TCL file located at: *skel/build/syn-rundir/syn.tcl*. You should see some TCL commands for the steps listed in the section above.

### Reports and STA
Go to *build/syn-rundir/*. There should be the following report generated as output products of synthesis: 
- *gcd.synth_stat.txt*

Go through the file and familiarize yourself with the information the report provide. 

Now, we will check the timing of the synthesized result.  To do this, swich directories to the *skel/sta* directory.  We will run the OpenSTA tool in this directory to analyze the timing.

    cd skel/sta
    make runsta

The results of the static timing analysis will be output to the terminal, and will also be saved in the file `sta_report.txt`.

 It should look similar to this:

```text
Startpoint: GCDdpath0/B_register/_70_
            (rising edge-triggered flip-flop clocked by clk)
Endpoint: GCDdpath0/A_register/_75_
          (rising edge-triggered flip-flop clocked by clk)
Path Group: clk
Path Type: max

  Delay    Time   Description
---------------------------------------------------------
   0.00    0.00   clock clk (rise edge)
   0.00    0.00   clock source latency
   0.13    0.13 ^ clk (in)
   0.00    0.13 ^ GCDdpath0/B_register/_70_/CLK (sky130_fd_sc_hd__dfxtp_1)
   0.36    0.49 v GCDdpath0/B_register/_70_/Q (sky130_fd_sc_hd__dfxtp_1)
   0.15    0.64 v GCDdpath0/_264_/Y (sky130_fd_sc_hd__nand2b_1)
   0.34    0.99 v GCDdpath0/_273_/X (sky130_fd_sc_hd__maj3_1)
   0.17    1.16 v GCDdpath0/_274_/X (sky130_fd_sc_hd__a21o_1)
   0.12    1.28 ^ GCDdpath0/_275_/Y (sky130_fd_sc_hd__a21oi_1)
   0.09    1.37 v GCDdpath0/_276_/Y (sky130_fd_sc_hd__o211ai_1)
   0.16    1.53 ^ GCDdpath0/_278_/Y (sky130_fd_sc_hd__a31oi_1)
   0.09    1.62 v GCDdpath0/_280_/Y (sky130_fd_sc_hd__o22ai_1)
   0.06    1.68 ^ GCDdpath0/_281_/Y (sky130_fd_sc_hd__nand2_1)
   0.05    1.74 v GCDdpath0/_283_/Y (sky130_fd_sc_hd__a21oi_1)
   0.16    1.90 ^ GCDdpath0/_284_/Y (sky130_fd_sc_hd__a211oi_1)
   0.08    1.98 v GCDdpath0/_285_/Y (sky130_fd_sc_hd__a41oi_1)
   0.75    2.73 ^ GCDctrl0/_09_/Y (sky130_fd_sc_hd__nor4_1)
   0.17    2.90 v GCDdpath0/_186_/X (sky130_fd_sc_hd__lpflow_isobufsrc_1)
   0.23    3.13 v GCDdpath0/_187_/X (sky130_fd_sc_hd__clkbuf_1)
   0.34    3.47 ^ GCDdpath0/_312_/Y (sky130_fd_sc_hd__a222oi_1)
   0.06    3.53 v GCDdpath0/_313_/Y (sky130_fd_sc_hd__inv_1)
   0.12    3.65 ^ GCDdpath0/A_register/_48_/Y (sky130_fd_sc_hd__mux2i_1)
   0.04    3.70 v GCDdpath0/A_register/_49_/Y (sky130_fd_sc_hd__nor2_1)
   0.00    3.70 v GCDdpath0/A_register/_75_/D (sky130_fd_sc_hd__dfxtp_1)
           3.70   data arrival time

  20.00   20.00   clock clk (rise edge)
   0.00   20.00   clock source latency
   0.13   20.13 ^ clk (in)
   0.00   20.13 ^ GCDdpath0/A_register/_75_/CLK (sky130_fd_sc_hd__dfxtp_1)
  -0.10   20.03   clock uncertainty
   0.00   20.03   clock reconvergence pessimism
  -0.08   19.94   library setup time
          19.94   data required time
---------------------------------------------------------
          19.94   data required time
          -3.70   data arrival time
---------------------------------------------------------
          16.25   slack (MET)
```

This is one of the most common ways to assess the critical paths in your circuit. 
The setup timing report lists each timing path's **slack**, which is the extra delay the signal can have before a setup violation occurs, in ascending order. The first block indicates the critical path of the design.
Each row represents a timing path from a gate to the next, and the whole block is the **timing
arc** between two flip-flops (or in some cases between latches). The `MET` at the top of the block
indicates that the timing requirements have been met and there is no violation. If there was, this
indicator would have read `VIOLATED`. Since our critical path meets the timing requirements with
a 16.25 ns of slack, this means we can run this synthesized design with a period equal to clock period (20000 ps) minus the critical path slack (16250 ps), which is 3750 ps.  

Note however that this particular analysis was done for the typical process corner.  Our slack in the slow corner will be less.

Running the OpenSTA tool will also create the SDF file, which contains the timing information for the post-synthesis simulation below.

> ###  Checkoff 2: Synthesis Understanding 
> 1. Understand the process of logic synthesis at a high level.
> 2. Where do the cells for synthesis come from?
> 3. What are the sub-steps elaboration and syn_design?
> 4. What is output of synthesis? 
> 5. The cells used in the output of the synthesis process come from where?
> 6. What is slack?
> &nbsp;

## Post-Synthesis Simulation
Make sure you run the STA tool in the above section before you try to run post-synthesis simulation, since the STA tool creates the SDF file for this simulation.

From the skel folder, type the following command:

    make sim-gl-syn
    
This will run a post-synthesis simulation using annotated delays from the `gcd.mapped.sdf` file created by the STA tool.


## Build A Parameterized ALU

In this section, you will build a parameterized arithmetic logic unit (ALU). You have three goals:
1. Write the RTL for the design
2. Verify functionality with a RTL simulation
3. Synthesize your design
  
### Write the Design
Some initial code in the *skel/src* directory (*alu.v* and *alu_testbench.v*) has been provided to help you get started.
The specifications for your ALU are:

    Parameter:
        WIDTH: Sets the bit-width of the operands and result. Default is 32 bits.

    Inputs:
        clk: input clock
        A: First operand.
        B: Second operand.
        alu_op: Operation selector that determines which ALU operation to perform.

    Output:
        result: The result of the ALU operation.

Supported Operations (determined by alu_op):

    ALU_ADD (3'b000): Addition (A + B)
    ALU_SUB (3'b001): Subtraction (A - B)
    ALU_AND (3'b010): Bitwise AND (A & B)
    ALU_OR (3'b011): Bitwise OR (A | B)
    ALU_XOR (3'b100): Bitwise XOR (A ^ B)
    ALU_SLL (3'b101): Shift Left Logical (A << B[3:0])
    ALU_SRL (3'b110): Shift Right Logical (A >> B[3:0])
    ALU_SRA (3'b111): Shift Right Arithmetic (A >>> B[3:0])

### Verify functionality with a RTL simulation
A simple testbench skeleton is also provided to you. You should change it to add more test vectors, and test your ALU with different bitwidths. You can simulate using the following command:

`make sim-rtl SIM_RTL_CONF=sim-rtl-alu.yml`

### Synthesize Your Design
To exercise your skills understanding synthesis and how to interact with yosys using Hammer, synthesize your design at two separate design points:

1. Instantiate your ALU to be a 4-bit ALU and synthesize it.
2. Instantiate your ALU to be a 32-bit ALU and synthesize it.
 
Refer to the YAML files, and general flow from the GCD example design.

	make syn DESIGN_CONF=design_alu.yml

Run static timing using:

	cd skel/sta
	make runsta_alu

Run post-synthesis simulation using:

	make sim-gl-syn SIM_GL_SYN_CONF=sim-gl-syn-alu.yml

## Questions

### Question 1: Understanding the algorithm

Hint: Look up Euclidean Algorithm for calculating GCD if you're stuck :)

By reading the provided Verilog code and/or viewing the RTL level simulations, demonstrate that
you understand the provided code:

1. Draw a table with 5 columns (cycle number, value of A_reg, value of B_reg, A_next, B_next) and fill in all of the rows for the first test vector (GCD of 27 and 15). Count the cycle number from 0 when `operands_rdy` and `operands_val` are 1. Fill in the table until the first test vector is done and upload a screenshot of the table. Use decminal number instead of binary or hex. Hint: It might be easier to view the waveforms instead of tracing the code. Hint: take a look starting at 140ns.

    | Cycle number | A_reg | B_reg | A_next | B_next |
    |:-------:|:-------:|:-------:|:-------:|:-------:|
    | 0 | 0 | 0 | 27 | 15 |
    | 1 |  |  |  |  |
    | 2 |  |  |  |  |
    | 3 |  |  |  |  |
    | ... |  |  |  |  |

2. In `src/gcd_testbench.v`, the inputs are changed on the negative edge of the clock to prevent hold time violations. Is the output checked on the positive edge of the clock or the negative edge of the clock? Why?

3. In `src/gcd_testbench.v`, what will happen if you change `result_rdy = 1;` to `result_rdy = 0;`? What state will the `gcd_control.v` state machine be in?


### Question 2: GCD Reports Questions
1. Which report would you look at to find the total number of each different standard cell that the design contains? Hint: Take a look in `build/syn-rundir/reports`.
   
2. Which report contains area breakdown by modules in the design?
  
3. What is the cell used for `A_register/q_reg[7]`? How much leakage power does `A_register/q_reg[7]` contribute? How did you find this?

### Question 3: GCD Synthesis Questions
1. Looking at the total number of instances of sequential cells synthesized and the number of `reg` definitions in the Verilog files, are they consistent? If not, why?

2. Reduce the clock period (in `design.yml`) by the amount of slack in the timing report. Now run the synthesis flow again. Does it still meet timing? Why or why not? Does the critical path stay the same? If not, what changed?

### Question 4: Delay Questions
Check the waveforms in DVE. 
```
cd build/sim-rundir
dve -vpd vcdplus.vpd &
```

1. Report the clk-q delay of `state[0]` in `GCDctrl0` at 350 ns and submit a screenshot of the waveforms showing how you found this delay.

2. Which line in the sdf file specifies this delay and what is the delay?

3. Is the delay from the waveform the same as from the sdf file? Why or why not?

### Question 5: Synthesized ALU
1. From the reports of your 4-bit synthesized ALU, determine its:
   - critical path and the slack
   - total cell area
   - maximum operating frequency in MHz from the reports (You might need to re-run synthesis multiple times to determine the maximum achievable frequency)

2. From the reports of your 32-bit synthesized divder, determine its:
   - critical path and the slack
   - total cell area
   - maximum operating frequency in MHz from the reports (You might need to re-run synthesis multiple times to determine the maximum achievable frequency)

3. Submit your ALU code and testbench to the report. Also, `git push` all your work to github repository. Add comments to explain your testbench and why it provides sufficient coverage for your divider module. (You don't have to run post-synthesis simulation for Question 5). That is, run `make sim-rtl SIM_RTL_CONF=sim-rtl-alu.yml` to verify your testbench).


## Acknowledgement

Lab re-written by Prof. Daniel Van Blerkom for Yosys/OpenSTA for Cal Poly Pomona.  Original acknowledgements below:

This lab is the result of the work of many EECS151/251 GSIs over the years including:
Written By:
- Nathan Narevsky (2014, 2017)
- Brian Zimmer (2014)

Modified By:
- John Wright (2015,2016)
- Ali Moin (2018)
- Arya Reais-Parsi (2019)
- Cem Yalcin (2019)
- Tan Nguyen (2020)
- Harrison Liew (2020)
- Sean Huang (2021)
- Daniel Grubb, Nayiri Krzysztofowicz, Zhaokai Liu (2021)
- Dima Nikiforov (2022)
- Roger Hsiao, Hansung Kim (2022)
- Chengyi Lux Zhang, (2023)
- Kevin Anderson, Kevin He (Sp2024)

<!-- 
## WASTE
Hammer abstracts some details of the synthesis process. Let's examine step-by-step what each step Hammer takes does to gain an intuition of what steps Genus performs:

1. In the *skel* directory, run the following command.
```
make buildfile
```
This generates another Makefile, *hammer.d* in the *build* subdirectory, specific to the GCD design with unique targets. We use some of these targets to run individual synthesis steps in the following commands.


2. Next, we need to provide Genus with the technology libraries from the PDK, constraints for the synthesis process (from *design.yml*), and the source code for our design. Lastly, and critically, the step always commands *Genus* to elaborate our design.
```
make redo-syn HAMMER_EXTRA_ARGS="--stop_after_step init_environment"
```

3. This step is the **generic synthesis** step. In this step, Genus converts our RTL read
in the previous step into an intermediate format, made up of technology-independent generic gates. These
gates are purely for gate-level functional representation of the RTL we have coded, and are going
to be used as an input to the next step. This step also performs logical optimizations on our design
to eliminate any redundant/unused operations.
```
    make redo-syn HAMMER_EXTRA_ARGS="--stop_after_step syn_generic"
```

4. This step is the **mapping** step. Genus takes its own generic gate-level output and converts it to
our SKY130-specific gates. This step further optimizes the design given the gates in our technology.
That being said, this step can also increase the number of gates from the previous step as not
all gates in the generic gate-level Verilog may be available for our use and they may need to be
constructed using several, simpler gates.
```
    make redo-syn HAMMER_EXTRA_ARGS="--stop_after_step syn_map"
```

5. In some designs, the pins in certain cells are hardwired to 0 or 1, which requires a tie-off cell. This step adds these cells.
```
    make redo-syn HAMMER_EXTRA_ARGS="--stop_after_step add_tieoffs"
```

6.  This step is purely for the benefit of the designer. For some designs, we may need to have a list
of all the registers in our design. In this lab, the list of regs is used in post-synthesis simulation to
generate the `force_regs.ucli`, which sets initial states of registers.
```
    make redo-syn HAMMER_EXTRA_ARGS="--stop_after_step write_regs"
```


7. The reports we have seen in the previous section are generated during this step.
```
    make redo-syn HAMMER_EXTRA_ARGS="--stop_after_step generate_reports"
``` -->
