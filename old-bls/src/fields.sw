library fields;

dep vect;
dep consts;

use vect::*;
use consts::*;
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

//TODO TEST
pub fn rshift_fp(a: vec384, count: u64) -> vec384 {
    rshift_mod_384(a, count, BLS12_381_P)
}

//TODO TEST
pub fn div_by_2_fp(a: vec384) -> vec384 {
    div_by_2_mod_384(a, BLS12_381_P)
}

//TODO TEST
pub fn mul_fp(a: vec384, b: vec384) -> vec384 {
    mul_mont_384(a, b, BLS12_381_P, P0)
}

//TODO TEST
pub fn sqr_fp(a: vec384) -> vec384 {
    sqr_mont_384(a, BLS12_381_P, P0)
}

//TODO TEST
// conditional negation
pub fn cneg_fp(a: vec384, flag: u64) -> vec384 {
    cneg_mod_384(a, flag, BLS12_381_P)
}

//TODO TEST
pub fn from_fp(a: vec384) -> vec384 {
    from_mont_384(a, BLS12_381_P, P0)
}

//TODO TEST
pub fn redc_fp(a: vec768) -> vec384 {
    redc_mont_384(a, BLS12_381_P, P0)
}

// Fp2

pub fn add_fp2(a: vec384x, b: vec384x) -> vec384x {
    let res_r = add_mod_384(a.r, b.r, BLS12_381_P);
    let res_i = add_mod_384(a.i, b.i, BLS12_381_P);
    vec384x {
        r: res_r,
        i: res_i,
    }
}

pub fn sub_fp2(a: vec384x, b: vec384x) -> vec384x {
    let res_r = sub_mod_384(a.r, b.r, BLS12_381_P);
    let res_i = sub_mod_384(a.i, b.i, BLS12_381_P);
    vec384x {
        r: res_r,
        i: res_i,
    }
}

//TODO TEST
pub fn mul_by_3_fp2(a: vec384x) -> vec384x {
    mul_by_3_mod_384x(a, BLS12_381_P)
}

//TODO TEST
pub fn mul_by_8_fp2(a: vec384x) -> vec384x {
    mul_by_8_mod_384x(a, BLS12_381_P)
}

//TODO TEST
pub fn lshift_fp2(a: vec384x, count: u64) -> vec384x {
    let res_r = lshift_mod_384(a.r, count, BLS12_381_P);
    let res_i = lshift_mod_384(a.i, count, BLS12_381_P);
    vec384x {
        r: res_r,
        i: res_i,
    }
}

//TODO TEST
pub fn mul_fp2(a: vec384x, b: vec384x) -> vec384x {
    mul_mont_384x(a, b, BLS12_381_P, P0)
}

//TODO TEST
pub fn sqr_fp2(a: vec384x) -> vec384x {
    sqr_mont_384x(a, BLS12_381_P, P0)
}

//TODO TEST
pub fn cneg_fp2(a: vec384x, flag: u64) -> vec384x {
    let res_r = cneg_mod_384(a.r, flag, BLS12_381_P);
    let res_i = cneg_mod_384(a.i, flag, BLS12_381_P);
    vec384x {
        r: res_r,
        i: res_i,
    }
}

pub fn reciprocal_fp(inp: vec384x) -> vec384x {
    //TODO
    ZERO_X
}
