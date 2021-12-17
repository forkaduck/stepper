#![feature(asm)]
#![no_std]
#![no_main]

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
    let io = motor_driver::RegIO::get_reg_io();

    io.init_driver();
    unsafe {
        //b10101
        io.test_angle_control.write(0x0000000b);
    }

    loop {}
}
