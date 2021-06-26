
`include "pwm.v"
`include "spi.v"

// top module
module top ( input clk_25mhz,
             input [ 6: 0 ] btn,
             output [ 7: 0 ] led,
             inout [ 27: 0 ] gp,
             inout [ 27: 0 ] gn,
             output wifi_gpio0 );


// Tie GPIO0, keep board from rebooting
assign wifi_gpio0 = 1'b1;

reg [ 39: 0 ] r_data_outgoing = 'b0;
wire [ 39: 0 ] data_ingoing;
reg r_enable_send = 1'b0;
reg r_send_status;

//spi clk is approximately 3.2 MHz
spi#( .SIZE( 40 ), .CS_SIZE( 1 ), .CLK_SIZE( 3 ) ) spi_1 ( .data_in( r_data_outgoing ), .clk_in( clk_25mhz ), .clk_count_max( 3'b111 ), .serial_in( gn[ 0 ] ), .send_enable_in( r_enable_send ), .cs_select( 1'b0 ), .data_out( data_ingoing ), .clk_out( gn[ 2 ] ), .serial_out( gn[ 3 ] ), .send_out_n( r_send_status ), .r_cs_out_n( gn[ 1 ] ) );


wire reset_n;
reg r_state_clk;

clk_divider#( .SIZE( 25 ) ) divider_1 ( .clk_in( clk_25mhz ), .max_in( 25000000 ), .clk_out( r_state_clk ) );

parameter Start = 'b000,
          GetStatus = 'b001,
          Inbetween = 'b010,
          GetStatus2 = 'b011,
          Inbetween2 = 'b100,
          End = 'b101;

reg [ 2: 0 ] state = 'b0;
reg [ 7: 0 ] r_led = 8'b00000000;
assign led[ 7: 0 ] = r_led;

assign reset_n = ~btn[ 1 ];

always@( posedge r_state_clk, negedge reset_n ) begin
    if ( !reset_n )
    begin
        state <= Start;
        r_led[ 5: 0 ] <= 6'b00000;
    end
    else
    begin
        if ( r_send_status )
        begin
            case ( state )
                Start:
                begin
                    r_led[ 0 ] <= 1'b1;
                end

                GetStatus:
                begin
                    r_data_outgoing <= 40'h6F00000000;
                    r_enable_send <= 1'b1;
                    r_led[ 1 ] <= 1'b1;
                end

                Inbetween:
                begin
                    r_enable_send <= 1'b0;
                    r_led[ 2 ] <= 1'b1;
                end

                GetStatus2:
                begin
                    r_data_outgoing <= 40'h6F00000000;
                    r_enable_send <= 1'b1;
                    r_led[ 3 ] <= 1'b1;
                end

                Inbetween2:
                begin
                    r_enable_send <= 1'b0;
                    r_led[ 4 ] <= 1'b1;
                end

                End:
                begin
                    r_led[ 5 ] <= 1'b1;
                end
            endcase

            state <= state + 1;
        end
    end
end

// assign led[ 7: 0 ] = data_ingoing[ 39: 32 ];
endmodule
