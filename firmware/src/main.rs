#![feature(asm)]
#![no_std]
#![no_main]

mod halt;

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

fn set_leds(data: u32) {
    unsafe {
        *(0x10000000 as *mut u32) = data;
    }
}

fn wait(instr: u32) {
    for _ in 0..instr {
        unsafe {
            asm!("nop");
        }
    }
}

fn main() -> ! {
    loop {
        set_leds(0xffffffff);
        wait(25000000 / 4);
        set_leds(0x00000000);
        wait(25000000 / 4);
    }
}
