library fp;

dep vec384;

use ::vec384::*;
use std::u128::*;

/*
Reference implementation 
https://github.com/supranational/blst
*/

pub fn add_fp(a: vec384, b: vec384) -> vec384 {
    add_mod_384(a, b, BLS12_381_P)
}