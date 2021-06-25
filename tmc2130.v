
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
