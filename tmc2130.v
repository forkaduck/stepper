

// General Configuration Registers
`define GCONF 'h00
`define GSTAT 'h01
`define IOIN 'h04

// Velocity Dependent Driver Feature Control Register Set
`define IHOLD_IRUN 'h10
`define TPOWERDOWN 'h11
`define TSTEP 'h12
`define TPWMTHRS 'h13
`define TCOOLTHRS 'h14
`define THIGH 'h15

// SPI Mode Register
`define XDIRECT 'h2d

// DcStep Minimum Velocity Register
`define VDCMIN 'h33

// Motor Driver Register
`define MSLUT0 'h60
`define MSLUT1 'h61
`define MSLUT2 'h62
`define MSLUT3 'h63
`define MSLUT4 'h64
`define MSLUT5 'h65
`define MSLUT6 'h66
`define MSLUT7 'h67
`define MSLUTSEL 'h68
`define MSLUTSTART 'h69
`define MSCNT 'h6a
`define MSCURACT 'h6b
`define CHOPCONF 'h6c
`define COOLCONF 'h6d
`define DCCTRL 'h6e
`define DRV_STATUS 'h6f
`define PWMCONF 'h70
`define PWM_SCALE 'h71
`define ENCM_CTRL 'h72
`define LOST_STEPS 'h73

module tmc2310( input clk_in, input reset_n_in, input serial_in, output clk_out, output serial_out, output cs_out_n );

reg [ 39: 0 ] r_data_outgoing = 'b0;
wire [ 39: 0 ] data_ingoing;
reg r_enable_send = 1'b0;
reg r_send_status;

//spi clk is approximately 3.2 MHz
spi#( .SIZE( 40 ), .CS_SIZE( 1 ), .CLK_SIZE( 3 ) ) spi_1 ( .data_in( r_data_outgoing ), .clk_in( clk_in ), .clk_count_max( 3'b111 ), .serial_in( serial_in ), .send_enable_in( r_enable_send ), .cs_select( 1'b0 ), .data_out( data_ingoing ), .clk_out( clk_out ), .serial_out( serial_out ), .send_out_n( r_send_status ), .r_cs_out_n( cs_out_n ) );


reg r_state_clk;
reg [ 4: 0 ] state;
reg ready = 'b0;
parameter Start = 'd0,
          ChopConf = 'd1,
          IHold_IRun = 'd2,
          TPowerDown = 'd3,
          En_Pwm_Mode = 'd4,
          TPwm_Thrs = 'd5,
          PwmConf = 'd6;

// divide clock down to about 4MHz
clk_divider#( .SIZE( 8 ) ) divider_1 ( .clk_in( clk_in ), .max_in( 250 ), .clk_out( r_state_clk ) );

// initialization state machine
always@( posedge r_state_clk, negedge reset_n_in ) begin
    if ( !reset_n_in )
    begin
        state <= Start;
    end
    else
    begin
        if ( ready )
        begin
            r_enable_send <= 1'b0;
        end
        else
        begin
            r_enable_send <= 1'b1;
            case ( state )
                ChopConf:
                begin
                    // CHOPCONF: TOFF=3, HSTRT=4, HEND=1, TBL=2, CHM=0 (SpreadCycle)
                    r_data_outgoing <= 40'hEC000100C3;
                end

                IHold_IRun:
                begin
                    // IHOLD_IRUN: IHOLD=10, IRUN=31 (max. current), IHOLDDELAY=6
                    r_data_outgoing <= 40'h9000061F0A;
                end

                TPowerDown:
                begin
                    // TPOWERDOWN=10: Delay before power down in stand still
                    r_data_outgoing <= 40'h910000000A;
                end

                En_Pwm_Mode:
                begin
                    // EN_PWM_MODE=1 enables StealthChop (with default PWMCONF)
                    r_data_outgoing <= 40'h8000000004;
                end

                TPwm_Thrs:
                begin
                    // TPWM_THRS=500 yields a switching velocity about 35000 = ca. 30RPM
                    r_data_outgoing <= 40'h93000001F4;
                end

                PwmConf:
                begin
                    // PWMCONF: AUTO=1, 2/1024 Fclk, Switch amplitude limit=200, Grad=1
                    r_data_outgoing <= 40'hF0000401C8;
                end
            endcase
        end

        ready <= !ready;
        state <= state + 1;
    end
end
endmodule
