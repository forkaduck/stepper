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
    /// Debug leds
    pub leds: RW<u32>,

    /// Spi module IO
    pub spi_outgoing_upper: RW<u32>,
    pub spi_outgoing_lower: RW<u32>,
    pub spi_ingoing_upper: RO<u32>,
    pub spi_ingoing_lower: RO<u32>,
    pub spi_config: RW<u32>,
    pub spi_status: RO<u32>,

    /// Analog stick remote control values as 16b numbers.
    pub remote_control0: RO<u32>,
    pub remote_control1: RO<u32>,

    /// Motor control registers
    pub motor_enable: RW<u32>,
    pub motor_dir: RW<u32>,
    pub test_angle_control_upper: RW<u32>,
    pub test_angle_control_lower: RW<u32>,
    pub test_angle_status: RO<u32>,
}

/// Represents all memory mapped hardware registers.
pub struct HardwareCTX {
    pub remote_max: u32,
    pub remote_min: u32,
    pub regs: &'static mut RegIO,
}

/// Reasonable defaults for all fields of HardwareCTX.
impl Default for HardwareCTX {
    fn default() -> Self {
        HardwareCTX {
            remote_max: 50389,
            remote_min: 24800,
            regs: unsafe { &mut *(0x10000000 as *mut RegIO) },
        }
    }
}

impl HardwareCTX {
    /// Sends one 40 bit value over the spi bus hardware.
    /// Blocks if the spi module is not ready to receive new data.
    pub fn spi_blocking_send(&mut self, data_upper: u32, data_lower: u32, cs: u32) {
        unsafe {
            // Wait until ready is 1
            while (self.regs.spi_status.read() & 0x1) == 0x0 {}

            // Unset send_enable and set cs
            self.regs
                .spi_config
                .write((self.regs.spi_config.read() & !0x1f) | ((cs & 0xf) << 1));

            self.regs.spi_outgoing_upper.write(data_upper);
            self.regs.spi_outgoing_lower.write(data_lower);

            // Set send_enable
            self.regs
                .spi_config
                .write((self.regs.spi_config.read() & !0x1f) | ((cs & 0xf) << 1) | 0x1);

            // Wait for the sending to start
            while (self.regs.spi_status.read() & 0x1) == 0x1 {}
        }
    }

    /// Sends a reasonable default driver configuration to one TMC2130.
    pub fn init_driver(&mut self, index: u32) {
        use crate::motor_driver::tmc2130::*;

        // GCONF
        // I_scale_analog (external AIN reference)
        // diag0_error (diag0 active if an error occurred)
        self.spi_blocking_send(GCONF + WRITE_ADDR, 0x00000021, index);

        // CHOPCONF
        self.spi_blocking_send(CHOPCONF + WRITE_ADDR, 0x30188113, index);

        // IHOLD_IRUN IHOLDDELAY / IRUN / IHOLD
        self.spi_blocking_send(IHOLD_IRUN + WRITE_ADDR, 0x00080a0a, index);

        // TPOWERDOWN
        self.spi_blocking_send(TPOWERDOWN + WRITE_ADDR, 0x0000000a, index);

        // THIGH
        self.spi_blocking_send(THIGH + WRITE_ADDR, 0x00000020, index);

        // PWMCONF
        self.spi_blocking_send(PWMCONF + WRITE_ADDR, 0x00040a74, index);
    }

    /// Maps the value of one of the remote control register to a number
    /// range.
    pub fn get_remote_control(&mut self, max_range: u32, index: u8) -> u32 {
        let mut register = &self.regs.remote_control0;
        let mut shift = 0;

        if index == 1 || index == 3 {
            shift = 15;
        }

        if index > 1 {
            register = &self.regs.remote_control1;
        }

        let val = ((register.read() >> shift) & 0x0000ffff) - self.remote_min;

        return val * max_range / self.remote_max;
    }
}
