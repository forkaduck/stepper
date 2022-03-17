use std::fs::File;
use std::io::prelude::*;

fn main() {
    let step = 100;
    let q = (2.0_f32).powf(32.0);

    let mut f_acos = File::create("arccos.mem").unwrap();
    let mut f_sqrt = File::create("sqrt.mem").unwrap();

    for i in -step..step {
        // acos [-1, 1] [300]
        let temp_acos = (i as f32 / (step as f32)).acos();
        // [0, inf] []
        let temp_sqrt = ((i + step) as f32).sqrt();

        let acos_str = format!("{:0>16x}", ((temp_acos * q) as u64));
        let sqrt_str = format!("{:0>16x}", ((temp_sqrt * q) as u64));

        f_acos
            .write_all(format!("{}\n", acos_str).as_bytes())
            .unwrap();

        println!("ACOS: {} - {} - {}", i, acos_str, temp_acos);

        f_sqrt
            .write_all(format!("{}\n", sqrt_str).as_bytes())
            .unwrap();

        println!("SQRT: {} - {} - {}", i + step, sqrt_str, temp_sqrt);
    }
}
