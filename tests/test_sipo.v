`timescale 1ns/100ps

`include "macros.v"
`include "../src/sipo.v"

module testbench();
    reg r_clk;
    reg r_reset_n;
    parameter TP = 1;
    parameter CLK_HALF_PERIOD = 5;
    
    // separate initial process that generates the clk
    initial begin
        r_clk = 0;
        #5;
        forever
            r_clk = #(CLK_HALF_PERIOD)  ~r_clk;
    end
    
    reg [31: 0] i;
    
    reg [15: 0] r_test_data_in;
    
    reg data_in = 1'b0;
    wire [7: 0] data_out;
    
    sipo #(.SIZE(8))  sipo1 (.data_in(data_in), .clk_in(r_clk), .reset_n_in(r_reset_n), .r_data_out(data_out));
    
    initial begin
        // dump waveform file
        $dumpfile("test_sipo.vcd");
        $dumpvars(0, testbench);
        
        $display("%0t:\tResetting system", $time);
        
        // create reset pulse
        r_reset_n = #TP 1'b1;
        repeat(30) @(posedge r_clk);
        
        r_reset_n = #TP 1'b0;
        repeat(30) @(posedge r_clk);
        
        r_reset_n = #TP 1'b1;
        repeat(30) @(posedge r_clk);
        
        $display("%0t:\tBeginning test of the piso module", $time);
        
        r_test_data_in = 16'habcd;
        
        // test if the sipo delivers the data in the right order
        // and doesn't miss a bit
        for (i = 0; i < 8; i++) begin
            $display("%d", i);
            data_in = r_test_data_in[i];
            repeat(1) @(posedge r_clk);
        end
        
        
        `assert(data_out, r_test_data_in[7: 0]);
        
        for (i = 8; i < 16; i++) begin
            $display("%d", i);
            data_in = r_test_data_in[i];
            repeat(1) @ (posedge r_clk);
        end
        
        `assert(data_out, r_test_data_in[15: 8]);
        
        $display("%0t:\tNo errors", $time);
        $finish;
    end
endmodule
