`timescale 1ns/100ps

`include "macros.v"
`include "../src/mux.v"

module testbench();
    reg r_clk;
    reg r_reset;
    parameter TP = 1;
    parameter CLK_HALF_PERIOD = 5;
    
    // separate initial process that generates the r_clk
    initial begin
        r_clk = 0;
        #5;
        forever
            r_clk = #(CLK_HALF_PERIOD) ~r_clk;
    end
    
    
    reg [31: 0] i;
    reg [31: 0] k;
    
    reg [2: 0] r_select = 'b0;
    wire [2: 0] r_mux_out;
    reg r_mux_in = 1'b0;
    
    mux#(.SIZE(3)) mux1(.select_in(r_select), .sig_in(r_mux_in), .clk_in(r_clk), .r_sig_out(r_mux_out));
    
    initial begin
        
        // dump waveform file
        $dumpfile("test_mux.vcd");
        $dumpvars(0, testbench);
        
        $display("%0t:\tResetting system", $time);
        
        // create reset pulse
        r_reset = #TP 1'b1;
        repeat (30) @ (posedge r_clk);
        
        r_reset = #TP 1'b0;
        repeat (30) @ (posedge r_clk);
        
        r_reset = #TP 1'b1;
        repeat (30) @ (posedge r_clk);
        
        $display("%0t:\tBeginning test of the mux module", $time);
        
        // test if the output of the mux is switchable and
        // sets the output in the array accordingly
        for (i = 0; i < 3; i++) begin
            repeat (1) @ (posedge r_clk);
            
            r_select = i[2: 0];
            r_mux_in = 1'b0;
            repeat (1) @ (posedge r_clk);
            
            for (k = i; k < 3; k = k + 1) begin
                `assert(r_mux_out[i], 1'b0);
            end
            
            r_mux_in = 1'b1;
            repeat (2) @ (posedge r_clk);
            
            for (k = 0; k < = i; k = k + 1) begin
                `assert(r_mux_out[i], 1'b1);
            end
            
            
            `assert(r_mux_out[i], 1'b1);
        end
        
        $display("%0t:\tNo errors", $time);
        $finish;
    end
    
endmodule
