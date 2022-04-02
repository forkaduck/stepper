// use core::sync::atomic::{compiler_fence, Ordering};
use core::{mem, ptr};

/// Initialize global variables.
pub unsafe fn init_data(mut sdata: *mut u32, edata: *mut u32, mut sidata: *const u32) {
    while sdata < edata {
        ptr::write(sdata, ptr::read(sidata));
        sdata = sdata.offset(1);
        sidata = sidata.offset(1);
    }

    // Ensure that any accesses of `static`s are not reordered before the `.data` section is
    // initialized.
    // We use `SeqCst`, because `Acquire` only prevents later accesses from being reordered before
    // *reads*, but this method only *writes* to the locations.
    // compiler_fence(Ordering::SeqCst);
}

/// Zero the ram section used for uninitialized variables.
pub unsafe fn zero_bss(mut sbss: *mut u32, ebss: *mut u32) {
    while sbss < ebss {
        // NOTE(volatile) to prevent this from being transformed into `memclr`
        ptr::write_volatile(sbss, mem::zeroed());
        sbss = sbss.offset(1);
    }

    // Ensure that any accesses of `static`s are not reordered before the `.bss` section is
    // initialized.
    // We use `SeqCst`, because `Acquire` only prevents later accesses from being reordered before
    // *reads*, but this method only *writes* to the locations.
    // compiler_fence(Ordering::SeqCst);
}
