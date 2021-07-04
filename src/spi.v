
module spi#( parameter SIZE = 40, parameter CS_SIZE = 1, parameter CLK_SIZE = 3 ) (
           input [ SIZE - 1: 0 ] data_in,
           input clk_in,
           input [ CLK_SIZE - 1: 0 ] clk_count_max,
           input serial_in,
           input send_enable_in,
           input [ CS_SIZE - 1: 0 ] cs_select,
           input reset_n_in,
           output [ SIZE - 1: 0 ] data_out,
           output clk_out,
           output serial_out,
           output [ CS_SIZE - 1 : 0 ] cs_out_n
       );

reg [ SIZE - 1 : 0 ] r_counter = 'b0;

reg r_curr_cs_n = 1'b1;

wire internal_clk;
reg r_clk_enable = 1'b0;
reg r_internal_clk_switched = 1'b0;

assign clk_out = r_internal_clk_switched;

// initialize clock divider
clk_divider#( .SIZE( CLK_SIZE ) ) clk_divider1 ( .clk_in( clk_in ), .max_in( clk_count_max ), .clk_out( internal_clk ) );

// decide if something should be sent (a sort of monoflop/delay mechanism
// which sends out the length of the buffer and then waits for another pulse
// on the enable line)
always @( posedge internal_clk, negedge reset_n_in ) begin
    if ( send_enable_in && r_counter <= SIZE ) begin
        // enable clock and cs on first counter state
        if ( r_counter == 0 ) begin
            r_curr_cs_n <= 1'b0;
            r_clk_enable <= 1'b1;
        end
        r_counter <= r_counter + 1;
    end

    case ( r_counter )
        // disable clock to form a frame end
        SIZE:
            r_clk_enable <= 1'b0;
        // disable cs a bit later to avoid a malformed frame
        SIZE + 1:
            r_curr_cs_n <= 1'b1;
    endcase

    // reset counter
    if ( !send_enable_in ) begin
        r_counter <= 'b0;
    end
    $display( "%m>\t\tsend_enable_in:%x r_counter:%x r_curr_cs_n:%x r_clk_enable:%x", send_enable_in, r_counter, r_curr_cs_n, r_clk_enable );
end

// handle clock enable signal
always@( posedge clk_in ) begin
    if ( r_clk_enable ) begin
        r_internal_clk_switched <= internal_clk;
    end
    else begin
        r_internal_clk_switched <= 1'b1;
    end
end

mux#( .SIZE( CS_SIZE ) ) mux1( .select_in( cs_select ), .sig_in( r_curr_cs_n ), .clk_in( clk_in ), .r_sig_out( cs_out_n ) );

// parallel in serial out module driving the mosi pin
piso#( .SIZE( SIZE ) ) piso1 ( .data_in( data_in ), .clk_in( r_internal_clk_switched ), .reset_n_in( reset_n_in ), .r_out( serial_out ) );

// serial in parallel out module spitting out received data
sipo#( .SIZE( SIZE ) ) sipo1 ( .data_in( serial_in ), .clk_in( r_internal_clk_switched ), .r_out( data_out ) );
endmodule
