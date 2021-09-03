#![feature(asm)]
#![no_std]
#![no_main]

extern crate panic_halt;

use riscv_rt::entry;

fn delay(cycles: u32) {
    for _ in 0..cycles {
        unsafe {
            asm!("nop");
        }
    }
}

#[entry]
fn main() -> ! {
    loop {
        unsafe {
            *(0x10000000 as *mut u32) = 0xffffffff;
        }
        delay(3125000);
    }
}
