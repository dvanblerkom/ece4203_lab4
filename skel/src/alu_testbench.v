`timescale 1 ns /  100 ps

module alu_testbench;
   parameter WIDTH = 32;
   reg  [WIDTH-1:0] A, B;
   reg [2:0] 	    alu_op;
   wire [WIDTH-1:0] result;
   
   alu #(WIDTH) uut (
		     .clk(clk),	      
		     .A(A),
		     .B(B),
		     .alu_op(alu_op),
		     .result(result)
		     );
   
   //--------------------------------------------------------------------
   // Setup a clock
   //--------------------------------------------------------------------
   reg 		    clk = 0;
   always #(`CLOCK_PERIOD/2) clk = ~clk;
   
   
   initial begin
      // Test addition
      A = 32'h0000_0005;
      B = 32'h0000_0003;
      alu_op = 3'b000; // ALU_ADD
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(negedge clk);
      $display("Addition Result: %h", result);
      
      // Test subtraction
      alu_op = 3'b001; // ALU_SUB
      @(posedge clk); // clock in the operation
      @(posedge clk); // clock out the result
      @(negedge clk); // wait for the negative clock edge
      $display("Subtraction Result: %h", result);
      
      // Test bitwise AND
      alu_op = 3'b010; // ALU_AND
      @(posedge clk);  // clock in the operation
      @(posedge clk);  // clock out the result
      @(negedge clk);  // wait for the negative clock edge
      $display("Bitwise AND Result: %h", result);
      
      // Add more test cases for each operation
      
      $finish;
   end
endmodule
