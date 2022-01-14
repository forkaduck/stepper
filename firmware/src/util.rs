use core::arch::asm;

pub fn wait(instr: u32) {
    for _ in 0..instr {
        unsafe {
            asm!("nop");
        }
    }
}
