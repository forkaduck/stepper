#![no_std]
#![no_main]

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

    unsafe {
        // io.motor_dir.write(0x00000001);
        loop {
            let ding = ctx.get_remote_control(32, 1);
            ctx.regs.leds.write(ding);

            // let mut ch1 = 0x00000000;
            // while io.get_remote_control(8, 0) < 2 {
            // ch1 = io.get_remote_control(0x168 * 2, 1);
            // }

            // io.motor_enable.write(0x00000001);

            // while io.test_angle_status.read() & 0x1 == 0x0 {}

            // io.test_angle_control_upper.write(0x00000000);
            // io.test_angle_control_lower.write(0x00000000);

            // io.test_angle_control_upper.write(ch1);
            // io.test_angle_control_lower.write(0x00000001);

            // while io.test_angle_status.read() & 0x1 == 0x0 {}

            // io.test_angle_control_upper.write(0x00000000);
            // io.test_angle_control_lower.write(0x00000000);

            // io.motor_enable.write(0x00000000);
        }
    }
}
