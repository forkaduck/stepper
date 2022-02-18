fn main() {
    let step = 100;
    let q = (2.0_f32).powf(32.0);

    for i in -step..step {
        let temp_acos = (i as f32 / (step as f32)).acos();

        print!("{:0>16x}\n", ((temp_acos * q) as u64));
    }
}
