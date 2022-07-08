library fp;

dep vec384;

use ::vec384::*;
use std::u128::*;

/*
Reference implementation 
https://github.com/supranational/blst
*/

// Fp

pub fn add_fp(a: vec384, b: vec384) -> vec384 {
    add_mod_384(a, b, BLS12_381_P)
}

pub fn sub_fp(a: vec384, b: vec384) -> vec384 {
    sub_mod_384(a, b, BLS12_381_P)
}

pub fn mul_by_3_fp(a: vec384) -> vec384 {
    mul_by_3_mod_384(a, BLS12_381_P)
}

pub fn mul_by_8_fp(a: vec384) -> vec384 {
    mul_by_8_mod_384(a, BLS12_381_P)
}

pub fn lshift_fp(a: vec384, count: u64) -> vec384 {   
    lshift_mod_384(a, count, BLS12_381_P)
}

// Fp2

pub fn add_fp2(a: vec384x, b: vec384x) -> vec384x {
    let res_r = add_mod_384(a.r, b.r, BLS12_381_P);
    let res_i = add_mod_384(a.i, b.i, BLS12_381_P);
    vec384x { r: res_r, i: res_i }
}

pub fn sub_fp2(a: vec384x, b: vec384x) -> vec384x {
    let res_r = sub_mod_384(a.r, b.r, BLS12_381_P);
    let res_i = sub_mod_384(a.i, b.i, BLS12_381_P);
    vec384x { r: res_r, i: res_i }
}