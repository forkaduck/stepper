use volatile_register::{RO, RW};

/// Addressing constants for use with the
/// TMC2130 over SPI.
#[allow(dead_code)]
pub mod tmc2130 {
    /// Read-Write
    pub const WRITE_ADDR: u32 = 0x80;

    /// General configuration registers
    pub const GCONF: u32 = 0x00;
    pub const GSTAT: u32 = 0x01;
    pub const IOIN: u32 = 0x04;

    /// Velocity dependent driver feature control register set
    pub const IHOLD_IRUN: u32 = 0x10;
    pub const TPOWERDOWN: u32 = 0x11;
    pub const TSTEP: u32 = 0x12;
    pub const TPWMTHRS: u32 = 0x13;
    pub const TCOOLTHRS: u32 = 0x14;
    pub const THIGH: u32 = 0x15;

    /// SPI Mode register
    pub const XDIRECT: u32 = 0x2d;

    /// DcStep Minimum velocity register
    pub const VDCMIN: u32 = 0x33;

    /// Motor driver register
    pub const MSLUT0: u32 = 0x60;
    pub const MSLUT1: u32 = 0x61;
    pub const MSLUT2: u32 = 0x62;
    pub const MSLUT3: u32 = 0x63;
    pub const MSLUT4: u32 = 0x64;
    pub const MSLUT5: u32 = 0x65;
    pub const MSLUT6: u32 = 0x66;
    pub const MSLUT7: u32 = 0x67;
    pub const MSLUTSEL: u32 = 0x68;
    pub const MSLUTSTART: u32 = 0x69;
    pub const MSCNT: u32 = 0x6a;
    pub const MSCURACT: u32 = 0x6b;
    pub const CHOPCONF: u32 = 0x6c;
    pub const COOLCONF: u32 = 0x6d;
    pub const DCCTRL: u32 = 0x6e;
    pub const DRV_STATUS: u32 = 0x6f;
    pub const PWMCONF: u32 = 0x70;
    pub const PWM_SCALE: u32 = 0x71;
    pub const ENCM_CTRL: u32 = 0x72;
    pub const LOST_STEPS: u32 = 0x73;
}

/// IO registers
#[repr(C)]
pub struct RegIO {
    pub leds: RW<u32>,
    pub spi_outgoing_upper: RW<u32>,
    pub spi_outgoing_lower: RW<u32>,
    pub spi_ingoing_upper: RW<u32>,
    pub spi_ingoing_lower: RW<u32>,
    pub spi_config: RW<u32>,
    pub spi_status: RO<u32>,
}

impl RegIO {
    pub fn get_reg_io() -> &'static mut RegIO {
        unsafe { &mut *(0x10000000 as *mut RegIO) }
    }

    pub fn spi_blocking_send(&mut self, data_upper: u32, data_lower: u32, cs: u32) {
        // spi_config.read() returns 0x00000000
        // leds.read() 0xffffffff

        unsafe {
            // wait until ready is 1
            while (self.spi_status.read() & 0x1) == 0x0 {}

            // unset send_enable and set cs
            self.spi_config
                .write((self.spi_config.read() & !0x1f) | ((cs & 0xf) << 1));

            self.spi_outgoing_upper.write(data_upper);
            self.spi_outgoing_lower.write(data_lower);

            // set send_enable
            self.spi_config
                .write((self.spi_config.read() & !0x1f) | ((cs & 0xf) << 1) | 0x1);

            self.leds.write(self.spi_config.read());

            // wait until ready is 0
            while (self.spi_status.read() & 0x1) == 0x1 {}
            // wait(100);
        }
    }

    pub fn init_driver(&mut self) {
        use crate::motor_driver::tmc2130::*;

        for i in 0..3 {
            // GCONF
            // I_scale_analog (external AIN reference)
            // diag0_error (diag0 active if an error occurred)
            self.spi_blocking_send(GCONF + WRITE_ADDR, 0x00000021, i);

            // CHOPCONF
            self.spi_blocking_send(CHOPCONF + WRITE_ADDR, 0x30188113, i);

            // IHOLD_IRUN IHOLDDELAY / IRUN / IHOLD
            self.spi_blocking_send(IHOLD_IRUN + WRITE_ADDR, 0x00080a0a, i);

            // TPOWERDOWN
            self.spi_blocking_send(TPOWERDOWN + WRITE_ADDR, 0x0000000a, i);

            // THIGH
            self.spi_blocking_send(THIGH + WRITE_ADDR, 0x00000020, i);

            // PWMCONF
            self.spi_blocking_send(PWMCONF + WRITE_ADDR, 0x00040a74, i);

            // wait(200);
        }
    }
}
