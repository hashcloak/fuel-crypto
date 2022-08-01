script;

dep fp;

use ::fp::*;
use std::{assert::assert};
use std::logging::log;

//this is a temporary file for test purposes. 
// Logging in a library is easier when testing with a script. When testing through a contract that's not possible

fn main () {
    assert(test_square_fp());
}

pub fn res_equals(a: Fp, b: Fp) -> bool {
    assert(a.ls[0] == b.ls[0]);
    assert(a.ls[1] == b.ls[1]);
    assert(a.ls[2] == b.ls[2]);
    assert(a.ls[3] == b.ls[3]);
    assert(a.ls[4] == b.ls[4]);
    assert(a.ls[5] == b.ls[5]);
    true
}

fn test_square_fp() -> bool {
    let a: Fp = Fp {
        ls: [0xd215_d276_8e83_191b,
        0x5085_d80f_8fb2_8261,
        0xce9a_032d_df39_3a56,
        0x3e9c_4fff_2ca0_c4bb,
        0x6436_b6f7_f4d9_5dfb,
        0x1060_6628_ad4a_4d90]
    };

    let expected_res: Fp = Fp {
        ls: [0x33d9_c42a_3cb3_e235,
        0xdad1_1a09_4c4c_d455,
        0xa2f1_44bd_729a_aeba,
        0xd415_0932_be9f_feac,
        0xe27b_c7c4_7d44_ee50,
        0x14b6_a78d_3ec7_a560]
    };

    let res = a.square();
    res_equals(res, expected_res);
    true
}