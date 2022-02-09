#![no_std]
#![no_main]
#![feature(int_abs_diff)]

use motor_driver::HardwareCTX;

mod halt;
mod init;
mod motor_driver;
mod util;

/// Rust entry point (_start_rust)
///
/// Zeros bss section, initializes data section and calls main. This function
/// never returns.
#[link_section = ".init.rust"]
#[export_name = "_start_rust"]
pub unsafe extern "C" fn start_rust() -> ! {
    extern "C" {
        static mut _sbss: u32;
        static mut _ebss: u32;

        static mut _sdata: u32;
        static mut _edata: u32;

        static _sidata: u32;
    }

    init::zero_bss(&mut _sbss, &mut _ebss);
    init::init_data(&mut _sdata, &mut _edata, &_sidata);

    main();
}

fn main() -> ! {
    let mut ctx = HardwareCTX::default();

    ctx.init_driver(0);
    ctx.init_driver(1);
    ctx.init_driver(2);

    let mut current = 180;

    unsafe {
        loop {
            if ctx.get_remote_control(16, 0) > 4 {
                ctx.regs.motor_enable.write(0x00000001);
            } else {
                ctx.regs.motor_enable.write(0x00000000);
            }

            let ch1 = ctx.get_remote_control(360, 1);

            if current != ch1 {
                if current < ch1 {
                    ctx.regs.motor_dir.write(0x00000001);
                } else {
                    ctx.regs.motor_dir.write(0x00000000);
                }

                while ctx.regs.test_angle_status.read() & 0x1 == 0x0 {}

                ctx.regs.test_angle_control_upper.write(0x00000000);
                ctx.regs.test_angle_control_lower.write(0x00000000);

                ctx.regs
                    .test_angle_control_upper
                    .write(current.abs_diff(ch1));
                ctx.regs.test_angle_control_lower.write(0x00000001);
            }
            current = ch1;
        }
    }
}
