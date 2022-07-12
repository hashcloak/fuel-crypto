library definitions;

pub struct fp {
    ls: [u64; 6]
}

pub struct p1 {
    x: fp, y: fp, z: fp
}
pub struct p1_affine {
    x: fp, y: fp
}

pub struct BLS12_381_G1 {
    value: p1_affine,
}

pub struct POINTonE1 {
    x: [u64; 6],
    y: [u64; 6],
    z: [u64; 6]
}
