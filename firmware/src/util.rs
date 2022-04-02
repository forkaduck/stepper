use core::arch::asm;

/// Waits for the given amount of micro instructions
pub fn wait(instr: u32) {
    for _ in 0..instr {
        unsafe {
            asm!("nop");
        }
    }
}
