#![feature(asm)]
#![no_std]
#![no_main]

use volatile_register::{RW, RO};

mod halt;

/// Read-Write
const WRITE_ADDR: u32 = 0x80;

/// General configuration registers
const GCONF: u32 = 0x00;
const GSTAT: u32 = 0x01;
const IOIN: u32 = 0x04;

/// Velocity dependent driver feature control register set
const IHOLD_IRUN: u32 = 0x10;
const TPOWERDOWN: u32 = 0x11;
const TSTEP: u32 = 0x12;
const TPWMTHRS: u32 = 0x13;
const TCOOLTHRS: u32 = 0x14;
const THIGH: u32 = 0x15;

/// SPI Mode register
const XDIRECT: u32 = 0x2d;

/// DcStep Minimum velocity register
const VDCMIN: u32 = 0x33;

/// Motor driver register
const MSLUT0: u32 = 0x60;
const MSLUT1: u32 = 0x61;
const MSLUT2: u32 = 0x62;
const MSLUT3: u32 = 0x63;
const MSLUT4: u32 = 0x64;
const MSLUT5: u32 = 0x65;
const MSLUT6: u32 = 0x66;
const MSLUT7: u32 = 0x67;
const MSLUTSEL: u32 = 0x68;
const MSLUTSTART: u32 = 0x69;
const MSCNT: u32 = 0x6a;
const MSCURACT: u32 = 0x6b;
const CHOPCONF: u32 = 0x6c;
const COOLCONF: u32 = 0x6d;
const DCCTRL: u32 = 0x6e;
const DRV_STATUS: u32 = 0x6f;
const PWMCONF: u32 = 0x70;
const PWM_SCALE: u32 = 0x71;
const ENCM_CTRL: u32 = 0x72;
const LOST_STEPS: u32 = 0x73;


/// IO registers
#[repr(C)]
struct RegIO {
    pub spi_outgoing_upper: RW<u32>,
    pub spi_outgoing_lower: RW<u32>,
    pub spi_ingoing_upper: RW<u32>,
    pub spi_ingoing_lower: RW<u32>,
    pub spi_config: RW<u32>,
    pub spi_status: RO<u32>,
}

impl RegIO {
    fn get_reg_io() -> &'static mut RegIO {
        unsafe { &mut *(0x10000000 as *mut RegIO)}
    }

    fn spi_wait_send(&mut self, data_upper: u32, data_lower: u32) {
        unsafe {
            // wait until ready is 1
            while !(self.spi_status.read() & 0x1 == 0x1) {
            }

            // unset spi enable pin
            self.spi_config.write(self.spi_config.read() & !0x1);

            self.spi_outgoing_upper.write(data_upper);
            self.spi_outgoing_lower.write(data_lower);

            self.spi_config.write(self.spi_config.read() | 0x1);
        }
    }

    fn init_driver(&mut self) {
        unsafe {
            self.spi_config.write(0x0);
        }
        // GCONF
        // I_scale_analog (external AIN reference)
        // diag0_error (diag0 active if an error occurred)
        self.spi_wait_send(GCONF + WRITE_ADDR, 0x00000021);

        // CHOPCONF
        self.spi_wait_send(CHOPCONF + WRITE_ADDR, 0x30188113);

        // IHOLD_IRUN IHOLDDELAY / IRUN / IHOLD
        self.spi_wait_send(IHOLD_IRUN + WRITE_ADDR, 0x00080a0a);

        // TPOWERDOWN
        self.spi_wait_send(TPOWERDOWN + WRITE_ADDR, 0x0000000a);

        // THIGH
        self.spi_wait_send(THIGH + WRITE_ADDR, 0x00000020);

        // PWMCONF
        self.spi_wait_send(PWMCONF + WRITE_ADDR, 0x00040a74);
    }
}


/// Rust entry point (_start_rust)
///
/// Zeros bss section, initializes data section and calls main. This function
/// never returns.
#[link_section = ".init.rust"]
#[export_name = "_start_rust"]
pub unsafe extern "C" fn start_rust() -> ! {
    // r0::zero_bss(&mut _sbss, &mut _ebss);
    // r0::init_data(&mut _sdata, &mut _edata, &_sidata);

    main();
}

fn wait(instr: u32) {
    for _ in 0..instr {
        unsafe {
            asm!("nop");
        }
    }
}

fn main() -> ! {
    let io = RegIO::get_reg_io();

    io.init_driver();
    loop {
    }
}
