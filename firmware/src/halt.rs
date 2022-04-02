use core::panic::PanicInfo;
use core::sync::atomic::{self, Ordering};

/// A simple default panic handler
#[inline(never)]
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {
        atomic::compiler_fence(Ordering::SeqCst);
    }
}
