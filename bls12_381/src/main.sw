script;

dep fp;
dep fp2;
dep g1;

use ::fp::Fp;
use ::fp2::Fp2;
use ::g1::G1Projective;
use std::{assert::assert};
use std::logging::log;
use ::g1::G1Affine;


//this is a temporary file for test purposes. 
// Logging in a library is easier when testing with a script. When testing through a contract that's not possible

fn main () {
    // assert(test_square_fp());
    // log(1010101);
    // assert(test_mul_fp2());
    test_double_identity();

}

// This doesn't terminate (or does it maybe give the Immediate18TooLarge after forever?)
fn test_double_identity() -> bool {
    let p_id = ~G1Projective::identity();
    let doubled = p_id.double();
    true
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

// fn test_square_fp() -> bool {
//     let a: Fp = Fp {
//         ls: [0xd215_d276_8e83_191b,
//         0x5085_d80f_8fb2_8261,
//         0xce9a_032d_df39_3a56,
//         0x3e9c_4fff_2ca0_c4bb,
//         0x6436_b6f7_f4d9_5dfb,
//         0x1060_6628_ad4a_4d90]
//     };

//     let expected_res: Fp = Fp {
//         ls: [0x33d9_c42a_3cb3_e235,
//         0xdad1_1a09_4c4c_d455,
//         0xa2f1_44bd_729a_aeba,
//         0xd415_0932_be9f_feac,
//         0xe27b_c7c4_7d44_ee50,
//         0x14b6_a78d_3ec7_a560]
//     };

//     let res = a.square();
//     res_equals(res, expected_res);
//     true
// }

fn test_mul_fp2() -> bool {
        let a = Fp2 {
        c0: Fp{ ls: [
            0xc9a2_1831_63ee_70d4,
            0xbc37_70a7_196b_5c91,
            0xa247_f8c1_304c_5f44,
            0xb01f_c2a3_726c_80b5,
            0xe1d2_93e5_bbd9_19c9,
            0x04b7_8e80_020e_f2ca,
        ]},
        c1: Fp{ ls: [
            0x952e_a446_0462_618f,
            0x238d_5edd_f025_c62f,
            0xf6c9_4b01_2ea9_2e72,
            0x03ce_24ea_c1c9_3808,
            0x0559_50f9_45da_483c,
            0x010a_768d_0df4_eabc,
        ]},
    };
    let b = Fp2 {
        c0: Fp{ ls: [
            0xa1e0_9175_a4d2_c1fe,
            0x8b33_acfc_204e_ff12,
            0xe244_15a1_1b45_6e42,
            0x61d9_96b1_b6ee_1936,
            0x1164_dbe8_667c_853c,
            0x0788_557a_cc7d_9c79,
        ]},
        c1: Fp{ ls: [
            0xda6a_87cc_6f48_fa36,
            0x0fc7_b488_277c_1903,
            0x9445_ac4a_dc44_8187,
            0x0261_6d5b_c909_9209,
            0xdbed_4677_2db5_8d48,
            0x11b9_4d50_76c7_b7b1,
        ]},
    };
    let c = Fp2 {
        c0: Fp{ ls: [
            0xf597_483e_27b4_e0f7,
            0x610f_badf_811d_ae5f,
            0x8432_af91_7714_327a,
            0x6a9a_9603_cf88_f09e,
            0xf05a_7bf8_bad0_eb01,
            0x0954_9131_c003_ffae,
        ]},
        c1: Fp{ ls: [
            0x963b_02d0_f93d_37cd,
            0xc95c_e1cd_b30a_73d4,
            0x3087_25fa_3126_f9b8,
            0x56da_3c16_7fab_0d50,
            0x6b50_86b5_f4b6_d6af,
            0x09c3_9f06_2f18_e9f2,
        ]},
    };
    let res = a.mul(b);
    res_equals(res.c0, c.c0);
    res_equals(res.c1, c.c1);
    true
}