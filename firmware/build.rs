use std::env;
use std::fs::File;
use std::io::Write;
use std::path::Path;
use std::process::Command;

/// Put the linker script somewhere the linker can find it.
fn main() {
    let out_dir = env::var("OUT_DIR").expect("No out dir");
    let dest_path = Path::new(&out_dir);

    let mut f = File::create(&dest_path.join("memory.x")).expect("Could not create file");

    f.write_all(include_bytes!("memory.x"))
        .expect("Could not write file");

    Command::new("riscv64-unknown-elf-gcc")
    .arg("-c")
    .arg("-mabi=ilp32")
    .arg("-march=rv32i")
    .arg("src/asm.S")
    .arg("-o")
    .arg(format!("{}/boot.o", dest_path.display()))
    .output()
    .expect("Failed to execute gcc!");

    Command::new("ar")
    .arg("crs")
    .arg(format!("{}/libboot.a", dest_path.display()))
    .arg(format!("{}/boot.o", dest_path.display()))
    .output()
    .expect("Failed to execute ar");

    println!("cargo:rustc-link-search=native={}", dest_path.display());
    println!("cargo:rustc-link-lib=static=boot");

    println!("cargo:rerun-if-changed=memory.x");
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=src/asm.S");
    println!("cargo:rerun-if-changed=src/custom_ops.S");
}
